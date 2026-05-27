import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';

class HealthHistoryScreen extends StatelessWidget {
  const HealthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final profile = controller.profile;
    final layout = PhoneLayout.of(context);
    final startWeight = controller.weightHistory.first.weight;
    final delta = startWeight - profile.weightKg;
    final targetGap = (profile.weightKg - profile.targetWeightKg).abs();

    return Scaffold(
      appBar: const CoreHealthSubPageAppBar(title: 'Lịch sử sức khỏe'),
      body: AdaptiveContent(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            layout.horizontalPadding,
            8,
            layout.horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(layout.isCompact ? 18 : 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theo dõi tiến độ theo ngày',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dữ liệu được lưu cục bộ trên thiết bị để bạn mở lại vẫn giữ nguyên hành trình.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HistoryBadge(
                          label: 'Hiện tại',
                          value: '${profile.weightKg.toStringAsFixed(1)} kg',
                        ),
                        _HistoryBadge(
                          label: 'Đã thay đổi',
                          value:
                              '${delta >= 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)} kg',
                        ),
                        _HistoryBadge(
                          label: 'Còn tới mục tiêu',
                          value: '${targetGap.toStringAsFixed(1)} kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeading(
                      title: 'Biểu đồ cân nặng',
                      icon: Icon(
                        Icons.show_chart_rounded,
                        color: AppPalette.emerald,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: layout.isCompact ? 180 : 210,
                      child: SparklineChart(
                        values: controller.weightHistory
                            .map((item) => item.weight)
                            .toList(),
                        strokeColor: AppPalette.emerald,
                        fillColor: AppPalette.emerald,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: controller.weightHistory
                          .map(
                            (entry) => _WeightLogChip(
                              label: entry.label,
                              value: '${entry.weight.toStringAsFixed(1)} kg',
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeading(
                title: 'Tóm tắt thể trạng',
                icon: Icon(
                  Icons.monitor_heart_outlined,
                  color: AppPalette.violet,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: layout.isCompact ? double.infinity : 200,
                    child: _StatCard(
                      label: 'BMI',
                      value: profile.bmi.toStringAsFixed(1),
                      subtitle: 'Theo chỉ số hiện tại',
                      accent: AppPalette.violet,
                    ),
                  ),
                  SizedBox(
                    width: layout.isCompact ? double.infinity : 200,
                    child: _StatCard(
                      label: 'Streak',
                      value: '${controller.streakCount} ngày',
                      subtitle: 'Buổi tập đã hoàn thành',
                      accent: AppPalette.orange,
                    ),
                  ),
                  SizedBox(
                    width: layout.isCompact ? double.infinity : 200,
                    child: _StatCard(
                      label: 'Kế hoạch',
                      value: '${controller.totalPlanDays} ngày',
                      subtitle: profile.plan.title,
                      accent: AppPalette.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryBadge extends StatelessWidget {
  const _HistoryBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeightLogChip extends StatelessWidget {
  const _WeightLogChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
