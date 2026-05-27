import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../theme.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  static const _logoAsset = 'assets/images/logocorehealth.png';
  static const _heroImageUrl =
      'https://images.unsplash.com/photo-1598514982205-f36b96d1e8d4?auto=format&fit=crop&q=80&w=1000';

  static const _green = Color(0xFF8DC63F);
  static const _gray50 = Color(0xFFF9FAFB);
  static const _gray100 = Color(0xFFF3F4F6);
  static const _gray300 = Color(0xFFD1D5DB);
  static const _gray400 = Color(0xFF9CA3AF);
  static const _gray800 = Color(0xFF1F2937);
  static const _gray900 = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);

    return Scaffold(
      backgroundColor: AppPalette.surface,
      body: SizedBox.expand(
        child: ClipRect(
          child: Stack(
            children: [
              const Positioned.fill(child: _FullHeightHeroImage()),
              const Positioned.fill(child: _IntroScrim()),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _IntroNutritionLinePainter(),
                  ),
                ),
              ),
              const Positioned(
                top: 350,
                left: 32,
                child: _CaloriePill(label: '504 Kcal'),
              ),
              const Positioned(
                top: 320,
                left: 148,
                child: _CaloriePill(label: '132 Kcal'),
              ),
              const Positioned(
                top: 392,
                right: 20,
                child: _CaloriePill(label: '320 Kcal'),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            _logoAsset,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CoreHealth',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: _gray900,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  letterSpacing: -0.2,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: _gray900,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                                letterSpacing: -0.4,
                              ),
                          children: const [
                            TextSpan(text: 'Dẫn lối mỗi ngày\n'),
                            TextSpan(text: 'để '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: _FlameBadge(),
                            ),
                            TextSpan(text: ' ăn uống\nthông minh hơn.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: MediaQuery.paddingOf(context).bottom + 24,
                child: _IntroCtaBar(
                  onStart: controller.goToWelcome,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullHeightHeroImage extends StatelessWidget {
  const _FullHeightHeroImage();

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: IntroScreen._heroImageUrl,
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      placeholder: (_, __) => const _IntroImageFallback(),
      errorWidget: (_, __, ___) => const _IntroImageFallback(),
    );
  }
}

class _IntroScrim extends StatelessWidget {
  const _IntroScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppPalette.surface.withValues(alpha: 0.95),
            AppPalette.surface.withValues(alpha: 0.78),
            AppPalette.surface.withValues(alpha: 0.22),
            Colors.transparent,
          ],
          stops: const [0, 0.28, 0.56, 1],
        ),
      ),
    );
  }
}

class _FlameBadge extends StatelessWidget {
  const _FlameBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: const BoxDecoration(
        color: IntroScreen._green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: AppPalette.surface,
        size: 22,
      ),
    );
  }
}

class _IntroCtaBar extends StatefulWidget {
  const _IntroCtaBar({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_IntroCtaBar> createState() => _IntroCtaBarState();
}

class _IntroCtaBarState extends State<_IntroCtaBar>
    with SingleTickerProviderStateMixin {
  static const _thumbSize = 56.0;
  static const _barHeight = 72.0;
  static const _padding = 8.0;
  static const _threshold = 0.7;

  double _dragOffset = 0;
  bool _triggered = false;

  late final AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        setState(() {
          _dragOffset = _resetAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  TickerFuture _animateThumb(double target) {
    _resetAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    return _resetController.forward(from: 0);
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_triggered) return;
    _resetController.stop();
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_triggered) return;
    final progress = maxDrag > 0 ? _dragOffset / maxDrag : 0.0;
    final velocity = details.primaryVelocity ?? 0;

    if (progress >= _threshold || velocity > 700) {
      _triggered = true;
      _animateThumb(maxDrag).then((_) => widget.onStart());
    } else {
      _animateThumb(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - _padding * 2;
        final progress = maxDrag > 0 ? _dragOffset / maxDrag : 0.0;

        return Container(
          height: _barHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(_barHeight / 2),
            border: Border.all(color: IntroScreen._gray50),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 30,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: (1 - progress * 1.6).clamp(0.0, 1.0),
                  child: Text(
                    'Kéo để bắt đầu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: IntroScreen._gray900,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              Positioned(
                right: _padding,
                child: Opacity(
                  opacity: (progress * 2).clamp(0.0, 1.0),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: IntroScreen._gray50,
                      shape: BoxShape.circle,
                      border: Border.all(color: IntroScreen._gray100),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: IntroScreen._gray400,
                      size: 23,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _padding + _dragOffset,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    _onDragUpdate(details, maxDrag);
                  },
                  onHorizontalDragEnd: (details) {
                    _onDragEnd(details, maxDrag);
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: const BoxDecoration(
                      color: IntroScreen._green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: AppPalette.surface,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CaloriePill extends StatelessWidget {
  const _CaloriePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppPalette.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: IntroScreen._gray100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: IntroScreen._gray800,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
          ),
        ),
      ),
    );
  }
}

class _IntroImageFallback extends StatelessWidget {
  const _IntroImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.surface,
      alignment: Alignment.bottomCenter,
      child: const Padding(
        padding: EdgeInsets.only(bottom: 90),
        child: Icon(
          Icons.spa_rounded,
          size: 120,
          color: IntroScreen._green,
        ),
      ),
    );
  }
}

class _IntroNutritionLinePainter extends CustomPainter {
  const _IntroNutritionLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 400;
    final scaleY = size.height / 760;
    Offset p(double x, double y) => Offset(x * scaleX, y * scaleY);

    final linePaint = Paint()
      ..color = IntroScreen._gray300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = IntroScreen._gray300
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = AppPalette.surface
      ..style = PaintingStyle.fill;

    final paths = [
      [p(80, 410), p(62, 490), p(104, 620)],
      [p(200, 372), p(182, 474), p(220, 590)],
      [p(320, 438), p(320, 536), p(260, 626)],
    ];

    for (final points in paths) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, linePaint);

      for (var i = 0; i < points.length; i++) {
        if (i == points.length - 1) {
          canvas
            ..drawCircle(points[i], 4, ringPaint)
            ..drawCircle(points[i], 4, linePaint);
        } else {
          canvas.drawCircle(points[i], 3, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IntroNutritionLinePainter oldDelegate) => false;
}
