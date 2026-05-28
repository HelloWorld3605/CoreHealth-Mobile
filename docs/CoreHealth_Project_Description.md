# CoreHealth Mobile - Mo Ta Du An

## 1. Tong Quan Du An

CoreHealth Mobile la ung dung suc khoe ca nhan hoa duoc xay dung bang Flutter, huong toi nguoi dung Viet Nam muon an uong dung hon, tap luyen hop ly hon va theo doi tien bo moi ngay. San pham khong chi la app dem calories, app tap gym hay app scan mon an rieng le, ma duoc dinh vi nhu mot AI Health Companion: mot tro ly suc khoe ca nhan co kha nang hieu muc tieu, co the, lich sinh hoat, thoi quen an uong va hanh vi that cua nguoi dung.

Vong lap san pham cot loi cua CoreHealth:

1. Nguoi dung onboarding va khai bao thong tin co the, muc tieu, lich sinh hoat, so thich an uong, dieu kien tap luyen.
2. AI tao ke hoach an uong, tap luyen va insight hang ngay.
3. Nguoi dung log bua an, scan mon an, cap nhat can nang, hoan thanh bai tap va thoi quen.
4. AI phan tich du lieu that, dua ra nhan xet va dieu chinh goi y.
5. Nguoi dung thay tien bo qua dashboard, health history, streak, token wallet va cac man hinh ho tro.

Muc tieu dai han cua CoreHealth la tro thanh trung tam dieu phoi suc khoe ca nhan: AI giup nguoi dung tra loi moi ngay nen an gi, nen tap gi, dang thieu gi so voi muc tieu, va ke hoach can thay doi ra sao khi cuoc song that khong dien ra dung nhu plan.

## 2. Doi Tuong Nguoi Dung

CoreHealth tap trung vao nhom nguoi dung:

- Nguoi Viet muon giam can, tang co, giu dang hoac an uong lanh manh hon.
- Nguoi moi bat dau tap luyen, can mot lo trinh don gian va de theo.
- Nguoi ban ron, can AI goi y bua an va bai tap phu hop thoi gian.
- Nguoi muon theo doi can nang, calories, protein, workout, nuoc uong va thoi quen hang ngay.
- Nguoi thich trai nghiem AI coach, scan mon an va ke hoach ca nhan hoa.

Tonality san pham can than thien, mem, khong phan xet va khong tao cam giac y te nang ne. CoreHealth nen dong vai tro nguoi dong hanh hon la mot he thong cham diem khe khat.

## 3. Gia Tri Cot Loi

CoreHealth mang lai gia tri chinh o 5 diem:

- Ca nhan hoa: ke hoach dua tren tuoi, gioi tinh, chieu cao, can nang, muc tieu, muc do van dong, lich sinh hoat, ngan sach bua an, thoi gian nau, thuc pham tranh ne, di ung va tinh trang suc khoe.
- AI-first: AI tao meal plan, workout plan, insight va cau tra loi coach theo context cua user.
- Tracking thuc te: nguoi dung co the ghi nhan bua an, can nang, workout, don hang, token va lich su chat.
- Scan mon an: AI phan tich hinh anh hoac ten mon an de uoc tinh calories, protein, carbs va fat.
- Token wallet: mot vi token chung cho cac hanh dong AI nhu chat, scan food, tao meal plan, tao workout plan va cac tinh nang AI nang cao.

## 4. Cac Page Va Chuc Nang Chinh

### 4.1. Welcome, Intro, Auth Va OTP

Flow dau vao cua app gom:

- Welcome Screen: man hinh chao mung, tao cam giac nhan dien thuong hieu CoreHealth.
- Intro Screen: gioi thieu nhanh gia tri san pham truoc khi dang nhap/onboarding.
- Auth Screen: dang nhap, dang ky, dang nhap Google.
- OTP Verification Screen: xac thuc email bang OTP khi tao tai khoan.

Ung dung quan ly trang thai bang `AppStage`, gom `welcome`, `intro`, `auth`, `verifyOtp`, `onboarding`, `home`. Sau khi bootstrap thanh cong, `MaterialApp` chon man hinh dua tren stage hien tai.

### 4.2. Onboarding - AI Health Assessment

Onboarding la buoc quan trong de CoreHealth hieu nguoi dung. Flow hien tai thu thap nhieu lop du lieu:

- Thong tin ca nhan: ten, tuoi, gioi tinh.
- Chi so co the: chieu cao, can nang hien tai, can nang muc tieu.
- Muc tieu: giam mo/giam can, duy tri, tang co, tang can, cai thien hieu suat.
- Muc do van dong va kinh nghiem tap luyen.
- Tan suat tap, vung co the muon tap trung, hoat dong ua thich.
- Lich sinh hoat, ngan sach bua an, thoi gian nau.
- Uu tien dinh duong, che do an, thuc pham tranh ne.
- Di ung va tinh trang suc khoe can AI luu y.
- Lua chon body shape va visual body focus.

Ket qua onboarding tao ra `DemoProfile`, la object trung tam cho tinh toan BMI, BMR, TDEE, body fat estimate, ideal weight range, quyen truy cap AI va goi y ca nhan hoa.

### 4.3. Home / Dashboard

Home la man hinh trung tam cua app. Vai tro cua Home la cho nguoi dung thay ngay hom nay nen lam gi va tinh trang suc khoe hien tai ra sao.

Cac nhom noi dung chinh:

- Dashboard insight: cac insight AI ve dinh duong, tap luyen, lich sinh hoat hoac tien bo.
- Health/progress overview: can nang, BMI, muc tieu, tien do va nhac nho.
- Daily plan: meal plan va workout plan trong ngay/tuan.
- Quick actions: mo AI Coach, scan mon an, xem lich su suc khoe, mua token, xem gio hang.
- Trang thai hoan thanh: danh dau ngay tap va ngay an uong da hoan thanh.

Home dang duoc thiet ke theo huong AI daily command center: khong chi hien thi widget, ma tao cam giac app dang dieu phoi ke hoach suc khoe hang ngay cho nguoi dung.

### 4.4. Meal Plan / An Uong

Trang Meal Plan giup nguoi dung xem ke hoach bua an va thong tin macro.

Chuc nang:

- Hien thi meal plan theo ngay.
- Moi bua co ten mon, slot bua an, calories, protein, carbs, fat, anh minh hoa va nguyen lieu.
- Tong hop calories va macro theo ngay.
- Danh dau ngay meal plan da hoan thanh.
- Tao meal plan bang AI neu user co du token hoac dang trong trial.
- Dieu chinh cac bua con lai dua tren meal log trong ngay.
- Tich hop Food Scan de ghi mon da an vao plan.

Huong phat trien tiep theo cua page nay la Smart Rebalance: khi nguoi dung muon an mot mon bat ky, AI se tinh tac dong calories/macro va de xuat dieu chinh bua phu, workout hoac ke hoach ngay tiep theo.

### 4.5. Workout Plan / Tap Luyen

Trang Workout Plan tap trung vao viec cho nguoi dung biet hom nay tap gi, tap trong bao lau va dot bao nhieu calories.

Chuc nang:

- Hien thi workout plan theo ngay.
- Moi ngay co focus muscle/chu de tap va danh sach bai tap.
- Moi bai tap co sets, reps, thoi luong, mo ta va calories burned.
- Tao workout plan bang AI.
- Danh dau ngay tap da hoan thanh.
- Mo Workout Player de tap theo tung bai, co rest timer va trang thai set.

Huong phat trien cua Workout la Adaptive Intensity: AI tu giam/tang cuong do dua tren giac ngu, stress, lich ban, dau co hoac lich su skip.

### 4.6. AI Coach

AI Coach la lop tuong tac thong minh cua CoreHealth. App hien co coach theo 3 huong:

- Nutrition Coach: hoi dap ve an uong, meal plan, macro, thuc pham thay the.
- Workout Coach: hoi dap ve lich tap, bai tap, tien trinh tap luyen.
- Wellness Coach: hoi dap ve thoi quen, suc khoe tong quan, dong luc va loi song.

Coach co context tu profile, goal, body stats, meal plan va workout plan. Lich su chat duoc luu thanh `ChatSession`, co title, category, timestamp va history.

Kien truc tuong lai nen phat trien AI Coach thanh action-based agent: AI khong chi tra loi bang text, ma de xuat structured actions nhu doi bua an, them snack, ghi nuoc, them activity, cap nhat workout, tao reminder. Cac action quan trong phai co preview, token cost, confirm va undo.

### 4.7. Food Scan

Food Scan la tinh nang AI Scan Center trong V1.

Nguoi dung co the:

- Chup anh mon an.
- Chon anh tu thu vien.
- Nhap ten mon truc tiep.
- De AI uoc tinh calories, protein, carbs va fat.
- Chon slot bua an de ghi vao meal log.
- Chi xem thong tin dinh duong ma khong ghi log.

Food Scan su dung `FoodScanService`, co kha nang goi model vision/text qua API tuong thich OpenAI va co fallback khi AI khong phan tich duoc.

### 4.8. Health History

Health History cho phep nguoi dung xem lai lich su suc khoe, bao gom can nang va cac chi so tien bo.

Du lieu lien quan:

- `WeightEntry`: label va can nang.
- Cap nhat can nang thong qua `AppController.updateWeight`.
- Luu weight history vao repository.

Day la nen tang cho cac chart nang cao nhu weight trend, calorie trend, protein trend, workout consistency va health score trend.

### 4.9. Profile / Toi

Profile la khu vuc quan ly thong tin ca nhan va tien bo.

Chuc nang:

- Xem thong tin profile, BMI, muc tieu va goi hien tai.
- Chinh sua profile.
- Xem token balance, token earned, token spent.
- Mo Token History.
- Mo Health History.
- Quan ly goi/trial/token pack.
- Dang xuat.
- Xem gio hang/don hang va cac shortcut lien quan.

Profile khong chi la trang tai khoan, ma nen phat trien thanh noi nguoi dung thay minh dang thay doi qua body stats, progress chart, achievement va streak.

### 4.10. Token Wallet Va Payment

CoreHealth dung mot vi token chung cho cac hanh dong AI.

Token costs hien tai:

- Basic AI Chat: 1 token.
- Advanced Coach Answer: 3 token.
- Full Day Meal Plan: 12 token.
- Food Scan: 3 token.
- Adaptive Weekly Plan: 20 token.

Token packs:

- Starter: 49.000 VND / 55 token.
- Basic: 99.000 VND / 120 token, goi recommended.
- Plus: 149.000 VND / 190 token.
- Pro: 199.000 VND / 260 token.
- Max: 299.000 VND / 420 token.
- Power: 499.000 VND / 760 token.
- Elite: 799.000 VND / 1.280 token.
- Founder: 1.000.000 VND / 1.650 token.

Payment Screen ho tro nhieu phuong thuc phu hop Viet Nam:

- Momo.
- ZaloPay.
- VietQR.
- PayPal.
- Apple Pay.
- Google Pay.
- Chuyen khoan ngan hang.

`SepayService` ho tro tao QR va kiem tra giao dich qua SePay API khi co token cau hinh.

### 4.11. Shop, Cart, Checkout Va Orders

Shop trong CoreHealth khong nen la ecommerce clone, ma nen la AI-curated health recommendations.

Chuc nang hien co:

- Danh sach san pham theo category: protein, vegetable, grain, fruit, dairy, supplement, equipment.
- Product detail.
- Them vao gio hang.
- Cart screen: chon nhieu san pham, xoa, checkout.
- Checkout screen: xac nhan san pham va thong tin nhan hang.
- Place order va xem orders.

Huong phat trien:

- Goi y san pham theo meal plan, workout plan, budget va muc tieu.
- Smart shopping list tu meal plan tuan.
- Product cards trong AI chat.
- Affiliate links minh bach.
- Khong de AI tu mua hang; user phai bam xac nhan.

### 4.12. Exercise Library

Exercise Library la man hinh thu vien bai tap.

Chuc nang:

- Loc bai tap theo category.
- Hien thi danh sach bai tap.
- Xem chi tiet bai tap bang bottom sheet.
- Co huong dan thuc hien theo tung buoc.
- Co luu y an toan.
- Them bai tap vao danh sach.

Trang nay ho tro nguoi dung tu tim bai tap ngoai workout plan AI.

### 4.13. Recipes

Recipes la thu vien cong thuc mon an healthy.

Chuc nang:

- Loc cong thuc theo nhom: tat ca, cao dam, it calo, chay, nau nhanh.
- Hien thi calories/macro va thong tin mon.
- Xem chi tiet cong thuc.
- Xem nguyen lieu can chuan bi.
- Xem cac buoc thuc hien.
- Them mon vao thuc don hom nay.

Trang nay bo sung cho Meal Plan, giup nguoi dung chu dong chon mon an phu hop.

### 4.14. Habits

Habits la man hinh theo doi thoi quen hang ngay.

Chuc nang:

- Theo doi uong nuoc.
- Theo doi giac ngu.
- Theo doi van dong/di bo.
- Checklist thoi quen tuy chinh.
- Them thoi quen moi.

Trang nay phu hop voi dinh huong CoreHealth la lifestyle coach, khong chi tap trung vao an va tap.

### 4.15. Favorites

Favorites gom cac mon an va bai tap nguoi dung danh dau yeu thich.

Vai tro:

- Luu mon hay an, bai tap hay dung.
- Giam friction khi lap ke hoach moi.
- Lam dau vao cho AI hieu preference cua user.

### 4.16. Challenges Va Leaderboard

Challenges va Leaderboard tao lop gamification/community.

Challenges:

- Danh sach thu thach suc khoe.
- Chi tiet thu thach.
- Nhiem vu hang ngay.
- Phan thuong token khi hoan thanh.
- Join challenge va mark completed.

Leaderboard:

- Xep hang thanh vien theo streak va health score.
- Podium top 3.
- Bang xep hang cac thanh vien khac.

Day la tinh nang tang retention, nen duoc uu tien sau khi daily AI loop on dinh.

### 4.17. Schedule

Schedule la man hinh lich trinh tuan.

Chuc nang:

- Chon ngay trong tuan.
- Xem bua an cua ngay.
- Xem workout cua ngay.
- Hien calories, sets, reps, duration.

Trang nay giup nguoi dung nhin plan theo lich thay vi chi xem tung module rieng.

### 4.18. Settings

Settings quan ly cau hinh he thong:

- Chinh sua ho so.
- Bao mat tai khoan.
- Nhac uong nuoc.
- Nhac lich tap.
- Nhac cap nhat can nang tuan.
- Chon ngon ngu.
- Chinh sach bao mat.
- Trung tam tro giup.

## 5. Design System

CoreHealth theo phong cach wellness hien dai: sang, sach, mem, than thien va co nang luong.

### 5.1. Mau Sac

Bang mau chinh:

- Background: `#FAFAFA`.
- Surface/card: `#FFFFFF`.
- Surface phu: `#F9FAFB`.
- Text chinh: `#111827`.
- Text phu: `#6B7280`.
- Text nhe: `#9CA3AF`.
- Accent chinh: `#A6D727`.
- Accent dam: `#8BC34A`.
- Accent mem: `#DCF58C`.
- Accent muted: `#C8E673`.
- Mint: `#F5F9EA`.
- Blue: `#60A5FA`.
- Orange: `#F59E0B`.
- Violet: `#A78BFA`.
- Gold: `#F4B740`.
- Border: `#E5E7EB`.

Mau xanh la la nhan dien chinh, dung cho CTA, active state, progress va cac diem nhan suc khoe. Cac mau phu nhu blue, orange, violet, gold dung de phan biet hydration, calories, reward, coach hoac trang thai phu.

### 5.2. Typography

Font chinh la Inter qua `google_fonts`.

He thong chu:

- Display: 32-46px, weight 700, dung cho hero/onboarding.
- Headline: 22-28px, weight 700, dung cho page title/section quan trong.
- Title: 16-20px, weight 700, dung cho card title.
- Body: 12-15px, weight 500, line-height 1.4-1.45.
- Label: 11-14px, weight 600-700, dung cho button, chip va metadata.

Typography nen gon, ro, de scan tren mobile. Khong nen lam text day dac nhu dashboard ky thuat.

### 5.3. Spacing Va Radius

Spacing tokens:

- XS: 6.
- SM: 10.
- MD: 14.
- LG: 18.
- XL: 24.

Radius tokens:

- Button: 18.
- Card: 24.
- Compact card: 14.
- Sheet: 28.
- Pill: 999.

UI uu tien bo goc lon, surface mem, spacing thoang va tap target de cham.

### 5.4. Component Style

Thanh phan chinh:

- Card nen trang, elevation nhe hoac shadow mem.
- Filled button nen xanh la, chu mau text chinh.
- Outlined button nen surface trang, border nhe.
- Input nen filled surface nhe, border 22px.
- Chip nen nen surface elevated, chu dam vua.
- Bottom sheet bo goc lon, noi dung tach lop ro.
- Bottom navigation co icon va label, kem nut hanh dong trung tam.

### 5.5. Nguyen Tac UX

- Mobile-first va ton trong SafeArea.
- Moi man hinh nen co mot trong tam ro.
- Khong nhoi qua nhieu card nho.
- AI insight nen giai thich bang ngon ngu doi thuong.
- Cac hanh dong ton token phai hien cost ro rang.
- Cac thay doi quan trong tu AI can co confirm.
- App khong dua ra chan doan y te, chi nen goi y suc khoe tong quan.

## 6. Luong Nguoi Dung Chinh

### 6.1. Luong User Moi

1. Mo app.
2. Xem Welcome/Intro.
3. Dang ky tai khoan.
4. Xac thuc OTP.
5. Hoan thanh onboarding.
6. Nhan profile, token khoi tao/trial.
7. Vao Home.
8. AI tao insight/meal/workout plan.
9. User bat dau scan mon, chat coach, tap luyen va theo doi tien bo.

### 6.2. Luong Tao Meal Plan AI

1. User vao Meal Plan.
2. App kiem tra trial/token balance.
3. Neu du dieu kien, `AppController.generateAiMealPlan` goi `AiService.generateMealPlan`.
4. AI tra ve meal plan 7 ngay.
5. App parse thanh `MealPlanDay` va `MealItem`.
6. User xem calories/macro va danh dau hoan thanh.

### 6.3. Luong Tao Workout Plan AI

1. User vao Workout Plan.
2. App kiem tra token/trial.
3. `AiService.generateWorkoutPlan` tao workout dua tren profile.
4. App hien danh sach ngay tap va bai tap.
5. User mo Workout Player.
6. User hoan thanh set, nghi giua set va ket thuc buoi tap.
7. App cap nhat completed workout day va co the hien notification.

### 6.4. Luong Food Scan

1. User mo sheet Scan do an.
2. Chup anh/chon anh/nhap ten mon.
3. `FoodScanService` phan tich mon an.
4. App hien calories, protein, carbs, fat.
5. User chon chi xem hoac ghi vao plan.
6. Neu ghi, app tao `MealLog` theo slot bua an.
7. Meal Plan/Home cap nhat du lieu hom nay.

### 6.5. Luong AI Coach

1. User mo coach theo category.
2. Nhap cau hoi.
3. App gui profile context, plan context va chat history vao `AiService.chat`.
4. AI tra loi theo vai tro nutrition/workout/wellness.
5. App luu message vao chat history hoac chat session.
6. Token duoc tru theo chi phi cau hoi.

### 6.6. Luong Mua Token

1. User vao Payment/Token area.
2. Chon token pack.
3. Chon phuong thuc thanh toan.
4. App hien QR/thong tin thanh toan.
5. Neu cau hinh SePay, app co the kiem tra giao dich.
6. Khi thanh cong, `activateTokenPack` cong token va ghi `TokenTransaction`.
7. Token balance cap nhat tren Profile va cac feature AI.

### 6.7. Luong Shop Va Checkout

1. User vao Shop.
2. Loc/xem san pham.
3. Mo Product Detail.
4. Them vao Cart.
5. Vao Cart, chon san pham can mua.
6. Checkout.
7. Place order.
8. Xem Orders.

## 7. Kien Truc Ung Dung

### 7.1. Frontend

CoreHealth Mobile duoc xay dung bang Flutter va Material 3.

Thanh phan chinh:

- `main.dart`: khoi tao repository, controller, theme va root app.
- `AppController`: state manager trung tam, ke thua `ChangeNotifier`.
- `CoreHealthScope`: cung cap controller cho widget tree.
- `models.dart`: dinh nghia domain models va enum.
- `theme.dart`: design tokens va Material theme.
- `screens/`: cac man hinh chinh/phu cua app.
- `widgets/visuals.dart`: cac component visual dung chung nhu bottom nav, sheet, chart, app bar, coach sheet.
- `services/`: AI, food scan, RAG, notification, payment.
- `data/`: repository abstraction va cac implementation.

### 7.2. State Management

State hien tai di theo mo hinh controller tap trung:

- `AppController` giu stage, session, profile, meal plan, workout plan, logs, cart, orders, token transactions, insights, chat histories va chat sessions.
- UI lang nghe controller qua `AnimatedBuilder`/scope.
- Mutations duoc dong bo qua repository va sau do notify UI.
- `_enqueueMutation` giup sap xep cac thao tac ghi de tranh race condition.

Mo hinh nay phu hop giai doan MVP vi don gian va de debug. Khi app lon hon, co the tach thanh cac controller/module rieng: AuthController, PlanController, CoachController, CommerceController, ProfileController.

### 7.3. Repository Layer

`AppRepository` la interface du lieu trung tam. Cac implementation:

- `MemoryAppRepository`: luu tam trong bo nho, phu hop demo/test.
- `PostgresAppRepository`: ket noi truc tiep PostgreSQL, tao schema va doc/ghi user data.
- `RemoteAppRepository`: goi backend API qua HTTP khi co `COREHEALTH_API_BASE_URL`.

App chon repository luc khoi dong:

- Neu co `COREHEALTH_API_BASE_URL`, dung remote backend.
- Neu khong, dung PostgreSQL local/host cau hinh qua dart-define.

### 7.4. Data Model

Domain models chinh:

- `AppUserSession`: userId, email, onboardingCompleted.
- `DemoProfile`: profile, body metrics, goal, activity, food/workout preferences, token wallet, referral, subscription/trial.
- `MealItem`, `MealPlanDay`, `MealLog`: meal plan va log bua an.
- `WorkoutExercise`, `WorkoutDay`: workout plan.
- `InsightItem`: AI insight tren dashboard.
- `ChatMessage`, `ChatSession`: AI chat.
- `TokenPack`, `TokenTransaction`: token wallet.
- `Product`, `OrderSummary`: shop, cart, order.
- `WeightEntry`: lich su can nang.

### 7.5. PostgreSQL Schema

Schema hien tai gom:

- `users`: tai khoan user.
- `pending_verify`: OTP dang cho xac thuc.
- `sessions`: session hien tai.
- `user_profiles`: profile, onboarding, subscription, token, referral.
- `weight_entries`: lich su can nang.
- `workout_completions`: ngay tap da hoan thanh.
- `meal_completions`: ngay meal plan da hoan thanh.
- `cart_items`: gio hang.
- `orders`: don hang.
- `meal_logs`: log mon an theo ngay.
- `token_transactions`: lich su token.
- `chat_sessions`: lich su chat AI.

### 7.6. AI Service Architecture

`AiService` xu ly:

- Tao dashboard insights.
- Chat nutrition/workout/wellness.
- Tao meal plan.
- Tao workout plan.
- Cache meal/workout plan theo profile hash.
- Fallback insight/plan khi khong co API key hoac loi model.

Service goi cac endpoint chat completions tuong thich OpenAI, voi fallback provider theo thu tu Groq -> Beeknoee -> GoLLM.

`RagService` bo sung fitness knowledge de cau tra loi coach on dinh hon.

### 7.7. Food Scan Architecture

`FoodScanService` xu ly:

- Phan tich anh bang vision model.
- Phan tich ten mon bang text model.
- Parse JSON ket qua thanh `FoodScanResult`.
- Fallback khi khong co API/loi parse.

Ket qua gom:

- Ten mon.
- Calories.
- Protein.
- Carbs.
- Fat.
- Confidence.

### 7.8. Notification Architecture

`NotificationService` su dung `flutter_local_notifications` va `timezone`.

Ho tro:

- Daily meal reminders.
- Smart notifications theo profile.
- Nhac workout buoi sang.
- Nhac uong nuoc.
- Streak guard.
- Evening check-in.
- Notification khi meal adjusted hoac workout completed.

### 7.9. Payment Architecture

`SepayService`:

- Tao VietQR URL theo reference, amount va bank account.
- Kiem tra giao dich qua SePay API neu inject `SEPAY_API_TOKEN`.
- Ghi chu production: token nen di qua backend proxy, khong nen de truc tiep trong mobile app.

## 8. Bao Mat Va Guardrails

CoreHealth co nhieu du lieu nhay cam ve suc khoe, nen can cac nguyen tac:

- Mat khau phai hash va salt.
- OTP co expiry va failed attempts.
- API/payment token khong hardcode trong app production.
- AI khong dua ra chan doan y khoa.
- Di ung va tinh trang suc khoe phai duoc ton trong trong meal/coach prompt.
- AI action anh huong du lieu quan trong can confirm.
- Token transaction can minh bach, co ledger.
- Payment confirmation nen do backend xac thuc.

## 9. Roadmap De Xuat

### Phase 1 - MVP Daily AI Health Loop

- Onboarding AI Health Assessment.
- Home dashboard/AI insight.
- Meal plan AI.
- Workout plan AI.
- Food Scan basic.
- AI Coach text.
- Tracking calories/protein/workout/water/weight.
- Token wallet.
- Payment/token packs.

### Phase 2 - Adaptive AI

- Smart Rebalance meal + workout.
- Adaptive workout intensity.
- Weekly AI review.
- Meal replacement.
- Protein/water alerts.
- Recovery check-in.
- Barcode scan.
- Fridge AI.
- Smart shopping list.

### Phase 3 - Advanced AI Features

- Body progress scan.
- AI form analysis.
- Voice coach.
- Advanced health score.
- Advanced analytics.
- Smart shop recommendations.
- Challenges va leaderboard co backend thuc.

### Phase 4 - Ecosystem

- Community.
- Wearable integration.
- Smart scale.
- Long-term AI memory.
- Export health report.
- Partner marketplace.

## 10. Ket Luan

CoreHealth Mobile la mot ung dung suc khoe AI-first, ket hop meal planning, workout planning, food scan, AI coach, token wallet, shop recommendation va progress tracking. Diem khac biet cua san pham nam o kha nang ca nhan hoa theo nguoi dung Viet Nam va vong lap hang ngay: AI tao plan, nguoi dung hanh dong, app ghi nhan du lieu, AI phan tich va dieu chinh.

Trong ngan han, CoreHealth nen tap trung lam that tot daily AI health loop: onboarding sau, home ro, scan food nhanh, meal/workout plan de theo, coach huu ich va token minh bach. Khi vong lap nay on dinh, cac lop nang cao nhu Smart Rebalance, shopping list, body scan, form analysis, community va wearable se co nen tang vung de phat trien.
