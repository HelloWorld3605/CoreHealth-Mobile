/// Fitness knowledge base — RAG chunks cho AI Coach CoreHealth
/// Mỗi chunk có: chủ đề, keywords (dùng để retrieval), nội dung chuyên sâu
library;

class FitnessChunk {
  const FitnessChunk({
    required this.id,
    required this.topic,
    required this.keywords,
    required this.content,
  });

  final String id;
  final String topic; // nutrition | workout | weightloss | musclegain | recovery | hydration | vi_food
  final List<String> keywords;
  final String content;
}

class FitnessKnowledge {
  static const chunks = <FitnessChunk>[
    // ─── TDEE & CALORIE ───────────────────────────────────────────────────────
    FitnessChunk(
      id: 'tdee_basics',
      topic: 'nutrition',
      keywords: ['calo', 'tdee', 'năng lượng', 'bmr', 'nhu cầu', 'tổng', 'đốt cháy', 'tiêu thụ'],
      content: '''
TDEE (Total Daily Energy Expenditure) — Tổng năng lượng tiêu thụ mỗi ngày:
• Ít vận động (sedentary): BMR × 1.2
• Nhẹ (1-2 buổi/tuần): BMR × 1.375
• Trung bình (3-5 buổi/tuần): BMR × 1.55
• Cao (6-7 buổi/tuần): BMR × 1.725
• Rất cao (2 buổi/ngày): BMR × 1.9

Công thức BMR Mifflin-St Jeor:
• Nam: (10 × kg) + (6.25 × cm) − (5 × tuổi) + 5
• Nữ: (10 × kg) + (6.25 × cm) − (5 × tuổi) − 161

Ví dụ: Nữ 28 tuổi, 62kg, 165cm, vận động trung bình:
BMR = (10×62) + (6.25×165) − (5×28) − 161 = 1,371 kcal
TDEE = 1,371 × 1.55 ≈ 2,125 kcal/ngày
''',
    ),

    FitnessChunk(
      id: 'macro_ratios',
      topic: 'nutrition',
      keywords: ['macro', 'protein', 'carb', 'fat', 'béo', 'tinh bột', 'đạm', 'tỷ lệ', 'phân bổ'],
      content: '''
Tỷ lệ macro theo mục tiêu:

GIẢM CÂN (calorie deficit 300-500 kcal/ngày):
• Protein: 30-35% (ưu tiên cao để giữ cơ)
• Carb: 35-40%
• Fat: 25-30%
• Protein tối thiểu: 1.6-2.0g × kg cân nặng

DUY TRÌ:
• Protein: 25-30%
• Carb: 40-50%
• Fat: 25-30%

TĂNG CƠ (surplus 200-300 kcal/ngày):
• Protein: 25-30% (2.0-2.2g × kg)
• Carb: 45-55% (fuel cho tập)
• Fat: 20-25%

Quan trọng: 1g protein = 4 kcal, 1g carb = 4 kcal, 1g fat = 9 kcal
''',
    ),

    FitnessChunk(
      id: 'protein_guide',
      topic: 'nutrition',
      keywords: ['protein', 'đạm', 'thịt', 'trứng', 'cá', 'cơ', 'muscle', 'phục hồi', 'amino'],
      content: '''
Hướng dẫn protein cho người tập:

Nhu cầu theo mục tiêu:
• Duy trì: 1.4–1.6g/kg
• Giảm mỡ giữ cơ: 1.8–2.2g/kg
• Tăng cơ: 2.0–2.4g/kg (không cần hơn)

Nguồn protein tốt (tính/100g):
• Ức gà: 31g protein, 165 kcal
• Cá hồi: 25g protein, 208 kcal (giàu Omega-3)
• Trứng gà: 13g protein, 155 kcal
• Đậu phụ: 8g protein, 76 kcal (phù hợp ăn chay)
• Sữa chua Hy Lạp: 10g protein, 59 kcal

Thời điểm ăn protein:
• Trong vòng 2 giờ sau tập để tối ưu tổng hợp cơ
• Chia đều bữa, mỗi bữa ~25-40g protein
• Trước ngủ: casein (phô mai, sữa) giúp phục hồi ban đêm
''',
    ),

    // ─── THỰC PHẨM VIỆT NAM ────────────────────────────────────────────────────
    FitnessChunk(
      id: 'vi_food_nutrition',
      topic: 'vi_food',
      keywords: ['phở', 'cơm', 'bún', 'bánh mì', 'thực phẩm', 'món ăn', 'việt nam', 'thực đơn', 'bữa'],
      content: '''
Giá trị dinh dưỡng món Việt phổ biến (ước tính/tô hoặc suất):

Bữa sáng:
• Phở bò (tô thường): ~380 kcal, 28g P, 48g C, 8g F
• Bún bò Huế: ~430 kcal, 25g P, 55g C, 12g F
• Bánh mì thịt: ~350 kcal, 18g P, 45g C, 10g F
• Xôi gà: ~450 kcal, 20g P, 65g C, 12g F

Bữa trưa/tối:
• Cơm tấm sườn (1 đĩa): ~620 kcal, 35g P, 75g C, 18g F
• Cơm gà (1 phần): ~520 kcal, 38g P, 58g C, 14g F
• Bún chả Hà Nội: ~480 kcal, 30g P, 55g C, 15g F
• Cơm lứt với gà luộc: ~420 kcal, 35g P, 52g C, 8g F ✓ (lành mạnh)
• Canh chua cá lóc + cơm: ~500 kcal, 32g P, 60g C, 10g F

Snack lành mạnh:
• Trái cây (chuối, xoài, ổi): 60-90 kcal/phần
• Sữa chua không đường: 60-80 kcal
• Hạt (hạnh nhân, hạt điều): 160 kcal/30g

Gợi ý thay thế lành mạnh hơn:
• Thay cơm trắng → cơm lứt: giảm GI, thêm chất xơ
• Thay nước ngọt → trà xanh không đường hoặc nước lọc
• Thay chiên → luộc/hấp: tiết kiệm 50-100 kcal/bữa
''',
    ),

    FitnessChunk(
      id: 'vi_meal_planning',
      topic: 'vi_food',
      keywords: ['thực đơn', 'lên menu', 'kế hoạch ăn', 'bữa sáng', 'bữa trưa', 'bữa tối', 'snack', 'ngày ăn'],
      content: '''
Mẫu thực đơn ngày cho người giảm cân (~1,600 kcal):

Sáng (7h): Phở bò tô nhỏ + 1 quả chuối
→ ~450 kcal, 30g P

Bữa phụ (10h): Sữa chua Hy Lạp không đường + ít hạt chia
→ ~100 kcal, 12g P

Trưa (12h): Cơm lứt 150g + ức gà luộc 150g + rau xào ít dầu
→ ~480 kcal, 40g P

Bữa phụ (15h): 1 quả táo hoặc ổi
→ ~80 kcal

Tối (18h): Canh chua cá + cơm lứt 100g + rau luộc
→ ~380 kcal, 28g P

Tổng: ~1,490 kcal, ~110g protein ✓

Mẫu thực đơn tăng cơ (~2,400 kcal):
• Tăng khẩu phần cơm lứt, thêm bữa protein buổi tối
• Thêm 2-3 quả trứng vào bữa sáng
• Bổ sung bơ đậu phộng (snack) ~180 kcal
''',
    ),

    // ─── WORKOUT PRINCIPLES ───────────────────────────────────────────────────
    FitnessChunk(
      id: 'workout_principles',
      topic: 'workout',
      keywords: ['tập luyện', 'bài tập', 'gym', 'progressive', 'overload', 'volume', 'intensity', 'hiệu quả'],
      content: '''
Nguyên tắc tập luyện hiệu quả:

1. Progressive Overload (Tăng tải dần):
• Mỗi tuần tăng 2.5-5% tạ HOẶC tăng 1-2 rep
• Không tăng cả hai cùng lúc
• Đây là NGUYÊN TẮC QUAN TRỌNG NHẤT để tăng cơ và sức mạnh

2. Volume (Khối lượng):
• Người mới: 10-15 sets/nhóm cơ/tuần
• Trung cấp: 15-20 sets
• Nâng cao: 20-25 sets

3. Nghỉ giữa set:
• Bài tập nặng (squat, deadlift): 2-3 phút
• Bài tập nhẹ/isolation: 60-90 giây
• Circuit training: 30-60 giây

4. Tần suất theo cấp độ:
• Người mới: Full body 3x/tuần (đủ kích thích, đủ phục hồi)
• Trung cấp: Upper/Lower 4x hoặc PPL 6x
• Nâng cao: Phân chia cơ cụ thể

5. Deload (Giảm tải):
• Mỗi 4-8 tuần nên deload 1 tuần (giảm 40-50% volume)
• Giúp phục hồi gân cơ và hệ thần kinh
''',
    ),

    FitnessChunk(
      id: 'workout_splits',
      topic: 'workout',
      keywords: ['lịch tập', 'split', 'upper lower', 'push pull', 'full body', 'ngày tập', 'phân chia', 'cơ ngực', 'cơ lưng'],
      content: '''
Lịch tập theo mục tiêu và thời gian:

FULL BODY 3x/tuần (người mới, thời gian hạn chế):
• T2: Squat, Bench Press, Row, Overhead Press, Deadlift nhẹ
• T4: Squat variation, Incline Press, Pull-up/Lat Pulldown, Curl, Tricep
• T6: Deadlift, Push-up, Row variation, Plank, Cardio nhẹ

UPPER/LOWER 4x/tuần (trung cấp):
• T2: Upper (ngực, lưng, vai, tay)
• T3: Lower (đùi, mông, bắp chân, core)
• T5: Upper (variation khác)
• T6: Lower (variation khác)

PPL (Push/Pull/Legs) 6x/tuần (nâng cao):
• Push: Ngực, vai, tricep
• Pull: Lưng, bicep
• Legs: Đùi trước, đùi sau, mông, bắp chân

TẬP TẠI NHÀ không dụng cụ:
• Push-up variations (30+ loại), Pull-up, Dip
• Squat, Lunges, Glute Bridge, Hip Thrust
• Plank, Mountain Climber, Burpee
• Đủ để tập toàn thân nếu tăng reps/thêm tạ nước
''',
    ),

    FitnessChunk(
      id: 'cardio_guide',
      topic: 'workout',
      keywords: ['cardio', 'chạy bộ', 'đạp xe', 'nhảy dây', 'aerobic', 'hiit', 'đốt mỡ', 'tim mạch'],
      content: '''
Hướng dẫn cardio cho từng mục tiêu:

GIẢM MỠ — Cardio hiệu quả nhất:
• HIIT (High Intensity Interval Training):
  20-30 phút × 3-4 lần/tuần
  Ví dụ: 30s chạy nhanh → 60s đi bộ → lặp 10-15 lần
  Đốt ~400-600 kcal/session, afterburn effect kéo dài 24-48h

• LISS (Steady State) — bền vững hơn:
  45-60 phút đi bộ nhanh/đạp xe/bơi, nhịp tim 60-70% max
  Đốt ~250-400 kcal/session
  Zone 2 training tốt cho sức bền và sức khỏe tim mạch

KHÔNG nên làm cardio dài trước khi tập tạ (ảnh hưởng performance)
Thứ tự tốt nhất: Tập tạ trước → Cardio sau (hoặc ngày riêng)

NHỊP TIM MỤC TIÊU:
• Đốt mỡ zone: 60-70% HRmax (220 - tuổi)
• Cardio zone: 70-80% HRmax
• Anaerobic: 80-90% (HIIT)
''',
    ),

    // ─── GIẢM CÂN ─────────────────────────────────────────────────────────────
    FitnessChunk(
      id: 'weight_loss_science',
      topic: 'weightloss',
      keywords: ['giảm cân', 'giảm mỡ', 'calo âm', 'deficit', 'chế độ', 'plateau', 'mất cân', 'cân nặng giảm'],
      content: '''
Khoa học giảm cân:

Tốc độ lành mạnh:
• 0.5-1.0 kg/tuần là lý tưởng (không mất cơ)
• Giảm quá nhanh (>1.5 kg/tuần) → mất cơ, metabolism chậm
• Calo deficit: 300-500 kcal/ngày là an toàn

Plateau (Trì hoãn giảm cân):
• Sau 4-6 tuần thường xảy ra
• Cơ thể thích nghi bằng cách giảm TDEE
• Giải pháp: refeed day (1 ngày ăn TDEE đầy đủ), thêm cardio, đổi bài tập

Không nên làm:
• Nhịn ăn hoàn toàn (ăn < BMR) → mất cơ, giảm trao đổi chất
• Chỉ cardio, không tập tạ → mất cơ nhiều hơn mỡ
• Loại bỏ hoàn toàn carb → không bền vững dài hạn

Cần làm:
• Đủ protein (1.8-2.2g/kg) để bảo vệ cơ
• Tập resistance training (tạ/bodyweight) song song
• Theo dõi calo thực tế (dùng app hoặc ghi chép)
• Ngủ đủ giấc (thiếu ngủ → tăng cortisol → tích mỡ bụng)
''',
    ),

    FitnessChunk(
      id: 'fat_loss_tips',
      topic: 'weightloss',
      keywords: ['mỡ bụng', 'giảm mỡ bụng', 'tích mỡ', 'béo bụng', 'body fat', 'mỡ cơ thể', 'spot reduction'],
      content: '''
Thực tế về giảm mỡ:

Spot reduction là MỸ TỪ — KHÔNG thể giảm mỡ cục bộ
• Tập bụng 100 cái/ngày KHÔNG giảm mỡ bụng
• Mỡ giảm từ toàn thân, gen quyết định thứ tự
• Bụng thường là nơi mỡ đi cuối cùng (đặc biệt nam)

Yếu tố ảnh hưởng tích mỡ bụng:
• Cortisol cao (stress, thiếu ngủ) → tích mỡ nội tạng
• Insulin resistance → khó đốt mỡ
• Estrogen thấp (nữ mãn kinh) → mỡ dịch từ hông → bụng
• Bia/rượu: calo rỗng + ức chế đốt mỡ trong 24h

Chiến lược giảm mỡ bụng hiệu quả:
1. Giảm calo deficit 300-400 kcal/ngày (bền vững)
2. Tập HIIT + tập tạ toàn thân
3. Giảm stress (yoga, thiền, đi bộ thiên nhiên)
4. Ngủ 7-9 tiếng (ưu tiên ngang protein!)
5. Giảm đường đơn (nước ngọt, bánh kẹo)
''',
    ),

    // ─── TĂNG CƠ ──────────────────────────────────────────────────────────────
    FitnessChunk(
      id: 'muscle_gain_science',
      topic: 'musclegain',
      keywords: ['tăng cơ', 'xây cơ', 'hypertrophy', 'muscle', 'bulk', 'cơ bắp', 'mạnh hơn', 'protein synthesis'],
      content: '''
Khoa học tăng cơ (Hypertrophy):

Tốc độ tăng cơ thực tế:
• Người mới (newbie gains): 1-2 kg cơ/tháng (tháng đầu)
• Sau 6 tháng: ~0.5-1 kg cơ/tháng
• Nâng cao (>2 năm): ~0.1-0.25 kg cơ/tháng

Điều kiện cần để cơ phát triển:
1. KÍCH THÍCH: Tập đủ volume, progressive overload
2. DINH DƯỠNG: Protein 2g/kg + Calorie surplus 200-300 kcal
3. PHỤC HỒI: Ngủ 7-9h, rest 48-72h cho mỗi nhóm cơ

Bulk clean vs Dirty bulk:
• Clean bulk: surplus 200-300 kcal → tăng cơ, ít mỡ thừa
• Dirty bulk: surplus 500+ kcal → tăng cơ NHANH HƠN nhưng kèm nhiều mỡ
• Recomposition (ăn maintenance): tăng cơ + giảm mỡ đồng thời — chậm nhưng có thể làm được với người mới

Hormone quan trọng:
• Testosterone: tập đa khớp (squat, deadlift), ngủ đủ giấc, giảm stress
• Growth Hormone: ngủ sâu (peak sau 1-2h ngủ), nhịn ăn ngắn (IF)
• IGF-1: kích hoạt bởi protein và GH
''',
    ),

    // ─── PHỤC HỒI ─────────────────────────────────────────────────────────────
    FitnessChunk(
      id: 'recovery_science',
      topic: 'recovery',
      keywords: ['phục hồi', 'nghỉ ngơi', 'đau cơ', 'doms', 'rest', 'ngủ', 'mệt', 'overtraining'],
      content: '''
Phục hồi — yếu tố quyết định kết quả:

Ngủ (quan trọng nhất):
• 7-9 tiếng/đêm là tối ưu cho tăng trưởng cơ
• Thiếu 1 giờ ngủ → giảm 24% nồng độ testosterone
• GH (Growth Hormone) tiết mạnh nhất trong giấc ngủ sâu
• Tắt điện thoại 1 tiếng trước khi ngủ, phòng tối và mát

DOMS (Đau cơ khởi phát chậm):
• Xuất hiện 24-48h sau tập, đỉnh ở 48-72h
• KHÔNG phải dấu hiệu cơ phát triển (là vi chấn thương)
• Không nên tập khi DOMS nặng (>7/10)
• Nhẹ (3-5/10): có thể tập với intensity thấp hơn

Kỹ thuật phục hồi hiệu quả:
• Active recovery: đi bộ nhẹ, yoga, bơi nhẹ — tốt hơn nghỉ hoàn toàn
• Massage/foam rolling: tăng lưu thông máu
• Contrast shower: nóng 3p → lạnh 1p, lặp 3-4 lần
• Protein sau tập + carb: window 2 giờ quan trọng nhất

Dấu hiệu Overtraining:
• Hiệu suất giảm liên tục >1 tuần
• Mất ngủ, hay cáu kỉnh
• Nhịp tim lúc nghỉ tăng 5+ bpm
• Giải pháp: Deload tuần hoặc nghỉ ngơi hoàn toàn 7-14 ngày
''',
    ),

    FitnessChunk(
      id: 'sleep_optimization',
      topic: 'recovery',
      keywords: ['ngủ', 'giấc ngủ', 'sleep', 'melatonin', 'circadian', 'mất ngủ', 'ngủ đủ giấc'],
      content: '''
Tối ưu giấc ngủ cho người tập:

Tại sao ngủ quan trọng với fitness:
• 80% GH tiết trong giấc ngủ → thiếu ngủ = thiếu "hormone tăng trưởng"
• Cortisol tăng khi thiếu ngủ → phân giải cơ + tích mỡ
• Phục hồi gân cơ, hệ miễn dịch đều xảy ra lúc ngủ
• Thiếu ngủ → thèm ăn nhiều hơn (ghrelin tăng, leptin giảm)

Thói quen ngủ tốt:
• Giờ ngủ cố định (kể cả cuối tuần)
• Phòng ngủ: 18-20°C, tối hoàn toàn
• Tránh caffeine sau 14h
• Tránh tập nặng sau 20h (cortisol và adrenalin còn cao)
• Không ăn bữa lớn trong 2h trước ngủ (có thể ăn casein nhẹ)
• Ánh sáng xanh từ điện thoại ức chế melatonin

Nếu khó ngủ:
• Magie glycinate 200-400mg trước ngủ (giúp thư giãn cơ)
• L-theanine 200mg (từ trà xanh)
• Kỹ thuật 4-7-8: hít 4s, giữ 7s, thở ra 8s
''',
    ),

    // ─── HYDRATION ────────────────────────────────────────────────────────────
    FitnessChunk(
      id: 'hydration',
      topic: 'hydration',
      keywords: ['nước', 'uống nước', 'hydrate', 'mất nước', 'electrolyte', 'thủy phân', 'khát'],
      content: '''
Hydration cho người tập thể thao:

Nhu cầu nước cơ bản:
• 35-40ml × kg cân nặng / ngày
• Ví dụ: 60kg → 2.1-2.4 lít/ngày (chưa tính khi tập)
• Thêm 500-750ml cho mỗi giờ tập (thêm nếu đổ nhiều mồ hôi)

Dấu hiệu mất nước:
• Nhẹ (1-2%): khát, nước tiểu vàng đậm
• Trung bình (2-3%): giảm 10-20% hiệu suất tập
• Nặng (>5%): chuột rút, chóng mặt, đau đầu

Nước tiểu màu lý tưởng: Vàng nhạt (màu nước chanh nhạt)

Electrolytes quan trọng:
• Natri (Na): mất theo mồ hôi, cần bổ sung khi tập >1h
• Kali (K): chuối, khoai lang, bơ — phòng chuột rút
• Magie (Mg): hạt, rau xanh đậm — phục hồi cơ
• Không cần nước điện giải nếu tập <1h

Timing uống nước:
• 500ml 2h trước khi tập
• 250ml ngay trước khi tập
• 150-250ml mỗi 15-20 phút trong khi tập
• Uống từ từ sau tập để tái hydrate
''',
    ),

    // ─── LIFESTYLE ────────────────────────────────────────────────────────────
    FitnessChunk(
      id: 'stress_cortisol',
      topic: 'recovery',
      keywords: ['stress', 'căng thẳng', 'cortisol', 'lo lắng', 'áp lực', 'mental', 'tâm lý', 'thư giãn'],
      content: '''
Stress và fitness — mối quan hệ hai chiều:

Cortisol (hormone stress):
• Cortisol cao → phân giải cơ, tích mỡ bụng, ức chế testosterone
• Tập quá nặng cũng làm cortisol tăng tạm thời (cần cân bằng)
• Stress công việc + stress tập luyện → overtraining nhanh hơn

Cách kiểm soát cortisol:
• Ngủ đủ 7-9h (hiệu quả nhất)
• Thiền/Mindfulness 10 phút/ngày: giảm cortisol 20-30%
• Đi bộ trong thiên nhiên 30 phút
• Tắm lạnh buổi sáng: tăng norepinephrine, tỉnh táo mà không cần caffeine
• Hạn chế caffeine sau 14h
• Kết nối xã hội: Oxytocin đối kháng cortisol

Tập luyện VÀ giảm stress:
• Cardio nhẹ (zone 2): giảm stress tốt nhất
• Yoga/Pilates: kết hợp cả thở và cơ thể
• Nếu stress nặng: giảm intensity buổi tập hoặc nghỉ 1-2 ngày
''',
    ),

    FitnessChunk(
      id: 'bmi_body_comp',
      topic: 'nutrition',
      keywords: ['bmi', 'chỉ số cơ thể', 'body fat', 'mỡ cơ thể', 'thành phần', 'waist', 'eo', 'vòng eo'],
      content: '''
BMI và thành phần cơ thể:

BMI (Body Mass Index):
• <18.5: Thiếu cân
• 18.5-22.9: Bình thường (chuẩn châu Á)
• 23.0-24.9: Thừa cân nhẹ (theo tiêu chuẩn châu Á, thấp hơn phương Tây)
• 25.0-29.9: Béo phì độ 1
• ≥30: Béo phì độ 2

Hạn chế của BMI:
• Không phân biệt cơ vs mỡ (VĐV có BMI cao nhưng không béo)
• Không tính phân bổ mỡ cơ thể

Chỉ số tốt hơn — Tỷ lệ vòng eo/chiều cao (WHtR):
• <0.5 là lý tưởng
• Ví dụ: cao 165cm → eo lý tưởng <82.5cm

% Body Fat ước tính (Navy formula):
• Nam: 495/(1.0324-0.19077×log10(bụng-cổ)+0.15456×log10(chiều cao))-450
• Nữ: tương tự nhưng tính thêm vòng hông

Mục tiêu % body fat:
• Nam: Athletic 6-13%, Fitness 14-17%, Healthy 18-24%
• Nữ: Athletic 14-20%, Fitness 21-24%, Healthy 25-31%
''',
    ),
  ];

  /// Lấy tất cả chunks theo topic
  static List<FitnessChunk> byTopic(String topic) =>
      chunks.where((c) => c.topic == topic).toList();

  /// Tìm kiếm theo keyword overlap
  static List<(FitnessChunk, double)> search(
    String query, {
    List<String> preferTopics = const [],
  }) {
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'[\s,.\-!?]+'))
        .where((w) => w.length > 1)
        .toSet();

    final scored = <(FitnessChunk, double)>[];
    for (final chunk in chunks) {
      final keywordSet = chunk.keywords.toSet();
      final overlap = queryWords
          .where((w) => keywordSet.any((k) => k.contains(w) || w.contains(k)))
          .length;
      if (overlap == 0) continue;

      double score = overlap / (keywordSet.length + queryWords.length - overlap);
      if (preferTopics.contains(chunk.topic)) score *= 1.5;
      scored.add((chunk, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored;
  }
}
