# CoreHealth Mobile — Gắn vào Backend chung (Cross-Platform)

- **Ngày:** 2026-06-11
- **Trạng thái:** Đã duyệt design, chờ lập kế hoạch thực thi
- **Phương án chọn:** A — *Remote-only switch + vá gap contract*
- **Repo:** `CoreHealth-Mobile` (Flutter)

## 1. Bối cảnh & mục tiêu

CoreHealth Web đã hoàn thành: `CoreHealth-BE` (Spring Boot REST API, base `/api`) + `CoreHealth-FE` (Next.js) + Postgres, đã deploy public tại **`https://api.corehealth.page`**. Mọi secret bên thứ ba (Gemini, Groq, SePay, GHN, SMTP, Cloudinary) sống server-side.

App `CoreHealth-Mobile` (Flutter) đã scaffold ~32 screen và lớp data với 3 repository: `RemoteAppRepository` (gọi BE — **đã implement đủ 40/40 method**), `PostgresAppRepository` (nối DB trực tiếp ⚠️), `MemoryAppRepository` (demo). Một số screen còn gọi thẳng bên thứ ba với key nhúng client.

**Mục tiêu:** web và mobile dùng **chung một backend** → đúng nghĩa cross-platform, một nguồn chân lý, mọi secret server-side. Đích trước mắt: app demo chạy thật trên BE public cho EXE201; ưu tiên *đúng + an toàn*, chưa release store.

**Không làm (YAGNI):** không viết lại lớp data (đã xong), không lên store/signing, không thêm tính năng mới, không integration-test tự động (để pha sau nếu cần).

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

## 6. Blast radius

`main.dart`, `data/remote_app_repository.dart`, `screens/food_scan_sheet.dart`, `screens/payment_screen.dart`, `services/environment_config.dart`, các `services/*_service.dart` (gỡ), `data/postgres_app_repository.dart` (xóa), `pubspec.yaml`, `.env.example`. Mức: trung bình-thấp, khu trú ở lớp data + 2 screen + config.
