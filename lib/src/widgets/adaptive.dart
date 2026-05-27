import 'package:flutter/material.dart';

class PhoneLayout {
  const PhoneLayout._(this.width);

  factory PhoneLayout.of(BuildContext context) {
    return PhoneLayout._(MediaQuery.sizeOf(context).width);
  }

  final double width;

  /// Very small phones: iPhone SE (375pt), older Android (360pt wide)
  bool get isTiny => width < 390;
  bool get isCompact => width < 360;
  bool get isStandard => width >= 360 && width < 430;
  bool get isLargePhone => width >= 430;
  /// Tablet / foldable unfolded
  bool get isTablet => width >= 600;

  double get horizontalPadding {
    if (isCompact) return 14;
    if (isTiny) return 16; // SE gets slightly less padding
    if (isLargePhone) return 24;
    return 20;
  }

  double get maxContentWidth => isTablet ? 680 : isLargePhone ? 560 : width;

  double get headlineSize {
    if (isCompact) return 36;
    if (isTiny) return 40; // SE
    if (isLargePhone) return 56;
    return 48;
  }

  /// Height of the bottom navigation bar (excluding safe area inset).
  double get navBarHeight => isTiny ? 64 : isCompact ? 68 : 74;

  bool get showBottomNavLabels => width >= 350;

  int columnsFor({
    required double minCardWidth,
    int maxColumns = 3,
  }) {
    final columns = (width / minCardWidth).floor();
    return columns.clamp(1, maxColumns);
  }
}

class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({
    super.key,
    required this.child,
    this.maxWidth,
  });

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final layout = PhoneLayout.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? layout.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
