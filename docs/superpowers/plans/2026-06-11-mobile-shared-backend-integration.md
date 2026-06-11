# CoreHealth Mobile — Shared-Backend Integration — Implementation Plan

**Goal:** App Flutter chạy hoàn toàn trên backend chung `https://api.corehealth.page/api`, gỡ sạch secret bên thứ ba khỏi client, bỏ đường nối Postgres trực tiếp — đúng nghĩa cross-platform + an toàn cho demo EXE201.

**Architecture:** Một đường ra dữ liệu duy nhất `RemoteAppRepository` → BE REST (`/api`). AI sinh nội dung & food-scan đi qua `/api/ai/*` (server-side, charge token-wallet). Giữ chữ ký public của `ai_service`/`food_scan_service` và chỉ thay ruột → `app_controller` gần như không đổi. Shopping list tính client-side từ plan; daily progress lưu `flutter_secure_storage`. **Không sửa CoreHealth-BE.**

**Tech Stack:** Flutter/Dart, `http`, `flutter_secure_storage`, BE Spring Boot (đã deploy). Base URL: `https://api.corehealth.page/api`.

**Spec nguồn:** `docs/superpowers/specs/2026-06-11-mobile-shared-backend-integration-design.md`
**Nhánh:** `feat/shared-backend-integration`

## Quy ước verify (không có culture TDD unit-test ở repo này)
- **V-ANALYZE:** `flutter analyze` → 0 error (warning cũ chấp nhận, không thêm warning mới).
- **V-GREP:** lệnh grep cụ thể trả về rỗng (guard secret/dead-import).
- **V-BUILD:** `flutter build apk --debug --dart-define=COREHEALTH_API_BASE_URL=https://api.corehealth.page/api` chạy xong.
- **V-SMOKE:** chạy app trên emulator/máy thật `--dart-define=COREHEALTH_API_BASE_URL=https://api.corehealth.page/api`, thao tác tay, quan sát request tới `api.corehealth.page`.
- Mỗi task **commit** sau khi verify pass.

## Hợp đồng endpoint BE (đã xác minh, base = `/api`)
| Việc | Method + path | Body / Trả về |
|---|---|---|
| Bootstrap | `GET /me/bootstrap` | `{session, userData{...,chatSessions,aiPlans}}` |
| Preferences | `PUT /me/preferences` | body map → trả map |
| Set profile (gồm `plan`) | `PUT /me/profile` | `{profile:{...,plan,subscriptionMonths}}` |
| Wallet + ledger | `GET /me/wallet` | `{walletBalance, recentTransactions:[20]}` |
| Mua token | `POST /billing/token-packs/{packId}/purchase` | → wallet |
| Chat AI | `POST /ai/chat` | `{message, coachType, history[]}` → `{message, walletBalanceAfter}` |
| Sinh plan | `POST /ai/generate-plan` | `{type, duration, goal, intensity, notes, startDate}` → plan blob |
| Insights | `GET /ai/insights` | `[{...}]` |
| Food scan | `POST /ai/analyze-food` | `{text, imageBase64}` → `{name, calories, protein, carbs, fat, ...}` |
| Lấy chat sessions | `GET /me/chat-sessions` | `[{...}]` |
| Lưu chat sessions | `POST /me/chat-sessions` | `{sessions:[...]}` (NO_CONTENT) |
| Lưu AI plan | `POST /me/ai-plans` | `{workoutPlan, mealPlan, workoutPlanStartDate, mealPlanStartDate}` → userData |
| Payment | `POST /payments/create-order` (+ `/payments/cod-order`) | theo PaymentController |

---

## TASK A — Gate Remote-only + cấu hình base URL

**File:** `lib/main.dart`, `.env.example`, `lib/src/services/environment_config.dart`

**Bước:**
1. Sửa `_createRepository()`:
   - Mặc định base URL: nếu `COREHEALTH_API_BASE_URL` rỗng → dùng const `https://api.corehealth.page/api`.
   - Luôn khởi tạo `RemoteAppRepository`, gọi `await remote.init()`, return.
   - **Release mode (`kReleaseMode`):** không cho fallback Postgres/Memory.
   - **Debug mode:** nếu muốn dev offline UI, cho phép `MemoryAppRepository` CHỈ khi `--dart-define=COREHEALTH_OFFLINE=true`. Bỏ toàn bộ nhánh `PostgresAppRepository` + import của nó khỏi `main.dart`.
2. `.env.example`: rút gọn còn `ENVIRONMENT`, `COREHEALTH_API_BASE_URL`, `GOOGLE_CLIENT_ID` (+ Turnstile site key nếu screen dùng). Xóa mọi key Gemini/Groq/Beeknoee/SHINESHOP/GOLLM/SePay/GHN/SMTP/Cloudinary/Postgres/JWT_SECRET.
3. `environment_config.dart`: thêm `static String get apiBaseUrl` đọc `COREHEALTH_API_BASE_URL` (default const ở trên) để AiService/FoodScanService dùng chung.

**Verify:** V-ANALYZE; V-GREP `grep -nE "PostgresAppRepository" lib/main.dart` → rỗng; V-BUILD.
**Commit:** `feat(config): gate app to remote-only shared backend`

---

## TASK B — Vá 4 contract gap trong RemoteAppRepository

**File:** `lib/src/data/remote_app_repository.dart`

**B1 — `updateUserSettings`:** đổi `POST /me/settings` → `PUT /me/preferences`. Body: map settings (`_settingsToJson`). Giữ nguyên fallback `AppAuthException` → bootstrap + `copyWith(settings)`. *(Trước khi sửa: `curl -X PUT $BASE/me/preferences -H "Authorization: Bearer $JWT" -d '{...}'` xem shape trả về để map đúng key.)*

**B2 — `updateSubscription`:** bỏ `POST /me/subscription`. Thay bằng `PUT /me/profile` với `{profile: _profileToJson(profile.copyWith(plan: plan, subscriptionMonths: months))}` — vì `plan` là field profile. Trả `_userData(json)`. (Caller truyền profile hiện tại; nếu chữ ký không có profile, đọc bootstrap trước rồi copyWith — kiểm caller `home_shell`/`onboarding`.)

**B3 — token (`updateTokenWallet`, `getTokenTransactions`, `addTokenTransaction`):**
- `getTokenTransactions` → `GET /me/wallet`, đọc `recentTransactions`, map qua `_tokenTransaction`.
- `updateTokenWallet` → `GET /me/wallet` lấy `walletBalance` mới rồi `bootstrap()` reconcile (ghi wallet là server-side; client không POST). Giữ fallback hiện có.
- `addTokenTransaction` → **no-op** (`return;`) kèm comment: ledger ghi server-side khi charge/purchase.
- `purchaseTokenPack` (đã đúng `/billing/...`) giữ nguyên.

**Verify:** V-ANALYZE; V-SMOKE: mở Settings đổi 1 toggle (PUT preferences 2xx), mở Token history (GET /me/wallet trả list), onboarding chọn plan (PUT /me/profile, bootstrap thấy plan đúng).
**Commit:** `fix(remote): reconcile settings/subscription/token endpoints to BE contract`

---

## TASK C — Thay ruột AI sinh nội dung sang BE (giữ chữ ký)

**File:** `lib/src/services/ai_service.dart`, `lib/src/services/food_scan_service.dart`

**Nguyên tắc:** giữ NGUYÊN public signature để `app_controller` + `food_scan_sheet` không đổi:
- `AiService`: `Future<String> chat({...})`, `Future<List<MealPlanDay>> generateMealPlan(DemoProfile)`, `Future<List<WorkoutDay>> generateWorkoutPlan(DemoProfile)`, `Future<List<InsightItem>> generateInsights(DemoProfile)`, `invalidateAllPlanCaches()`.
- `FoodScanService`: `Future<FoodScanResult> analyzeByImage(Uint8List)`, `Future<FoodScanResult> analyzeByName(String)`.

**Bước:**
1. Thêm helper HTTP chung (hoặc tái dùng 1 client) đọc `EnvironmentConfig.apiBaseUrl` + JWT từ `FlutterSecureStorage(key:'corehealth_jwt')`, header `Authorization: Bearer`.
2. `chat(...)` → `POST /ai/chat` `{message, coachType, history}` → trả `json['message']`.
3. `generateMealPlan/generateWorkoutPlan` → `POST /ai/generate-plan` `{type:'meal'|'workout', duration, goal, intensity, notes, startDate}` → parse blob trả về thành `List<MealPlanDay>`/`List<WorkoutDay>` (tái dùng parser cũ trong file nếu có; đọc kỹ shape `result` từ BE `ai.generatePlan`).
4. `generateInsights` → `GET /ai/insights` → map `List<InsightItem>`.
5. `analyzeByImage` → base64 hóa bytes → `POST /ai/analyze-food` `{imageBase64}`; `analyzeByName` → `{text: foodName}`. Map về `FoodScanResult`.
6. **Xóa** mọi gọi tới `gemini_service`/`rag_service`/`fitness_knowledge` + key client trong 2 file.

**Verify:** V-ANALYZE; V-SMOKE: chat coach trả lời (POST /ai/chat 2xx, token trừ), food scan ảnh ra dinh dưỡng (POST /ai/analyze-food), generate plan ra ngày kế hoạch.
**Commit:** `refactor(ai): route AI generation + food-scan through shared BE`

---

## TASK D — Implement stub persistence (chat sessions, AI plans, shopping, progress)

**File:** `lib/src/data/remote_app_repository.dart` (+ helper local store cho progress)

**D1 — Chat sessions (thay 3 stub):**
- `getChatSessions` → `GET /me/chat-sessions` → map `List<ChatSession>` (hoặc đọc từ `bootstrap.chatSessions` đã có).
- `saveChatSession` → đọc list hiện tại, chèn/thay session theo id, `POST /me/chat-sessions {sessions:[...]}`.
- `deleteChatSession` → list bỏ id đó rồi `POST /me/chat-sessions`.
- Cần parser `_chatSession`/`_chatSessionToJson` khớp model `ChatSession`.

**D2 — AI plans (thay 6 stub, remap blob):**
- BE lưu blob: `aiPlans = {workoutPlan:[...days], mealPlan:[...days], workoutPlanStartDate, mealPlanStartDate}`.
- `savePlanGeneration` → cache `PlanGeneration` (id/version/startDate) vào field nội bộ + secure storage (BE không có khái niệm generation).
- `saveMealPlan`/`saveWorkoutPlan(dayIndex, plan)` → tích lũy vào buffer ngày, rồi `POST /me/ai-plans` với full `mealPlan`/`workoutPlan` arrays + start dates.
- `getMealPlan`/`getWorkoutPlan(version, dayIndex)` → đọc `bootstrap.aiPlans`, lấy phần tử `dayIndex`.
- `getCurrentGeneration` → suy từ generation đã cache + sự tồn tại của `aiPlans`.
- Đọc kỹ model `MealPlanDay`/`WorkoutDay`/`PlanGeneration` trong `models.dart` để parser khớp.

**D3 — Shopping list (device-local, dẫn xuất):**
- `saveShoppingItems`/`getShoppingItems` → lưu/đọc `flutter_secure_storage` key `corehealth_shopping_<userId>` (JSON). (Hoặc tính lại từ meal plan hiện tại nếu app_controller có sẵn logic — kiểm trước; ưu tiên không thêm phức tạp.)

**D4 — Daily progress (device-local):**
- `saveDailyProgress`/`getDailyProgress(date)` → `flutter_secure_storage` key `corehealth_progress_<userId>_<date>` (JSON).
- `logAiEvent` → no-op (audit đã ghi server-side ở mỗi call `/ai/*`).

**Verify:** V-ANALYZE; V-SMOKE: tạo plan → thoát app → mở lại thấy plan (bootstrap.aiPlans), chat rồi mở lại thấy lịch sử, tick progress 1 ngày → mở lại còn.
**Commit:** `feat(remote): implement chat/plan sync via BE + device-local shopping/progress`

---

## TASK E — Payment screen → BE

**File:** `lib/src/screens/payment_screen.dart`

**Bước:** thay `sepay_service` trực tiếp bằng gọi `POST /api/payments/create-order` (và `/payments/cod-order` cho COD) qua helper HTTP có JWT. Đọc PaymentController để biết body/response (QR string, orderCode). Webhook đối soát do BE lo — client chỉ poll trạng thái nếu cần (kiểm endpoint tracking).

**Verify:** V-ANALYZE; V-SMOKE: checkout → tạo order qua BE, hiện QR/COD đúng.
**Commit:** `refactor(payment): route checkout through BE payments API`

---

## TASK F — Gỡ secret + xóa file chết + dọn pubspec

**Bước:**
1. Xác nhận hết import rồi **xóa**: `lib/src/data/postgres_app_repository.dart`, `lib/src/services/gemini_service.dart`, `services/rag_service.dart`, `services/fitness_knowledge.dart`, `services/sepay_service.dart`, `services/ghn_service.dart`, `services/cloudinary_service.dart`, `services/ymove_service.dart`.
2. `email_service.dart`: gỡ khỏi `memory_app_repository.dart` (debug-only) rồi xóa; nếu còn ràng buộc thì để lại + ghi chú.
3. `pubspec.yaml`: gỡ `postgres`, `mailer` (+ gói AI-direct nếu hết dùng). `flutter pub get`.
4. Quét toàn repo gỡ chuỗi key thô còn sót.

**Verify:**
- V-GREP `grep -rniE "sk-bee|AIza|GROQ|SEPAY_API|CLOUDINARY_API_SECRET|smtp|postgres://|password" lib/` → rỗng.
- V-GREP `grep -rnE "import .*(postgres_app_repository|gemini_service|sepay_service|rag_service|ghn_service|cloudinary_service|ymove_service)" lib/` → rỗng.
- V-ANALYZE; V-BUILD.
**Commit:** `chore: remove embedded secrets, dead services, and direct-DB repository`

---

## TASK G — Smoke test E2E + walkthrough

**Bước:** chạy V-SMOKE toàn luồng trỏ BE public:
đăng ký → OTP → login → bootstrap → onboarding (chọn plan) → xem schedule → generate plan → chat coach → food scan → log meal → thêm giỏ → checkout/payment → token history.
Mỗi bước xác nhận request tới `api.corehealth.page`, không có call tới gemini/groq/sepay trực tiếp (xem network log).

**Verify (tiêu chí PASS spec mục 5):** (1) build & chạy chỉ với `COREHEALTH_API_BASE_URL`; (2) không còn secret bên thứ ba; (3) toàn luồng demo qua BE chung; (4) không còn code nối Postgres trực tiếp ở release.
Viết `docs/walkthrough.md` ghi kết quả từng bước.
**Commit:** `docs: smoke-test walkthrough for shared-backend integration`

---

## Thứ tự & phụ thuộc
A → B → C → D → E → F → G. C trước D (D dùng helper HTTP/JWT của C). F sau khi A–E đã bỏ hết caller của file bị xóa. G cuối cùng.

## Rủi ro đã biết
- **Shape blob `aiPlans`** từ BE có thể khác model mobile → Task D2 phải đọc `models.dart` + 1 response thật (`curl /me/bootstrap`) trước khi viết parser.
- **PaymentController contract** chưa đọc chi tiết → Task E mở file trước khi code.
- **Caller của `updateSubscription`** có thể không truyền đủ profile → Task B2 kiểm caller, đọc bootstrap nếu thiếu.
