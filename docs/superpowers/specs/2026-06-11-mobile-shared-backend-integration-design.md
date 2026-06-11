# CoreHealth Mobile — Gắn vào Backend chung (Cross-Platform)

- **Ngày:** 2026-06-11
- **Trạng thái:** Đã duyệt design, chờ lập kế hoạch thực thi
- **Phương án chọn:** A — *Remote-only switch + vá gap contract*
- **Repo:** `CoreHealth-Mobile` (Flutter)

## 1. Bối cảnh & mục tiêu

CoreHealth Web đã hoàn thành: `CoreHealth-BE` (Spring Boot REST API, base `/api`) + `CoreHealth-FE` (Next.js) + Postgres, đã deploy public tại **`https://api.corehealth.page`**. Mọi secret bên thứ ba (Gemini, Groq, SePay, GHN, SMTP, Cloudinary) sống server-side.

App `CoreHealth-Mobile` (Flutter) đã scaffold ~32 screen và lớp data với 3 repository: `RemoteAppRepository` (gọi BE), `PostgresAppRepository` (nối DB trực tiếp ⚠️), `MemoryAppRepository` (demo). Một số screen + `app_controller` còn gọi thẳng bên thứ ba với key nhúng client.

> **Đính chính (planning phase):** giả định "RemoteAppRepository xong 40/40 method" trong bản design đầu là **sai** — đó là đếm số method, không phải implement. Thực tế ~27 method core đã chạy, **~13 method AI/plan-sync là `throw UnimplementedError()`** (chat sessions, plan generation/persistence, shopping, daily progress). Ngoài ra việc sinh nội dung AI chạy **client-side** qua `ai_service`/`food_scan_service` (key Gemini/Groq nhúng app), gọi từ `app_controller`. Xem mục 1b.

**Mục tiêu:** web và mobile dùng **chung một backend** → đúng nghĩa cross-platform, một nguồn chân lý, mọi secret server-side. Đích trước mắt: app demo chạy thật trên BE public cho EXE201; ưu tiên *đúng + an toàn*, chưa release store.

**Không làm (YAGNI):** không lên store/signing, không thêm tính năng mới, không integration-test tự động, **không sửa CoreHealth-BE** (đã xong — mọi gap xử lý phía mobile).

## 1b. Thực trạng theo 3 tầng & quyết định (planning)

| Tầng | Nội dung | Trạng thái BE | Quyết định |
|---|---|---|---|
| 1. Core | auth, profile, cart, order, meal-log, toggle, weight | ✅ Remote chạy | giữ nguyên |
| 2. Contract gaps | settings→preferences, subscription, token | ✅ có route khác | remap client theo BE |
| 3a. Sinh AI | chat, generate-plan, insights, food-scan | ✅ `/api/ai/*` server-side, charge token | **thay ruột `ai_service`/`food_scan_service`, giữ chữ ký** → app_controller gần như không đổi |
| 3b. Lưu chat | `bootstrap.chatSessions` + `GET/POST /me/chat-sessions` | ✅ | implement stub theo batch-save |
| 3c. Lưu AI plan | `POST /me/ai-plans` (blob) + `bootstrap.aiPlans` | ✅ blob | implement stub, remap generation/version/dayIndex ↔ blob ở client |
| 3d. Shopping list | ❌ không có endpoint | — | **tính client-side từ plan** (dữ liệu dẫn xuất) |
| 3e. Daily progress | ❌ không có endpoint | — | **lưu `flutter_secure_storage`** (device-local) |

**Cốt lõi giảm rủi ro:** BE `bootstrap` DTO đã trả `chatSessions` + `aiPlans`; AI sinh nội dung đã server-side + charge token-wallet. Nên Tier 3 khả thi ~85% **không đụng BE**. Hai thứ BE không lưu (shopping, daily progress) đều là dữ liệu device-local nên giữ ở client là hợp bản chất, không phải nợ kỹ thuật.

## 2. Kiến trúc đích & cấu hình

App chỉ còn **một** đường ra dữ liệu: `RemoteAppRepository` → `https://api.corehealth.page/api`.

Sửa `main.dart` `_createRepository()`:
- Luôn dùng `RemoteAppRepository`, base URL từ `COREHEALTH_API_BASE_URL` (mặc định `https://api.corehealth.page/api`).
- **Release mode:** thiếu URL → fail rõ ràng, KHÔNG im lặng fallback DB/Memory.
- **Debug mode:** giữ `MemoryAppRepository` làm fallback offline cho dev UI. `PostgresAppRepository` bị loại khỏi luồng khởi tạo.

Secret được phép ở client (đều là public client value): `COREHEALTH_API_BASE_URL`, `GOOGLE_CLIENT_ID`, (tùy chọn) Turnstile **site** key. Mọi key khác → xóa khỏi app.

## 3. Đối chiếu & vá contract

BE đã expose gần như mọi thứ mobile cần (auth, me/*, cart, orders, meal-logs, `/api/ai/*`, `/api/payments/*`, `/api/ghn/*`). 4 nhóm endpoint lệch — xử lý bằng cách **chỉnh mobile theo BE**, không đụng BE:

| Mobile hiện gọi | Xử lý |
|---|---|
| `POST /me/settings` | → `PUT /me/preferences` (map field) |
| `POST /me/subscription` | `plan` là field profile (`free`/`meal`/`workout`/`max`); set qua update profile, đọc từ `bootstrap`. Bỏ route riêng |
| `POST /me/token-wallet` | Đọc wallet từ `bootstrap`; nạp qua `/billing/token-packs/{packId}/purchase` (+`/sepay`) |
| `GET/POST /me/token-transactions` | Verify route lịch sử thật (`/billing/*` hoặc trong bootstrap) bằng curl rồi map |

**Nguyên tắc:** trước khi sửa mỗi endpoint, curl thử lên BE public để biết route + shape thật, không đoán mò.

## 4. Chuyển direct third-party → BE & dọn secret

- **`food_scan_sheet.dart`:** `gemini_service`/`food_scan_service` trực tiếp → `POST /api/ai/analyze-food` (gửi ảnh, nhận kết quả). Gemini chạy server-side.
- **`payment_screen.dart`:** `sepay_service` trực tiếp → `POST /api/payments/create-order` (+ `/cod-order` cho COD). QR/đối soát do BE + webhook `/api/payments/webhook/sepay` lo.
- **`pubspec.yaml`:** gỡ `postgres`, `mailer`, và gói chỉ phục vụ gọi AI trực tiếp nếu hết dùng. Giữ `http`, `flutter_secure_storage`, `google_sign_in`, `image_picker`, `cached_network_image`...
- **Xóa file chết** (sau khi xác nhận hết import): `postgres_app_repository.dart`, các `*_service.dart` không còn ai gọi (gemini, sepay, ghn, cloudinary, email, ymove, rag...).
- **`.env.example` mobile:** rút gọn còn `ENVIRONMENT`, `COREHEALTH_API_BASE_URL`, `GOOGLE_CLIENT_ID` (+ Turnstile site key nếu cần). Xóa hết key Gemini/Groq/SePay/GHN/SMTP/Cloudinary/Postgres.

## 5. Kiểm thử & tiêu chí thành công

**Smoke test thủ công** (emulator/máy thật, trỏ BE public), verify mỗi bước gọi `api.corehealth.page`:
đăng ký → OTP → login → bootstrap → onboarding (set plan) → schedule → log meal → food scan → thêm giỏ → đặt hàng → payment.

**Grep guard** sau khi dọn: `lib/` không còn chuỗi key thô / import `postgres`/`mailer` / gọi `Sepay`/`Gemini` trực tiếp.

**PASS khi:**
1. App build & chạy chỉ với `COREHEALTH_API_BASE_URL`.
2. Không còn secret bên thứ ba trong source/bundle.
3. Toàn bộ luồng demo chạy thật qua BE chung.
4. Không còn code nối Postgres trực tiếp trong luồng release.

## 6. Blast radius (cập nhật)

- **Sửa:** `main.dart` (gate Remote-only), `data/remote_app_repository.dart` (4 contract gap + implement ~13 stub theo BE blob/batch), `services/ai_service.dart` + `services/food_scan_service.dart` (thay ruột → gọi `/api/ai/*`, giữ chữ ký public), `screens/payment_screen.dart` (→ `/api/payments/*`), `.env.example`, `pubspec.yaml` (gỡ `postgres`, `mailer`).
- **Xóa (sau khi xác nhận hết import):** `data/postgres_app_repository.dart`, `services/gemini_service.dart`, `services/rag_service.dart`, `services/fitness_knowledge.dart`, `services/sepay_service.dart`, và các service đã chết sẵn (`ghn_service`, `cloudinary_service`, `ymove_service`). `email_service` chỉ xóa được nếu gỡ khỏi `memory_app_repository`.
- **Gần như không đổi:** `app_controller.dart` (nhờ giữ chữ ký `ai_service`/`food_scan_service`); 32 screen UI.

Mức: **trung bình** — khu trú ở lớp data + service layer + config; `app_controller` được bảo vệ bằng cách giữ interface service.
