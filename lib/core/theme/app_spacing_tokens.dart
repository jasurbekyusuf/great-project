import 'package:flutter/material.dart';

@immutable
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens> {
  const AppSpacingTokens({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.controlHeightSm,
    required this.controlHeight,
    required this.footerBarHeight,
    required this.pageHeadHeight,
    required this.tabsHeight,
  });

  final double xxs; // 2
  final double xs;  // 4
  final double sm;  // 8
  final double md;  // 12
  final double lg;  // 16
  final double xl;  // 24
  final double xxl; // 32

  final double radiusXs;   // 4
  final double radiusSm;   // 8
  final double radiusMd;   // 12
  final double radiusLg;   // 16
  final double radiusXl;   // 24
  final double radiusPill; // 999

  final double controlHeightSm; // 36
  final double controlHeight;   // 44 (button + input)
  final double footerBarHeight; // 52
  final double pageHeadHeight;  // 52
  final double tabsHeight;      // 40

  static const base = AppSpacingTokens(
    xxs: 2,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xxl: 32,
    radiusXs: 4,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusXl: 24,
    radiusPill: 999,
    controlHeightSm: 36,
    controlHeight: 44,
    footerBarHeight: 52,
    pageHeadHeight: 52,
    tabsHeight: 40,
  );

  @override
  AppSpacingTokens copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusPill,
    double? controlHeightSm,
    double? controlHeight,
    double? footerBarHeight,
    double? pageHeadHeight,
    double? tabsHeight,
  }) {
    return AppSpacingTokens(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusPill: radiusPill ?? this.radiusPill,
      controlHeightSm: controlHeightSm ?? this.controlHeightSm,
      controlHeight: controlHeight ?? this.controlHeight,
      footerBarHeight: footerBarHeight ?? this.footerBarHeight,
      pageHeadHeight: pageHeadHeight ?? this.pageHeadHeight,
      tabsHeight: tabsHeight ?? this.tabsHeight,
    );
  }

  @override
  ThemeExtension<AppSpacingTokens> lerp(covariant ThemeExtension<AppSpacingTokens>? other, double t) {
    if (other is! AppSpacingTokens) return this;
    double l(double a, double b) => a + (b - a) * t;
    return AppSpacingTokens(
      xxs: l(xxs, other.xxs),
      xs: l(xs, other.xs),
      sm: l(sm, other.sm),
      md: l(md, other.md),
      lg: l(lg, other.lg),
      xl: l(xl, other.xl),
      xxl: l(xxl, other.xxl),
      radiusXs: l(radiusXs, other.radiusXs),
      radiusSm: l(radiusSm, other.radiusSm),
      radiusMd: l(radiusMd, other.radiusMd),
      radiusLg: l(radiusLg, other.radiusLg),
      radiusXl: l(radiusXl, other.radiusXl),
      radiusPill: l(radiusPill, other.radiusPill),
      controlHeightSm: l(controlHeightSm, other.controlHeightSm),
      controlHeight: l(controlHeight, other.controlHeight),
      footerBarHeight: l(footerBarHeight, other.footerBarHeight),
      pageHeadHeight: l(pageHeadHeight, other.pageHeadHeight),
      tabsHeight: l(tabsHeight, other.tabsHeight),
    );
  }
}
