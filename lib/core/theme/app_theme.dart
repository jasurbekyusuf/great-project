import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/app_color_tokens.dart';
import 'package:loadme_mobile/core/theme/app_spacing_tokens.dart';

class AppTheme {
  const AppTheme._();

  static TextTheme _textTheme(Color textPrimary, Color textSecondary) => TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      );

  static ThemeData light() {
    const colors = AppColorTokens.light;
    const spacing = AppSpacingTokens.base;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.light().copyWith(
        primary: colors.primary,
        surface: colors.surface,
        error: colors.error,
      ),
      extensions: const [colors, spacing],
      textTheme: _textTheme(colors.textPrimary, colors.textSecondary),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const colors = AppColorTokens.dark;
    const spacing = AppSpacingTokens.base;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colors.background,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: colors.primary,
        surface: colors.surface,
        error: colors.error,
      ),
      extensions: const [colors, spacing],
      textTheme: _textTheme(colors.textPrimary, colors.textSecondary),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}
