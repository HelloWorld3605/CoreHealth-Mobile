import 'dart:async';

import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../demo_data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final Timer _timer;
  final _activeFeature = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      _activeFeature.value = (_activeFeature.value + 1) % 3;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _activeFeature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final textTheme = Theme.of(context).textTheme;
    final layout = PhoneLayout.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppPalette.background,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              layout.horizontalPadding,
              8,
              layout.horizontalPadding,
              26,
            ),
            child: AdaptiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: AppPalette.shadow,
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/logocorehealth.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CoreHealth',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text('Sức khỏe của bạn',
                                style: textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.openAuth(AuthMode.signIn),
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppPalette.emeraldSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 18, color: AppPalette.emeraldDeep),
                          const SizedBox(width: 8),
                          Text(
                            'Powered by AI • Made for Vietnam',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppPalette.emeraldDeep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Sống khỏe theo\ncách của bạn',
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge?.copyWith(
                      fontSize: layout.headlineSize,
                      height: 1.03,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'Kế hoạch ăn uống và tập luyện cá nhân hóa, phù hợp với món Việt và nhịp sống bận rộn.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppPalette.mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (layout.isCompact)
                    const Column(
                      children: [
                        _WelcomeStat(
                          value: '10K+',
                          label: 'Người dùng',
                          icon: Icons.groups_rounded,
                        ),
                        SizedBox(height: 12),
                        _WelcomeStat(
                          value: '95%',
                          label: 'Hài lòng',
                          icon: Icons.star_rounded,
                        ),
                        SizedBox(height: 12),
                        _WelcomeStat(
                          value: '30 ngày',
                          label: 'Kết quả',
                          icon: Icons.my_location_rounded,
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Expanded(
                          child: _WelcomeStat(
                            value: '10K+',
                            label: 'Người dùng',
                            icon: Icons.groups_rounded,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _WelcomeStat(
                            value: '95%',
                            label: 'Hài lòng',
                            icon: Icons.star_rounded,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _WelcomeStat(
                            value: '30 ngày',
                            label: 'Kết quả',
                            icon: Icons.my_location_rounded,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 26),
                  Stack(
                    children: [
                      const RemoteImage(url: DemoData.heroFood, height: 268),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xB3000000)],
                            ),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 18,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroPill(
                              icon: Icons.restaurant_menu_rounded,
                              label: 'Món Việt chuẩn macro',
                            ),
                            SizedBox(height: 10),
                            Padding(
                              padding: EdgeInsets.only(left: 30),
                              child: _HeroPill(
                                icon: Icons.bolt_rounded,
                                label: 'Tập 20 phút/ngày',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GradientActionButton(
                    label: 'Bắt đầu miễn phí',
                    onPressed: controller.openIntro,
                    colors: const [AppPalette.emerald, Color(0xFF18C290)],
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tặng ngay 25 token AI miễn phí khi đăng ký tài khoản mới',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppPalette.emeraldDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _SectionBlock(
                    title: 'Tính năng nổi bật',
                    subtitle: 'Mọi thứ bạn cần cho hành trình sức khỏe',
                    child: Column(
                      children: [
                        ValueListenableBuilder<int>(
                          valueListenable: _activeFeature,
                          builder: (_, active, __) => Column(
                            children: [
                              _FeatureCard(
                                active: active == 0,
                                colors: const [
                                  AppPalette.violet,
                                  Color(0xFFC668FF)
                                ],
                                icon: Icons.psychology_alt_rounded,
                                title: 'AI Coach cá nhân',
                                description:
                                    '3 trợ lý AI chuyên biệt về dinh dưỡng, tập luyện và sức khỏe tổng quan.',
                              ),
                              const SizedBox(height: 12),
                              _FeatureCard(
                                active: active == 1,
                                colors: const [
                                  AppPalette.emerald,
                                  Color(0xFF18C290)
                                ],
                                icon: Icons.set_meal_rounded,
                                title: 'Kế hoạch bữa ăn Việt',
                                description:
                                    'Thực đơn phù hợp với khẩu vị Việt: phở, cơm tấm, bún và món nhà quen thuộc.',
                              ),
                              const SizedBox(height: 12),
                              _FeatureCard(
                                active: active == 2,
                                colors: const [
                                  AppPalette.orange,
                                  Color(0xFFFFB45D)
                                ],
                                icon: Icons.fitness_center_rounded,
                                title: 'Bài tập linh hoạt',
                                description:
                                    'Tập ở nhà hoặc gym, chỉ 20-45 phút mỗi ngày cho lịch làm việc bận rộn.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (layout.isCompact)
                          const Column(
                            children: [
                              _MiniFeature(
                                icon: Icons.insights_rounded,
                                title: 'Theo dõi tiến trình',
                                description: 'Dashboard trực quan',
                              ),
                              SizedBox(height: 12),
                              _MiniFeature(
                                icon: Icons.local_mall_outlined,
                                title: 'CoreHealth Shop',
                                description: 'Mua nguyên liệu tiện lợi',
                              ),
                              SizedBox(height: 12),
                              _MiniFeature(
                                icon: Icons.notifications_active_rounded,
                                title: 'Nhắc nhở',
                                description: 'Không bỏ lỡ bữa ăn',
                              ),
                              SizedBox(height: 12),
                              _MiniFeature(
                                icon: Icons.track_changes_rounded,
                                title: 'Mục tiêu linh hoạt',
                                description: 'Giảm, tăng hoặc duy trì',
                              ),
                            ],
                          )
                        else ...[
                          const Row(
                            children: [
                              Expanded(
                                child: _MiniFeature(
                                  icon: Icons.insights_rounded,
                                  title: 'Theo dõi tiến trình',
                                  description: 'Dashboard trực quan',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _MiniFeature(
                                  icon: Icons.local_mall_outlined,
                                  title: 'CoreHealth Shop',
                                  description: 'Mua nguyên liệu tiện lợi',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Expanded(
                                child: _MiniFeature(
                                  icon: Icons.notifications_active_rounded,
                                  title: 'Nhắc nhở',
                                  description: 'Không bỏ lỡ bữa ăn',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _MiniFeature(
                                  icon: Icons.track_changes_rounded,
                                  title: 'Mục tiêu linh hoạt',
                                  description: 'Giảm, tăng hoặc duy trì',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SectionBlock(
                    title: 'Nạp token linh hoạt',
                    subtitle: 'Một ví token dùng chung cho toàn bộ tính năng AI',
                    child: Column(
                      children: [
                        _PricingCard(
                          title: 'Tài khoản Starter (Đăng ký mới)',
                          price: 'Tặng 25 token',
                          features: [
                            '25 token AI miễn phí',
                            'Theo dõi cân nặng và calo cơ bản',
                            'Trải nghiệm AI Coach & Food Scan',
                          ],
                        ),
                        SizedBox(height: 14),
                        _PricingCard(
                          title: 'Gói Token Basic',
                          price: '99.000đ',
                          highlight: true,
                          badge: 'Phổ biến nhất',
                          features: [
                            'Nhận ngay 120 token vào ví chung',
                            'Đủ dùng cho ~40 lần quét món ăn AI',
                            'Chat tư vấn sức khỏe & dinh dưỡng',
                            'Kích hoạt tính năng Smart Rebalance',
                          ],
                        ),
                        SizedBox(height: 14),
                        _PricingCard(
                          title: 'Gói Token Pro',
                          price: '199.000đ',
                          features: [
                            'Nhận ngay 260 token vào ví chung',
                            'Tiết kiệm hơn (~765đ/token)',
                            'Phù hợp người tập luyện hàng ngày',
                            'Thoải mái tạo AI Meal/Workout plan',
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SectionBlock(
                    title: 'Người dùng nói gì?',
                    child: Column(
                      children: [
                        _TestimonialCard(
                          name: 'Minh Anh',
                          role: 'Marketing Manager, 28 tuổi',
                          quote:
                              'Mình thích nhất là có món Việt. Không phải ăn salad mãi như app nước ngoài. Giảm 5kg trong 2 tháng.',
                        ),
                        SizedBox(height: 12),
                        _TestimonialCard(
                          name: 'Tuấn Kiệt',
                          role: 'Developer, 32 tuổi',
                          quote:
                              'Bài tập ngắn gọn, tập ở nhà được. Hợp với dân IT. AI Coach trả lời rất thực tế.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppPalette.emerald, Color(0xFF18C290)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Bắt đầu ngay hôm nay',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Hành trình sức khỏe của bạn chỉ cách 2 phút.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 18),
                        GradientActionButton(
                          label: 'Đăng ký miễn phí ngay',
                          onPressed: controller.openIntro,
                          colors: const [Colors.white, Color(0xFFF1FFF9)],
                          foregroundColor: AppPalette.emeraldDeep,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '© 2026 CoreHealth • Bảo mật dữ liệu sức khỏe',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.headlineSmall?.copyWith(fontSize: 30)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: textTheme.bodyLarge),
        ],
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _WelcomeStat extends StatelessWidget {
  const _WelcomeStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      child: Column(
        children: [
          Icon(icon, color: AppPalette.emerald),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppPalette.emerald),
          const SizedBox(width: 8),
          Text(
            label,
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

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.active,
    required this.colors,
    required this.icon,
    required this.title,
    required this.description,
  });

  final bool active;
  final List<Color> colors;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      transform: Matrix4.diagonal3Values(active ? 1.01 : 1.0, active ? 1.01 : 1.0, 1.0),
      child: AppCard(
        border: BorderSide(
          color: active ? colors.first : AppPalette.border,
          width: active ? 2 : 1,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
            if (active)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.circle, color: AppPalette.emerald, size: 10),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  const _MiniFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      color: AppPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppPalette.emeraldSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppPalette.emerald),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.title,
    required this.price,
    required this.features,
    this.highlight = false,
    this.badge,
  });

  final String title;
  final String price;
  final List<String> features;
  final bool highlight;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: highlight
                ? const LinearGradient(
                    colors: [AppPalette.emerald, Color(0xFF18C290)],
                  )
                : null,
            color: highlight ? null : AppPalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: highlight ? Colors.transparent : AppPalette.border,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadow,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: highlight ? Colors.white : AppPalette.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: textTheme.headlineSmall?.copyWith(
                  color: highlight ? Colors.white : AppPalette.emerald,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: highlight ? Colors.white : AppPalette.emerald,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: textTheme.bodyMedium?.copyWith(
                            color: highlight
                                ? Colors.white.withValues(alpha: 0.92)
                                : AppPalette.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -12,
            left: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppPalette.orange,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.name,
    required this.role,
    required this.quote,
  });

  final String name;
  final String role;
  final String quote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppPalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Padding(
                padding: EdgeInsets.only(right: 4),
                child:
                    Icon(Icons.star_rounded, size: 18, color: AppPalette.gold),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '“$quote”',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppPalette.text,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(role),
        ],
      ),
    );
  }
}
