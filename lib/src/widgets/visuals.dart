import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import 'adaptive.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.card,
    this.color = AppPalette.surface,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final resolvedBorder = border == null
        ? Border.all(color: AppPalette.borderLight)
        : Border.fromBorderSide(border!);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: resolvedBorder,
        boxShadow: const [
          BoxShadow(
            color: AppPalette.shadow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.colors,
    this.icon,
    this.height = 56,
    this.foregroundColor = Colors.white,
    this.radius = AppRadius.button,
  });

  final String label;
  final VoidCallback onPressed;
  final List<Color> colors;
  final Widget? icon;
  final double height;
  final Color foregroundColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shadowColor = colors.first.withValues(alpha: 0.18);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 10),
              ],
              Flexible(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }
}

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppActionButtonVariant.primary,
    this.height = 54,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppActionButtonVariant variant;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isPrimary = variant == AppActionButtonVariant.primary;
    final foreground = isPrimary
        ? Colors.white
        : enabled
            ? AppPalette.emeraldDeep
            : AppPalette.subtleText;
    final background = isPrimary
        ? (enabled ? AppPalette.emerald : const Color(0xFFB9C6D2))
        : (enabled ? AppPalette.emeraldSoft : AppPalette.surfaceElevated);
    final border = isPrimary
        ? BorderSide.none
        : BorderSide(
            color: enabled ? AppPalette.emeraldSoft : AppPalette.border,
          );

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(color: foreground, size: 19),
            child: icon!,
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.fromBorderSide(border),
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

enum AppActionButtonVariant { primary, secondary }

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppPalette.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppPalette.mutedText, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final Widget? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: textTheme.titleMedium,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    final tilePadding = isCompact ? 12.0 : 14.0;
    final iconSize = isCompact ? 36.0 : 38.0;
    final labelFontSize = isCompact ? 12.0 : 13.0;
    final valueFontSize = isCompact ? 18.0 : 20.0;
    final card = AppCard(
      radius: 24,
      padding: EdgeInsets.all(tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: colors.first.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.first, size: isCompact ? 19 : 20),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: AppPalette.text,
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isCompact ? 3 : 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: valueFontSize,
              height: 1.08,
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: isCompact ? 4 : 5),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: isCompact ? 10.2 : 11.0,
                    height: 1.15,
                    color: AppPalette.mutedText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

class CoreHealthBottomNav extends StatelessWidget {
  const CoreHealthBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCoachTap,
    this.onMoreTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCoachTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final layout = PhoneLayout.of(context);
    final leftItems = <({IconData icon, String label, int tabIndex})>[
      (icon: Icons.home_rounded, label: 'Trang', tabIndex: 0),
      (icon: Icons.restaurant_menu_rounded, label: 'Ăn', tabIndex: 1),
      (icon: Icons.fitness_center_rounded, label: 'Tập', tabIndex: 2),
    ];
    final rightItems =
        <({IconData icon, String label, int? tabIndex, VoidCallback? action})>[
      (
        icon: Icons.shopping_bag_rounded,
        label: 'Cửa hàng',
        tabIndex: 3,
        action: null
      ),
      (icon: Icons.person_rounded, label: 'Tôi', tabIndex: 4, action: null),
      (
        icon: Icons.more_horiz_rounded,
        label: 'Xem thêm',
        tabIndex: null,
        action: onMoreTap
      ),
    ];
    final navHeight = layout.isCompact ? 70.0 : 76.0;
    final coachSize = layout.isCompact ? 58.0 : 64.0;
    final centerSlotWidth = layout.isCompact ? 66.0 : 76.0;
    final totalHeight = navHeight + 30;
    final itemLabelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: layout.isCompact ? 9.0 : 9.6,
          height: 1,
          fontWeight: FontWeight.w800,
        );

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(
        layout.isCompact ? 6 : 10,
        0,
        layout.isCompact ? 6 : 10,
        10,
      ),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: navHeight,
                padding: EdgeInsets.fromLTRB(
                  layout.isCompact ? 8 : 12,
                  8,
                  layout.isCompact ? 8 : 12,
                  8,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.surface.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppPalette.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppPalette.shadowHeavy,
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: leftItems
                            .map(
                              (item) => Expanded(
                                child: _CoreHealthNavItem(
                                  icon: item.icon,
                                  label: item.label,
                                  selected: currentIndex == item.tabIndex,
                                  labelStyle: itemLabelStyle,
                                  onTap: () => onTap(item.tabIndex),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(width: centerSlotWidth),
                    Expanded(
                      child: Row(
                        children: rightItems
                            .map(
                              (item) => Expanded(
                                child: _CoreHealthNavItem(
                                  icon: item.icon,
                                  label: item.label,
                                  selected: item.tabIndex == currentIndex,
                                  labelStyle: itemLabelStyle,
                                  onTap: () {
                                    final tabIndex = item.tabIndex;
                                    if (tabIndex == null) {
                                      item.action?.call();
                                      return;
                                    }
                                    onTap(tabIndex);
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onCoachTap,
                    child: Container(
                      width: coachSize,
                      height: coachSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppPalette.emerald, AppPalette.emeraldDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.emerald.withValues(alpha: 0.34),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: AppPalette.background,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: centerSlotWidth,
                    child: Text(
                      'AI Coach',
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      textAlign: TextAlign.center,
                      style: itemLabelStyle?.copyWith(
                        color: AppPalette.text,
                        fontSize: layout.isCompact ? 9.6 : 10.8,
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

class _CoreHealthNavItem extends StatelessWidget {
  const _CoreHealthNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.labelStyle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppPalette.text : AppPalette.subtleText;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  width: 32,
                  height: 30,
                  decoration: BoxDecoration(
                    color:
                        selected ? AppPalette.accentSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    textAlign: TextAlign.center,
                    style: labelStyle?.copyWith(color: color),
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

class FloatingAiMenu extends StatelessWidget {
  const FloatingAiMenu({
    super.key,
    required this.expanded,
    required this.onToggle,
    required this.onCoachTap,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<CoachType> onCoachTap;

  @override
  Widget build(BuildContext context) {
    const options = [
      _CoachAction(
        type: CoachType.nutrition,
        title: 'AI Meal Coach',
        subtitle: 'Dinh dưỡng',
        icon: Icons.restaurant_rounded,
        colors: [AppPalette.orange, Color(0xFFFFA955)],
      ),
      _CoachAction(
        type: CoachType.workout,
        title: 'AI Workout Coach',
        subtitle: 'Tập luyện',
        icon: Icons.bolt_rounded,
        colors: [AppPalette.blue, Color(0xFF67A1FF)],
      ),
      _CoachAction(
        type: CoachType.wellness,
        title: 'AI Assistant',
        subtitle: 'Tổng quát',
        icon: Icons.auto_awesome_rounded,
        colors: [AppPalette.emerald, AppPalette.emeraldDeep],
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (expanded)
          ...options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: option.colors),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: AppPalette.shadow,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onCoachTap(option.type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(option.icon, color: Colors.white),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              option.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            Text(
                              option.subtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: expanded
                  ? const [Color(0xFFE75252), Color(0xFFFF7D7D)]
                  : const [AppPalette.emerald, Color(0xFF29D38E)],
            ),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadow,
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onToggle,
            iconSize: 30,
            padding: const EdgeInsets.all(18),
            icon: Icon(
              expanded ? Icons.close_rounded : Icons.smart_toy_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.height,
    this.width,
    this.radius = 28,
  });

  final String url;
  final double height;
  final double? width;
  final double radius;

  Widget _placeholder(BuildContext context) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: [AppPalette.emeraldSoft, AppPalette.mint],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined,
            color: AppPalette.subtleText),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppPalette.mint,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        errorWidget: (context, _, __) => _placeholder(context),
      ),
    );
  }
}

class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.values,
    required this.strokeColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color strokeColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          strokeColor: strokeColor,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.strokeColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color strokeColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1);
    final step = size.width / (values.length - 1);
    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = step * i;
      final normalized = (values[i] - minValue) / range;
      final y = size.height - (normalized * (size.height - 18)) - 12;
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
      fillPath.lineTo(point.dx, point.dy);
    }

    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    final gridPaint = Paint()
      ..color = AppPalette.border.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = 12 + i * ((size.height - 24) / 3);
      canvas.drawLine(
          Offset.zero.translate(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            fillColor.withValues(alpha: 0.32),
            fillColor.withValues(alpha: 0.04)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3.5, Paint()..color = strokeColor);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.fillColor != fillColor;
  }
}

Future<void> showCoachSheet(BuildContext context, CoachType type) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CoachChatSheet(type: type, parentContext: context),
  );
}

class _CoachChatSheet extends StatefulWidget {
  const _CoachChatSheet({required this.type, required this.parentContext});

  final CoachType type;
  final BuildContext parentContext;

  @override
  State<_CoachChatSheet> createState() => _CoachChatSheetState();
}

class _CoachChatSheetState extends State<_CoachChatSheet> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isInChatView = false;
  String _selectedCategory = 'All';

  (String, String, List<Color>) get _config => switch (widget.type) {
        CoachType.nutrition => (
            'AI Meal Coach',
            'Tối ưu macro cho món Việt',
            [AppPalette.orange, const Color(0xFFFFAF66)],
          ),
        CoachType.workout => (
            'AI Workout Coach',
            'Điều tiết cường độ tập thông minh',
            [AppPalette.blue, const Color(0xFF73A9FF)],
          ),
        CoachType.wellness => (
            'AI Assistant',
            'Nhìn toàn cảnh tiến trình sức khỏe',
            [AppPalette.emerald, AppPalette.emeraldDeep],
          ),
      };

  AppController get _controller => CoreHealthScope.of(widget.parentContext);

  @override
  void initState() {
    super.initState();
    _isInChatView = _controller.chatSessions.isEmpty;
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendSessionChat() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _controller.sendSessionChatMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasAccess = _controller.profile.canAccessCoach(widget.type);

    if (!hasAccess) {
      final requiredPlan = switch (widget.type) {
        CoachType.nutrition => 'CoreHealth Meal hoặc Max',
        CoachType.workout => 'CoreHealth Workout hoặc Max',
        CoachType.wellness => 'gói trả phí bất kỳ',
      };
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 22 + bottomInset),
        child: AppCard(
          radius: 34,
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: config.$3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_outline_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      config.$1,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    Text(
                      'Tính năng này yêu cầu $requiredPlan để sử dụng.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    GradientActionButton(
                      label: 'Nâng cấp để mở khóa',
                      icon:
                          const Icon(Icons.workspace_premium_rounded, size: 18),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      colors: config.$3,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Để sau',
                          style: TextStyle(color: config.$3.first)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final sessions = _controller.chatSessions;
        final activeSession = _controller.activeChatSession;
        final loading = _controller.isWellnessChatLoading;

        if (_isInChatView &&
            activeSession != null &&
            activeSession.history.isNotEmpty) {
          _scrollToBottom();
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 22 + bottomInset),
          child: AppCard(
            radius: 34,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: (MediaQuery.of(context).size.height * 0.65)
                  .clamp(380.0, 580.0),
              child: _isInChatView
                  ? _buildChatView(context, activeSession, loading, config)
                  : _buildHistoryView(context, sessions, config),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryView(
    BuildContext context,
    List<ChatSession> sessions,
    (String, String, List<Color>) config,
  ) {
    final filteredSessions = sessions.where((s) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.title.toLowerCase().contains(query) ||
          s.history.any((m) => m.text.toLowerCase().contains(query));

      final matchesCategory =
          _selectedCategory == 'All' || s.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    final categoriesList = ['All', 'Workout', 'Nutrition', 'Form', 'General'];
    final categoryLabels = {
      'All': 'Tất cả',
      'Workout': 'Tập luyện',
      'Nutrition': 'Dinh dưỡng',
      'Form': 'Tư thế',
      'General': 'Chung',
    };

    final badgeConfig = {
      'Workout': (AppPalette.blueSoft, AppPalette.blue, 'Tập luyện'),
      'Nutrition': (AppPalette.orangeSoft, AppPalette.orange, 'Dinh dưỡng'),
      'Form': (AppPalette.emeraldSoft, AppPalette.emeraldDeep, 'Tư thế'),
      'General': (AppPalette.mint, AppPalette.emeraldDeep, 'Chung'),
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: config.$3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Coach History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lịch sử trò chuyện với AI',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm cuộc hội thoại...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppPalette.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  _controller.startNewChatSession();
                  setState(() {
                    _isInChatView = true;
                  });
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: config.$3.first,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Mới',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categoriesList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = categoriesList[idx];
                final isSelected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? config.$3.first
                          : AppPalette.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Colors.transparent : AppPalette.border,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: config.$3.first.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categoryLabels[cat]!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppPalette.mutedText,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: filteredSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          color: Colors.grey.withValues(alpha: 0.3), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có cuộc trò chuyện nào',
                        style: TextStyle(color: AppPalette.mutedText),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: filteredSessions.length,
                  itemBuilder: (context, index) {
                    final session = filteredSessions[index];
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(session.ts);
                    final dateStr =
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                    final lastMsg = session.history.isNotEmpty
                        ? session.history.last.text
                        : 'Cuộc trò chuyện mới';

                    final bConfig = badgeConfig[session.category] ??
                        badgeConfig['General']!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: AppPalette.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppPalette.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          _controller.selectChatSession(session.id);
                          setState(() {
                            _isInChatView = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: config.$3.first.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.forum_rounded,
                                    color: config.$3.first, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  session.title,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      fontSize: 14),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: bConfig.$1,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  bConfig.$3,
                                                  style: TextStyle(
                                                    color: bConfig.$2,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                              color: AppPalette.mutedText,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMsg,
                                      style: const TextStyle(
                                          color: AppPalette.mutedText,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  _controller.deleteChatSession(session.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatView(
    BuildContext context,
    ChatSession? session,
    bool loading,
    (String, String, List<Color>) config,
  ) {
    final history = session?.history ?? const <ChatMessage>[];

    final suggestions = [
      'Tôi nên ăn gì trước khi tập?',
      'Lịch tập cho người mới bắt đầu?',
      'Cách cải thiện giấc ngủ hiệu quả?',
      'Cách tính calo tiêu thụ hàng ngày?'
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 16, 20, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: config.$3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 20),
                onPressed: () {
                  setState(() {
                    _isInChatView = false;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.title ?? 'Cuộc trò chuyện mới',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Coach • Online & Monitoring',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              if (session != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white70),
                  tooltip: 'Xoá lịch sử',
                  onPressed: () {
                    _controller.deleteChatSession(session.id);
                    setState(() {
                      _isInChatView = false;
                    });
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: history.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: config.$3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Xin chào! Tôi là AI Coach của bạn.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Hỏi tôi bất cứ điều gì về chế độ ăn uống, bài tập thể hình hoặc thói quen sống lành mạnh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppPalette.mutedText, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: suggestions
                              .map((s) => ActionChip(
                                    label: Text(s,
                                        style: const TextStyle(fontSize: 11)),
                                    backgroundColor: AppPalette.surfaceElevated,
                                    onPressed: () {
                                      _textController.text = s;
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: history.length + (loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == history.length) {
                      return _TypingIndicator(colors: config.$3);
                    }
                    final msg = history[index];
                    return _ChatBubble(
                      message: msg,
                      colors: config.$3,
                    );
                  },
                ),
        ),
        if (history.isNotEmpty && !loading)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: suggestions
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppPalette.surfaceElevated,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            _textController.text = s;
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Nhắn tin cho AI Coach...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppPalette.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendSessionChat(),
                  enabled: !loading,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: loading ? null : _sendSessionChat,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient:
                        loading ? null : LinearGradient(colors: config.$3),
                    color: loading ? AppPalette.border : null,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    loading
                        ? Icons.hourglass_empty_rounded
                        : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.colors});

  final ChatMessage message;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? LinearGradient(colors: colors) : null,
                color: isUser ? null : AppPalette.surfaceElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser ? Colors.white : null,
                    ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.colors});
  final List<Color> colors;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.colors),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Row(
              children: List.generate(3, (i) {
                final delay = i * 0.3;
                final opacity =
                    (math.sin((_controller.value * math.pi) - delay) + 1) / 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.colors.first
                          .withValues(alpha: opacity.clamp(0.2, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAction {
  const _CoachAction({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final CoachType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}

/// A reusable selector field that opens a bottom sheet with options.
/// Matches the app's input field style (borderRadius 22, surfaceElevated).
class CoreHealthSelector<T> extends StatelessWidget {
  const CoreHealthSelector({
    super.key,
    required this.label,
    required this.value,
    required this.displayText,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  final String label;
  final T value;
  final String Function(T value) displayText;
  final List<({T value, String label, IconData? icon})> options;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null ? Icon(icon, color: AppPalette.emerald) : null,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppPalette.mutedText),
          filled: true,
          fillColor: AppPalette.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: AppPalette.border),
          ),
        ),
        child: Text(
          displayText(value),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppPalette.borderLight),
            boxShadow: const [
              BoxShadow(
                color: AppPalette.shadowHeavy,
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...options.map((option) {
                final selected = option.value == value;
                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  leading: option.icon != null
                      ? Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppPalette.emeraldSoft
                                : AppPalette.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            option.icon,
                            color: selected
                                ? AppPalette.emerald
                                : AppPalette.mutedText,
                            size: 18,
                          ),
                        )
                      : null,
                  title: Text(
                    option.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? AppPalette.emeraldDeep : null,
                        ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded,
                          color: AppPalette.emerald, size: 20)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: () {
                    onChanged(option.value);
                    Navigator.of(sheetContext).pop();
                  },
                );
              }),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
            ],
          ),
        );
      },
    );
  }
}

/// Shows a centered translucent toast with a check icon and "Đã thêm vào giỏ" text.
/// Auto-dismisses after [duration].
void showCartAddedOverlay(BuildContext context,
    {Duration duration = const Duration(milliseconds: 1500)}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _CartAddedToast(
      duration: duration,
      onDismiss: () => entry.remove(),
    ),
  );

  overlay.insert(entry);
}

class _CartAddedToast extends StatefulWidget {
  const _CartAddedToast({required this.duration, required this.onDismiss});

  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_CartAddedToast> createState() => _CartAddedToastState();
}

class _CartAddedToastState extends State<_CartAddedToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Đã thêm vào giỏ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
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

/// Unified icon button used across all screens for back, cart, etc.
/// Consistent 44x44 rounded container with surface background and shadow.
class CoreHealthIconButton extends StatelessWidget {
  const CoreHealthIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge,
    this.size = 44,
    this.borderRadius = 14,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final hasBadge = badge != null && badge! > 0;

    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppPalette.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: const [
            BoxShadow(
              color: AppPalette.shadow,
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: AppPalette.text, size: 22),
      ),
    );

    if (!hasBadge) return button;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 8,
            child: button,
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.orange,
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.surface, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$badge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified AppBar used across sub-pages (cart, checkout, history, edit profile, etc.)
class CoreHealthSubPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CoreHealthSubPageAppBar({
    super.key,
    required this.title,
    this.showCart = false,
    this.cartCount = 0,
    this.onCartTap,
    this.actions,
  });

  final String title;
  final bool showCart;
  final int cartCount;
  final VoidCallback? onCartTap;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Center(
          child: CoreHealthIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      centerTitle: true,
      actions: [
        if (showCart && onCartTap != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CoreHealthIconButton(
              icon: Icons.shopping_cart_outlined,
              badge: cartCount > 0 ? cartCount : null,
              onTap: onCartTap!,
            ),
          ),
        if (actions != null) ...actions!,
      ],
    );
  }
}
