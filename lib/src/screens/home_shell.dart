import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../demo_data.dart';
import '../models.dart';
import '../widgets/adaptive.dart';
import '../theme.dart';
import '../widgets/visuals.dart';
import 'ai_chat_screen.dart';
import 'cart_screen.dart';
import 'edit_profile_screen.dart';
import 'food_scan_sheet.dart';
import 'payment_screen.dart';
import 'health_history_screen.dart';
import 'exercise_library_screen.dart';
import 'recipes_screen.dart';
import 'habits_screen.dart';
import 'favorites_screen.dart';
import 'challenges_screen.dart';
import 'leaderboard_screen.dart';
import 'workout_player_screen.dart';
import 'orders_screen.dart';
import 'settings_screen.dart';
import 'schedule_screen.dart';
import 'token_history_screen.dart';

void _showFoodScanSheet(BuildContext context,
    {bool triggerCameraDirectly = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FoodScanSheet(triggerCameraDirectly: triggerCameraDirectly),
  );
}

void _openAiChatPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AiChatScreen()),
  );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  bool _offerScheduled = false;

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
        final items = [
          (
            icon: Icons.fitness_center_rounded,
            label: 'Bài tập',
            iconColor: AppPalette.blue,
            bgColor: AppPalette.blueSoft,
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ExerciseLibraryScreen()),
              );
            }
          ),
          (
            icon: Icons.restaurant_rounded,
            label: 'Công thức',
            iconColor: AppPalette.orange,
            bgColor: const Color(0xFFFFF6EE),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const RecipesScreen()),
              );
            }
          ),
          (
            icon: Icons.check_circle_rounded,
            label: 'Thói quen',
            iconColor: AppPalette.emeraldDeep,
            bgColor: AppPalette.emeraldSoft,
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HabitsScreen()),
              );
            }
          ),
          (
            icon: Icons.favorite_rounded,
            label: 'Yêu thích',
            iconColor: Colors.pinkAccent,
            bgColor: const Color(0xFFFFF0F5),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const FavoritesScreen()),
              );
            }
          ),
          (
            icon: Icons.emoji_events_rounded,
            label: 'Thử thách',
            iconColor: Colors.amber,
            bgColor: const Color(0xFFFFFDE7),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const ChallengesScreen()),
              );
            }
          ),
          (
            icon: Icons.leaderboard_rounded,
            label: 'Xếp hạng',
            iconColor: Colors.purpleAccent,
            bgColor: const Color(0xFFFAE6FF),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => const LeaderboardScreen()),
              );
            }
          ),
          (
            icon: Icons.receipt_long_rounded,
            label: 'Đơn hàng',
            iconColor: Colors.blueGrey,
            bgColor: const Color(0xFFECEFF1),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
              );
            }
          ),
          (
            icon: Icons.calendar_month_rounded,
            label: 'Lịch biểu',
            iconColor: Colors.deepOrange,
            bgColor: const Color(0xFFFBE9E7),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ScheduleScreen()),
              );
            }
          ),
          (
            icon: Icons.settings_rounded,
            label: 'Cài đặt',
            iconColor: Colors.grey,
            bgColor: const Color(0xFFF5F5F5),
            onTap: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            }
          ),
        ];

        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE2EA),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Xem thêm chức năng',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        return _GridMenuItem(
                          icon: item.icon,
                          label: item.label,
                          iconColor: item.iconColor,
                          bgColor: item.bgColor,
                          onTap: item.onTap,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    if (controller.showPostOnboardingOffer && !_offerScheduled) {
      _offerScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPostOnboardingOffer(context);
      });
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          IndexedStack(
            index: controller.currentTab.clamp(0, 4),
            children: const [
              _LegacyDashboardScreen(),
              MealPlanScreen(),
              WorkoutPlanScreen(),
              ShopScreen(),
              ProfileScreen(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CoreHealthBottomNav(
              currentIndex: controller.currentTab.clamp(0, 4),
              onTap: controller.selectTab,
              onCoachTap: () => _openAiChatPage(context),
              onMoreTap: () => _showMoreMenu(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPostOnboardingOffer(BuildContext context) async {
    final controller = CoreHealthScope.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PostOnboardingOfferSheet(
          onClose: () {
            final controller = CoreHealthScope.of(context);
            final navigator = Navigator.of(sheetContext);
            final messenger = ScaffoldMessenger.of(context);
            unawaited(controller.claimCoreHealthMaxTrial());
            navigator.pop();
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Bạn đã nhận 25 token miễn phí để dùng thử AI.',
                ),
              ),
            );
          },
          onPayment: (pack) {
            final navigator = Navigator.of(sheetContext);
            final messenger = ScaffoldMessenger.of(context);
            navigator.pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PaymentScreen(
                  amountK: pack.priceK,
                  description:
                      '${pack.title} token pack - ${pack.tokens} token',
                  onSuccess: () {
                    controller.activateTokenPack(pack);
                    Navigator.of(context).pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã nạp ${pack.tokens} token vào ví CoreHealth.',
                        ),
                      ),
                    );
                  },
                  onTimeout: () {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Chưa nhận được thanh toán. Token miễn phí vẫn ở trong ví của bạn.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() => _offerScheduled = false);
      controller.dismissPostOnboardingOffer();
    }
  }
}

class _PostOnboardingOfferSheet extends StatefulWidget {
  const _PostOnboardingOfferSheet({
    required this.onClose,
    required this.onPayment,
  });

  final VoidCallback onClose;
  final void Function(TokenPack pack) onPayment;

  @override
  State<_PostOnboardingOfferSheet> createState() =>
      _PostOnboardingOfferSheetState();
}

class _PostOnboardingOfferSheetState extends State<_PostOnboardingOfferSheet> {
  TokenPack _selectedPack =
      tokenPacks.firstWhere((pack) => pack.id == TokenPackId.basic);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Material(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'NHẬN KẾ HOẠCH\nCÁ NHÂN CỦA BẠN',
                        style: tt.headlineLarge?.copyWith(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Đóng',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
                  decoration: BoxDecoration(
                    color: AppPalette.emeraldSoft,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppPalette.emerald.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppPalette.emerald, Color(0xFF18C290)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.emerald.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Token Wallet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.titleLarge?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppPalette.emerald
                                          .withValues(alpha: 0.24),
                                    ),
                                  ),
                                  child: Text(
                                    '25 token miễn phí',
                                    style: tt.labelSmall?.copyWith(
                                      color: AppPalette.emeraldDeep,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Một ví token dùng chung cho AI chat, scan món ăn, meal plan, workout plan và Smart Rebalance.',
                              style: tt.bodyMedium?.copyWith(
                                color: AppPalette.emeraldDeep
                                    .withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppPalette.borderLight),
                  ),
                  child: Column(
                    children: [
                      ...tokenPacks.take(4).map(
                            (pack) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _OfferPlanRow(
                                title: pack.title,
                                price: '${pack.priceK}k',
                                detail:
                                    '${pack.tokens} token • ~${pack.pricePerToken}đ/token',
                                selected: _selectedPack.id == pack.id,
                                badge: pack.recommended ? 'Phổ biến' : null,
                                onTap: () => setState(
                                  () => _selectedPack = pack,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF404040), Color(0xFF040404)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: AppPalette.shadowHeavy,
                          blurRadius: 18,
                          offset: Offset(0, 9),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => widget.onPayment(
                        _selectedPack,
                      ),
                      icon: const Icon(Icons.payment_rounded),
                      label: Text('Nạp ${_selectedPack.tokens} token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        textStyle: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppPalette.emeraldSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppPalette.emerald.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppPalette.emeraldDeep,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tracking cơ bản miễn phí. Chỉ AI action mới trừ token và luôn hiển thị chi phí trước khi dùng.',
                          style: tt.titleSmall?.copyWith(
                            color: AppPalette.emeraldDeep,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferPlanRow extends StatelessWidget {
  const _OfferPlanRow({
    required this.title,
    required this.price,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String detail;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppPalette.emeraldSoft : AppPalette.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppPalette.emerald : AppPalette.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: tt.titleMedium?.copyWith(
                          color: selected
                              ? AppPalette.emeraldDeep
                              : AppPalette.text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppPalette.emerald,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            style: tt.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    style: tt.bodyMedium?.copyWith(
                      color: AppPalette.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 82),
              child: Text(
                price,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(
                  color: selected ? AppPalette.emeraldDeep : AppPalette.text,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: selected ? AppPalette.emerald : AppPalette.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppPalette.emerald : AppPalette.borderLight,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 17)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridMenuItem extends StatelessWidget {
  const _GridMenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppPalette.text,
                ),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final profile = controller.profile;
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);
    final horizontalPadding = layout.horizontalPadding;
    final weekDates = _dashboardWeekDates(DateTime.now());
    final weeklyDays = math.min(controller.streakCount, 7);
    final weeklyProgress = weeklyDays / 7;
    final todayCalories =
        controller.todayMeals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final primaryInsight = controller.insights.isNotEmpty
        ? controller.insights.first
        : const InsightItem(
            title: 'Đi đúng hướng',
            message:
                'Giữ nhịp bữa ăn và vận động như hôm nay để tiến trình tiếp tục ổn định.',
            accent: 'success',
          );
    final bottomPad =
        layout.navBarHeight + MediaQuery.of(context).padding.bottom + 42;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: AdaptiveContent(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topInset + 14,
            horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeaderBar(
                profile: profile,
                onCalendarTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HealthHistoryScreen(),
                    ),
                  );
                },
                onNotificationTap: () => _openAiChatPage(context),
              ),
              const SizedBox(height: 22),
              _DashboardWeeklyCard(
                planTitle: '${profile.tokenBalance} token',
                title: 'Tiến trình tuần này',
                subtitle:
                    'Giữ nhịp ${profile.goal.title.toLowerCase()} thật đều để kết quả đến tự nhiên.',
                days: weeklyDays,
                progress: weeklyProgress,
              ),
              const SizedBox(height: 18),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: layout.isCompact ? 0.94 : 1.0,
                children: [
                  MetricTile(
                    label: 'Cân nặng',
                    value: _formatKg(profile.weightKg),
                    icon: Icons.monitor_weight_outlined,
                    colors: const [AppPalette.emeraldDeep],
                    caption: 'Mục tiêu ${_formatKg(profile.targetWeightKg)}',
                  ),
                  MetricTile(
                    label: 'Calo hôm nay',
                    value: '$todayCalories',
                    icon: Icons.local_fire_department_rounded,
                    colors: const [AppPalette.orange],
                    caption: 'Mục tiêu 1600 kcal',
                  ),
                  MetricTile(
                    label: 'BMI',
                    value: _formatDecimal(profile.bmi),
                    icon: Icons.favorite_outline_rounded,
                    colors: const [AppPalette.blue],
                    caption: profile.bmiCategory,
                    onTap: () => showBmiDetailSheet(context, profile),
                  ),
                  MetricTile(
                    label: 'Streak',
                    value: '${controller.streakCount} ngày',
                    icon: Icons.workspace_premium_outlined,
                    colors: const [AppPalette.violet],
                    caption: 'Duy trì thói quen mỗi ngày',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DashboardInsightPeek(
                insight: primaryInsight,
                loading: controller.insightsLoading,
                onOpenCoach: () => _openAiChatPage(context),
              ),
              const SizedBox(height: 18),
              _DashboardCalendarCard(
                monthLabel: _dashboardMonthLabel(weekDates.first),
                dates: weekDates,
              ),
              const SizedBox(height: 18),
              Text(
                'Bữa ăn hôm nay',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              ...controller.todayMeals.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _DashboardMealCard(
                    meal: meal,
                    onAddTap: () => controller.selectTab(1),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: _DashboardMiniAction(
                        icon: Icons.restaurant_menu_rounded,
                        title: 'Meal plan',
                        subtitle: 'Xem thực đơn',
                        color: AppPalette.orange,
                        background: AppPalette.orangeSoft,
                        onTap: () => controller.selectTab(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DashboardMiniAction(
                        icon: Icons.fitness_center_rounded,
                        title: 'Workout',
                        subtitle: 'Lịch tập hôm nay',
                        color: AppPalette.blue,
                        background: AppPalette.blueSoft,
                        onTap: () => controller.selectTab(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DashboardMiniAction(
                        icon: Icons.local_mall_outlined,
                        title: 'Shop',
                        subtitle: 'Mua nhanh',
                        color: AppPalette.emeraldDeep,
                        background: AppPalette.mint,
                        onTap: () => controller.selectTab(3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<DateTime> _dashboardWeekDates(DateTime now) {
  final start = now.subtract(Duration(days: now.weekday - 1));
  return List.generate(
    7,
    (index) => DateTime(start.year, start.month, start.day + index),
  );
}

String _dashboardGreeting(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning!';
  if (hour < 18) return 'Good afternoon!';
  return 'Good evening!';
}

String _dashboardMonthLabel(DateTime date) {
  const months = [
    'Tháng 1',
    'Tháng 2',
    'Tháng 3',
    'Tháng 4',
    'Tháng 5',
    'Tháng 6',
    'Tháng 7',
    'Tháng 8',
    'Tháng 9',
    'Tháng 10',
    'Tháng 11',
    'Tháng 12',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _dashboardDayLabel(DateTime date) {
  const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return labels[date.weekday - 1];
}

class _DashboardHeaderBar extends StatelessWidget {
  const _DashboardHeaderBar({
    required this.profile,
    required this.onCalendarTap,
    required this.onNotificationTap,
  });

  final DemoProfile profile;
  final VoidCallback onCalendarTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.trim().isEmpty ? 'C' : profile.name.trim()[0];
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppPalette.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.border),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initial.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dashboardGreeting(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        _DashboardRoundButton(
          icon: Icons.calendar_month_rounded,
          onTap: onCalendarTap,
        ),
        const SizedBox(width: 8),
        _DashboardRoundButton(
          icon: Icons.notifications_none_rounded,
          showBadge: true,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}

class _DashboardRoundButton extends StatelessWidget {
  const _DashboardRoundButton({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppPalette.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.border),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(icon, size: 20, color: AppPalette.text),
            ),
            if (showBadge)
              Positioned(
                top: 11,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppPalette.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppPalette.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardWeeklyCard extends StatelessWidget {
  const _DashboardWeeklyCard({
    required this.planTitle,
    required this.title,
    required this.subtitle,
    required this.days,
    required this.progress,
  });

  final String planTitle;
  final String title;
  final String subtitle;
  final int days;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPalette.accentSoft,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -10,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            left: 120,
            bottom: -42,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 14, color: AppPalette.text),
                          const SizedBox(width: 6),
                          Text(
                            planTitle,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppPalette.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPalette.text.withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 92,
                      height: 92,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppPalette.emeraldDeep,
                        ),
                        backgroundColor: AppPalette.accentMuted,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$days',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        Text(
                          'days',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppPalette.text.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardInsightPeek extends StatelessWidget {
  const _DashboardInsightPeek({
    required this.insight,
    required this.loading,
    required this.onOpenCoach,
  });

  final InsightItem insight;
  final bool loading;
  final VoidCallback onOpenCoach;

  @override
  Widget build(BuildContext context) {
    final config = switch (insight.accent) {
      'violet' => (
          AppPalette.violet,
          AppPalette.violetSoft,
          Icons.auto_awesome_rounded
        ),
      'success' => (
          AppPalette.emeraldDeep,
          AppPalette.mint,
          Icons.trending_up_rounded
        ),
      _ => (AppPalette.emeraldDeep, AppPalette.mint, Icons.insights_rounded),
    };

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: config.$2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(config.$3, color: config.$1),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loading ? 'AI đang chuẩn bị gợi ý' : insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading
                      ? 'CoreHealth đang đọc tiến trình gần nhất của bạn.'
                      : insight.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onOpenCoach,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppPalette.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_outward_rounded,
                color: AppPalette.text,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCalendarCard extends StatelessWidget {
  const _DashboardCalendarCard({
    required this.monthLabel,
    required this.dates,
  });

  final String monthLabel;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const _DashboardCalendarArrow(icon: Icons.chevron_left_rounded),
              const SizedBox(width: 8),
              const _DashboardCalendarArrow(icon: Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dates.map((date) {
              final active = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      _dashboardDayLabel(date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            active ? AppPalette.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        date.day.toString().padLeft(2, '0'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPalette.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DashboardCalendarArrow extends StatelessWidget {
  const _DashboardCalendarArrow({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: AppPalette.surfaceElevated,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppPalette.mutedText),
    );
  }
}

class _DashboardMealCard extends StatelessWidget {
  const _DashboardMealCard({
    required this.meal,
    required this.onAddTap,
  });

  final MealItem meal;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.slotLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  meal.nameVi,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppPalette.orangeSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: AppPalette.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${meal.calories} kcal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: AppPalette.surfaceElevated,
                backgroundImage: NetworkImage(meal.imageUrl),
              ),
              Transform.translate(
                offset: const Offset(-10, 0),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppPalette.accentSoft,
                  child: Text(
                    '+${meal.ingredients.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(-10, 0),
                child: InkWell(
                  onTap: onAddTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppPalette.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppPalette.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardMiniAction extends StatelessWidget {
  const _DashboardMiniAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _LegacyDashboardScreen extends StatelessWidget {
  // ignore: unused_element_parameter
  const _LegacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final profile = controller.profile;
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);
    final isCompact = layout.isCompact;
    final horizontalPadding = layout.horizontalPadding;
    final startWeight = controller.weightHistory.first.weight;
    final progressDenominator =
        (startWeight - profile.targetWeightKg).abs().clamp(1.0, 100.0);
    final progress =
        ((startWeight - profile.weightKg).abs() / progressDenominator)
            .clamp(0.0, 1.0);
    final todayCalories =
        controller.todayMeals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final bmiStatus = profile.bmiCategory;
    final earnedBadgeCount = _dashboardStreakBadges
        .where((badge) => controller.streakCount >= badge.days)
        .length;
    _DashboardStreakBadge? nextBadge;
    for (final badge in _dashboardStreakBadges) {
      if (controller.streakCount < badge.days) {
        nextBadge = badge;
        break;
      }
    }
    final previousMilestone = _dashboardStreakBadges
        .where((badge) => badge.days <= controller.streakCount)
        .fold<int>(0, (max, badge) => badge.days > max ? badge.days : max);
    final streakProgress = nextBadge == null
        ? 1.0
        : ((controller.streakCount - previousMilestone) /
                (nextBadge.days - previousMilestone))
            .clamp(0.0, 1.0);

    final metricCardHeight = isCompact ? 174.0 : 184.0;
    final metricColumns = layout.columnsFor(
      minCardWidth: isCompact ? 300 : 160,
      maxColumns: 2,
    );
    final bottomPad =
        layout.navBarHeight + MediaQuery.of(context).padding.bottom + 16;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: AdaptiveContent(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topInset + 14,
                horizontalPadding,
                26,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -70,
                    top: 40,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -54,
                    top: -12,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _DashboardPlanPill(
                              label: '${profile.tokenBalance} token'),
                          const Spacer(),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? 250 : 290,
                        ),
                        child: Text(
                          'Chào ${profile.name}!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đừng nản lòng ${profile.name}. Sự thay đổi sẽ đến, hãy kiên trì! ${profile.goal == GoalType.loseWeight ? '🍀' : '💪'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.45,
                            ),
                      ),
                      const SizedBox(height: 18),
                      const _DashboardUpgradeBanner(
                        actionLabel: 'Nạp token',
                        description:
                            'Token dùng chung cho AI chat, food scan, meal plan, workout plan và Smart Rebalance.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 18, horizontalPadding, 0),
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: metricColumns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: metricCardHeight,
                ),
                children: [
                  MetricTile(
                    label: 'Cân nặng',
                    value: _formatKg(profile.weightKg),
                    icon: Icons.track_changes_rounded,
                    colors: const [AppPalette.blue, Color(0xFF71A4FF)],
                    caption: 'Mục tiêu ${_formatKg(profile.targetWeightKg)}',
                  ),
                  MetricTile(
                    label: 'BMI',
                    value: _formatDecimal(profile.bmi),
                    icon: Icons.monitor_heart_outlined,
                    colors: const [AppPalette.violet, Color(0xFFC57EFF)],
                    caption: bmiStatus,
                    onTap: () => showBmiDetailSheet(context, profile),
                  ),
                  MetricTile(
                    label: 'Calo hôm nay',
                    value: '$todayCalories',
                    icon: Icons.local_fire_department_rounded,
                    colors: const [AppPalette.orange, Color(0xFFFFB45D)],
                    caption: 'Mục tiêu 1600',
                  ),
                  MetricTile(
                    label: 'Streak',
                    value: '${controller.streakCount} ngày',
                    icon: Icons.workspace_premium_outlined,
                    colors: const [AppPalette.emerald, Color(0xFF29D38E)],
                    caption: nextBadge == null
                        ? 'Đã mở khóa tất cả badge'
                        : 'Còn ${nextBadge.days - controller.streakCount} ngày',
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  _DashboardStreakCard(
                    streakCount: controller.streakCount,
                    earnedBadgeCount: earnedBadgeCount,
                    nextBadge: nextBadge,
                    streakProgress: streakProgress,
                  ),
                  const SizedBox(height: 18),
                  SectionHeading(
                    title: 'Phân tích AI',
                    icon: const Icon(Icons.auto_awesome_rounded,
                        color: AppPalette.violet),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppPalette.violetSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        controller.insightsLoading
                            ? 'Đang tải...'
                            : '${controller.insights.length} gợi ý',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.violet,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  RepaintBoundary(
                    child: controller.insightsLoading
                        ? const _InsightSkeletonList()
                        : Column(
                            children: controller.insights
                                .map(
                                  (insight) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _InsightCard(insight: insight),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeading(
                          title: 'Tiến độ cân nặng',
                          icon: const Icon(Icons.show_chart_rounded,
                              color: AppPalette.emerald),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppPalette.emeraldSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: AppPalette.surfaceElevated,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppPalette.emerald),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 160,
                          child: SparklineChart(
                            values: controller.weightHistory
                                .map((item) => item.weight)
                                .toList(),
                            strokeColor: AppPalette.emerald,
                            fillColor: AppPalette.emerald,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: controller.weightHistory
                              .map(
                                (item) => Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeading(
                    title: 'Hành động nhanh',
                    icon:
                        Icon(Icons.flash_on_rounded, color: AppPalette.orange),
                  ),
                  const SizedBox(height: 14),
                  if (layout.isCompact)
                    Column(
                      children: [
                        GradientActionButton(
                          label: 'Ghi bữa ăn',
                          onPressed: () => _showFoodScanSheet(context),
                          colors: const [AppPalette.orange, Color(0xFFFFB15F)],
                          icon: const Icon(Icons.restaurant_menu_rounded),
                          height: 72,
                        ),
                        const SizedBox(height: 12),
                        GradientActionButton(
                          label: 'Tập hôm nay',
                          onPressed: () => controller.selectTab(2),
                          colors: const [AppPalette.blue, Color(0xFF67A1FF)],
                          icon: const Icon(Icons.fitness_center_rounded),
                          height: 72,
                        ),
                        const SizedBox(height: 12),
                        GradientActionButton(
                          label: 'Chat với AI',
                          onPressed: () => _openAiChatPage(context),
                          colors: const [
                            AppPalette.emerald,
                            AppPalette.emeraldDeep
                          ],
                          icon: const Icon(Icons.smart_toy_rounded),
                          height: 72,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: GradientActionButton(
                            label: 'Ghi bữa ăn',
                            onPressed: () => _showFoodScanSheet(context),
                            colors: const [
                              AppPalette.orange,
                              Color(0xFFFFB15F)
                            ],
                            icon: const Icon(Icons.restaurant_menu_rounded),
                            height: 72,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientActionButton(
                            label: 'Tập hôm nay',
                            onPressed: () => controller.selectTab(2),
                            colors: const [AppPalette.blue, Color(0xFF67A1FF)],
                            icon: const Icon(Icons.fitness_center_rounded),
                            height: 72,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GradientActionButton(
                            label: 'Chat với AI',
                            onPressed: () => _openAiChatPage(context),
                            colors: const [
                              AppPalette.emerald,
                              AppPalette.emeraldDeep
                            ],
                            icon: const Icon(Icons.smart_toy_rounded),
                            height: 72,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  const SectionHeading(
                    title: 'Bữa ăn hôm nay',
                    icon: Icon(Icons.soup_kitchen_rounded,
                        color: AppPalette.orange),
                  ),
                  const SizedBox(height: 14),
                  _TodayMealsSummary(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardPlanPill extends StatelessWidget {
  const _DashboardPlanPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardUpgradeBanner extends StatelessWidget {
  const _DashboardUpgradeBanner({
    required this.actionLabel,
    required this.description,
  });

  final String actionLabel;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB400),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionLabel == 'Nạp token'
                      ? 'Ví token CoreHealth'
                      : 'Quyền lợi hiện tại',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              actionLabel == 'Nạp token'
                  ? Icons.toll_rounded
                  : Icons.arrow_outward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStreakCard extends StatelessWidget {
  const _DashboardStreakCard({
    required this.streakCount,
    required this.earnedBadgeCount,
    required this.nextBadge,
    required this.streakProgress,
  });

  final int streakCount;
  final int earnedBadgeCount;
  final _DashboardStreakBadge? nextBadge;
  final double streakProgress;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: 'Streak & badge',
            icon: const Icon(
              Icons.local_fire_department_rounded,
              color: AppPalette.orange,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppPalette.orangeSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$earnedBadgeCount/${_dashboardStreakBadges.length} badge',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.orange,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streakCount ngày liên tiếp',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nextBadge == null
                          ? 'Bạn đã mở khóa toàn bộ badge streak.'
                          : 'Còn ${nextBadge!.days - streakCount} ngày để mở khóa ${nextBadge!.title}.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppPalette.orangeSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppPalette.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: streakProgress,
              minHeight: 10,
              backgroundColor: AppPalette.surfaceElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppPalette.orange),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _dashboardStreakBadges
                .map(
                  (badge) => _DashboardBadgeChip(
                    badge: badge,
                    earned: streakCount >= badge.days,
                    upcoming: nextBadge?.days == badge.days,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DashboardBadgeChip extends StatelessWidget {
  const _DashboardBadgeChip({
    required this.badge,
    required this.earned,
    required this.upcoming,
  });

  final _DashboardStreakBadge badge;
  final bool earned;
  final bool upcoming;

  @override
  Widget build(BuildContext context) {
    final fill = earned
        ? badge.softColor
        : upcoming
            ? AppPalette.surfaceElevated
            : AppPalette.surface;
    final borderColor = earned
        ? Colors.transparent
        : upcoming
            ? badge.color
            : AppPalette.border;
    final textColor = earned || upcoming ? badge.color : AppPalette.mutedText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: earned
                  ? badge.color
                  : badge.color.withValues(alpha: upcoming ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              badge.icon,
              size: 16,
              color: earned ? Colors.white : badge.color,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${badge.days} ngày',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStreakBadge {
  const _DashboardStreakBadge({
    required this.days,
    required this.title,
    required this.icon,
    required this.color,
    required this.softColor,
  });

  final int days;
  final String title;
  final IconData icon;
  final Color color;
  final Color softColor;
}

const _dashboardStreakBadges = [
  _DashboardStreakBadge(
    days: 3,
    title: 'Khởi động',
    icon: Icons.flash_on_rounded,
    color: AppPalette.orange,
    softColor: AppPalette.orangeSoft,
  ),
  _DashboardStreakBadge(
    days: 7,
    title: 'Giữ nhịp',
    icon: Icons.local_fire_department_rounded,
    color: AppPalette.emerald,
    softColor: AppPalette.emeraldSoft,
  ),
  _DashboardStreakBadge(
    days: 14,
    title: 'Bền bỉ',
    icon: Icons.workspace_premium_rounded,
    color: AppPalette.blue,
    softColor: AppPalette.blueSoft,
  ),
  _DashboardStreakBadge(
    days: 30,
    title: 'Huy hiệu vàng',
    icon: Icons.emoji_events_rounded,
    color: AppPalette.violet,
    softColor: AppPalette.violetSoft,
  ),
];

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final InsightItem insight;

  @override
  Widget build(BuildContext context) {
    final config = switch (insight.accent) {
      'success' => (
          AppPalette.emeraldSoft,
          AppPalette.emerald,
          Icons.trending_up_rounded
        ),
      'violet' => (
          AppPalette.violetSoft,
          AppPalette.violet,
          Icons.auto_awesome_rounded
        ),
      _ => (
          AppPalette.emeraldSoft,
          AppPalette.emeraldDeep,
          Icons.bar_chart_rounded
        ),
    };

    return AppCard(
      color: config.$1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(config.$3, color: config.$2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: config.$2,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.message,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightSkeletonList extends StatefulWidget {
  const _InsightSkeletonList();

  @override
  State<_InsightSkeletonList> createState() => _InsightSkeletonListState();
}

class _InsightSkeletonListState extends State<_InsightSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final opacity = 0.4 + 0.3 * _anim.value;
        return Column(
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: opacity,
                child: AppCard(
                  color: AppPalette.surfaceElevated,
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppPalette.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppPalette.border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 10,
                              width: 180,
                              decoration: BoxDecoration(
                                color: AppPalette.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NutrientPill extends StatelessWidget {
  const _NutrientPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

// ---------------------------------------------------------------------------
// AI plan helpers
// ---------------------------------------------------------------------------

class _AiPlanLoadingView extends StatelessWidget {
  const _AiPlanLoadingView({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppPalette.emerald),
            const SizedBox(height: 24),
            Text(label,
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Dựa trên mục tiêu và thông tin cá nhân của bạn',
                style: tt.bodySmall?.copyWith(color: AppPalette.mutedText),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge({this.color = AppPalette.emerald});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text('AI',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  )),
        ],
      ),
    );
  }
}

class _FeatureLockedView extends StatelessWidget {
  const _FeatureLockedView({
    required this.title,
    required this.description,
    required this.requiredPlan,
    required this.benefits,
    required this.colors,
    required this.icon,
  });

  final String title;
  final String description;
  final String requiredPlan;
  final List<String> benefits;
  final List<Color> colors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(layout.horizontalPadding, topInset + 24,
          layout.horizontalPadding, 100),
      child: AdaptiveContent(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          color: AppPalette.mutedText, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cần $requiredPlan',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppPalette.mutedText,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI action dùng token cho:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...benefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: colors),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(b,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GradientActionButton(
                    label: 'Nạp token',
                    icon: const Icon(Icons.toll_rounded, size: 18),
                    onPressed: () => _showUpgradeSheet(context),
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen>
    with AutomaticKeepAliveClientMixin {
  int currentMonth = 0;
  int selectedDay = 0;
  bool _calendarExpanded = true;
  late final DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = CoreHealthScope.of(context);
      if (c.profile.hasMealPlan &&
          !c.hasMealAiPlan &&
          !c.isMealPlanGenerating) {
        c.generateAiMealPlan().then((success) {
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể tạo kế hoạch lúc này, vui lòng thử lại sau.')),
            );
          }
        });
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = CoreHealthScope.of(context);
    if (!controller.profile.hasMealPlan) {
      return const _FeatureLockedView(
        title: 'Meal Plan',
        description:
            'Kế hoạch bữa ăn cá nhân hóa theo mục tiêu và khẩu vị Việt Nam của bạn.',
        requiredPlan: '${TokenCosts.fullDayMealPlan} token',
        benefits: [
          'Thực đơn chi tiết từng bữa mỗi ngày',
          'Tính calo & macro tự động',
          'Gợi ý món Việt Nam phù hợp mục tiêu',
          'AI Meal Coach hỗ trợ 24/7',
        ],
        colors: [AppPalette.orange, Color(0xFFFFB15F)],
        icon: Icons.restaurant_menu_rounded,
      );
    }
    if (controller.isMealPlanGenerating && !controller.hasMealAiPlan) {
      return const _AiPlanLoadingView(
          label: 'AI đang tạo thực đơn cá nhân hóa...');
    }
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);
    final plan = controller.mealPlan;
    const totalMonths = 1;
    final monthStart = currentMonth * 30;
    final daysInMonth = math.min(30, plan.length - monthStart);
    final globalIndex = (monthStart + selectedDay).clamp(0, plan.length - 1);
    final selectedPlan = plan[globalIndex];
    final isCompleted = controller.isMealCompleted(selectedPlan.dayNumber);
    final selectedDate = _startDate.add(Duration(days: globalIndex));
    final selectedDateLabel = globalIndex == 0
        ? 'Hôm nay'
        : '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    final segmentStart = _startDate.add(Duration(days: monthStart));
    final isCompact = layout.isCompact;
    final horizontalPadding = layout.horizontalPadding;
    final calendarCardPadding = EdgeInsets.all(isCompact ? 14 : 18);
    final calendarSpacing = isCompact ? 6.0 : 10.0;
    final bottomPad =
        layout.navBarHeight + MediaQuery.of(context).padding.bottom + 16;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topInset + 16,
        horizontalPadding,
        bottomPad,
      ),
      child: AdaptiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text('Kế hoạch bữa ăn',
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                          ),
                          if (controller.hasMealAiPlan) ...[
                            const SizedBox(width: 8),
                            const _AiBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${controller.profile.tokenBalance} token • tạo lại tốn ${TokenCosts.fullDayMealPlan} token',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (controller.isMealPlanGenerating)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppPalette.orange),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Tạo lại bằng AI',
                    onPressed: () => () async {
                      final success = await controller.generateAiMealPlan();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể tạo kế hoạch lúc này, vui lòng thử lại sau.')),
                        );
                      }
                    }(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _showFoodScanSheet(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text(
                    'Chụp ảnh scan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: controller.isMealPlanGenerating
                      ? null
                      : () => () async {
                      final success = await controller.generateAiMealPlan();
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không thể tạo kế hoạch lúc này, vui lòng thử lại sau.')),
                        );
                      }
                    }(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    side: const BorderSide(color: AppPalette.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Tạo thực đơn AI'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (totalMonths > 1)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final active = currentMonth == index;
                    final tabDate = _startDate.add(Duration(days: index * 30));
                    return ChoiceChip(
                      selected: active,
                      label: Text(
                          'Th.${tabDate.month}/${tabDate.year.toString().substring(2)}'),
                      selectedColor: AppPalette.emerald,
                      backgroundColor: AppPalette.surfaceElevated,
                      labelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: active ? Colors.black : AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                      onSelected: (_) => setState(() {
                        currentMonth = index;
                        selectedDay = 0;
                      }),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: totalMonths,
                ),
              ),
            if (totalMonths > 1) const SizedBox(height: 18),
            AppCard(
              padding: calendarCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _calendarExpanded = !_calendarExpanded),
                    child: SectionHeading(
                      title: 'Tháng ${segmentStart.month}/${segmentStart.year}',
                      icon: const Icon(Icons.calendar_month_rounded,
                          color: AppPalette.emerald),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 10 : 12,
                              vertical: isCompact ? 6 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.emeraldSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$daysInMonth ngày',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 11 : null,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: _calendarExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(Icons.expand_more_rounded,
                                color: AppPalette.mutedText, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _calendarExpanded
                        ? Column(
                            children: [
                              const SizedBox(height: 18),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cellWidth = (constraints.maxWidth -
                                          (calendarSpacing * 6)) /
                                      7;
                                  final cellHeight = math.max(
                                    isCompact ? 52.0 : 58.0,
                                    math.min(
                                      isCompact ? 64.0 : 72.0,
                                      cellWidth * (isCompact ? 1.54 : 1.68),
                                    ),
                                  );
                                  final badgeSize = isCompact ? 16.0 : 18.0;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: calendarSpacing,
                                      crossAxisSpacing: calendarSpacing,
                                      mainAxisExtent: cellHeight,
                                    ),
                                    itemCount: daysInMonth,
                                    itemBuilder: (context, index) {
                                      final active = index == selectedDay;
                                      final day = plan[monthStart + index];
                                      final completed = controller
                                          .isMealCompleted(day.dayNumber);
                                      final cellDate = _startDate.add(
                                          Duration(days: monthStart + index));
                                      final isToday = monthStart + index == 0;
                                      const wdLabels = [
                                        'T2',
                                        'T3',
                                        'T4',
                                        'T5',
                                        'T6',
                                        'T7',
                                        'CN'
                                      ];
                                      final weekday =
                                          wdLabels[cellDate.weekday - 1];
                                      final showBadge = completed || active;
                                      final badgeIcon = completed
                                          ? Icons.check_rounded
                                          : Icons.restaurant_rounded;
                                      final badgeColor = active
                                          ? Colors.white
                                          : AppPalette.emeraldDeep;

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(
                                            isCompact ? 14 : 18),
                                        onTap: () =>
                                            setState(() => selectedDay = index),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 4 : 6,
                                            vertical: isCompact ? 6 : 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? AppPalette.emerald
                                                : isToday
                                                    ? AppPalette.emeraldSoft
                                                    : AppPalette
                                                        .surfaceElevated,
                                            borderRadius: BorderRadius.circular(
                                                isCompact ? 14 : 18),
                                            border: Border.all(
                                              color: active
                                                  ? Colors.transparent
                                                  : isToday
                                                      ? AppPalette.emerald
                                                      : AppPalette.border,
                                              width: isToday && !active
                                                  ? 1.5
                                                  : 1.0,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              if (showBadge)
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: badgeSize,
                                                    height: badgeSize,
                                                    decoration: BoxDecoration(
                                                      color: active
                                                          ? Colors.white
                                                              .withValues(
                                                                  alpha: 0.2)
                                                          : AppPalette
                                                              .emeraldSoft,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      badgeIcon,
                                                      size: isCompact ? 10 : 11,
                                                      color: badgeColor,
                                                    ),
                                                  ),
                                                ),
                                              Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      weekday,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: active
                                                                ? Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.82)
                                                                : isToday
                                                                    ? AppPalette
                                                                        .emeraldDeep
                                                                    : AppPalette
                                                                        .mutedText,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: isCompact
                                                                ? 10
                                                                : 11,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            isCompact ? 2 : 4),
                                                    Text(
                                                      '${cellDate.day}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            color: active
                                                                ? Colors.white
                                                                : isToday
                                                                    ? AppPalette
                                                                        .emeraldDeep
                                                                    : AppPalette
                                                                        .text,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: isCompact
                                                                ? 16
                                                                : 18,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.emerald, Color(0xFF18C290)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bản phân bổ calo trong ngày',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 26),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isCompact)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _WorkoutSummaryTile(
                                label: 'Calo',
                                value: '${selectedPlan.totalCalories}',
                                icon: Icons.local_fire_department_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _WorkoutSummaryTile(
                                label: 'Protein',
                                value: '${selectedPlan.totalProtein}g',
                                icon: Icons.fitness_center_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _WorkoutSummaryTile(
                                label: 'Carbs',
                                value: '${selectedPlan.totalCarbs}g',
                                icon: Icons.grain_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _WorkoutSummaryTile(
                                label: 'Fat',
                                value: '${selectedPlan.totalFat}g',
                                icon: Icons.opacity_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _WorkoutSummaryTile(
                            label: 'Calo',
                            value: '${selectedPlan.totalCalories}',
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WorkoutSummaryTile(
                            label: 'Protein',
                            value: '${selectedPlan.totalProtein}g',
                            icon: Icons.fitness_center_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WorkoutSummaryTile(
                            label: 'Carbs',
                            value: '${selectedPlan.totalCarbs}g',
                            icon: Icons.grain_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WorkoutSummaryTile(
                            label: 'Fat',
                            value: '${selectedPlan.totalFat}g',
                            icon: Icons.opacity_rounded,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (isCompact)
                    Column(
                      children: [
                        TextButton.icon(
                          onPressed: () => controller
                              .toggleMealCompleted(selectedPlan.dayNumber),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                          ),
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.restaurant_menu_rounded,
                          ),
                          label: Text(
                              isCompleted ? 'Đã hoàn thành' : 'Hoàn thành'),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => controller.selectTab(3),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                            ),
                            icon: const Icon(
                                Icons.shopping_cart_checkout_rounded),
                            label: const Text('Mua nguyên liệu'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => controller
                                .toggleMealCompleted(selectedPlan.dayNumber),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                            ),
                            icon: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.restaurant_menu_rounded,
                            ),
                            label: Text(
                                isCompleted ? 'Đã hoàn thành' : 'Hoàn thành'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => controller.selectTab(3),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                            ),
                            icon: const Icon(
                                Icons.shopping_cart_checkout_rounded),
                            label: const Text('Mua nguyên liệu'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeading(
              title: 'Thực đơn trong ngày',
              icon: Icon(Icons.menu_book_rounded, color: AppPalette.emerald),
            ),
            const SizedBox(height: 14),
            ...selectedPlan.meals.map(
              (meal) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MealCard(meal: meal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal});

  final MealItem meal;

  @override
  Widget build(BuildContext context) {
    final isCompact = PhoneLayout.of(context).isCompact;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RemoteImage(
                      url: meal.imageUrl,
                      height: 96,
                      width: 96,
                      radius: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        meal.nameVi,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${meal.calories}\ncal',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppPalette.emeraldDeep,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MealCardBody(meal: meal),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RemoteImage(
                  url: meal.imageUrl,
                  height: 104,
                  width: 104,
                  radius: 22,
                ),
                const SizedBox(width: 14),
                Expanded(child: _MealCardBody(meal: meal)),
                const SizedBox(width: 10),
                Text(
                  '${meal.calories}\ncal',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppPalette.emeraldDeep,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
    );
  }
}

class _MealCardBody extends StatelessWidget {
  const _MealCardBody({required this.meal});

  final MealItem meal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppPalette.emeraldSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            meal.slotLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.emeraldDeep,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          meal.nameVi,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _NutrientPill(label: 'P ${meal.protein}g'),
            _NutrientPill(label: 'C ${meal.carbs}g'),
            _NutrientPill(label: 'F ${meal.fat}g'),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: meal.ingredients
              .take(4)
              .map((item) => _NutrientPill(label: item))
              .toList(),
        ),
      ],
    );
  }
}

class WorkoutPlanScreen extends StatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  State<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen>
    with AutomaticKeepAliveClientMixin {
  int currentMonth = 0;
  int selectedDay = 0;
  bool _calendarExpanded = true;
  late final DateTime _startDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = CoreHealthScope.of(context);
      if (c.profile.hasWorkoutPlan &&
          !c.hasWorkoutAiPlan &&
          !c.isWorkoutPlanGenerating) {
        c.generateAiWorkoutPlan();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = CoreHealthScope.of(context);
    if (!controller.profile.hasWorkoutPlan) {
      return const _FeatureLockedView(
        title: 'Workout Plan',
        description:
            'Lịch tập luyện cá nhân hóa theo thể lực và mục tiêu của bạn.',
        requiredPlan: '${TokenCosts.adaptiveWeeklyPlan} token',
        benefits: [
          'Kế hoạch tập chi tiết từng ngày',
          'Bài tập phù hợp mọi cấp độ',
          'Tập tại nhà, gym hoặc ngoài trời',
          'AI Workout Coach theo dõi tiến trình',
        ],
        colors: [AppPalette.blue, Color(0xFF73A9FF)],
        icon: Icons.fitness_center_rounded,
      );
    }
    if (controller.isWorkoutPlanGenerating && !controller.hasWorkoutAiPlan) {
      return const _AiPlanLoadingView(
          label: 'AI đang tạo lịch tập cá nhân hóa...');
    }
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);
    final plan = controller.workoutPlan;
    const totalMonths = 1;
    final monthStart = currentMonth * 30;
    final daysInMonth = math.min(30, plan.length - monthStart);
    final globalIndex = (monthStart + selectedDay).clamp(0, plan.length - 1);
    final selectedPlan = plan[globalIndex];
    final isCompleted = controller.isWorkoutCompleted(selectedPlan.dayNumber);
    final selectedDate = _startDate.add(Duration(days: globalIndex));
    final selectedDateLabel = globalIndex == 0
        ? 'Hôm nay'
        : '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    final segmentStart = _startDate.add(Duration(days: monthStart));
    final isCompact = layout.isCompact;
    final horizontalPadding = layout.horizontalPadding;
    final calendarCardPadding = EdgeInsets.all(isCompact ? 14 : 18);
    final calendarSpacing = isCompact ? 6.0 : 10.0;
    final bottomPad =
        layout.navBarHeight + MediaQuery.of(context).padding.bottom + 16;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topInset + 16,
        horizontalPadding,
        bottomPad,
      ),
      child: AdaptiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text('Kế hoạch tập luyện',
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                          ),
                          if (controller.hasWorkoutAiPlan) ...[
                            const SizedBox(width: 8),
                            const _AiBadge(color: AppPalette.blue),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${controller.profile.tokenBalance} token • tạo lại tốn ${TokenCosts.adaptiveWeeklyPlan} token',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (controller.isWorkoutPlanGenerating)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppPalette.blue),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Tạo lại bằng AI',
                    onPressed: () => controller.generateAiWorkoutPlan(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lịch tập tối ưu từ AI cho hôm nay của bạn, kèm bài tập, thời lượng và calo ước tính.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: controller.isWorkoutPlanGenerating
                      ? null
                      : () => controller.generateAiWorkoutPlan(),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Tạo lịch tập AI'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (totalMonths > 1)
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final active = currentMonth == index;
                    final tabDate = _startDate.add(Duration(days: index * 30));
                    return ChoiceChip(
                      selected: active,
                      label: Text(
                          'Th.${tabDate.month}/${tabDate.year.toString().substring(2)}'),
                      selectedColor: AppPalette.blue,
                      backgroundColor: AppPalette.surfaceElevated,
                      labelStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: active ? Colors.white : AppPalette.text,
                                fontWeight: FontWeight.w800,
                              ),
                      onSelected: (_) => setState(() {
                        currentMonth = index;
                        selectedDay = 0;
                      }),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: totalMonths,
                ),
              ),
            if (totalMonths > 1) const SizedBox(height: 18),
            AppCard(
              padding: calendarCardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _calendarExpanded = !_calendarExpanded),
                    child: SectionHeading(
                      title: 'Tháng ${segmentStart.month}/${segmentStart.year}',
                      icon: const Icon(Icons.calendar_today_rounded,
                          color: AppPalette.blue),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 10 : 12,
                              vertical: isCompact ? 6 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppPalette.blueSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$daysInMonth ngày',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppPalette.blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: isCompact ? 11 : null,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedRotation(
                            turns: _calendarExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: const Icon(Icons.expand_more_rounded,
                                color: AppPalette.mutedText, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _calendarExpanded
                        ? Column(
                            children: [
                              const SizedBox(height: 18),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cellWidth = (constraints.maxWidth -
                                          (calendarSpacing * 6)) /
                                      7;
                                  final cellHeight = math.max(
                                    isCompact ? 50.0 : 56.0,
                                    math.min(
                                      isCompact ? 64.0 : 72.0,
                                      cellWidth * (isCompact ? 1.55 : 1.7),
                                    ),
                                  );
                                  final badgeSize = isCompact ? 16.0 : 18.0;

                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: calendarSpacing,
                                      crossAxisSpacing: calendarSpacing,
                                      mainAxisExtent: cellHeight,
                                    ),
                                    itemCount: daysInMonth,
                                    itemBuilder: (context, index) {
                                      final active = index == selectedDay;
                                      final day = plan[monthStart + index];
                                      final completed = controller
                                          .isWorkoutCompleted(day.dayNumber);
                                      final cellDate = _startDate.add(
                                          Duration(days: monthStart + index));
                                      final isToday = monthStart + index == 0;
                                      const wdLabels = [
                                        'T2',
                                        'T3',
                                        'T4',
                                        'T5',
                                        'T6',
                                        'T7',
                                        'CN'
                                      ];
                                      final weekday =
                                          wdLabels[cellDate.weekday - 1];
                                      final showBadge = completed || active;
                                      final badgeIcon = completed
                                          ? Icons.check_rounded
                                          : Icons.bolt_rounded;
                                      final badgeColor = active
                                          ? Colors.white
                                          : completed
                                              ? AppPalette.emeraldDeep
                                              : AppPalette.blue;

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(
                                            isCompact ? 14 : 18),
                                        onTap: () =>
                                            setState(() => selectedDay = index),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 220),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isCompact ? 4 : 6,
                                            vertical: isCompact ? 6 : 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? AppPalette.blue
                                                : isToday
                                                    ? AppPalette.blueSoft
                                                    : AppPalette
                                                        .surfaceElevated,
                                            borderRadius: BorderRadius.circular(
                                                isCompact ? 14 : 18),
                                            border: Border.all(
                                              color: active
                                                  ? Colors.transparent
                                                  : isToday
                                                      ? AppPalette.blue
                                                      : AppPalette.border,
                                              width: isToday && !active
                                                  ? 1.5
                                                  : 1.0,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              if (showBadge)
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Container(
                                                    width: badgeSize,
                                                    height: badgeSize,
                                                    decoration: BoxDecoration(
                                                      color: active
                                                          ? Colors.white
                                                              .withValues(
                                                                  alpha: 0.2)
                                                          : AppPalette
                                                              .emeraldSoft,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      badgeIcon,
                                                      size: isCompact ? 10 : 11,
                                                      color: badgeColor,
                                                    ),
                                                  ),
                                                ),
                                              Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      weekday,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: active
                                                                ? Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            0.82)
                                                                : isToday
                                                                    ? AppPalette
                                                                        .blue
                                                                    : AppPalette
                                                                        .mutedText,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: isCompact
                                                                ? 10
                                                                : 11,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                        height:
                                                            isCompact ? 2 : 4),
                                                    Text(
                                                      '${cellDate.day}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            color: active
                                                                ? Colors.white
                                                                : isToday
                                                                    ? AppPalette
                                                                        .blue
                                                                    : AppPalette
                                                                        .text,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: isCompact
                                                                ? 16
                                                                : 18,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPalette.blue, Color(0xFF67A1FF)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              selectedPlan.focusVi,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 26),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isCompact)
                    Column(
                      children: [
                        _WorkoutSummaryTile(
                          label: 'Thời gian',
                          value: '${selectedPlan.totalDuration} phút',
                          icon: Icons.schedule_rounded,
                        ),
                        const SizedBox(height: 10),
                        _WorkoutSummaryTile(
                          label: 'Calo đốt',
                          value: '${selectedPlan.totalCalories}',
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _WorkoutSummaryTile(
                            label: 'Thời gian',
                            value: '${selectedPlan.totalDuration} phút',
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WorkoutSummaryTile(
                            label: 'Calo đốt',
                            value: '${selectedPlan.totalCalories}',
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (isCompact)
                    Column(
                      children: [
                        TextButton.icon(
                          onPressed: () => controller
                              .toggleWorkoutCompleted(selectedPlan.dayNumber),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                          ),
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.emoji_events_outlined,
                          ),
                          label: Text(
                              isCompleted ? 'Đã hoàn thành' : 'Hoàn thành'),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => controller.selectTab(3),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                            ),
                            child: const Text('Đồ tập'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => controller
                                .toggleWorkoutCompleted(selectedPlan.dayNumber),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                            ),
                            icon: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.emoji_events_outlined,
                            ),
                            label: Text(
                                isCompleted ? 'Đã hoàn thành' : 'Hoàn thành'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () => controller.selectTab(3),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.18),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                            ),
                            child: const Text('Đồ tập'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientActionButton(
              label: 'Bắt đầu tập ngay ⚡',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WorkoutPlayerScreen(
                      workoutFocus: selectedPlan.focusVi,
                      exercises: selectedPlan.exercises,
                    ),
                  ),
                );
              },
              colors: const [AppPalette.blue, Color(0xFF67A1FF)],
            ),
            const SizedBox(height: 20),
            const SectionHeading(
              title: 'Danh sách bài tập',
              icon: Icon(Icons.list_alt_rounded, color: AppPalette.blue),
            ),
            const SizedBox(height: 14),
            ...selectedPlan.exercises.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppPalette.blue, Color(0xFF67A1FF)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.value.nameVi,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(entry.value.description),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (entry.value.sets != null &&
                                        entry.value.reps != null)
                                      _NutrientPill(
                                        label:
                                            '${entry.value.sets} sets × ${entry.value.reps}',
                                      ),
                                    if (entry.value.durationMinutes != null)
                                      _NutrientPill(
                                        label:
                                            '${entry.value.durationMinutes} phút',
                                      ),
                                    _NutrientPill(
                                        label:
                                            '${entry.value.caloriesBurned} cal'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSummaryTile extends StatelessWidget {
  const _WorkoutSummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.86)),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 6),
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

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with AutomaticKeepAliveClientMixin {
  String searchQuery = '';
  String category = 'all';
  Timer? _searchDebounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _addProductToCart(BuildContext context, Product product) {
    final controller = CoreHealthScope.of(context);
    controller.addToCart(product);
    showCartAddedOverlay(context);
  }

  void _openProductDetails(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          categoryLabel: _categoryLabel(product.categoryId),
        ),
      ),
    );
  }

  String _categoryLabel(String categoryId) {
    final match = DemoData.categories.where((item) => item.$1 == categoryId);
    return match.isEmpty ? 'Thực phẩm' : match.first.$2;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = CoreHealthScope.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);
    final isCompact = layout.isCompact;
    final horizontalPadding = layout.horizontalPadding;
    final allProducts = CoreHealthScope.of(context).products;
    final products = allProducts.where((product) {
      final matchesCategory =
          category == 'all' || product.categoryId == category;
      final query = searchQuery.toLowerCase();
      final matchesSearch = product.nameVi.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
    final featured =
        allProducts.where((product) => product.hot).take(4).toList();
    final showHighlights = category == 'all' && searchQuery.isEmpty;

    final bottomPad =
        layout.navBarHeight + MediaQuery.of(context).padding.bottom + 16;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topInset + 16,
              horizontalPadding,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppPalette.emerald, AppPalette.emeraldDeep],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -42,
                  top: 16,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: -28,
                  bottom: -24,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CoreHealth Shop',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mua theo thực đơn, giao nhanh trong ngày',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        CoreHealthIconButton(
                          icon: Icons.shopping_cart_outlined,
                          badge: controller.cartCount,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CartScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            if (mounted) setState(() => searchQuery = value);
                          },
                        );
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText:
                            'Tìm nguyên liệu, đồ tập, thực phẩm bổ sung...',
                        fillColor: Colors.white.withValues(alpha: 0.18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ShopHeroCarousel(
                      controller: controller,
                      categoryLabel: _categoryLabel,
                      onAdd: _addProductToCart,
                      onOpen: _openProductDetails,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              18,
              horizontalPadding,
              0,
            ),
            child: AdaptiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHighlights && featured.isNotEmpty) ...[
                    SectionHeading(
                      title: 'Giỏ nổi bật hôm nay',
                      icon: const Icon(Icons.auto_awesome_rounded,
                          color: AppPalette.orange),
                      trailing: Text(
                        'Mua nhanh',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppPalette.orange,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: isCompact ? 268 : 282,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: featured.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final product = featured[index];
                          return _ShopHighlightCard(
                            product: product,
                            categoryLabel: _categoryLabel(product.categoryId),
                            compact: isCompact,
                            onAdd: () => _addProductToCart(context, product),
                            onOpen: () => _openProductDetails(context, product),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final item = DemoData.categories[index];
                              final active = category == item.$1;
                              return ChoiceChip(
                                selected: active,
                                label: Text(item.$2),
                                selectedColor: AppPalette.emerald,
                                backgroundColor: AppPalette.surfaceElevated,
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: active
                                          ? Colors.black
                                          : AppPalette.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                                onSelected: (_) =>
                                    setState(() => category = item.$1),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemCount: DemoData.categories.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          showHighlights
                              ? 'Tất cả sản phẩm'
                              : 'Kết quả phù hợp',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppPalette.emeraldSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${products.length} sản phẩm',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (products.isEmpty)
                    AppCard(
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded,
                              color: AppPalette.mutedText, size: 32),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy sản phẩm phù hợp',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Thử từ khóa khác hoặc đổi bộ lọc danh mục.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = layout.columnsFor(
                          minCardWidth: 170,
                          maxColumns: 2,
                        );
                        final totalSpacing = 14.0 * (crossAxisCount - 1);
                        final itemWidth =
                            (constraints.maxWidth - totalSpacing) /
                                crossAxisCount;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: products.map((product) {
                            return SizedBox(
                              width: itemWidth,
                              child: _ProductCard(
                                product: product,
                                categoryLabel:
                                    _categoryLabel(product.categoryId),
                                onAdd: () =>
                                    _addProductToCart(context, product),
                                onOpen: () =>
                                    _openProductDetails(context, product),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtVnd(int priceK) {
  final s = (priceK * 1000).toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${buf}đ'; // ignore: unnecessary_brace_in_string_interps
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.categoryLabel,
    required this.onAdd,
    required this.onOpen,
  });

  final Product product;
  final String categoryLabel;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = _shopCategoryStyle(product.categoryId);
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        padding: const EdgeInsets.all(8),
        radius: 12,
        color: AppPalette.surfaceElevated,
        border: const BorderSide(color: AppPalette.borderLight),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColoredBox(
                color: AppPalette.surface,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) => RemoteImage(
                      url: product.imageUrl,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      radius: 10,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nameVi,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.text,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtVnd(product.priceK),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppPalette.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.hot ? 'Bán chạy' : 'Còn hàng',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: style.color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppPalette.emerald, Color(0xFF18C290)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Thêm vào giỏ',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHeroCarousel extends StatefulWidget {
  const _ShopHeroCarousel({
    required this.controller,
    required this.categoryLabel,
    required this.onAdd,
    required this.onOpen,
  });

  final AppController controller;
  final String Function(String categoryId) categoryLabel;
  final void Function(BuildContext context, Product product) onAdd;
  final void Function(BuildContext context, Product product) onOpen;

  @override
  State<_ShopHeroCarousel> createState() => _ShopHeroCarouselState();
}

class _ShopHeroCarouselState extends State<_ShopHeroCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Product> _getMealSuggestedProducts() {
    final controller = widget.controller;
    final mealPlan = controller.mealPlan;
    if (mealPlan.isEmpty) return DemoData.products.take(5).toList();

    final todayMeals = mealPlan.first.meals;
    final allIngredients = todayMeals
        .expand((meal) => meal.ingredients)
        .map((i) => i.toLowerCase())
        .toSet();

    final matched = DemoData.products.where((product) {
      final name = product.nameVi.toLowerCase();
      return allIngredients
          .any((ing) => name.contains(ing) || ing.contains(name));
    }).toList();

    if (matched.length < 3) {
      final hot = DemoData.products.where((p) => p.hot && !matched.contains(p));
      matched.addAll(hot.take(5 - matched.length));
    }

    return matched.isNotEmpty
        ? matched.take(5).toList()
        : DemoData.products.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _getMealSuggestedProducts();
    if (products.isEmpty) return const SizedBox.shrink();

    final isCompact = PhoneLayout.of(context).isCompact;
    final bannerHeight = isCompact ? 310.0 : 200.0;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: products.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final product = products[index];
              return _ShopHeroBanner(
                product: product,
                categoryLabel: widget.categoryLabel(product.categoryId),
                cartCount: widget.controller.cartCount,
                onAdd: () => widget.onAdd(context, product),
                onOpen: () => widget.onOpen(context, product),
              );
            },
          ),
        ),
        if (products.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(products.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == _currentIndex ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: i == _currentIndex ? 0.9 : 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ShopHeroBanner extends StatelessWidget {
  const _ShopHeroBanner({
    required this.product,
    required this.categoryLabel,
    required this.cartCount,
    required this.onAdd,
    required this.onOpen,
  });

  final Product product;
  final String categoryLabel;
  final int cartCount;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isCompact = PhoneLayout.of(context).isCompact;
    return GestureDetector(
      onTap: onOpen,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RemoteImage(
                      url: product.imageUrl,
                      width: double.infinity,
                      height: 152,
                      radius: 20,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ShopHeroBannerContent(
                    product: product,
                    categoryLabel: categoryLabel,
                    cartCount: cartCount,
                    onAdd: onAdd,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _ShopHeroBannerContent(
                      product: product,
                      categoryLabel: categoryLabel,
                      cartCount: cartCount,
                      onAdd: onAdd,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RemoteImage(
                      url: product.imageUrl,
                      width: 104,
                      height: 132,
                      radius: 20,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ShopHeroBannerContent extends StatelessWidget {
  const _ShopHeroBannerContent({
    required this.product,
    required this.categoryLabel,
    required this.cartCount,
    required this.onAdd,
  });

  final Product product;
  final String categoryLabel;
  final int cartCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Gợi ý theo thực đơn',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          product.nameVi,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '$categoryLabel • từ ${_fmtVnd(product.priceK)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
              ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_shopping_cart_rounded,
                  color: AppPalette.emeraldDeep,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thêm nhanh',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.emeraldDeep,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShopHighlightCard extends StatelessWidget {
  const _ShopHighlightCard({
    required this.product,
    required this.categoryLabel,
    required this.compact,
    required this.onAdd,
    required this.onOpen,
  });

  final Product product;
  final String categoryLabel;
  final bool compact;
  final VoidCallback onAdd;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = _shopCategoryStyle(product.categoryId);
    return SizedBox(
      width: compact ? 248 : 268,
      child: GestureDetector(
        onTap: onOpen,
        behavior: HitTestBehavior.opaque,
        child: AppCard(
          padding: const EdgeInsets.all(8),
          radius: 12,
          color: AppPalette.surfaceElevated,
          border: const BorderSide(color: AppPalette.borderLight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                  color: AppPalette.surface,
                  child: RemoteImage(
                    url: product.imageUrl,
                    height: compact ? 124 : 136,
                    radius: 10,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameVi,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppPalette.text,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _fmtVnd(product.priceK),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$categoryLabel • Còn hàng',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: style.color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppPalette.emerald, Color(0xFF18C290)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Thêm vào giỏ',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.categoryLabel,
  });

  final Product product;
  final String categoryLabel;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  void _addToCart({required bool openCart}) {
    final controller = CoreHealthScope.of(context);
    for (var i = 0; i < quantity; i++) {
      controller.addToCart(widget.product);
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    showCartAddedOverlay(context);

    if (openCart) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CartScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final style = _shopCategoryStyle(product.categoryId);
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalK = product.priceK * quantity;

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    RemoteImage(
                      url: product.imageUrl,
                      width: double.infinity,
                      height: 320,
                      radius: 0,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.18),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      top: topInset + 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CoreHealthIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          CoreHealthIconButton(
                            icon: Icons.shopping_cart_outlined,
                            badge: CoreHealthScope.of(context).cartCount,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppPalette.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        34,
                        20,
                        120 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: style.softColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(style.icon,
                                        size: 14, color: style.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.categoryLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: style.color,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              if (product.hot)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPalette.orangeSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Bán chạy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppPalette.orange,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            product.nameVi,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tươi mới mỗi ngày, đóng gói theo khẩu phần CoreHealth và giao nhanh trong 2 giờ.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppPalette.mutedText,
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 22),
                          AppCard(
                            padding: const EdgeInsets.all(16),
                            radius: 18,
                            child: Column(
                              children: [
                                _ProductDetailInfoRow(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Đơn vị',
                                  value: product.unit,
                                  color: style.color,
                                ),
                                const Divider(height: 24),
                                const _ProductDetailInfoRow(
                                  icon: Icons.local_shipping_outlined,
                                  label: 'Giao hàng',
                                  value: 'Trong 2 giờ',
                                  color: AppPalette.blue,
                                ),
                                const Divider(height: 24),
                                const _ProductDetailInfoRow(
                                  icon: Icons.verified_outlined,
                                  label: 'Tình trạng',
                                  value: 'Còn hàng',
                                  color: AppPalette.emeraldDeep,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Giá',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppPalette.mutedText),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmtVnd(product.priceK),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppPalette.emeraldDeep,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              _QuantityStepper(
                                value: quantity,
                                onMinus: quantity == 1
                                    ? null
                                    : () => setState(() => quantity--),
                                onPlus: () => setState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInset,
            child: AppCard(
              padding: const EdgeInsets.all(12),
              radius: 22,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tổng cộng',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmtVnd(totalK),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _addToCart(openCart: false),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppPalette.emeraldSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: AppPalette.emeraldDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () => _addToCart(openCart: true),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppPalette.emerald, Color(0xFF18C290)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Mua ngay',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailInfoRow extends StatelessWidget {
  const _ProductDetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppPalette.mutedText),
          ),
        ),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(icon: Icons.remove_rounded, onTap: onMinus),
          SizedBox(
            width: 42,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          _QuantityButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? AppPalette.emeraldSoft : AppPalette.surfaceElevated,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppPalette.emeraldDeep : AppPalette.subtleText,
          size: 18,
        ),
      ),
    );
  }
}

class _ShopCategoryStyle {
  const _ShopCategoryStyle({
    required this.color,
    required this.softColor,
    required this.icon,
  });

  final Color color;
  final Color softColor;
  final IconData icon;
}

_ShopCategoryStyle _shopCategoryStyle(String categoryId) {
  switch (categoryId) {
    case 'vegetable':
      return const _ShopCategoryStyle(
        color: AppPalette.emeraldDeep,
        softColor: AppPalette.emeraldSoft,
        icon: Icons.eco_rounded,
      );
    case 'protein':
      return const _ShopCategoryStyle(
        color: AppPalette.orange,
        softColor: AppPalette.orangeSoft,
        icon: Icons.restaurant_rounded,
      );
    case 'grain':
      return const _ShopCategoryStyle(
        color: AppPalette.gold,
        softColor: Color(0xFFFFF6D9),
        icon: Icons.grain_rounded,
      );
    case 'fruit':
      return const _ShopCategoryStyle(
        color: Color(0xFFFF5F7A),
        softColor: Color(0xFFFFE7EC),
        icon: Icons.apple_rounded,
      );
    case 'dairy':
      return const _ShopCategoryStyle(
        color: AppPalette.blue,
        softColor: AppPalette.blueSoft,
        icon: Icons.icecream_rounded,
      );
    case 'supplement':
      return const _ShopCategoryStyle(
        color: AppPalette.violet,
        softColor: AppPalette.violetSoft,
        icon: Icons.bolt_rounded,
      );
    case 'equipment':
      return const _ShopCategoryStyle(
        color: AppPalette.text,
        softColor: Color(0xFFF0F3F7),
        icon: Icons.fitness_center_rounded,
      );
    default:
      return const _ShopCategoryStyle(
        color: AppPalette.emeraldDeep,
        softColor: AppPalette.emeraldSoft,
        icon: Icons.shopping_basket_rounded,
      );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final profile = controller.profile;
    final userEmail = controller.userEmail ?? 'local@corehealth.app';
    final topInset = MediaQuery.of(context).padding.top;
    final layout = PhoneLayout.of(context);
    final horizontalPadding = layout.horizontalPadding;
    final bottomPad =
        layout.navBarHeight + MediaQuery.of(context).padding.bottom + 16;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPad),
      child: AdaptiveContent(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topInset + 18,
                horizontalPadding,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: AppPalette.emerald, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${profile.age} tuổi • ${profile.gender.title}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.84),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (layout.isCompact)
                    Column(
                      children: [
                        _HeaderStat(
                          label: 'Chiều cao',
                          value: _formatCm(profile.heightCm),
                        ),
                        const SizedBox(height: 10),
                        _HeaderStat(
                          label: 'Cân nặng',
                          value: _formatKg(profile.weightKg),
                        ),
                        const SizedBox(height: 10),
                        _HeaderStat(
                          label: 'BMI',
                          value: _formatDecimal(profile.bmi),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _HeaderStat(
                            label: 'Chiều cao',
                            value: _formatCm(profile.heightCm),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeaderStat(
                            label: 'Cân nặng',
                            value: _formatKg(profile.weightKg),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeaderStat(
                            label: 'BMI',
                            value: _formatDecimal(profile.bmi),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, 18, horizontalPadding, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppPalette.violet, width: 1.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: AppCard(
                      radius: 28,
                      border: BorderSide.none,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppPalette.violet,
                                      Color(0xFFC58FFF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ví token',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${profile.tokenBalance} token',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Một ví dùng chung cho toàn bộ AI usage.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 18),
                          _InfoRow(
                            label: 'Đã nhận',
                            value: '${profile.tokenEarned} token',
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            label: 'Đã dùng',
                            value: '${profile.tokenSpent} token',
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const TokenHistoryScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.receipt_long_rounded),
                            label: const Text('Xem lịch sử nạp'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color: AppPalette.violet.withValues(alpha: 0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      children: [
                        if (layout.isCompact)
                          Column(
                            children: [
                              _ActionTile(
                                title: 'Cập nhật cân nặng',
                                icon: Icons.monitor_weight_outlined,
                                color: AppPalette.emerald,
                                onTap: () => _showUpdateWeightSheet(context),
                              ),
                              const SizedBox(height: 12),
                              _ActionTile(
                                title: 'Lịch sử sức khỏe',
                                icon: Icons.timeline_rounded,
                                color: AppPalette.blue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const HealthHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _ActionTile(
                                title: 'AI Coach',
                                icon: Icons.smart_toy_rounded,
                                color: AppPalette.emerald,
                                highlighted: true,
                                onTap: () => _openAiChatPage(context),
                              ),
                              const SizedBox(height: 12),
                              _ActionTile(
                                title: 'Nạp token',
                                icon: Icons.toll_rounded,
                                color: AppPalette.orange,
                                highlighted: true,
                                onTap: () => _showUpgradeSheet(context),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionTile(
                                      title: 'Cập nhật cân nặng',
                                      icon: Icons.monitor_weight_outlined,
                                      color: AppPalette.emerald,
                                      onTap: () =>
                                          _showUpdateWeightSheet(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionTile(
                                      title: 'Lịch sử sức khỏe',
                                      icon: Icons.timeline_rounded,
                                      color: AppPalette.blue,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const HealthHistoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionTile(
                                      title: 'AI Coach',
                                      icon: Icons.smart_toy_rounded,
                                      color: AppPalette.emerald,
                                      highlighted: true,
                                      onTap: () => _openAiChatPage(context),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _ActionTile(
                                      title: 'Nạp token',
                                      icon: Icons.toll_rounded,
                                      color: AppPalette.orange,
                                      highlighted: true,
                                      onTap: () => _showUpgradeSheet(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeading(title: 'Mục tiêu của bạn'),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppPalette.emeraldSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.track_changes_rounded,
                              color: AppPalette.emerald),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.goal.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Mục tiêu ${_formatKg(profile.targetWeightKg)}'),
                            ],
                          ),
                        ),
                        Text(
                          _formatKg(
                            (profile.weightKg - profile.targetWeightKg).abs(),
                          ),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppPalette.emeraldDeep,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeading(title: 'Hồ sơ theo survey'),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                            label: 'Mục tiêu',
                            value:
                                '${profile.goal.title} • ${_formatKg(profile.targetWeightKg)}'),
                        const SizedBox(height: 12),
                        _InfoRow(
                            label: 'Mức vận động',
                            value: profile.activityLevel.title),
                        const SizedBox(height: 12),
                        _InfoRow(
                            label: 'Tần suất tập',
                            value: profile.trainingFrequency.isEmpty
                                ? profile.schedule
                                : profile.trainingFrequency),
                        const SizedBox(height: 14),
                        _SurveyInfoChips(
                          icon: Icons.track_changes_rounded,
                          title: 'Vùng cơ thể tập trung',
                          items: _displayFocusAreas(profile.focusAreas),
                          emptyLabel: 'Chưa chọn vùng tập trung',
                          color: AppPalette.violet,
                        ),
                        const SizedBox(height: 12),
                        _SurveyInfoChips(
                          icon: Icons.directions_run_rounded,
                          title: 'Hoạt động yêu thích',
                          items: profile.preferredActivities,
                          emptyLabel: 'Chưa chọn hoạt động',
                          color: AppPalette.blue,
                        ),
                        const SizedBox(height: 12),
                        _SurveyInfoChips(
                          icon: Icons.accessibility_new_rounded,
                          title: 'Lưu ý sức khỏe',
                          items: profile.healthConditions,
                          emptyLabel: 'Không có',
                          color: AppPalette.emerald,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Ngân sách meal',
                          value: profile.mealBudget.isEmpty
                              ? 'Chưa thiết lập'
                              : profile.mealBudget,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Thời gian nấu',
                          value: profile.cookingTime.isEmpty
                              ? 'Chưa thiết lập'
                              : profile.cookingTime,
                        ),
                        const SizedBox(height: 14),
                        _SurveyInfoChips(
                          icon: Icons.restaurant_menu_rounded,
                          title: 'Khẩu vị & meal plan',
                          items: profile.dietaryRestrictions,
                          emptyLabel: 'Không yêu cầu đặc biệt',
                          color: AppPalette.orange,
                        ),
                        const SizedBox(height: 12),
                        _SurveyInfoChips(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Ưu tiên dinh dưỡng',
                          items: profile.nutritionPriorities,
                          emptyLabel: 'Chưa chọn ưu tiên',
                          color: AppPalette.emerald,
                        ),
                        const SizedBox(height: 12),
                        _SurveyInfoChips(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Dị ứng thực phẩm',
                          items: profile.allergies,
                          emptyLabel: 'Không có',
                          color: AppPalette.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (controller.orders.isNotEmpty) ...[
                    const SectionHeading(title: 'Đơn hàng gần đây'),
                    const SizedBox(height: 14),
                    ...controller.orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      color: AppPalette.mutedText),
                                  const SizedBox(width: 10),
                                  Text(
                                    order.id,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppPalette.emeraldSoft,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      order.statusLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppPalette.emeraldDeep,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _InfoRow(
                                label: '${order.itemCount} sản phẩm',
                                value: '${order.totalK}k VNĐ',
                              ),
                              const SizedBox(height: 10),
                              _InfoRow(
                                  label: 'Ngày đặt', value: order.dateLabel),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: controller.signOut,
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      side: const BorderSide(color: Color(0xFFFFD3D3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ReferralCodeCard(
                    referralCode: profile.referralCode.trim(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateWeightSheet(BuildContext context) async {
    final controller = CoreHealthScope.of(context);
    final textController = TextEditingController(
      text: _formatDecimal(controller.profile.weightKg),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AppCard(
            radius: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật cân nặng',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Cân nặng hiện tại (kg)'),
                ),
                const SizedBox(height: 18),
                GradientActionButton(
                  label: 'Lưu thay đổi',
                  onPressed: () {
                    final value = _parseLocalizedDouble(textController.text);
                    if (value != null && value >= 30 && value <= 200) {
                      controller.updateWeight(value);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cân nặng hợp lệ từ 30 đến 200 kg.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  colors: const [AppPalette.emerald, Color(0xFF18C290)],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({required this.referralCode});

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final hasCode = referralCode.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
      color: AppPalette.mint,
      border: const BorderSide(color: AppPalette.emeraldSoft),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPalette.borderLight),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppPalette.emeraldDeep,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mã giới thiệu',
                  style: tt.labelMedium?.copyWith(
                    color: AppPalette.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  hasCode ? referralCode : 'Chưa có mã',
                  maxLines: 1,
                  style: tt.titleMedium?.copyWith(
                    color: hasCode ? AppPalette.text : AppPalette.subtleText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasCode
                      ? 'Gửi mã này cho bạn bè khi họ đăng ký.'
                      : 'Mã sẽ xuất hiện sau khi tài khoản được xác thực.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: AppPalette.mutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message:
                hasCode ? 'Sao chép mã giới thiệu' : 'Chưa có mã để sao chép',
            child: IconButton.filledTonal(
              onPressed:
                  hasCode ? () => _copyCode(context, referralCode) : null,
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                backgroundColor:
                    hasCode ? AppPalette.emeraldSoft : AppPalette.borderLight,
                disabledBackgroundColor: AppPalette.borderLight,
                foregroundColor: AppPalette.emeraldDeep,
                disabledForegroundColor: AppPalette.subtleText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.copy_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép mã giới thiệu.')),
    );
  }
}

Future<void> _showUpgradeSheet(BuildContext context) async {
  final controller = CoreHealthScope.of(context);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      var selectedPack = tokenPacks.firstWhere(
        (pack) => pack.recommended,
        orElse: () => tokenPacks.first,
      );

      return StatefulBuilder(
        builder: (context, setModalState) {
          final safeTop = MediaQuery.of(context).padding.top;
          final safeBottom = MediaQuery.of(context).padding.bottom;
          final maxH =
              MediaQuery.of(context).size.height - safeTop - 8 - safeBottom;
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, safeBottom > 0 ? 0 : 10),
              child: SizedBox(
                height: (MediaQuery.of(context).size.height * 0.84)
                    .clamp(0.0, maxH),
                child: AppCard(
                  radius: 34,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Nạp token',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: AppPalette.mutedText,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.mint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.toll_rounded,
                                        color: AppPalette.emerald,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Ví hiện có ${controller.profile.tokenBalance} token. Token dùng chung cho AI chat, scan, meal plan và workout plan.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppPalette.text,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...tokenPacks.asMap().entries.map((entry) {
                                final pack = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: entry.key == tokenPacks.length - 1
                                        ? 0
                                        : 14,
                                  ),
                                  child: _TokenPackCard(
                                    pack: pack,
                                    selected: selectedPack.id == pack.id,
                                    onTap: () => setModalState(() {
                                      selectedPack = pack;
                                    }),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                        child: GradientActionButton(
                          label:
                              'Nạp ${selectedPack.tokens} token - ${selectedPack.priceK}k VNĐ',
                          icon: const Icon(
                            Icons.toll_rounded,
                            size: 18,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PaymentScreen(
                                  amountK: selectedPack.priceK,
                                  description:
                                      '${selectedPack.title} token pack - ${selectedPack.tokens} token',
                                  onSuccess: () {
                                    controller.activateTokenPack(selectedPack);
                                    Navigator.of(context)
                                      ..pop()
                                      ..pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Đã nạp ${selectedPack.tokens} token.',
                                        ),
                                      ),
                                    );
                                  },
                                  onTimeout: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã huỷ — không nhận được thanh toán.',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          colors: const [
                            AppPalette.emerald,
                            Color(0xFF18C290),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _TokenPackCard extends StatelessWidget {
  const _TokenPackCard({
    required this.pack,
    required this.selected,
    required this.onTap,
  });

  final TokenPack pack;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = pack.recommended ? AppPalette.emerald : AppPalette.blue;
    final titleColor = selected ? Colors.white : AppPalette.text;
    final bodyColor =
        selected ? Colors.white.withValues(alpha: 0.86) : AppPalette.mutedText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [accent, AppPalette.emeraldDeep])
              : null,
          color: selected ? null : AppPalette.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? Colors.transparent : AppPalette.border,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  selected ? accent.withValues(alpha: 0.22) : AppPalette.shadow,
              blurRadius: selected ? 24 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.toll_rounded,
                color: selected ? Colors.white : accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pack.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      if (pack.recommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.18)
                                : AppPalette.emeraldSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Phổ biến',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppPalette.emeraldDeep,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pack.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${pack.tokens}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  '${pack.priceK}k',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 8),
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppPalette.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: highlighted ? color : AppPalette.border,
            width: highlighted ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppPalette.text,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _SurveyInfoChips extends StatelessWidget {
  const _SurveyInfoChips({
    required this.icon,
    required this.title,
    required this.items,
    required this.emptyLabel,
    required this.color,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final String emptyLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayItems = items.isEmpty ? [emptyLabel] : items;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                displayItems.map((item) => _NutrientPill(label: item)).toList(),
          ),
        ],
      ),
    );
  }
}

// Legacy subscription widgets stay here while older screens are migrated.
// ignore: unused_element
class _SubscriptionExpiryBanner extends StatelessWidget {
  const _SubscriptionExpiryBanner({
    required this.daysLeft,
    required this.onRenew,
  });

  final int daysLeft;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final isExpired = daysLeft <= 0;
    final color = isExpired ? Colors.red.shade600 : Colors.orange.shade700;
    final bg = isExpired ? Colors.red.shade50 : Colors.orange.shade50;
    final message = isExpired
        ? 'Gói đã hết hạn. Các tính năng AI đã bị khoá.'
        : 'Gói sắp hết hạn sau $daysLeft ngày.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isExpired
                ? Icons.lock_outline_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRenew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Gia hạn',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

// ignore: unused_element
String _subscriptionDurationLabel(DemoProfile profile) {
  if (profile.hasActiveCoreHealthMaxTrial &&
      profile.plan == SubscriptionPlan.max) {
    return 'Dùng thử 7 ngày';
  }

  if (profile.plan == SubscriptionPlan.free ||
      profile.subscriptionMonths <= 0) {
    return 'Miễn phí';
  }

  if (profile.hasActiveCoreHealthMaxTrial) {
    return '${profile.subscriptionMonths} tháng + trial Max';
  }

  return '${profile.subscriptionMonths} tháng';
}

double? _parseLocalizedDouble(String raw) {
  final normalized = raw.trim().replaceAll(',', '.');
  return double.tryParse(normalized);
}

String _formatDecimal(double value, {int fractionDigits = 1}) {
  return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
}

String _formatKg(double value) {
  return '${_formatDecimal(value)} kg';
}

String _formatCm(double value) {
  return '${_formatDecimal(value)} cm';
}

List<String> _displayFocusAreas(List<String> focusAreas) {
  if (focusAreas.length <= 1) {
    return focusAreas;
  }

  return focusAreas
      .map((area) => area == 'Toàn Thân' ? '(Toàn thân)' : area)
      .toList(growable: false);
}

class _UpgradePlanData {
  const _UpgradePlanData({
    required this.id,
    required this.plan,
    required this.icon,
    required this.colors,
    required this.highlights,
    required this.durations,
    required this.teaser,
    required this.extraFeatureCount,
  });

  final String id;
  final SubscriptionPlan plan;
  final IconData icon;
  final List<Color> colors;
  final List<String> highlights;
  final List<_UpgradeDuration> durations;
  final String teaser;
  final int extraFeatureCount;

  String get title => plan.title;
  Color get accentColor => colors.first;
}

class _UpgradeDuration {
  const _UpgradeDuration({
    required this.months,
    required this.totalPrice,
    required this.monthlyLabel,
    this.savingsLabel,
  });

  final int months;
  final int totalPrice;
  final String monthlyLabel;
  final String? savingsLabel;
}

// ignore: unused_element
const _upgradePlans = <_UpgradePlanData>[
  _UpgradePlanData(
    id: 'meal',
    plan: SubscriptionPlan.meal,
    icon: Icons.restaurant_menu_rounded,
    colors: [AppPalette.orange, Color(0xFFFFB15F)],
    teaser: 'meal plan chuyên sâu',
    highlights: [
      'Kế hoạch bữa ăn cá nhân hóa chi tiết',
      'Tính toàn calo & macro chính xác',
      'Gợi ý thực đơn Việt Nam',
    ],
    extraFeatureCount: 3,
    durations: [
      _UpgradeDuration(months: 1, totalPrice: 99, monthlyLabel: '~99k/tháng'),
      _UpgradeDuration(
        months: 3,
        totalPrice: 249,
        monthlyLabel: '~83k/tháng',
        savingsLabel: 'Tiết kiệm 16%',
      ),
      _UpgradeDuration(
        months: 6,
        totalPrice: 449,
        monthlyLabel: '~75k/tháng',
        savingsLabel: 'Tiết kiệm 24%',
      ),
    ],
  ),
  _UpgradePlanData(
    id: 'workout',
    plan: SubscriptionPlan.workout,
    icon: Icons.fitness_center_rounded,
    colors: [AppPalette.blue, Color(0xFF73A9FF)],
    teaser: 'workout plan có AI',
    highlights: [
      'Kế hoạch tập luyện cá nhân hóa',
      'Bài tập phù hợp mọi cấp độ',
      'Tập tại nhà, gym hoặc ngoài trời',
    ],
    extraFeatureCount: 3,
    durations: [
      _UpgradeDuration(months: 1, totalPrice: 89, monthlyLabel: '~89k/tháng'),
      _UpgradeDuration(
        months: 3,
        totalPrice: 219,
        monthlyLabel: '~73k/tháng',
        savingsLabel: 'Tiết kiệm 18%',
      ),
      _UpgradeDuration(
        months: 6,
        totalPrice: 399,
        monthlyLabel: '~66k/tháng',
        savingsLabel: 'Tiết kiệm 26%',
      ),
    ],
  ),
  _UpgradePlanData(
    id: 'max',
    plan: SubscriptionPlan.max,
    icon: Icons.workspace_premium_rounded,
    colors: [AppPalette.violet, Color(0xFFC58FFF)],
    teaser: 'giải pháp toàn diện',
    highlights: [
      'Tất cả tính năng Meal',
      'Tất cả tính năng Workout',
      'Dashboard tích hợp hoàn chỉnh',
    ],
    extraFeatureCount: 4,
    durations: [
      _UpgradeDuration(months: 1, totalPrice: 159, monthlyLabel: '~159k/tháng'),
      _UpgradeDuration(
        months: 3,
        totalPrice: 399,
        monthlyLabel: '~133k/tháng',
        savingsLabel: 'Tiết kiệm 16%',
      ),
      _UpgradeDuration(
        months: 6,
        totalPrice: 699,
        monthlyLabel: '~117k/tháng',
        savingsLabel: 'Tiết kiệm 26%',
      ),
    ],
  ),
];

// ignore: unused_element
class _UpgradePlanCard extends StatelessWidget {
  const _UpgradePlanCard({
    required this.plan,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final _UpgradePlanData plan;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = selected ? Colors.white : AppPalette.text;
    final bodyColor =
        selected ? Colors.white.withValues(alpha: 0.84) : AppPalette.mutedText;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: plan.colors) : null,
          color: selected ? null : AppPalette.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : current
                    ? plan.accentColor.withValues(alpha: 0.55)
                    : AppPalette.border,
            width: current ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? plan.accentColor.withValues(alpha: 0.22)
                  : AppPalette.shadow,
              blurRadius: selected ? 24 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.16)
                        : plan.accentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(plan.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: titleColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          if (current && !selected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: plan.accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Hiện tại',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: plan.accentColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            )
                          else if (selected)
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${plan.durations.first.totalPrice}k/tháng • ${plan.teaser}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: bodyColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plan.durations.map((duration) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${duration.months} tháng: ${duration.totalPrice}k',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected ? Colors.white : AppPalette.text,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            ...plan.highlights.map((highlight) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: selected ? Colors.white : plan.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        highlight,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: selected ? Colors.white : AppPalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Text(
              '+${plan.extraFeatureCount} tính năng khác',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _UpgradeDurationCard extends StatelessWidget {
  const _UpgradeDurationCard({
    required this.duration,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  final _UpgradeDuration duration;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.12)
              : AppPalette.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accentColor : AppPalette.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${duration.months} tháng',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.text,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${duration.totalPrice}k',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: selected ? accentColor : AppPalette.emeraldDeep,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              duration.monthlyLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPalette.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: duration.savingsLabel == null
                    ? AppPalette.surfaceElevated
                    : AppPalette.orangeSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                duration.savingsLabel ?? 'Linh hoạt',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: duration.savingsLabel == null
                          ? AppPalette.mutedText
                          : AppPalette.orange,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showBmiDetailSheet(BuildContext context, DemoProfile profile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BmiDetailSheet(profile: profile),
  );
}

class _BmiDetailSheet extends StatelessWidget {
  const _BmiDetailSheet({required this.profile});
  final DemoProfile profile;

  @override
  Widget build(BuildContext context) {
    final bmi = profile.bmi;
    final category = profile.bmiCategory;
    final Color catColor;
    if (bmi < 18.5) {
      catColor = AppPalette.blue;
    } else if (bmi < 23.0) {
      catColor = AppPalette.emerald;
    } else if (bmi < 25.0) {
      catColor = AppPalette.orange;
    } else {
      catColor = Colors.redAccent;
    }

    final delta = profile.weightDeltaKg;
    final String deltaText;
    if (delta == 0) {
      deltaText = 'Bạn đang trong ngưỡng cân nặng lý tưởng 🎉';
    } else if (delta > 0) {
      deltaText = 'Cần tăng ${_formatKg(delta)} để vào vùng bình thường';
    } else {
      deltaText = 'Cần giảm ${_formatKg(-delta)} để vào vùng bình thường';
    }

    final bodyFat = profile.bodyFatPercent.clamp(5.0, 60.0);

    final String healthNote;
    if (bmi < 18.5) {
      healthNote =
          'Thiếu cân có thể dẫn đến thiếu hụt dinh dưỡng, loãng xương và hệ miễn dịch yếu. Ưu tiên tăng khối lượng cơ qua chế độ ăn giàu protein và tập luyện sức mạnh.';
    } else if (bmi < 23.0) {
      healthNote =
          'Chỉ số BMI nằm trong vùng lý tưởng theo tiêu chuẩn châu Á. Duy trì lối sống lành mạnh và kiểm tra sức khỏe định kỳ mỗi 6 tháng.';
    } else if (bmi < 25.0) {
      healthNote =
          'Ngưỡng thừa cân nhẹ theo tiêu chuẩn châu Á. Nguy cơ tim mạch và tiểu đường tăng nhẹ — điều chỉnh khẩu phần ăn và tăng vận động aerobic.';
    } else if (bmi < 30.0) {
      healthNote =
          'Béo phì độ I liên quan đến tăng nguy cơ huyết áp cao, tiểu đường type 2 và bệnh tim mạch. Nên tư vấn chuyên gia dinh dưỡng để có kế hoạch giảm cân phù hợp.';
    } else {
      healthNote =
          'Béo phì độ II làm tăng đáng kể nguy cơ các bệnh mãn tính. Cần can thiệp y tế kết hợp thay đổi lối sống toàn diện — tham khảo ý kiến bác sĩ.';
    }

    final tt = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.88,
      builder: (_, scrollController) {
        return SafeArea(
          bottom: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE2EA),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.monitor_heart_outlined,
                                color: catColor),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phân tích BMI', style: tt.titleMedium),
                              Text('Tiêu chuẩn WHO châu Á',
                                  style: tt.bodySmall
                                      ?.copyWith(color: AppPalette.mutedText)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: catColor.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDecimal(bmi),
                                  style: tt.displayLarge
                                      ?.copyWith(color: catColor, fontSize: 48),
                                ),
                                Text('kg/m²',
                                    style: tt.bodySmall?.copyWith(
                                        color: AppPalette.mutedText)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: catColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(category,
                                  style: tt.bodyMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _BmiInfoRow(
                        icon: Icons.track_changes_rounded,
                        color:
                            delta == 0 ? AppPalette.emerald : AppPalette.orange,
                        label: 'Cân nặng lý tưởng',
                        value:
                            '${_formatKg(profile.idealWeightMinKg)} - ${_formatKg(profile.idealWeightMaxKg)}',
                        sub: deltaText,
                      ),
                      const SizedBox(height: 10),
                      _BmiInfoRow(
                        icon: Icons.pie_chart_outline_rounded,
                        color: AppPalette.violet,
                        label: 'Mỡ cơ thể ước tính',
                        value: '${_formatDecimal(bodyFat)}%',
                        sub: 'Công thức Deurenberg (BMI + tuổi + giới tính)',
                      ),
                      const SizedBox(height: 10),
                      _BmiInfoRow(
                        icon: Icons.bolt_rounded,
                        color: AppPalette.blue,
                        label: 'Chuyển hóa cơ bản (BMR)',
                        value: '${profile.bmr.round()} kcal/ngày',
                        sub: 'Năng lượng cần thiết khi nghỉ ngơi hoàn toàn',
                      ),
                      const SizedBox(height: 10),
                      _BmiInfoRow(
                        icon: Icons.local_fire_department_rounded,
                        color: AppPalette.orange,
                        label: 'Nhu cầu calo thực tế (TDEE)',
                        value: '${profile.tdee.round()} kcal/ngày',
                        sub:
                            'Đã tính mức vận động: ${profile.activityLevel.title}',
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.mint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppPalette.emeraldDeep, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(healthNote,
                                  style: tt.bodySmall?.copyWith(
                                      color: AppPalette.emeraldDeep,
                                      height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '* BMI không phân biệt cơ và mỡ. Người tập gym có thể có BMI cao nhưng tỷ lệ mỡ thấp.',
                        style: tt.bodySmall?.copyWith(
                            color: AppPalette.mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BmiInfoRow extends StatelessWidget {
  const _BmiInfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPalette.border),
        boxShadow: const [
          BoxShadow(
              color: AppPalette.shadow, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: tt.bodySmall?.copyWith(color: AppPalette.mutedText)),
                const SizedBox(height: 2),
                Text(value,
                    style:
                        tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(sub,
                    style: tt.bodySmall
                        ?.copyWith(color: AppPalette.mutedText, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMealsSummary extends StatelessWidget {
  const _TodayMealsSummary({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mealsWithLogs = controller.todayMealsWithLogs;
    final targetCal = controller.profile.tdee.round();
    final eatenCal = controller.todayEatenCalories;
    final hasLogs = controller.todayMealLogs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress summary bar
        if (hasLogs) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text('Hôm nay: $eatenCal / $targetCal kcal',
                        style: tt.titleSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (eatenCal / targetCal).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(targetCal - eatenCal).clamp(0, targetCal)} kcal còn lại hôm nay',
                  style: tt.bodySmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
        // Meal list
        AppCard(
          child: Column(
            children: mealsWithLogs.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Chưa có bữa ăn hôm nay',
                          style: tt.bodySmall
                              ?.copyWith(color: AppPalette.mutedText)),
                    )
                  ]
                : mealsWithLogs.asMap().entries.map((entry) {
                    final isLast = entry.key == mealsWithLogs.length - 1;
                    final item = entry.value;
                    final log = item.log;
                    final meal = item.meal;
                    final isEaten = log != null;

                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isEaten
                              ? AppPalette.emeraldSoft
                              : AppPalette.surfaceElevated,
                          borderRadius: BorderRadius.circular(22),
                          border: isEaten
                              ? Border.all(
                                  color:
                                      AppPalette.emerald.withValues(alpha: 0.4))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isEaten
                                    ? AppPalette.emerald.withValues(alpha: 0.15)
                                    : AppPalette.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                meal.slotLabel.split(' ').first,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEaten ? log.foodName : meal.nameVi,
                                    style: tt.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      if (isEaten) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppPalette.emerald,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text('Đã ăn',
                                              style: tt.bodySmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10)),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      Text(
                                        meal.slotLabel,
                                        style: tt.bodySmall?.copyWith(
                                            color: AppPalette.mutedText),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isEaten ? log.calories : meal.calories} kcal',
                                  style: tt.bodyLarge?.copyWith(
                                    color: isEaten
                                        ? AppPalette.emerald
                                        : AppPalette.text,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (isEaten)
                                  GestureDetector(
                                    onTap: () =>
                                        controller.deleteMealLog(log.id),
                                    child: Text('Xóa',
                                        style: tt.bodySmall?.copyWith(
                                            color: AppPalette.mutedText,
                                            fontSize: 10)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}

class StandaloneShopScreen extends StatelessWidget {
  const StandaloneShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Cửa hàng'),
      ),
      body: ShopScreen(),
    );
  }
}

class StandaloneProfileScreen extends StatelessWidget {
  const StandaloneProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CoreHealthSubPageAppBar(title: 'Hồ sơ cá nhân'),
      ),
      body: ProfileScreen(),
    );
  }
}
