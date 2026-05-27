# Kế Hoạch Sản Phẩm CoreHealth

## 1. Định Vị Mới

CoreHealth không nên chỉ là một app ăn uống, app tập luyện, hay app quét calories đơn lẻ.

Định vị đề xuất:

> CoreHealth - AI Health Companion cá nhân hóa bữa ăn, tập luyện và thói quen hằng ngày theo cơ thể, mục tiêu và lối sống của bạn.

Tầm nhìn nội bộ:

> AI Health Operating System

Khi truyền thông với người dùng, nên dùng wording mềm hơn để tránh cảm giác quá y tế:

- AI Health Companion
- Personal Health AI
- AI Lifestyle Coach
- Daily Health Command Center

CoreHealth cần giúp người dùng trả lời mỗi ngày:

- Hôm nay tôi nên ăn gì?
- Hôm nay tôi nên tập gì?
- Tôi đang thiếu gì so với mục tiêu?
- Nếu tôi ngủ ít, bận, stress hoặc bỏ tập thì kế hoạch thay đổi thế nào?
- Tôi có đang tiến bộ không?

## 2. Sản Phẩm Cốt Lõi

CoreHealth nên xoay quanh một vòng lặp chính:

> Onboarding -> AI tạo plan -> Người dùng log/scan -> AI đánh giá -> AI tự điều chỉnh -> Người dùng thấy tiến bộ

Đây là phần quan trọng nhất. Nếu vòng lặp này mạnh, app sẽ có lý do để người dùng quay lại mỗi ngày.

| Trụ cột | Vai trò |
| --- | --- |
| AI Plan | Tạo bữa ăn, bài tập và task hằng ngày được cá nhân hóa |
| AI Tracking | Ghi nhận đồ ăn, workout, cân nặng, nước, mood, giấc ngủ |
| AI Coach | Giải thích, nhắc nhở, điều chỉnh và động viên |
| Adaptive Engine | Tự thay đổi plan theo hành vi thật |
| Progress System | Cho người dùng thấy tiến bộ rõ ràng |
| AI Agent | Có thể đề xuất, xác nhận và cập nhật dữ liệu trong app |

## 3. Bottom Navigation

Bottom nav nên gồm 6 tab:

| Tab | Vai trò |
| --- | --- |
| Home | Dashboard AI hằng ngày |
| Ăn | Meal/Nutrition |
| Tập | Workout |
| Quét | AI Scan Center |
| Coach | AI Chat/Voice Coach |
| Tôi | Profile/Progress/Settings |

Không nên để `Shop` ở bottom nav.

Shop nên nằm trong:

- Home recommendation
- Meal recommendation
- Coach suggestion
- Profile/More

Lý do: shop không phải hành động chính mỗi ngày. Nếu để shop ở bottom nav, app dễ có cảm giác thương mại quá sớm.

## 4. Home Page

Home là trang quan trọng nhất. Không nên chỉ là dashboard nhiều widget. Home phải tạo cảm giác:

> AI đang điều hành ngày hôm nay của tôi.

### 4.1. AI Dynamic Hero Card

Card đầu tiên phải là insight quan trọng nhất trong ngày.

Ví dụ:

- Hôm nay bạn ngủ ít hơn bình thường 1.5 giờ. Tôi đã giảm intensity workout xuống 20%.
- Bạn đang thiếu 32g protein để đạt mục tiêu hôm nay.
- Bạn đã giữ streak 6 ngày. Hôm nay chỉ cần hoàn thành thêm 2 task.
- Cân nặng đang giảm đúng hướng. Hãy giữ mức calories hiện tại thêm 5 ngày.

### 4.2. Daily Health Score

Một điểm tổng hợp dễ hiểu:

> Health Score: 82/100

Thành phần:

- Calories
- Protein
- Water
- Workout
- Sleep
- Mood/Stress
- Weight trend

Score phải giải thích được.

Ví dụ:

> Bạn mất 8 điểm vì protein thấp và chưa uống đủ nước.

### 4.3. Daily Timeline

Timeline theo ngày:

- Sáng: uống nước, breakfast, stretch
- Trưa: lunch suggestion
- Chiều: workout/reminder
- Tối: dinner, recovery, sleep coaching

Mỗi task có trạng thái:

- Chưa làm
- Đã làm
- Bỏ qua
- AI đã điều chỉnh

### 4.4. Quick Actions

Các action cần dùng mỗi ngày:

- Scan food
- Generate meal
- Generate workout
- Ask AI
- Log weight
- Track water

### 4.5. Adaptive Plan Card

Card thể hiện AI đang tự điều chỉnh.

Ví dụ:

- Bạn đã skip 2 buổi tập. Tôi đổi lịch tuần này sang 3 buổi full-body.
- Bạn ăn thiếu protein 3 ngày liên tiếp. Tôi thêm snack giàu protein vào plan.
- Bạn bận vào buổi tối. Tôi chuyển workout sang 15 phút buổi sáng.

### 4.6. Smart Recommendations

Không nên biến thành shop lộ liễu. Nên là recommendation theo context:

- Thiếu protein -> gợi ý meal/whey.
- Ngủ kém -> gợi ý sleep routine.
- Tập tại nhà -> gợi ý equipment nhẹ.
- Ăn ngoài nhiều -> gợi ý món Việt phù hợp macro.
- Bữa gần nhất cần ức gà/rau -> gợi ý nơi mua trong shop hoặc đối tác gần người dùng.

## 5. Ăn Page

Meal page nên tập trung vào việc giúp người dùng ăn đúng mục tiêu, không chỉ xem danh sách món.

### 5.1. Daily Meal Timeline

Các bữa trong ngày:

- Breakfast
- Lunch
- Dinner
- Snack

Mỗi bữa hiển thị:

- Calories
- Protein
- Carbs
- Fat
- Trạng thái: planned/logged/skipped/replaced

### 5.2. Nutrition Progress

Thanh tiến độ:

- Calories hôm nay
- Protein
- Carbs
- Fat
- Water

Ví dụ:

> Protein: 68/110g

### 5.3. AI Meal Generator

Input:

- Budget
- Món Việt
- Nguyên liệu có sẵn
- Thời gian nấu
- Mục tiêu
- Dị ứng
- Khẩu vị

Output:

- Món ăn
- Recipe
- Calories/macros
- Shopping list
- Lựa chọn thay thế

### 5.4. Replace Meal

Người dùng có thể đổi món nếu không thích. AI phải giữ mục tiêu macro tương đương.

Ví dụ:

> Đổi ức gà sang bò áp chảo nhưng vẫn giữ protein tương đương.

### 5.5. Smart Rebalance

Đây là tính năng rất quan trọng cho CoreHealth vì nó làm app thực tế hơn: người dùng vẫn được ăn món mình thích, AI sẽ điều chỉnh phần còn lại để giữ mục tiêu.

Ví dụ người dùng nói:

> Tối nay tôi muốn ăn gà rán.

AI sẽ:

1. Thay bữa tối hiện tại thành gà rán.
2. Ước tính calories/macros của gà rán theo khẩu phần người dùng chọn.
3. So sánh với mục tiêu ngày và timeline giảm/tăng cân.
4. Điều chỉnh bữa gần nhất nếu còn có thể.
5. Thêm hoặc đổi bữa phụ nếu cần bổ sung protein/fiber.
6. Vì token là một ví chung, AI có thể đồng thời gợi ý điều chỉnh meal và workout nếu token balance đủ.
7. Nếu token không đủ cho full rebalance, AI vẫn đưa phương án đơn giản miễn phí hoặc ít token hơn.

Nguyên tắc:

- Không phán xét món ăn là "xấu" hay "cheat".
- Luôn đưa ra phương án cân bằng thực tế.
- Nếu không thể giữ đúng mục tiêu trong ngày, AI sẽ điều chỉnh theo tuần thay vì ép người dùng.
- Người dùng phải thấy rõ trade-off: ăn món này thì cần đổi gì.

Ví dụ output:

> Được. Tôi sẽ đổi bữa tối thành gà rán. Bữa này ước tính khoảng 720 kcal và 38g protein. Để vẫn bám mục tiêu hôm nay, tôi đề xuất bữa phụ chuyển sang sữa chua Hy Lạp không đường, ngày mai giảm 120 kcal ở bữa trưa, và thêm 18 phút đi bộ nhanh sau bữa tối. Nếu đồng ý, tôi sẽ cập nhật meal plan, workout/timeline và trừ 15 token.

Token logic:

- Tất cả action dùng chung một loại token, không chia meal token/workout token.
- Meal swap cơ bản: tốn ít token.
- Full Smart Rebalance meal + workout/timeline: tốn token trung bình.
- Nếu người dùng không đủ token, vẫn nên cho bản gợi ý đơn giản miễn phí hoặc đề xuất mua token pack phù hợp.

Tên đề xuất trong app: **Smart Rebalance**.

### 5.6. AI Fridge Mode

Người dùng scan hoặc nhập nguyên liệu:

- Trứng
- Thịt
- Rau
- Cơm
- Đậu hũ

AI tạo món phù hợp với macro, budget và khẩu vị.

### 5.7. Water Tracking

Đơn giản, dễ dùng, có streak.

### 5.8. Smart Nutrition Alerts

Ví dụ:

- Protein hôm nay thấp hơn mục tiêu 35g.
- Bạn đã ăn ngoài 4 lần tuần này.
- Bữa tối nên nhẹ hơn vì trưa đã vượt calories.

## 6. Tập Page

Workout page nên làm tốt 3 việc:

- Hôm nay tập gì.
- Bài tập có phù hợp tình trạng hiện tại không.
- Người dùng đang tiến bộ ra sao.

### 6.1. Today Workout

Workout AI tạo theo:

- Mục tiêu
- Level
- Equipment
- Thời gian rảnh
- Lịch tuần
- Recovery
- Sleep/stress

### 6.2. Start Workout Mode

Khi bắt đầu tập:

- Bài tập
- Sets
- Reps
- Rest timer
- Weight
- RPE/cảm giác nặng nhẹ
- Complete/skip/replace exercise

### 6.3. Adaptive Intensity

AI tự điều chỉnh nếu:

- Ngủ ít
- Stress cao
- Đau cơ
- Skip nhiều ngày
- Thời gian còn ít

Ví dụ:

> Hôm nay bạn ngủ 5h30. Tôi chuyển leg day thành mobility + upper body nhẹ.

### 6.4. Body Focus Visualization

Nên giữ và nâng cấp phần body overlay.

Các mode:

- Muscle focus
- Soreness map
- Recovery map
- Progress map

### 6.5. Progressive Overload AI

AI đề xuất tăng:

- Reps
- Sets
- Weight
- Duration
- Difficulty

Ví dụ:

> Tuần trước bạn hoàn thành 3x12 dễ dàng. Hôm nay tăng lên 3x14.

### 6.6. AI Form Analysis

Đưa vào Phase 3 hoặc tính năng tốn nhiều token:

- Squat form
- Pushup form
- Plank posture
- Deadlift warning

Cần có disclaimer vì liên quan an toàn vận động.

## 7. Quét Page

`Quét` nên trở thành:

> AI Scan Center

| Mode | Chức năng | Ưu tiên |
| --- | --- | --- |
| Food Scan | Nhận diện món, calories/macros | Phase 1 |
| Meal Scan | Nhận diện nhiều món trong 1 bữa | Phase 1/2 |
| Barcode Scan | Đọc nutrition sản phẩm | Phase 2 |
| Ingredient Scan | Scan nguyên liệu để tạo món | Phase 2/3 |
| Body Progress Scan | Before/after, body shape progress | Phase 3 |
| Supplement Scan | Phân tích supplement label | Phase 3 |
| Form Scan | Phân tích động tác tập | Phase 3/4 |

Ưu tiên đầu tiên nên là Food Scan vì dễ viral, dễ hiểu, gắn trực tiếp với calorie tracking.

## 8. Coach Page

Coach nên là tab riêng vì AI là lõi sản phẩm.

### 8.1. Chat AI

Context AI cần nhớ:

- Profile
- Goal
- Body stats
- Meal history
- Workout history
- Budget
- Allergies
- Equipment
- Schedule
- Preferences

### 8.2. Coach Modes

| Mode | Vai trò |
| --- | --- |
| Nutrition Coach | Ăn uống, macro, meal replacement |
| Workout Coach | Lịch tập, bài tập, progression |
| Recovery Coach | Ngủ, stress, đau cơ |
| Motivation Coach | Streak, thói quen, kỷ luật |
| General Health Coach | Kiến thức sức khỏe cơ bản, không chẩn đoán |

### 8.3. Daily Check-in

Mỗi ngày AI hỏi nhanh:

- Hôm nay bạn thấy thế nào?
- Ngủ bao lâu?
- Mức stress?
- Có đau cơ không?
- Có bận không?

Sau đó điều chỉnh plan.

### 8.4. AI Reflection

Mỗi tối:

> Hôm nay bạn hoàn thành 78% mục tiêu. Điểm tốt nhất là protein đạt chuẩn. Ngày mai nên tập trung vào nước và giấc ngủ.

### 8.5. Voice AI

Nên để Phase 2/3. Không cần làm ngay trong MVP.

### 8.6. AI App Actions Sync

Chat với AI không nên chỉ dừng lại ở việc trả lời bằng text. AI Coach phải có khả năng đề xuất và thực hiện thay đổi trong app sau khi người dùng xác nhận.

Ví dụ:

> User: Tối nay tôi muốn ăn gà rán.

AI trả lời:

> Được. Nếu đổi bữa tối thành gà rán, hôm nay bạn sẽ vượt khoảng 260 kcal. Tôi đề xuất đổi bữa phụ sang sữa chua Hy Lạp và thêm 15 phút đi bộ nhanh sau bữa tối. Bạn có muốn tôi cập nhật kế hoạch không?

User xác nhận:

> Đồng ý.

Hệ thống tự động:

- Cập nhật dinner trong meal plan thành gà rán.
- Cập nhật macro/calorie estimate.
- Đổi bữa phụ nếu cần.
- Thêm walking task vào daily timeline.
- Cập nhật health score/remaining calories.
- Ghi lịch sử thay đổi vào timeline.

Nguyên tắc sản phẩm:

- AI không tự sửa dữ liệu quan trọng nếu chưa có xác nhận.
- Mọi thay đổi phải có preview rõ ràng trước khi apply.
- Người dùng có thể undo.
- AI phải nói rõ thay đổi nào sẽ được cập nhật.
- Cùng một action có thể thực hiện từ UI hoặc từ chat, kết quả phải đồng bộ như nhau.

Loại action AI có thể thực hiện:

| Action | Ví dụ |
| --- | --- |
| Update meal | Đổi bữa tối thành gà rán |
| Replace meal | Đổi món không thích sang món khác |
| Add snack | Thêm bữa phụ giàu protein |
| Update workout | Giảm intensity hoặc đổi bài tập |
| Add activity | Thêm 15 phút đi bộ |
| Log food | Log món người dùng vừa ăn |
| Log water | Thêm 500ml nước |
| Log weight | Ghi cân nặng mới |
| Adjust plan | Điều chỉnh calories/workout trong tuần |
| Create reminder | Nhắc uống nước, tập, đi ngủ |
| Find product | Tìm nguồn mua nguyên liệu/sản phẩm phù hợp |
| Add shopping item | Thêm nguyên liệu vào shopping list |
| Show shop card | Gửi popup/card sản phẩm trong chat |

### 8.7. AI App Data Manager

AI của CoreHealth nên được thiết kế như một agent quản lý toàn bộ dữ liệu app, nhưng theo quyền và guardrails rõ ràng.

AI có thể đọc context:

- Profile và mục tiêu
- Meal plan
- Workout plan
- Daily timeline
- Food/workout/water/weight logs
- Token balance
- Shop products
- Shopping list
- Reminders
- Progress charts
- Preferences và restrictions

AI có thể đề xuất/cập nhật:

- Meal
- Workout
- Timeline
- Shopping list
- Reminders
- Goals nhỏ
- Health score explanation
- Product recommendations

AI không được tự động thay đổi:

- Thông tin y tế nhạy cảm
- Token purchase/thanh toán
- Mua hàng
- Xóa dữ liệu lớn
- Mục tiêu dài hạn quan trọng
- Thông tin profile quan trọng

Những action này cần explicit confirmation và audit log.

Mục tiêu sản phẩm:

> Người dùng có thể nói chuyện bằng ngôn ngữ tự nhiên, còn CoreHealth tự cập nhật UI, plan, reminder, shop suggestion và tracking phù hợp.

## 9. Tôi Page

Profile không chỉ là thông tin tài khoản. Nó nên là nơi người dùng thấy mình đang thay đổi.

### 9.1. Body Stats

- Weight
- BMI
- Body fat nếu có
- Muscle nếu có
- Goal weight
- Weekly change

### 9.2. Progress Charts

- Weight trend
- Calorie trend
- Protein trend
- Workout consistency
- Body measurements
- Health score trend

### 9.3. Achievements

Gamification:

- 7-day streak
- 30 workouts
- Protein goal streak
- Hydration streak
- First 5kg lost
- Consistency badge

### 9.4. Token Wallet

- Token balance
- Token history
- Buy token packs
- Earn free tokens
- Usage breakdown
- Low-token reminder

### 9.5. Settings / More

- Language
- Dark mode
- Notifications
- Help center
- Privacy
- Export report
- Referral
- Community
- Challenges

## 10. Shop Page

Không nên làm như Shopee clone.

Shop nên là:

> AI Curated Health Recommendations

Không phải trang bán hàng chính, mà là gợi ý theo nhu cầu thật.

Categories:

- Whey/protein
- Healthy food
- Gym accessories
- Smart scale
- Sleep products
- Vitamins/supplements
- Meal prep tools

Mô hình kiếm tiền:

- Affiliate Shopee
- Affiliate TikTok Shop
- Affiliate Lazada
- Brand partnership
- AI recommendation theo ngữ cảnh

### 10.1. AI Smart Shop Agent

Shop nên được điều khiển bởi AI agent, không chỉ là trang list sản phẩm.

AI có thể đọc context trong app:

- Meal plan sắp tới
- Bữa ăn gần nhất
- Nguyên liệu cần mua
- Workout plan
- Equipment người dùng đang có/chưa có
- Budget
- Địa điểm nếu người dùng cho phép
- Mục tiêu sức khỏe
- Lịch sử mua/quan tâm sản phẩm

Ví dụ:

> Bữa tối của người dùng có ức gà và rau.

Home có thể hiện suggestion:

> Bạn cần ức gà và rau cho bữa tối. Tôi tìm thấy vài lựa chọn phù hợp budget của bạn.

Nếu người dùng hỏi trong chat:

> Tôi muốn nguồn mua món này.

AI sẽ:

1. Hiểu "món này" đang refer tới meal/ingredient nào trong context.
2. Tìm trong CoreHealth Shop trước.
3. Nếu có sản phẩm phù hợp, gửi product cards vào chat.
4. Nếu không có trong shop, gợi ý nguồn mua khác: siêu thị, cửa hàng healthy food, sàn TMĐT, cửa hàng gần người dùng nếu có location.
5. Nếu là affiliate product, gắn tracking link.
6. Nếu giá vượt budget, AI đưa lựa chọn rẻ hơn.

Product card trong AI chat nên gồm:

- Ảnh sản phẩm
- Title
- Giá
- Tên shop
- Lý do gợi ý
- Nút xem chi tiết
- Nút thêm vào shopping list
- Nút mở link mua

Ví dụ popup/card:

```text
Ức gà phi lê 500g
85.000đ
Shop: Healthy Food VN
Lý do: Đủ protein cho bữa tối và nằm trong budget hôm nay.
[Thêm vào shopping list] [Mở link mua]
```

Nguyên tắc:

- AI phải ưu tiên lợi ích sức khỏe và budget của người dùng, không chỉ ưu tiên hoa hồng.
- Nếu sản phẩm là affiliate/partner, nên có nhãn rõ ràng.
- Nếu không có sản phẩm phù hợp, AI nên nói thật và gợi ý nơi mua khác.
- AI không nên spam shop trên Home; chỉ gợi ý khi có context thật.
- Người dùng có thể tắt shop recommendations.

### 10.2. Smart Shopping List

Từ meal plan, AI có thể tạo shopping list tự động.

Nguồn tạo shopping list:

- Meal plan trong ngày
- Meal plan trong tuần
- AI Fridge Mode
- Smart Rebalance
- Người dùng hỏi trong chat

Tính năng:

- Gom nguyên liệu trùng lặp
- Ước tính số lượng
- Ước tính chi phí
- Gợi ý nơi mua
- Thay thế nguyên liệu nếu quá đắt/hết hàng
- Thêm item vào cart/shop link nếu có

Ví dụ:

> Tuần này bạn cần 1.2kg ức gà, 10 trứng, 700g rau xanh và 4 hộp sữa chua Hy Lạp. Tổng ước tính 420.000đ.

### 10.3. AI Commerce Actions

AI agent có thể thực hiện các action liên quan shop sau khi người dùng xác nhận:

| Action | Ví dụ |
| --- | --- |
| Find product | Tìm nguồn mua ức gà cho bữa tối |
| Show product cards | Gửi card sản phẩm vào chat |
| Add to shopping list | Thêm ức gà 500g vào shopping list |
| Replace product | Đổi whey đắt sang lựa chọn rẻ hơn |
| Open affiliate link | Mở link Shopee/TikTok Shop/Lazada |
| Recommend local store | Gợi ý siêu thị/cửa hàng gần người dùng |
| Estimate weekly grocery cost | Tính tiền nguyên liệu cho meal plan tuần này |

AI không nên tự động mua hàng. Bước mua hàng phải do người dùng bấm xác nhận trên link/shop.

## 11. Community Và Challenge

Community có tiềm năng, nhưng chưa nên build sớm.

Community có thể gồm:

- Transformation posts
- Progress sharing
- Leaderboard
- Streak battles
- Meal ideas
- Workout logs

Challenge ví dụ:

- 30-day fat loss
- 7-day protein challenge
- Water challenge
- 100 pushups challenge
- Sleep better challenge

Nên đưa vào Phase 3/4 sau khi core tracking đã tốt.

## 12. Sleep / Recovery

Đây là điểm khác biệt tốt vì nhiều app fitness Việt Nam còn yếu.

Phase đầu nên đưa recovery vào Home + Coach + Workout, chưa cần tab riêng.

Recovery features:

- Sleep score
- Stress check-in
- Soreness tracking
- Recovery recommendation
- Workout readiness
- Evening reflection

## 13. Token Monetization System

CoreHealth nên dùng mô hình token/credit làm cách kiếm tiền chính.

Lý do:

- AI chat, food scan, meal generation, body scan và voice AI đều có chi phí theo usage.
- Người dùng Việt Nam có thể ngại trả tiền hằng tháng, nhưng dễ mua gói token nhỏ để thử hơn.
- Token giúp app linh hoạt: ai dùng nhiều trả nhiều, ai dùng ít vẫn ở lại.
- Dễ tạo gamification: streak, challenge, referral, daily check-in có thể tặng token.
- Dễ bán theo moment: khi người dùng cần scan, generate plan, phân tích body, họ sẽ dễ chấp nhận tiêu token hơn.

Nguyên tắc:

- Tracking cơ bản nên miễn phí.
- AI action tốn chi phí mới dùng token.
- Mỗi action phải hiện rõ token trước khi người dùng bấm.
- Token không nên làm người dùng sợ dùng app; hãy cho free daily token để tạo habit.
- Feature càng nặng về AI/vision/voice thì càng tốn token.

### 13.1. Free Token Allowance

Dành cho người dùng mới và người dùng hằng ngày:

- Basic tracking
- Daily free tokens
- Limited food scan bằng free token
- Limited AI chat bằng free token
- 1 meal suggestion cơ bản/ngày
- 1 workout suggestion cơ bản/ngày
- Basic health score
- Basic progress chart
- Earn token từ streak, referral, challenge, daily check-in

### 13.2. Token Wallet

CoreHealth chỉ nên có **một loại token chung** cho toàn bộ AI usage. Không chia token riêng cho meal, workout, scan hay coach.

Hiển thị:

- Token balance
- Token earned
- Token spent
- Action history
- Expiry nếu có
- Gói token đề xuất theo usage

Ví dụ:

> Bạn còn 120 token. Đủ để scan khoảng 12 bữa ăn hoặc tạo 6 meal plans nâng cao.

Nguyên tắc:

- Một token wallet duy nhất.
- Mọi AI action trừ token từ cùng một balance.
- Người dùng mua pack nào cũng dùng được cho meal, workout, scan, coach, shop agent và Smart Rebalance.
- Backend là nơi tính token cost và trừ token; Flutter chỉ hiển thị preview.

### 13.3. Token Pricing Theo Action

Bảng giá token nên để backend config được, không hardcode trong app.

| Action | Token |
| --- | ---: |
| Basic AI chat message | 1 |
| Advanced AI coach answer | 3 |
| Generate 1 meal | 5 |
| Generate full day meal plan | 12 |
| Replace meal | 3 |
| Smart Rebalance meal swap | 8 |
| Smart Rebalance full meal + workout/timeline | 15 |
| Food scan | 10 |
| Meal scan nhiều món | 15 |
| Generate 1 workout | 5 |
| Adaptive weekly plan | 20 |
| Weekly AI review | 15 |
| Fridge AI | 15 |
| Barcode scan | 5 |
| Body progress scan | 30 |
| Voice AI minute | 5 |
| AI form analysis | 40 |

Giá trị token có thể thay đổi theo chi phí AI thực tế.

### 13.4. Token Packs

Bán gói token theo mệnh giá, dùng chung cho tất cả tính năng AI.

| Id | Pack | Giá | Token | Mô tả | Recommended |
| --- | --- | ---: | ---: | --- | --- |
| starter | Starter | 49.000đ | 55 | Nạp nhanh để thử AI plan và scan. | No |
| basic | Basic | 99.000đ | 120 | Mệnh giá phổ biến nhất cho user mới bắt đầu. | Yes |
| plus | Plus | 149.000đ | 190 | Thoải mái generate plan và refresh nhiều lần hơn. | No |
| pro | Pro | 199.000đ | 260 | Đủ cho nhiều lần generate plan và top-up chat. | No |
| max | Max | 299.000đ | 420 | Phù hợp user dùng AI đều mỗi tuần. | No |
| power | Power | 499.000đ | 760 | Dành cho người dùng AI liên tục và scan thường xuyên. | No |
| elite | Elite | 799.000đ | 1.280 | Pack lớn cho usage cao, tiết kiệm hơn theo token. | No |
| founder | Founder | 1.000.000đ | 1.650 | Mệnh giá cao nhất để scale usage dài hạn. | No |

`basic` nên là pack recommended mặc định vì giá dễ tiếp cận và đủ token để người dùng trải nghiệm AI chat, food scan, meal generation và Smart Rebalance.

Backend seed/config đề xuất:

```java
List.of(
    new TokenPack("starter", "Starter", 49_000, 55, "Nạp nhanh để thử AI plan và scan.", false),
    new TokenPack("basic", "Basic", 99_000, 120, "Mệnh giá phổ biến nhất cho user mới bắt đầu.", true),
    new TokenPack("plus", "Plus", 149_000, 190, "Thoải mái generate plan và refresh nhiều lần hơn.", false),
    new TokenPack("pro", "Pro", 199_000, 260, "Đủ cho nhiều lần generate plan và top-up chat.", false),
    new TokenPack("max", "Max", 299_000, 420, "Phù hợp user dùng AI đều mỗi tuần.", false),
    new TokenPack("power", "Power", 499_000, 760, "Dành cho người dùng AI liên tục và scan thường xuyên.", false),
    new TokenPack("elite", "Elite", 799_000, 1_280, "Pack lớn cho usage cao, tiết kiệm hơn theo token.", false),
    new TokenPack("founder", "Founder", 1_000_000, 1_650, "Mệnh giá cao nhất để scale usage dài hạn.", false)
);
```

Giá trị tham chiếu:

| Pack | Giá/token |
| --- | ---: |
| starter | ~891đ/token |
| basic | ~825đ/token |
| plus | ~784đ/token |
| pro | ~765đ/token |
| max | ~712đ/token |
| power | ~657đ/token |
| elite | ~624đ/token |
| founder | ~606đ/token |

Không còn gói tháng Meal/Workout/Max. Các pack trên chỉ khác nhau về giá và số token, không khóa/mở khóa feature theo gói.

### 13.5. Token Earning

Người dùng có thể nhận token miễn phí để tăng retention:

- Daily check-in
- Giữ streak
- Hoàn thành workout
- Log meal đủ ngày
- Đạt protein target
- Mời bạn bè
- Tham gia challenge
- Xem partner offer
- Feedback kết quả scan/AI

Cần giới hạn token free để tránh abuse.

### 13.6. Feature Access

Không nên chia feature theo paywall cứng ngay từ đầu. Nên chia thành:

- Free core features: tracking, profile, basic health score, basic dashboard.
- Token AI features: scan, generate, coach, adaptive review, body/form analysis.
- Special programs: 7 ngày, 30 ngày, transformation challenge có thể mua bằng token hoặc tiền mặt.

### 13.7. Không Dùng Gói Tháng Trong V1

Trong V1, CoreHealth nên tập trung vào token packs, không thêm gói tháng để tránh làm người dùng rối.

Không làm trong V1:

- Không chia Meal/Workout/Max theo tháng.
- Không khóa feature theo gói tháng.
- Không bắt user renew mỗi tháng để dùng AI.
- Không tạo nhiều entitlement phức tạp.

Nếu sau này cần loyalty system, chỉ nên làm dạng reward/benefit nhẹ trên token wallet, không thay thế token packs.

## 14. Onboarding Redesign

Onboarding hiện tại sâu là tốt, nhưng không nên tạo cảm giác survey dài. Nên đổi thành:

> AI Health Assessment

Flow đề xuất:

1. Goal: lose fat, build muscle, eat healthier, improve fitness, maintain health.
2. Body & baseline: height, weight, age, gender, activity level, target weight.
3. Lifestyle: office worker, student, busy worker, athlete, parent, shift worker.
4. Food preference: món Việt, clean eating, vegetarian, budget meals, high protein, allergies, cooking time.
5. Workout setup: home/gym, equipment, experience level, available days, time/session, injuries.
6. AI Preview: calorie target, protein target, meal style, workout schedule, estimated timeline, first day plan.

AI Preview là bước cực quan trọng.

Ví dụ:

> AI đã tạo kế hoạch 4 tuần đầu cho bạn. Mục tiêu: giảm 1.8-2.4kg nếu giữ consistency 80%.

Sau đó mới yêu cầu tạo tài khoản hoặc tặng free starter tokens để người dùng dùng thử.

## 15. Killer Features Cần Ưu Tiên

### Tier 1 - Phải Làm Trước

1. AI Daily Plan: meal + workout + task hôm nay.
2. Food Scan: scan món ăn, log calories/macros.
3. AI Coach Text: chat có context từ profile và tracking.
4. Adaptive Plan Basic: tự chỉnh khi user skip, thiếu protein, quá calories, ngủ ít.
5. Health Score Basic: score đơn giản nhưng giải thích được.
6. Smart Rebalance: user muốn ăn món bất kỳ, AI tự cân bằng lại meal/workout để vẫn bám mục tiêu.
7. Token Wallet: một ví token chung cho toàn bộ AI actions.

### Tier 2 - Làm Sau Khi Core Ổn

1. Fridge AI: scan nguyên liệu -> tạo món.
2. Weekly AI Review: tổng kết tuần và chỉnh plan.
3. Body Focus / Recovery Map: nâng cấp workout visualization.
4. Barcode Scan: scan nutrition label.
5. Smart Shopping List: tự tạo list nguyên liệu từ meal plan.

### Tier 3 - High-Token / Viral / Advanced

1. Body Progress Scan: before/after, progress visualization.
2. AI Form Analysis: phân tích động tác tập.
3. Voice Coach: nói chuyện với AI.
4. Wearables: Apple Health, Google Fit, smartwatch.
5. Community / Challenges: tăng retention và social loop.
6. AI Smart Shop Agent: gợi ý sản phẩm/nguyên liệu theo context.

## 16. Design Direction

Style nên là sự kết hợp:

- Apple Health: sạch, tin cậy.
- Whoop: recovery, score, readiness.
- Duolingo: streak, habit, gamification.
- MyFitnessPal: tracking rõ ràng.
- Notion AI: cảm giác AI companion.

Không nên:

- Quá medical.
- Quá hardcore gym.
- Quá nhiều chart nhỏ.
- Quá nhiều card vụn.
- Quá giống ecommerce.

Nên:

- AI-first.
- Card lớn, có ngữ cảnh.
- Thông tin ít nhưng đúng lúc.
- Gamification nhẹ.
- Progress rõ.
- Emotional companion.

## 17. Kiến Trúc Feature Đề Xuất

Không nên để toàn bộ logic AI nằm trực tiếp trong Flutter. Flutter nên gọi service và hiển thị kết quả.

| Module | Vai trò |
| --- | --- |
| Flutter App | UI/UX mobile, state, local cache |
| User/Profile Service | Profile, goal, preferences |
| Tracking Service | Meal log, workout log, water, weight |
| AI Coach Service | Chat, insight, plan explanation |
| AI Action Orchestrator | Biến chat intent thành app actions có preview, confirm, execute, undo |
| Nutrition Engine | Meal plan, macros, food database |
| Workout Engine | Workout generation, progression |
| Scan Service | Food recognition, image analysis |
| Token Wallet Service | Balance, pricing, usage ledger, earned tokens |
| Recommendation Engine | Shop/content suggestions theo context |
| Shop/Product Service | Product catalog, affiliate links, product cards |
| Shopping List Service | Nguyên liệu cần mua, số lượng, chi phí ước tính |
| Notification Service | Reminders, daily check-in |

### 17.1. AI Action Architecture

Để chat AI và app đồng bộ chuẩn, nên thiết kế AI theo kiểu action-based, không để AI tự sửa database trực tiếp.

Flow chuẩn:

1. Người dùng chat với AI.
2. AI Coach Service đọc context user.
3. AI tạo `proposed_actions` dạng structured JSON.
4. AI Action Orchestrator validate action theo business rules.
5. Backend tính preview: calories, macro, token cost, timeline impact.
6. App hiện confirmation UI.
7. Người dùng bấm confirm.
8. Backend execute action bằng domain services.
9. App sync state realtime/local cache.
10. Hệ thống lưu audit log và cho undo nếu phù hợp.

Ví dụ `proposed_actions`:

```json
{
  "intent": "smart_rebalance_meal",
  "requires_confirmation": true,
  "token_cost": 15,
  "actions": [
    {
      "type": "replace_meal",
      "meal_slot": "dinner",
      "new_item": "gà rán",
      "estimated_calories": 720
    },
    {
      "type": "replace_snack",
      "meal_slot": "snack",
      "new_item": "sữa chua Hy Lạp không đường"
    },
    {
      "type": "add_activity",
      "activity": "đi bộ nhanh",
      "duration_minutes": 15
    }
  ]
}
```

Backend phải validate:

- Action user có quyền dùng không.
- Token có đủ không.
- Action có ảnh hưởng dữ liệu quan trọng không.
- Calories/macros có nằm trong ngưỡng hợp lý không.
- Có cần warning về sức khỏe/an toàn không.
- Action có thể undo không.
- Product/link có hợp lệ không nếu là shop action.

Không nên làm:

- Không để LLM ghi trực tiếp vào database.
- Không parse text tự do để update data.
- Không apply action quan trọng khi user chưa confirm.
- Không để Flutter tự tính logic token/entitlement chính.
- Không để AI ưu tiên sản phẩm chỉ vì hoa hồng nếu không phù hợp người dùng.

### 17.2. Tech Stack Đề Xuất Cho AI Sync

Frontend:

- Flutter
- State management hiện có của app
- Local cache cho current plan, timeline, profile
- Confirmation bottom sheet cho AI actions
- Undo snackbar/log screen

Backend:

- Spring Boot cho domain APIs, tracking, token wallet, user profile
- AI Coach Service riêng nếu cần xử lý LLM/orchestration nhanh
- AI Action Orchestrator nằm ở backend, không nằm trong Flutter
- WebSocket/Firebase Cloud Messaging cho sync realtime nếu cần

Data:

- PostgreSQL cho user, plan, meal, workout, token ledger, action log
- Redis cho cache context, rate limit, pending confirmations
- Vector DB sau này cho AI memory/knowledge nếu cần

AI:

- LLM dùng structured output/function calling
- Action schema versioning
- Prompt tách rõ: answer text + proposed actions
- Guardrails/rule validation ở backend

Core tables nên có:

| Table | Vai trò |
| --- | --- |
| ai_conversations | Lưu thread chat |
| ai_messages | Lưu message user/assistant |
| ai_pending_actions | Action đang chờ user confirm |
| ai_action_logs | Action đã execute/failed/undone |
| token_ledger | Cộng/trừ token minh bạch |
| meal_plan_items | Bữa ăn trong plan |
| workout_plan_items | Bài tập trong plan |
| daily_timeline_items | Task hằng ngày |
| products | Catalog sản phẩm/shop/affiliate |
| product_recommendations | Lịch sử AI gợi ý sản phẩm |
| shopping_list_items | Nguyên liệu/sản phẩm user cần mua |

### 17.3. UX Cho AI Action Confirmation

Khi AI đề xuất sửa app, UI nên hiện một confirmation card/bottom sheet:

- Nội dung thay đổi
- Tác động calories/macros
- Tác động workout/timeline
- Token sẽ trừ
- Nút `Apply changes`
- Nút `Edit`
- Nút `Cancel`

Sau khi apply:

- Home, Ăn, Tập, Timeline cập nhật ngay.
- Chat hiện message "Đã cập nhật kế hoạch".
- Có `Undo` trong một khoảng thời gian ngắn nếu action phù hợp.

## 18. Roadmap Build Thực Tế

### Phase 1 - MVP: Daily AI Health Loop

Mục tiêu:

> User mở app mỗi ngày và biết hôm nay cần ăn gì, tập gì, làm gì.

Build:

- Onboarding AI health assessment
- Home AI Dynamic Card
- Daily Health Score basic
- Daily Timeline
- Meal planning basic
- Workout planning basic
- Food Scan basic
- AI Coach text
- Basic tracking: calories, protein, workout, water, weight
- Token wallet và free starter tokens
- Smart Rebalance basic

Chưa build:

- Community
- Shop full
- Body scan
- Form analysis
- Wearable
- Voice AI

### Phase 2 - Adaptive AI

Mục tiêu:

> AI không chỉ tạo plan, mà biết tự chỉnh plan.

Build:

- Adaptive meal adjustment
- Adaptive workout intensity
- Weekly AI review
- Meal replacement
- Smart Rebalance meal/workout
- Protein/water alerts
- Recovery check-in
- Progress trend
- Barcode scan
- Fridge AI basic
- Smart shopping list

### Phase 3 - High-Token Differentiators

Mục tiêu:

> Tạo các feature mạnh để user sẵn sàng tiêu token nhiều hơn.

Build:

- Body progress scan
- AI form analysis
- Voice coach
- Advanced health score
- Advanced analytics
- Smart recommendations/shop affiliate
- AI Smart Shop Agent
- Challenges basic

### Phase 4 - Ecosystem

Mục tiêu:

> CoreHealth trở thành hệ sinh thái sức khỏe cá nhân.

Build:

- Community
- Full challenges
- Wearable integrations
- Smart scale
- Predictive insights
- AI memory dài hạn
- Export health report
- Partner marketplace

## 19. Những Điều Cần Thay Đổi So Với Kế Hoạch Ban Đầu

1. Không build quá nhiều killer feature cùng lúc.
2. Không gọi trực tiếp là Health Operating System với user ngay từ đầu.
3. Không để Shop ở bottom nav.
4. Home phải chuyển từ dashboard widget sang AI daily command center.
5. AI Coach phải thành tab riêng vì AI là core.
6. Health Score phải có giải thích, không chỉ là con số.
7. Onboarding phải có AI Preview để tạo hook tâm lý.
8. Ưu tiên vòng lặp hằng ngày trước, không ưu tiên số lượng page.
9. Không dùng subscription Meal/Workout/Max trong V1.
10. Dùng một ví token chung cho toàn bộ AI actions.
11. Chat AI phải đồng bộ với app qua action system.
12. Shop phải là AI recommendation theo context, không phải ecommerce clone.

## 20. North Star

CoreHealth nên đi theo hướng:

> Một AI companion giúp người dùng ăn đúng hơn, tập hợp lý hơn, theo dõi tiến bộ rõ hơn, và tự điều chỉnh kế hoạch mỗi ngày dựa trên cuộc sống thật của họ.

Product strategy ngắn gọn:

> CoreHealth không chỉ tạo kế hoạch sức khỏe. CoreHealth theo dõi, hiểu và tự điều chỉnh kế hoạch đó cùng bạn mỗi ngày.
