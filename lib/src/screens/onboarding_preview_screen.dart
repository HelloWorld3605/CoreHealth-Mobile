import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/visuals.dart';

class OnboardingPreviewScreen extends StatelessWidget {
  const OnboardingPreviewScreen({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Báo cáo phân tích AI',
            style: TextStyle(fontWeight: FontWeight.w800)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.emeraldSoft.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppPalette.emeraldDeep,
                    child: Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kế hoạch của bạn đã sẵn sàng!',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppPalette.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AI đã tổng hợp dữ liệu khảo sát và thiết lập lộ trình tối ưu nhất.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppPalette.mutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Targets Widget
            const SectionHeading(title: 'Chỉ tiêu hằng ngày'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ngân sách Calo',
                            style: TextStyle(
                                color: AppPalette.mutedText, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          '1.850 kcal',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.orange),
                        ),
                        const SizedBox(height: 2),
                        const Text('Mức thâm hụt giảm mỡ',
                            style: TextStyle(
                                fontSize: 10, color: AppPalette.mutedText)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lượng Protein',
                            style: TextStyle(
                                color: AppPalette.mutedText, fontSize: 11)),
                        const SizedBox(height: 6),
                        Text(
                          '110 gram',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.blue),
                        ),
                        const SizedBox(height: 2),
                        const Text('Duy trì khối lượng cơ',
                            style: TextStyle(
                                fontSize: 10, color: AppPalette.mutedText)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Weight Forecast Chart
            const SectionHeading(title: 'Dự báo tiến độ cân nặng'),
            const SizedBox(height: 4),
            Text(
              'Nếu duy trì sự kiên định tối thiểu 80%, lộ trình của bạn:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tuần 1',
                              style: TextStyle(
                                  fontSize: 10, color: AppPalette.mutedText)),
                          Text('65,0 kg',
                              style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Giảm ~2,4 kg',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppPalette.emeraldDeep,
                                fontSize: 12),
                          ),
                          const Icon(Icons.trending_down_rounded,
                              color: AppPalette.emeraldDeep, size: 18),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tuần 4',
                              style: TextStyle(
                                  fontSize: 10, color: AppPalette.mutedText)),
                          Text('62,6 kg',
                              style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Draw an illustrative projection chart.
                  SizedBox(
                    height: 100,
                    child: SparklineChart(
                      values: const [65.0, 64.3, 63.8, 63.2, 62.6],
                      strokeColor: AppPalette.emeraldDeep,
                      fillColor: AppPalette.emerald,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline Preview
            const SectionHeading(title: 'Lịch trình tuần đầu tiên'),
            const SizedBox(height: 10),
            _TimelineDayRow(
                day: 'Thứ 2',
                focus: 'Tập ngực & tay sau • Bữa ăn cơ bản',
                color: AppPalette.blue),
            _TimelineDayRow(
                day: 'Thứ 3',
                focus: 'Active Recovery • Bữa ăn nhẹ calo',
                color: AppPalette.emeraldDeep),
            _TimelineDayRow(
                day: 'Thứ 4',
                focus: 'Tập lưng & tay trước • Bữa ăn nhiều protein',
                color: AppPalette.blue),
            _TimelineDayRow(
                day: 'Thứ 5',
                focus: 'Active Recovery • Lối sống thiền định',
                color: AppPalette.emeraldDeep),
            _TimelineDayRow(
                day: 'Thứ 6',
                focus: 'Tập chân & mông đùi • Bữa ăn cơ bản',
                color: AppPalette.blue),
            const SizedBox(height: 32),

            // Confirm Action
            GradientActionButton(
              label: 'Kích hoạt kế hoạch & Bắt đầu',
              onPressed: onStart,
              colors: const [AppPalette.emerald, AppPalette.emeraldDeep],
            )
          ],
        ),
      ),
    );
  }
}

class _TimelineDayRow extends StatelessWidget {
  const _TimelineDayRow(
      {required this.day, required this.focus, required this.color});
  final String day;
  final String focus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppPalette.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.border),
              ),
              child: Text(
                focus,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
