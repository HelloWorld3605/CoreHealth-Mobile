import 'package:flutter/material.dart';

/// Loading screen shown while the backend generates the user's AI plan
/// (AppStage.generatingPlan).
class PlanGeneratingScreen extends StatelessWidget {
  const PlanGeneratingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Đang tạo kế hoạch cho bạn...',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'CoreHealth AI đang cá nhân hoá thực đơn và lịch tập.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
