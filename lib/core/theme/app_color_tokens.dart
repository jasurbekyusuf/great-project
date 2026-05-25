import 'package:flutter/material.dart';

@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.primary,
    required this.textPrimary,
    required this.textSecondary,
    required this.background,
    required this.surface,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color primary;
  final Color textPrimary;
  final Color textSecondary;
  final Color background;
  final Color surface;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;

  static const light = AppColorTokens(
    primary: Color(0xFF004EEB),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF475467),
    background: Color(0xFFF9FAFB),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFEAECF0),
    success: Color(0xFF099250),
    warning: Color(0xFFD97706),
    error: Color(0xFFD92D20),
  );

  static const dark = AppColorTokens(
    primary: Color(0xFF2970FF),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFF98A2B3),
    background: Color(0xFF0B1220),
    surface: Color(0xFF111827),
    border: Color(0xFF1D2939),
    success: Color(0xFF12B76A),
    warning: Color(0xFFF79009),
    error: Color(0xFFF04438),
  );

  @override
  AppColorTokens copyWith({
    Color? primary,
    Color? textPrimary,
    Color? textSecondary,
    Color? background,
    Color? surface,
    Color? border,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppColorTokens(
      primary: primary ?? this.primary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  ThemeExtension<AppColorTokens> lerp(covariant ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    return AppColorTokens(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      border: Color.lerp(border, other.border, t) ?? border,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      error: Color.lerp(error, other.error, t) ?? error,
    );
  }
}
