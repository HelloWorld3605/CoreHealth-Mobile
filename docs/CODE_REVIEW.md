# CoreHealth — Senior Code Review

> Review date: 2026-05-18 · HEAD: `4a16254` · Branch: `main`
> Stack: Flutter (lib/) + Spring Boot 3.4.5 / Java 21 (backend/) + React 18 + Vite (web-react/)
> Reviewer: Claude Opus 4.7 (1M)
> Phương pháp: đọc trực tiếp toàn bộ Auth/Payment/AI/Admin layer + Flutter client + React frontend + Flyway migrations + application.yml. GitNexus index hơi stale (4 commit chậm hơn HEAD) nên một số module mới (backend, web-react) audit thuần bằng file-read.

---

## 0. Tóm tắt điều hành (TL;DR)

| Hạng mục | Đánh giá | Ghi chú |
|---|---|---|
| Kiến trúc tổng thể | ⚠️ Trung bình | Có ý tưởng đúng (BE proxy AI/SePay) nhưng client vẫn gọi thẳng → leak secrets |
| Bảo mật (security) | 🚨 **Kém** | Hardcode secrets thật vào source, payment bypass, OTP có thể leak qua API, webhook không bắt buộc xác thực, JWT thủ công, Flutter còn ôm cả API key Beeknoee + SePay |
| Auth/Authorization | ⚠️ Yếu | JWT TTL 720h, không refresh, không revoke, OTP brute-force dễ, audience check có thể bypass khi `GOOGLE_CLIENT_ID` rỗng |
| Payments | 🚨 **Lỗ hổng nghiêm trọng** | Backend tin `req.amountVnd()` của client → user có thể "trả" 1₫ vẫn được đánh dấu `paid`; user A có thể claim payment của user B |
| Performance | ⚠️ Trung bình | Read/modify/write JSON column (race condition + N+1), không streaming AI, không connection pool tuning, ChatGPT/Groq gọi blocking |
| Code quality | ⚠️ Trung bình | `main.tsx` 4238 dòng, `payment_screen.dart` 1492 dòng, `AiProxyService.fallback()` 350 dòng hardcoded — không thể bảo trì |
| Testing | 🚨 **Hầu như không có** | Chỉ 1 file test (`corehealth_app_test.dart`), backend không có test |
| Observability | ⚠️ Yếu | Trộn `System.out.println` với `slf4j`, không có metrics, không có structured logging |

**5 lỗ hổng phải xử lý trong tuần này:**

1. **Hardcode SePay token + Groq key + GHN token** trong `application.yml` (thuộc git history → rotate ngay).
2. **Payment amount trust client** — `/payments/create-order` và `/payments/cod-order` lấy `amountVnd` từ request body, không tính lại từ cart/voucher server-side.
3. **OTP leak qua API response** — khi `MAIL_USERNAME` rỗng (kể cả tạm thời lỗi SMTP), `resendOtp` trả OTP về client.
4. **Webhook SePay không có chữ ký HMAC**, key mặc định hardcoded; nếu `SEPAY_WEBHOOK_KEY=""` → mọi request được chấp nhận.
5. **Flutter app gọi thẳng Beeknoee + SePay** với key/token nhúng trong APK — anyone decompiles → có key.

---

## 1. SECURITY — 🚨 CRITICAL

### 1.1 [CRITICAL] Hardcode production secrets trong source control
**File:** `backend/src/main/resources/application.yml:27,38-45,55`

```yaml
corehealth:
  jwt:
    secret: ${COREHEALTH_JWT_SECRET:<redacted-dev-secret>}  # ← yếu, in repo
  sepay:
    api-token: ${SEPAY_API_TOKEN:<redacted-sepay-token>}
    account: ${SEPAY_ACCOUNT:<redacted-account>}
    webhook-api-key: ${SEPAY_WEBHOOK_KEY:<redacted-webhook-key>}
  ghn:
    token: ${GHN_TOKEN:<redacted-ghn-token>}
  groq:
    api-key: ${GROQ_API_KEY:<redacted-groq-key>}
```

**Vấn đề:** Token + tài khoản ngân hàng thật + API key đã commit vào public Git (`tinzisreal/Corehealth`). Bất kỳ ai clone repo đều có quyền:
- Đọc lịch sử giao dịch SePay của tài khoản `<redacted-account>`
- Gửi payment confirmation webhook giả mạo
- Tạo đơn GHN bằng tên shop 2511563
- Gọi Groq billing API

**Fix:**
1. **Rotate ngay** tất cả secrets (SePay reissue token, Groq revoke + reissue, GHN reissue).
2. Loại bỏ default literal khỏi `application.yml`: chỉ giữ `${SEPAY_API_TOKEN}` (không có fallback) → app fail-fast khi thiếu biến môi trường.
3. Chạy `git filter-repo` hoặc BFG để xoá secrets khỏi history (đã thấy `pubspec.lock` modify cho thấy đang dùng git công khai).
4. Thêm `git-secrets` / `gitleaks` pre-commit hook.

### 1.2 [CRITICAL] Payment amount bị client kiểm soát hoàn toàn
**File:** `backend/src/main/java/com/corehealth/api/web/PaymentController.java:42`, `OrderService.java:32-54`

```java
@PostMapping("/create-order")
public CreateOrderResponse createOrder(AuthUser user, @Valid @RequestBody CreateShopOrderRequest req) {
    var order = orders.createOrder(user.id(), email, req);
    var qrUrl = payments.vietQrUrl(req.amountVnd(), order.reference());  // ← amount từ client
    ...
}
```

```java
// OrderService.java
jdbc.update("insert into shop_orders (..., amount_vnd, ...) values (..., ?, ...)",
    ..., req.amountVnd(), ...);  // ← lưu nguyên amount client gửi
```

**Lỗ hổng:** User POST `amountVnd: 1` với items giá thực 5.000.000đ → SePay QR sinh ra với amount = 1₫. Sau khi user trả 1₫:
- `recordPayment(ref, 1)` so sánh `paidAmount (1) >= amountVnd (1)` → status = "paid"
- `placeOrder` + tạo đơn GHN ship hàng trị giá 5tr.

**Fix:**
```java
// Tính lại amount từ catalog server-side
int subtotalK = req.items().stream()
    .mapToInt(item -> {
        var product = catalog.findById((String) item.get("id"))
            .orElseThrow(() -> new ApiException("Sản phẩm không tồn tại"));
        int qty = (int) item.getOrDefault("qty", 1);
        return product.priceK() * qty;
    }).sum();
int discount = voucherService.computeDiscount(req.voucherCode(), subtotalK * 1000);
int shipping = ghn.calculateFee(req.districtId(), req.wardCode(), totalWeightGrams);
int finalAmountVnd = subtotalK * 1000 - discount + shipping;
// Bỏ qua req.amountVnd() — chỉ dùng finalAmountVnd.
```

Đồng thời:
- Kiểm tra voucher `used_count < max_uses` và `active = true` (hiện tại không kiểm tra).
- Khoá optimistic trên `vouchers.used_count` để tránh race khi flash sale.

### 1.3 [CRITICAL] Cross-account payment hijack qua `/payments/verify`
**File:** `PaymentController.java:68-78`

```java
@PostMapping("/verify")
public PaymentVerifyResponse verify(AuthUser user, @Valid @RequestBody PaymentVerifyRequest request) {
    boolean paid = payments.verify(request.reference(), request.amountVnd());
    if (paid) {
        orders.recordPayment(request.reference(), request.amountVnd());
        users.placeOrder(user.id());           // ← gắn vào USER hiện tại, không kiểm tra owner
        createGhnOrderIfNeeded(request.reference());
        sendOrderConfirmationIfNeeded(...);
    }
}
```

**Kịch bản:** User A tạo order ref `CH184567` 1tr, trả tiền thật. Attacker B chỉ cần biết reference (8 ký số có thể brute-force trong vòng 10 phút trước khi expire) → gọi `/verify` với `{reference: "CH184567", amountVnd: 1000000}` từ tài khoản B → hệ thống thấy SePay có giao dịch match → tự động `placeOrder` cho user B → user B nhận hàng, user A bị mất tiền và mất đơn.

**Fix:** Verify phải kiểm tra `shop_orders.user_id = user.id()` trước khi `recordPayment` hoặc `placeOrder`:
```java
var order = orders.findByReference(request.reference())
    .orElseThrow(() -> new ApiException("Không tìm thấy đơn hàng."));
if (!order.userId().equals(user.id())) throw new ApiException("Không có quyền.");
```

### 1.4 [CRITICAL] OTP leak qua API response
**File:** `backend/src/main/java/com/corehealth/api/service/OtpService.java:61`

```java
return mailEnabled ? null : otp;  // ← trả OTP plaintext nếu mail không cấu hình
```

**Kết hợp:** `AuthController.resendOtp` thẳng tay đưa `devOtp` vào response. Trong production nếu `MAIL_USERNAME` empty hoặc SMTP fail (catch nuốt exception ở line 56-58: `// log but don't fail — caller can show OTP in dev mode`), API trả OTP về client → bypass email verification hoàn toàn.

**Fix:**
```java
@Value("${corehealth.environment:production}") String env;
...
return ("development".equals(env) || "local".equals(env)) ? otp : null;
```
Và sửa logic `catch` của `mailSender.send` để fail-fast trong production (chí ít bump status code 500), không trả OTP bù vào.

Đồng thời thêm:
- Counter `attempts_left` trong `email_otps`; sau 5 lần sai → invalidate row.
- Rate limit theo email (không chỉ IP) — mỗi 60s tối đa 1 OTP per email.

### 1.5 [CRITICAL] Webhook SePay không bắt buộc xác thực
**File:** `PaymentController.java:84-87`

```java
if (!webhookApiKey.isBlank()) {
    var expected = "Apikey " + webhookApiKey;
    if (!expected.equals(authHeader)) return ResponseEntity.status(401).body(...);
}
```

**Vấn đề:**
1. Nếu env `SEPAY_WEBHOOK_KEY=""` → bỏ qua kiểm tra, mọi request đều confirm payment.
2. So sánh `String.equals` → timing attack lý thuyết.
3. SePay native nên có HMAC signature header — đang verify bằng static API key, ai có key sẽ giả webhook vô hạn.

**Fix:**
```java
if (webhookApiKey.isBlank()) {
    log.error("SEPAY_WEBHOOK_KEY chưa cấu hình — từ chối tất cả webhook");
    return ResponseEntity.status(503).body(...);
}
if (!MessageDigest.isEqual(expected.getBytes(StandardCharsets.UTF_8),
                           (authHeader == null ? "" : authHeader).getBytes(StandardCharsets.UTF_8))) {
    return ResponseEntity.status(401).body(...);
}
```
Tốt hơn: chuyển sang HMAC-signed webhook (nếu SePay hỗ trợ) hoặc verify bằng SePay transaction polling thay vì trust webhook.

### 1.6 [CRITICAL] Flutter app nhúng API key Beeknoee + SePay → ai cũng có thể trích xuất
**File:** `lib/src/services/ai_service.dart:12-17`, `food_scan_service.dart:25-26`, `sepay_service.dart:23-29`

```dart
// ai_service.dart
static const _apiKey = String.fromEnvironment('BEEKNOEE_API_KEY', defaultValue: '');
static const _baseUrl = 'https://platform.beeknoee.com';
...
headers: {'x-api-key': _apiKey, 'anthropic-version': '2023-06-01', ...}

// sepay_service.dart
static const _token = String.fromEnvironment('SEPAY_API_TOKEN', defaultValue: '');
// đã có comment "Production note: move the token to your backend proxy" nhưng chưa làm!
```

**Vấn đề:**
- `--dart-define` compile vào APK/IPA, ai cũng `strings` ra được. Tổng chi phí Beeknoee bị spam mở rộng tuỳ ý.
- App đã có backend `/api/ai/chat` rồi nhưng Flutter vẫn bypass.

**Fix:**
1. Xoá `_apiKey`, `_baseUrl`, `_model` khỏi `AiService` và `FoodScanService`.
2. Chuyển toàn bộ `_callMessages` về gọi `POST $apiBase/api/ai/chat` qua `RemoteAppRepository`.
3. Backend bổ sung endpoint `POST /api/ai/scan-food` (multipart) → BE forward lên Beeknoee.
4. Xoá `SepayService` Flutter — chỉ dùng `POST /api/payments/verify` (đã có). Sửa `payment_screen.dart` để poll qua backend.
5. Cần kiểm tra `payment_screen.dart` 1492 dòng để xác định usage.

### 1.7 [HIGH] Google OAuth audience check có thể bypass
**File:** `GoogleAuthService.java:33`

```java
if (!clientId.isBlank() && !aud.equals(clientId)) throw new ApiException(...);
```

Nếu `GOOGLE_CLIENT_ID` rỗng (cấu hình thiếu), điều kiện ngắn mạch → bỏ qua check. Attacker với bất kỳ ID token Google hợp lệ nào (kể cả từ web app khác) có thể đăng nhập với email tuỳ ý.

**Fix:** Force fail nếu `clientId.isBlank()`:
```java
if (clientId.isBlank()) throw new ApiException("Google OAuth chưa được cấu hình.");
if (!aud.equals(clientId)) throw new ApiException("Google token không khớp.");
```

Ngoài ra:
- Đang gọi `https://oauth2.googleapis.com/tokeninfo` (debug endpoint, không khuyến nghị production).
- Nên dùng `google-auth-library-oauth2-http` để verify ID token cục bộ bằng JWK Google public keys (đỡ latency, đỡ rate-limit Google).

### 1.8 [HIGH] JWT thủ công — không có `iat`, `jti`, không revoke
**File:** `TokenService.java`

- ✅ Constant-time compare đúng (`MessageDigestSafe.equals`).
- ✅ Không trust `alg` header (re-sign bằng HmacSHA256 cứng).
- 🚨 **TTL = 720h (30 ngày)** — quá dài cho bearer không revoke.
- 🚨 **Không có `jti`** → không thể blacklist khi đổi mật khẩu hoặc logout.
- 🚨 **`changePassword` không invalidate JWT** → token cũ vẫn dùng được sau khi đổi pass.
- ⚠️ Catch tất cả `Exception` và throw cùng 1 message — đúng cho security nhưng nuốt cả NPE bug.

**Fix tối thiểu:**
1. Giảm TTL xuống 24h (mobile) / 8h (web), thêm refresh token rotation lưu vào DB.
2. Thêm `jti` (UUID) vào payload, lưu vào `revoked_tokens` table khi logout / change-password.
3. Khi `changePassword` thành công, update `users.token_version`; mỗi JWT mang `v` (token version) → reject token có `v` khác user hiện tại.

### 1.9 [HIGH] User enumeration qua `/auth/check-email`
**File:** `AuthController.java:39-43`

`GET /auth/check-email?email=foo@bar.com` trả về `{exists: true|false}`. Attacker với danh sách email rò rỉ có thể quét toàn bộ user của hệ thống. Kết hợp `/auth/login` (response "Email hoặc mật khẩu không đúng" — đúng là khá generic, ổn) nhưng `check-email` thì lộ thẳng.

**Fix:**
- Bỏ endpoint này. Frontend kiểm tra email trùng bằng cách submit register thực, server response `Email đã được đăng ký`.
- Nếu muốn giữ UX (check khi gõ xong email), bọc thêm captcha hoặc rate limit cực gắt (1/phút/IP riêng cho endpoint này).

### 1.10 [HIGH] WebSocket payment không có auth
**File:** `PaymentWebSocketHandler.java:33-43`

```java
public void afterConnectionEstablished(WebSocketSession session) {
    var reference = extractReference(session);
    if (reference == null || reference.isBlank()) { session.close(...); return; }
    sessions.put(reference.toLowerCase(), session);  // ← ai cũng connect được
}
```

Reference 8 ký số, brute-force trong vòng 10 phút expire khả thi. Attacker subscribe `?reference=CH18045xxx` lặp lại → khi user khác trả tiền, sẽ nghe lén được event với amount.

**Fix:**
- Yêu cầu JWT token trong query (`?token=...`) hoặc cookie, decode trong `afterConnectionEstablished`, check `shop_orders.user_id = token.user_id`.
- Tăng entropy reference (UUIDv7 hoặc 16 ký tự ngẫu nhiên).

### 1.11 [MEDIUM] localStorage JWT trên web → XSS = mất account
**File:** `web-react/src/api.ts:98-103`

```ts
private token = localStorage.getItem('corehealth_token') ?? '';
setToken(token: string) {
    this.token = token;
    localStorage.setItem('corehealth_token', token);
}
```

`localStorage` đọc được từ mọi JS chạy trên domain. Bất kỳ XSS nào (qua content review, ảnh URL không sanitize, voucher input...) → đánh cắp token hợp lệ trong 30 ngày.

**Fix:**
- Backend set `Set-Cookie: corehealth_token=...; HttpOnly; Secure; SameSite=Strict; Path=/api`.
- React đọc `credentials: 'include'` khi fetch.
- Bổ sung CSRF token cho POST/PUT/DELETE.

### 1.12 [MEDIUM] Postgres-specific SQL trộn với H2 default
**File:** `application.yml:8` (H2 default), `AdminService.java:42-48,91`

```java
"select to_char(date_trunc('day', created_at), 'DD/MM') as label, ..."  // Postgres only
"update users set role = ? where id = ?::uuid"                          // ::uuid cast Postgres
```

Khi chạy dev với H2 fallback → endpoint admin/revenue và admin/users/{id}/role sẽ ném SQL exception → ApiExceptionHandler catch → trả 500 generic.

**Fix:**
- Force Postgres profile cho cả dev (Docker compose Postgres trong `docker-compose.dev.yml`).
- Hoặc dùng JOOQ/native dialect-aware query.
- Hoặc viết 2 query (Postgres + H2) tách Profile.

### 1.13 [MEDIUM] Không có `Content-Security-Policy`, `X-Frame-Options`, `HSTS`
**File:** Toàn bộ backend không có security headers. Spring Security không được dùng, `WebConfig` chỉ có CORS.

**Fix:** Thêm filter:
```java
@Component
public class SecurityHeadersFilter extends OncePerRequestFilter {
    protected void doFilterInternal(...) {
        response.setHeader("X-Content-Type-Options", "nosniff");
        response.setHeader("X-Frame-Options", "DENY");
        response.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
        response.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
        chain.doFilter(request, response);
    }
}
```

### 1.14 [LOW] Mật khẩu mới chỉ check length 6 ký tự
**File:** `UserService.java:262`

```java
if (newPassword.length() < 6) throw new ApiException("Mật khẩu mới phải ít nhất 6 ký tự.");
```

Không check entropy, không check common passwords. Đăng ký cũng không validate ở backend ngoài bcrypt.

**Fix:** Thêm rule tối thiểu 8 ký tự, có chữ + số, hoặc dùng `passay` lib.

---

## 2. AUTHENTICATION & AUTHORIZATION

### 2.1 [HIGH] Flutter không persist JWT
**File:** `lib/src/data/remote_app_repository.dart:15-19`

```dart
String? _token;

Future<AppBootstrapData> bootstrap() async {
    if (_token == null || _token!.isEmpty) return const AppBootstrapData();
    ...
}
```

`_token` chỉ tồn tại trong memory → mỗi lần kill app, user phải login lại. Cũng có nghĩa: nếu `COREHEALTH_API_BASE_URL` được set, app không có khả năng "remember me".

**Fix:** Dùng `flutter_secure_storage` (Android: EncryptedSharedPreferences/Keystore, iOS: Keychain).
```dart
final _storage = const FlutterSecureStorage();
Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt', value: token);
    _token = token;
}
Future<void> _loadToken() async {
    _token = await _storage.read(key: 'jwt');
}
```

### 2.2 [HIGH] AuthFilter dùng `response.sendError` → trả HTML error page
**File:** `AuthFilter.java:37,46`

```java
response.sendError(401, "Missing bearer token");
```

`sendError` ủy thác cho container render error page (servlet error mapping). Trên Spring Boot mặc định nó trả HTML/JSON tuỳ Accept header, không nhất quán. Client mong JSON.

**Fix:**
```java
response.setStatus(401);
response.setContentType("application/json");
response.getWriter().write("{\"message\":\"Phiên đăng nhập đã hết hạn.\"}");
```

### 2.3 [MEDIUM] `OtpService.verify` không có brute-force counter
**File:** `OtpService.java:64-73`

10 phút TTL × 1M tổ hợp × 100 req/min (RateLimitFilter) qua nhiều IP proxy → có thể quét vào trong vài giờ. Cần invalidate row sau 5 lần verify sai.

### 2.4 [MEDIUM] `__NEEDS_VERIFICATION__:` magic string
**File:** `UserService.java:74`, `ApiExceptionHandler.java:22-25`

Truyền state qua message exception là anti-pattern. Tạo `NeedsVerificationException(email)` subclass, handler check theo type.

### 2.5 [LOW] `request.setAttribute("authUser", ...)` không type-safe
**File:** `AuthFilter.java:43`, `WebConfig.java:52`

Dùng request attribute String key → typo runtime error. Spring có cách clean hơn: implement `HandlerInterceptor` đặt vào `RequestAttributes`, hoặc dùng `@AuthenticationPrincipal` của Spring Security.

---

## 3. PAYMENTS & ORDERING

### 3.1 [CRITICAL] Race condition trên cart/orders JSON
**File:** `UserService.java:172-189`, `placeOrder` (198-214)

```java
@Transactional
public PersistedUserDataDto addToCart(UUID userId, ProductDto product) {
    var row = findUser(userId).orElseThrow();         // SELECT *
    var cart = new ArrayList<>(json.mapList(...));    // parse JSON
    cart.add(productMap(product));
    jdbc.update("update users set cart_json = ? ...", json.write(cart), userId);  // OVERWRITE
}
```

Pattern này **read-modify-write trong transaction nhưng không SELECT FOR UPDATE**. Hai request đồng thời `addToCart` của cùng user → một bản update đè bản kia → mất sản phẩm. Tương tự `placeOrder`, `toggleWorkout`, `updateWeight`, `saveAiPlans`, `saveChatSessions`.

**Fix:**
1. Ngắn hạn: `select ... for update` trong cùng transaction:
   ```java
   jdbc.queryForList("select * from users where id = ? for update", userId);
   ```
2. Trung hạn: normalize ra bảng `cart_items(user_id, product_id, qty, added_at)` — atomic INSERT/UPDATE/DELETE.
3. JSON column hiện tại chỉ hợp lý cho data immutable/snapshot (profile lưu trữ OK), không hợp lý cho cart/orders đang sống.

### 3.2 [CRITICAL] Hai nguồn truth cho orders
Có **2 cách lưu order**:
- `users.orders_json` (legacy, `UserService.placeOrder` thêm vào)
- `shop_orders` (proper, `OrderService.createOrder` insert)

`placeOrder` chỉ tạo snapshot trong `orders_json`, không tham chiếu `shop_orders.id`. Frontend hiển thị từ `orders_json`, backend admin xem từ `shop_orders`. **Drift là chắc chắn xảy ra.**

**Fix:** Bỏ `orders_json`, đọc orders từ `shop_orders` qua query `select * from shop_orders where user_id = ? order by created_at desc limit 50`.

### 3.3 [HIGH] Reference collision khi traffic cao
**File:** `OrderService.java:137`

```java
private String generateReference() {
    return "CH" + String.valueOf(System.currentTimeMillis()).substring(5);
}
```

`millis().substring(5)` → 8 ký số. Hai user click cùng millisecond → cùng reference → `processWebhookPayment` `findFirst()` chọn nhầm order.

**Fix:** `"CH" + Base32.encode(UUID.randomUUID()).substring(0, 10)` hoặc `Random.alphanumeric(10)`. Đảm bảo entropy ≥ 50 bits.

### 3.4 [HIGH] Voucher logic không check `max_uses` / `active`
**File:** `OrderService.java:57-59`

```java
if (req.voucherCode() != null && !req.voucherCode().isBlank()) {
    jdbc.update("update vouchers set used_count = used_count + 1 where code = ?", req.voucherCode().toUpperCase());
}
```

Không kiểm tra `used_count < max_uses` và `active = true` trước khi áp dụng discount. Voucher có `max_uses=1` có thể được dùng vô hạn.

**Fix:**
```java
int rows = jdbc.update("""
    update vouchers set used_count = used_count + 1
    where code = ? and active = true and used_count < max_uses
    """, code);
if (rows == 0) throw new ApiException("Voucher không khả dụng hoặc đã hết lượt.");
// Đồng thời tính discount server-side, không trust req.discountVnd()
```

### 3.5 [MEDIUM] `expireStaleOrders` chạy mỗi lần `createOrder`/`listAll`
**File:** `OrderService.java:33,123-128`

Mỗi POST /create-order chạy 1 UPDATE quét toàn bảng `shop_orders` để expire. Lúc traffic cao → tốn IO.

**Fix:** Tách ra `@Scheduled(fixedRate = 60_000)` job riêng. Index `(status, expires_at)` để query nhanh.

### 3.6 [MEDIUM] GHN weight cứng 200g/sản phẩm
**File:** `GhnService.java:174,184`

```java
"quantity", 1, "weight", 200
...
"weight", Math.max(200, itemList.size() * 200),
```

Cốc whey 5kg → vẫn báo 200g → GHN tính phí sai. Backend trừ phí sai cho user.

**Fix:** Thêm `weight_grams` vào ProductDto, lấy từ catalog khi build GHN payload.

### 3.7 [LOW] `expiresAt` của order = 10 phút — UX hạn chế cho người chuyển khoản chậm

Mã ngân hàng Việt Nam có khi 5-15 phút mới thấy giao dịch. 10 phút khá tight. Đề xuất 30 phút và tách hai trạng thái: `awaiting_payment` (chờ tiền) và `confirmed_pending_ship` (đã nhận tiền).

---

## 4. AI PROXY & EVALS

### 4.1 [HIGH] Không có per-user rate limit cho AI
**File:** `AiController.java:33-36`

`RateLimitFilter` chỉ giới hạn 100req/phút theo IP. Một user authenticated có thể spam `/api/ai/chat` (chi phí token Beeknoee + Groq) hoặc gửi 1MB prompt → đốt budget.

**Fix:**
- Bucket riêng cho `/api/ai/*` theo `user.id()`: ví dụ 20 req/giờ free, 100 req/giờ paid.
- Validate `request.message().length() <= 2000` ở DTO (`@Size(max=2000)`).
- Validate `request.history().size() <= 20`.

### 4.2 [HIGH] `System.out.println` thay vì `slf4j`
**File:** `AiProxyService.java:91, 100, 111, 122, 130, 618, 653, 694, 697`

```java
System.out.println("[CoreHealth AI] Beeknoee primary failed: " + e.getMessage());
```

- Không có log level, không có timestamp/thread, không có MDC để correlate request.
- Stdout không rotate, /var/log/ phình to.
- Mọi service khác đã dùng `slf4j` (e.g. `GhnService`).

**Fix:**
```java
private static final Logger log = LoggerFactory.getLogger(AiProxyService.class);
...
log.warn("AI provider failed: beeknoee primary, model={}", model, e);
```

### 4.3 [HIGH] Hardcoded 350-line medical fallback
**File:** `AiProxyService.java:143-498` (`fallback()` method)

Khi tất cả provider fail, hệ thống trả lời người dùng bằng template Java với:
- Lời khuyên BMI ngưỡng béo phì
- Liều supplement (creatine, magie 200mg, Vitamin D 1000-2000 IU)
- Khuyên "giảm cân ≤ 0.5kg/tuần", "không dưới 1200 kcal/ngày (nữ) hoặc 1500 (nam)"

**Vấn đề:**
1. **Tính chất y tế** — đây là medical advice, có thể bị TT.16/2018 (luật khám chữa bệnh VN) áp dụng nếu sản phẩm chính thức.
2. **Hardcoded → khó update** — sai số liệu cho người có comorbidity.
3. Comment ở line 4 README ghi "không phải bác sĩ" nhưng app vẫn cho advice.

**Fix:**
- Tách fallback ra file content riêng (Markdown/JSON), code load runtime.
- Thêm disclaimer rõ ràng: "Đây là gợi ý chung, không thay thế bác sĩ. Nếu bạn có bệnh ${conditions}, vui lòng tham vấn chuyên gia."
- Hoặc đơn giản hơn: khi tất cả LLM fail, trả lời ngắn gọn "Đang bận, vui lòng thử lại sau" — không cho lời khuyên hardcoded.

### 4.4 [MEDIUM] PII/PHI gửi tới nhiều LLM không cùng nước
**File:** `AiProxyService.chat()` — fan-out Beeknoee → Groq (US) → OpenRouter/local.

Bệnh án, dị ứng, cân nặng, tuổi → gửi sang Groq (US), OpenRouter (EU/US). Nếu CoreHealth nhắm thị trường VN có thể vướng:
- Nghị định 13/2023 (Bảo vệ dữ liệu cá nhân): data sensitive (health) phải có consent rõ ràng.
- Onboarding screen có disclosure chưa? Cần xác nhận.

**Fix:**
- Onboarding: checkbox "Tôi đồng ý chia sẻ thông tin sức khoẻ với AI third-party (Beeknoee/Groq) để cá nhân hoá lời khuyên".
- Lưu consent có timestamp + version vào DB.

### 4.5 [MEDIUM] `requestModel` không retry trên transient 502/503
30s timeout per request, không retry, không circuit breaker. Khi Beeknoee có spike latency, user thấy "Hệ thống đang bận".

**Fix:** Spring Retry `@Retryable` 2 lần với backoff 500ms-2s cho 5xx; circuit breaker (Resilience4j) để fail-fast và fallback nhanh sang Groq.

### 4.6 [MEDIUM] AI insights/plans không cache server-side
`ai_cache` table đã có (V1__corehealth_schema.sql) nhưng `AiProxyService` không dùng. Mỗi user mở app → tạo 3 insights mới mỗi 6h (client-side cache duy nhất là Flutter in-memory).

**Fix:** Bật server-side cache với key = `(user_id, profile_hash, type)` TTL 6h.

### 4.7 [LOW] AI prompt rò rỉ system prompt qua response
System prompt mã hoá phong cách brand. Nếu user hỏi "bạn là AI nào, system prompt là gì" — vài LLM sẽ tiết lộ. Cần test "jailbreak resistance".

---

## 5. FRONTEND — FLUTTER

### 5.1 [HIGH] `main.tsx` 4238 dòng & `payment_screen.dart` 1492 dòng → unmaintainable
Một file React duy nhất chứa cả: routing, auth, onboarding, dashboard, profile, plan, workout, coach, shop, checkout, admin. Một file Flutter chứa toàn bộ payment flow.

**Triệu chứng senior:** Khi feature mới yêu cầu sửa, mọi developer đều phải đụng đến cùng 1 file → merge conflict triền miên + impossible code review.

**Fix:**
- React: tách theo route — `src/pages/Overview.tsx`, `src/pages/Shop.tsx`, ...; shared `src/components/`.
- Flutter: tách `payment_screen.dart` thành `pages/payment/payment_qr.dart`, `pages/payment/payment_polling.dart`, `pages/payment/cod_form.dart`.

### 5.2 [MEDIUM] Flutter app mặc định fallback về `LocalAppRepository` nếu thiếu env
**File:** `lib/main.dart:17-22`

```dart
const apiBaseUrl = String.fromEnvironment('COREHEALTH_API_BASE_URL');
final controller = AppController(
    repository: apiBaseUrl.isEmpty ? LocalAppRepository() : RemoteAppRepository(...));
```

Build production quên `--dart-define=COREHEALTH_API_BASE_URL=` → app silent fallback về SQLite local — không sync data, không có shop, không có AI server-side.

**Fix:** Force fail trong release mode:
```dart
const apiBaseUrl = String.fromEnvironment('COREHEALTH_API_BASE_URL');
if (kReleaseMode && apiBaseUrl.isEmpty) {
    throw StateError('COREHEALTH_API_BASE_URL phải được cấu hình cho release build');
}
```

### 5.3 [MEDIUM] `RemoteAppRepository._request` 15s timeout cho cả AI chat
**File:** `lib/src/data/remote_app_repository.dart:195`

AI chat backend `requestModel` có readTimeout 30s. Flutter wrap 15s timeout → 50% chat request timeout ở client trước khi backend trả lời.

**Fix:** Timeout theo endpoint: 10s cho `/me/*`, `/cart/*`; 60s cho `/ai/*`; 90s cho `/ai/scan-food`.

### 5.4 [LOW] Cart UI không có quantity
`Product` model thiếu `qty`. User thêm cùng product 2 lần → BE bỏ qua (`noneMatch(item.id)` ở `UserService.addToCart:175`). Sản phẩm như "Whey 1kg" hai bao không thể add.

**Fix:** Thêm field `quantity` vào `ProductDto` cart, BE merge thay vì skip.

### 5.5 [LOW] Plan rotation 7 ngày AI lặp lại nguyên xi
**File:** `app_controller.dart:120-124`

```dart
return List.generate(days, (i) => MealPlanDay(dayNumber: i+1, meals: tpl[i % tpl.length].meals));
```

180 ngày = 25.7 lần lặp lại đúng cùng menu. Bot perception khá rõ — đề xuất xáo trộn hoặc gọi AI sinh mới mỗi 30 ngày.

---

## 6. FRONTEND — REACT

### 6.1 [HIGH] Toàn bộ app trong 1 file 4238 dòng
Đã nêu 5.1. Reload mỗi lần edit là full re-render toàn site.

### 6.2 [MEDIUM] Không có protected route component
Auth state quản lý trong useState local, mọi page tự check. Sửa 1 chỗ → quên 1 chỗ. Nên có `<RequireAuth>` HOC + `<RequireAdmin>`.

### 6.3 [LOW] CAPTCHA token nullable không validate
**File:** `api.ts:113,145`

```ts
{ ..., captchaToken: captchaToken || null }
```

Nếu Turnstile script chưa load → submit với token null → backend `TurnstileService.verify(null, ip)` → return false → "Xác minh CAPTCHA thất bại". Tốt, nhưng UX: disabled button cho đến khi Turnstile sẵn sàng.

---

## 7. PERFORMANCE

### 7.1 [HIGH] Mỗi mutate trả về SELECT của user → N+2 query / request
**File:** `UserService.java` — pattern `findUser(userId).orElseThrow()` xuất hiện 2-3 lần trong mỗi mutation (`addToCart`, `removeCartIndex`, `placeOrder`, `updateSubscription`...).

```java
var row = findUser(userId).orElseThrow();           // SELECT *
// modify
jdbc.update("update users set ... where id = ?");   // UPDATE
return data(findUser(userId).orElseThrow());        // SELECT * lần 2
```

→ 2-3 round-trip cho mỗi mutation. Nhân lên ở `/cart/items`, `/me/weight` (gọi mỗi lần cân lại).

**Fix:** Postgres hỗ trợ `update ... returning *`:
```java
var rows = jdbc.queryForList("update users set cart_json = ? where id = ? returning *", json.write(cart), userId);
return data(rows.get(0));
```

### 7.2 [MEDIUM] `select *` toàn bộ users (gồm BCrypt hash, JSON columns lớn) mỗi request
**File:** mọi mutation/`bootstrap` trong `UserService`.

User có 6 tháng dữ liệu chat + ai_plans + weight_history → row có thể 500KB. Mỗi request kéo nguyên row qua wire để chỉ update 1 field.

**Fix:** Specific SELECT columns; tách `chat_sessions` ra bảng riêng (đã có thiết kế?).

### 7.3 [MEDIUM] Không có connection pool config
**File:** `application.yml` — không thấy `spring.datasource.hikari.*`. Spring Boot mặc định 10 connections.

Production Postgres trên Heroku/Render thường 20-100 connection limit. Với 1 instance × 10 conn = OK; nhiều instance + worker → cạn pool.

**Fix:** Tuning:
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 2
      connection-timeout: 5000
      max-lifetime: 1800000
```

### 7.4 [MEDIUM] AI request trong tomcat worker thread
**File:** `AiController.chat` synchronous → worker thread bị block 5-30s mỗi request. Tomcat default 200 thread → 200 chat đồng thời ⇒ block toàn server.

**Fix:** Trả về SSE/streaming hoặc `@Async + DeferredResult<ChatResponse>` để giải phóng worker.

### 7.5 [LOW] `RateLimitFilter` map vô hạn → memory leak
**File:** `RateLimitFilter.java:33-36`

`generalBuckets`/`authBuckets`/`violations`/`bannedIps` không có TTL eviction. IP attacker random từng request → memory tăng tuyến tính.

**Fix:** Spring Scheduled cleanup mỗi 5 phút quét map, remove entry có `windowStart < now - 10*WINDOW_MS`; hoặc dùng Caffeine cache với `expireAfterAccess`.

### 7.6 [LOW] `RateLimitFilter` không scale ngang
Một instance backend → OK. Nếu chạy 2+ replicas → mỗi instance có map riêng → 100rpm trên mỗi instance.

**Fix khi scale:** Redis-backed token bucket (Bucket4j có Redis integration).

---

## 8. CODE QUALITY

### 8.1 [HIGH] Thiếu test
**File:** chỉ tìm thấy `test/corehealth_app_test.dart` (1 file Flutter). Backend `src/test/` rỗng. React không có test.

Một codebase 9.825 dòng (5 file critical) không thể không có test với một sản phẩm release Play Store + App Store.

**Fix tối thiểu:**
- Backend: `@SpringBootTest` cho `AuthController.register → verify-otp → login` flow. `MockMvc` cho `PaymentController` (đảm bảo amount tính server-side, ownership check).
- Flutter: widget test cho `AuthScreen`, integration test cho cart→checkout flow.
- CI gate ≥ 60% coverage cho service layer.

### 8.2 [MEDIUM] `@SuppressWarnings("unchecked")` rải rác — đánh dấu nhưng không sửa
Toàn bộ JSON parse `Map<String, Object>` được cast bằng SuppressWarnings. Có Jackson `TypeReference` rồi — nên dùng record DTO.

### 8.3 [MEDIUM] Magic strings & magic numbers
- `"__NEEDS_VERIFICATION__:"` (UserService.java:74)
- `OTP_TTL_SECONDS = 600` (OtpService)
- `expiresAt = Instant.now().plusSeconds(600)` (OrderService)
- `"loseWeight"`, `"gainMuscle"`, `"maintain"` (rải rác)

**Fix:** Constants/enums; share enum giữa BE và Flutter qua codegen (OpenAPI hoặc protobuf).

### 8.4 [LOW] Code chết trong `AiProxyService`
`appendSafetyLine` (line 538), `trimNumber` (line 573), `bmr` variable không return — không gọi từ đâu. Cleanup.

### 8.5 [LOW] Worktrees không nằm trong `.gitignore`
`.claude/worktrees/feat+app-polish/`, `.claude/worktrees/feat+smart-food-scan/`, `.claude/worktrees/fix+payment-flow/` xuất hiện trong file system → có thể accidental commit duplicate code.

**Fix:** `.gitignore` thêm `.claude/worktrees/`.

---

## 9. OBSERVABILITY & OPERATIONS

### 9.1 [HIGH] Không có healthcheck đầy đủ
`GET /api/health` chỉ trả `"ok"`. Không check DB, không check SMTP, không check AI provider.

**Fix:** Bật Spring Actuator:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```
Expose `/actuator/health` (DB component, mail component), `/actuator/metrics`.

### 9.2 [MEDIUM] Không có request ID / correlation
Khi user báo lỗi, không có cách trace lại request log. Cần `MDC` filter inject `X-Request-Id`.

### 9.3 [MEDIUM] `ApiExceptionHandler.fallback` log full stack nhưng generic message — OK nhưng không ghi user ID
Khi 500 xảy ra với user X, cần biết `user_id`, `path`, `request_body` (masked). Hiện chỉ log stack.

### 9.4 [LOW] Không có rate-limit/abuse metrics
`RateLimitFilter` có ban IP nhưng không export metric. Khó tune threshold.

---

## 10. KIẾN TRÚC & SCHEMA

### 10.1 [HIGH] `users` table là god-object
JSON columns: `profile_json`, `weight_history_json`, `completed_workout_days_json`, `completed_meal_days_json`, `cart_json`, `orders_json`, `chat_sessions_json`, `ai_plans_json`.

Mọi thao tác đụng đến `users` → row bị lock cả gần chục field tách biệt logic.

**Fix incrementally:**
- V9: `weight_history(user_id, label, weight, recorded_at)`
- V10: `cart_items(user_id, product_id, qty, added_at)`
- V11: `workout_completions(user_id, day_number, completed_at)`
- V12: `chat_messages(session_id, role, content, created_at)`
- Giữ `profile_json` (immutable snapshot per change) là OK.

### 10.2 [MEDIUM] Không có audit table cho admin actions
Admin có thể setRole, toggleVoucher, createVoucher — không log ai làm gì lúc nào.

**Fix:** `admin_audit_log(id, admin_id, action, target_id, payload_json, created_at)`.

### 10.3 [MEDIUM] `ai_cache` table có sẵn nhưng không dùng — dead schema
Xoá hoặc dùng (xem 4.6).

### 10.4 [LOW] H2 file mode `./temp/corehealth` checked in?
File `temp/gradle-error.txt` untracked. Đảm bảo `temp/` trong `.gitignore`.

---

## 11. CHECKLIST KHẨN CẤP (≤ 1 tuần)

| Ưu tiên | Việc | File chính |
|---|---|---|
| 🚨 P0 | Rotate SePay token, Groq key, GHN token, đổi JWT secret | `application.yml` |
| 🚨 P0 | Tính `amountVnd` server-side từ catalog + voucher + GHN fee | `OrderService.java`, `PaymentController.java` |
| 🚨 P0 | Verify ownership `shop_orders.user_id == authUser.id` trong `/payments/verify` | `PaymentController.java:68-78` |
| 🚨 P0 | Tắt OTP-in-response trong prod | `OtpService.java:61`, `AuthController.java:55` |
| 🚨 P0 | Webhook key bắt buộc, từ chối khi blank; constant-time compare | `PaymentController.java:84` |
| 🚨 P1 | Xoá Beeknoee API key + SePay token khỏi Flutter, route qua BE | `ai_service.dart`, `food_scan_service.dart`, `sepay_service.dart` |
| 🚨 P1 | Force fail `GoogleAuthService` khi `clientId` blank | `GoogleAuthService.java:33` |
| ⚠️ P1 | Persist JWT bằng `flutter_secure_storage` | `remote_app_repository.dart` |
| ⚠️ P1 | Add `for update` hoặc normalize cart/orders | `UserService.java` |
| ⚠️ P1 | Tăng entropy reference + WebSocket auth | `OrderService.java`, `PaymentWebSocketHandler.java` |
| ⚠️ P2 | Bỏ `/auth/check-email` hoặc rate-limit gắt | `AuthController.java:39` |
| ⚠️ P2 | Tách `main.tsx` và `payment_screen.dart` | React + Flutter |
| ⚠️ P2 | Bật Spring Actuator healthcheck + correlation ID | backend config |
| ⚠️ P3 | Migration cart_items / weight_history ra bảng riêng | new V9 migrations |
| ⚠️ P3 | Per-user rate limit cho `/api/ai/*` | new filter |
| ⚠️ P3 | Test coverage tối thiểu cho auth + payment | backend src/test |

---

## 12. ĐIỂM CỘNG ĐÁNG GHI NHẬN

Không phải tất cả đều xấu — review fair:

- ✅ **BCrypt cost factor 12** cho password — đúng practice 2026.
- ✅ **HMAC SHA-256 constant-time compare** trong `TokenService` đúng — tránh timing attack.
- ✅ **Turnstile CAPTCHA** đã wire — phòng được brute-force đơn giản.
- ✅ **CORS allowlist explicit** (không "*") trong `WebConfig`.
- ✅ **OTP TTL ngắn** (10 phút) — hợp lý.
- ✅ **Flyway migrations** versioned đúng quy ước.
- ✅ **DTO records + jakarta.validation** — modern Spring Boot 3 idiom.
- ✅ **WebSocket** cho payment confirmation thay vì polling — UX tốt.
- ✅ **Provider fallback chain** Beeknoee → Groq → OpenRouter — resilience tốt (chỉ cần fix observability).
- ✅ **`@Transactional`** dùng đúng ở các mutation chính.
- ✅ **Cloudflare/proxy IP header parsing** trong `RateLimitFilter`.

---

## Phụ lục A — File line counts

```
   72  lib/main.dart
  605  lib/src/app_controller.dart
1,616  lib/src/data/local_app_repository.dart
  347  lib/src/data/remote_app_repository.dart
  323  lib/src/screens/auth_screen.dart
1,492  lib/src/screens/payment_screen.dart        ⚠️ refactor candidate
  388  lib/src/screens/checkout_screen.dart
  436  lib/src/services/ai_service.dart
  308  web-react/src/api.ts
4,238  web-react/src/main.tsx                     ⚠️ refactor candidate
```

## Phụ lục B — Stack inventory

- Spring Boot **3.4.5**, Java 21, JdbcTemplate (không JPA), Flyway 8 migrations, Postgres (prod) + H2 (dev fallback), Spring Mail, spring-security-crypto (BCrypt only — no full Security), WebSocket starter.
- Flutter SDK ≥3.4, sqflite + sqflite_common_ffi, http, google_sign_in 6.2, flutter_local_notifications 18, **không có** `flutter_secure_storage`, **không có** `dio`, **không có** state mgmt library (chỉ ChangeNotifier).
- React 18 + Vite + lucide-react + react-day-picker. Không Redux/Zustand. Không React Router (custom view switcher trong main.tsx).

---

*Generated bởi Claude Opus 4.7. Reviewer khuyến nghị làm follow-up: chạy `/gsd-secure-phase` để audit threat model + `/gitnexus-impact-analysis` trước mỗi PR đụng vào `OrderService`, `PaymentController`, `TokenService`.*

---

## 13. FLUTTER — Deep Dive Supplement (2026-05-18)

> Reviewer: Claude Sonnet 4.6 — đọc trực tiếp toàn bộ `lib/` source.
> Lưu ý: Repo hiện tại chỉ chứa Flutter app. Không tìm thấy `backend/` hay `web-react/` trong working tree.

---

### 13.1 [CRITICAL] Static password salt — rainbow table attack

**File:** `lib/src/data/local_app_repository.dart:1574`

```dart
const _kPasswordSalt = 'CHv1_2026_s@lt';
String _hashPassword(String value) =>
    sha256.convert(utf8.encode('$_kPasswordSalt:$value')).toString();
```

Cùng salt cho **tất cả user**. Ai có SQLite file (root device, backup unencrypted) có thể build rainbow table một lần và crack toàn bộ mật khẩu.

**Fix:** Per-user random salt (16 bytes) lưu cùng row trong `users`. Hoặc dùng `bcrypt` via `dart_bcrypt` package.

---

### 13.2 [CRITICAL] Notification timezone không được set → lệch 7 tiếng ở VN

**File:** `lib/src/services/notification_service.dart:31–32`

```dart
tz.initializeTimeZones();
// ← THIẾU: tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'))
```

`tz.local` mặc định là UTC. Bữa sáng 7:30 sẽ fire lúc 14:30 giờ VN.

**Fix:**
```dart
import 'package:flutter_timezone/flutter_timezone.dart';

tz.initializeTimeZones();
final String tzName = await FlutterTimezone.getLocalTimezone();
tz.setLocalLocation(tz.getLocation(tzName));
```
Thêm `flutter_timezone: ^1.0.4` vào `pubspec.yaml`.

---

### 13.3 [HIGH] `todayMeals` getter trả demo data tĩnh — calorie dashboard sai

**File:** `lib/src/app_controller.dart:54`

```dart
List<MealItem> get todayMeals => DemoData.todayMeals;  // KHÔNG dùng mealPlan!
```

`DashboardScreen` tính `todayCalories` từ getter này. Nếu user có AI meal plan (đã generate), con số hiển thị vẫn là demo data. `todayMealsWithLogs` dùng đúng `mealPlan.first.meals` — nhưng dashboard không dùng getter đó.

**Fix:**
```dart
List<MealItem> get todayMeals =>
    mealPlan.isNotEmpty ? mealPlan.first.meals : const [];
```

---

### 13.4 [HIGH] `_profileHash` bỏ sót `dietaryRestrictions` → AI cache stale

**File:** `lib/src/services/ai_service.dart:385–387`

```dart
String _profileHash(DemoProfile p) =>
    '${p.name}_${p.weightKg}_..._${p.allergies.join(',')}__${p.healthConditions.join(',')}';
    // ← p.dietaryRestrictions không có ở đây!
```

User đổi từ "ăn thịt" → "ăn chay" → cache key không thay đổi → AI trả kế hoạch bữa ăn có thịt cũ.
`_applyUserData` đã invalidate đúng khi `dietaryRestrictions.join()` thay đổi — nhưng khi app restart và AI load lại, cache key sai.

**Fix:** Thêm `_${p.dietaryRestrictions.join(',')}` vào hash string.

---

### 13.5 [HIGH] FoodScanService dùng `Authorization: Bearer` trong khi AiService dùng `x-api-key`

**File:** `lib/src/services/food_scan_service.dart:38` vs `lib/src/services/ai_service.dart:366`

Cùng endpoint `https://platform.beeknoee.com/v1/messages` nhưng:
- `food_scan_service.dart`: `'Authorization': 'Bearer $_apiKey'`
- `ai_service.dart`: `'x-api-key': _apiKey`

Một trong hai scheme sẽ bị server reject. Cần kiểm tra Beeknoee docs và thống nhất.

---

### 13.6 [HIGH] DB migration silent catch — schema corruption ẩn

**File:** `lib/src/data/local_app_repository.dart:667–714`

```dart
if (oldVersion < 5) {
  try {
    await db.execute('CREATE TABLE IF NOT EXISTS ...');
  } catch (_) {}  // ← im lặng hoàn toàn
}
```

Lỗi migration (type conflict, constraint error) bị nuốt hoàn toàn. App tiếp tục với schema không đúng → crash âm thầm về sau.

**Fix:** Chỉ bắt `DatabaseException` với message `already exists` (idempotent). Các lỗi khác: `rethrow` hoặc ít nhất `debugPrint`.

---

### 13.7 [MEDIUM] `removeCartItemAt` dùng positional index — race condition tiềm ẩn

**File:** `lib/src/data/remote_app_repository.dart:119`

```dart
final json = await _request('DELETE', '/cart/items/$index');
```

Nếu backend có request song song thêm/xóa item, index lệch → xóa nhầm sản phẩm. Backend nên nhận `product.id`.

---

### 13.8 [MEDIUM] `_generateUserId` dùng timestamp — không đủ entropy

**File:** `lib/src/data/local_app_repository.dart:1579`

```dart
String _generateUserId() => 'usr_${DateTime.now().microsecondsSinceEpoch}';
```

Microsecond timestamp có thể đoán được và có khả năng collision thấp trên emulator/chậm.

**Fix:** `'usr_${const Uuid().v4()}'` — thêm `uuid: ^4.4.0`.

---

### 13.9 [MEDIUM] Debug card lộ trong production auth screen

**File:** `lib/src/screens/auth_screen.dart:261–279`

```dart
AppCard(
  color: AppPalette.mint,
  child: Column(children: [
    Text('Thiết kế lưu trữ'),
    Text('Tài khoản, hồ sơ... SQLite cục bộ...'),
  ]),
),
```

Đây là note kiến trúc cho developer, không phải nội dung dành cho end user. Cần xóa trước khi ship.

---

### 13.10 [MEDIUM] RemoteAppRepository không persist JWT token

**File:** `lib/src/data/remote_app_repository.dart:15`

```dart
String? _token;  // in-memory only
```

Mỗi lần kill app → user phải login lại. `LocalAppRepository` persist session vào SQLite, nhưng `RemoteAppRepository` không làm tương đương.

**Fix:** `flutter_secure_storage` như đã nêu ở mục 2.1.

---

### 13.11 [LOW] `subscriptionMonths: 1` cho user free mới đăng ký

**File:** `lib/src/data/local_app_repository.dart:1447`

```dart
DemoProfile _defaultProfileFor(String displayName) {
  return DemoData.initialProfile.copyWith(
    plan: SubscriptionPlan.free,
    subscriptionMonths: 1,  // ← nên là 0
  );
}
```

Free plan với 1 tháng và không có `subscriptionStartDate` không expire — OK hiện tại. Nhưng nếu logic sau này đọc `subscriptionMonths` để tính feature, giá trị 1 gây nhầm.

---

### 13.12 [LOW] Notification ID 50 không có trong comment range

**File:** `lib/src/services/notification_service.dart:8–13,213`

Comment đầu file khai báo range 10–41, nhưng `showWorkoutCompleted` dùng ID 50. Conflict tiềm ẩn nếu thêm notification mới.

---

### 13.13 [LOW] `CLAUDE.md` ghi schema version 3 nhưng code là version 6

Tài liệu lệch thực tế. Cập nhật: `DB: SQLite via sqflite (current schema version: 6)`.

---

### Tóm tắt Flutter-specific

| Mức | # | Vấn đề nổi bật |
|-----|---|----------------|
| 🔴 CRITICAL | 2 | Static salt, timezone UTC |
| 🟠 HIGH | 4 | todayMeals getter sai, cache key thiếu field, header auth không nhất quán, migration silent fail |
| 🟡 MEDIUM | 4 | JWT không persist, index-based cart delete, userId entropy thấp, debug card production |
| 🟢 LOW | 3 | subscriptionMonths mặc định, notification ID gap, CLAUDE.md stale |

**Priority fixes Flutter:**
1. `tz.setLocalLocation(...)` — 30 phút (H3)
2. Fix `todayMeals` getter — 5 phút (H1)
3. Add `dietaryRestrictions` to `_profileHash` — 2 phút (H2)
4. Remove debug card từ auth_screen — 2 phút (M6)
5. Unify API auth header — 5 phút (H5)
6. Per-user bcrypt salt — 1 ngày (C1)

*Supplement bởi Claude Sonnet 4.6 — 2026-05-18*
