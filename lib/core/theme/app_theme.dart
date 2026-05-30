import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loadme_mobile/core/theme/app_color_tokens.dart';
import 'package:loadme_mobile/core/theme/app_spacing_tokens.dart';
import 'package:loadme_mobile/core/theme/app_typography_tokens.dart';

class AppTheme {
  const AppTheme._();

  static TextTheme _textTheme(AppTypographyTokens t) => TextTheme(
        displayLarge: t.display,
        headlineLarge: t.h1,
        headlineMedium: t.h2,
        titleLarge: t.h2,
        titleMedium: t.h3,
        bodyLarge: t.bodyLg,
        bodyMedium: t.body,
        bodySmall: t.caption,
        labelLarge: t.button,
        labelMedium: t.captionStrong,
        labelSmall: t.overline,
      );

  static ThemeData _build(AppColorTokens c, {required Brightness brightness}) {
    final t = AppTypographyTokens.of(c.textPrimary, c.textSecondary);
    const spacing = AppSpacingTokens.base;

    final base = brightness == Brightness.light
        ? const ColorScheme.light()
        : const ColorScheme.dark();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: GoogleFonts.interTextTheme(_textTheme(t)),
      scaffoldBackgroundColor: c.background,
      colorScheme: base.copyWith(
        primary: c.primary,
        onPrimary: Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.error,
        outline: c.border,
      ),
      extensions: [c, spacing, t],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: c.surface,
        foregroundColor: c.textPrimary,
        titleTextStyle: t.h3,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: c.borderSubtle, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.textPrimary, size: 22),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(spacing.controlHeight)),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return c.primaryDisabled;
            if (s.contains(WidgetState.pressed)) return c.primary700;
            if (s.contains(WidgetState.hovered)) return c.primaryHover;
            return c.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(t.button.copyWith(color: Colors.white)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusSm)),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.fromHeight(spacing.controlHeight)),
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          textStyle: WidgetStatePropertyAll(t.button),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusSm)),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.primary),
          textStyle: WidgetStatePropertyAll(t.button),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusSm)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        constraints: BoxConstraints(minHeight: spacing.controlHeight),
        hintStyle: t.input.copyWith(color: c.textMuted),
        labelStyle: t.bodyMedium.copyWith(color: c.textSecondary),
        floatingLabelStyle: t.bodyMedium.copyWith(color: c.primary),
        // Web inputs have no visible border by default — only on focus.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          borderSide: BorderSide(color: c.inputFocusBorder, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          borderSide: BorderSide(color: c.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(spacing.radiusSm),
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing.radiusLg),
          side: BorderSide(color: c.border, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(spacing.radiusXl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(spacing.radiusLg)),
        titleTextStyle: t.h3,
        contentTextStyle: t.body,
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }

  static ThemeData light() => _build(AppColorTokens.light, brightness: Brightness.light);
  static ThemeData dark() => _build(AppColorTokens.dark, brightness: Brightness.dark);
}
