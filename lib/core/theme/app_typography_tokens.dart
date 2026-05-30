import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Mirrors web typography scale used across mobile screens.
// Font family: Inter (loaded via google_fonts).
@immutable
class AppTypographyTokens extends ThemeExtension<AppTypographyTokens> {
  const AppTypographyTokens({
    required this.display,        // 28 / 36 / 700
    required this.h1,             // 24 / 32 / 700
    required this.h2,             // 20 / 28 / 600
    required this.h3,             // 18 / 26 / 600
    required this.bodyLg,         // 16 / 24 / 400
    required this.bodyLgMedium,   // 16 / 24 / 500
    required this.body,           // 14 / 20 / 400
    required this.bodyMedium,     // 14 / 20 / 500
    required this.bodySemibold,   // 14 / 20 / 600
    required this.caption,        // 12 / 18 / 500
    required this.captionStrong,  // 12 / 18 / 600
    required this.overline,       // 10 / 16 / 600 (footer/tab labels)
    required this.button,         // 14 / 20 / 600
    required this.input,          // 14 / 20 / 400
  });

  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle bodyLg;
  final TextStyle bodyLgMedium;
  final TextStyle body;
  final TextStyle bodyMedium;
  final TextStyle bodySemibold;
  final TextStyle caption;
  final TextStyle captionStrong;
  final TextStyle overline;
  final TextStyle button;
  final TextStyle input;

  static AppTypographyTokens of(Color textPrimary, Color textSecondary) {
    TextStyle s(double size, double height, FontWeight weight, Color color) => GoogleFonts.inter(
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          color: color,
          letterSpacing: 0,
        );
    return AppTypographyTokens(
      display: s(28, 36, FontWeight.w700, textPrimary),
      h1: s(24, 32, FontWeight.w700, textPrimary),
      h2: s(20, 28, FontWeight.w600, textPrimary),
      h3: s(18, 26, FontWeight.w600, textPrimary),
      bodyLg: s(16, 24, FontWeight.w400, textPrimary),
      bodyLgMedium: s(16, 24, FontWeight.w500, textPrimary),
      body: s(14, 20, FontWeight.w400, textPrimary),
      bodyMedium: s(14, 20, FontWeight.w500, textPrimary),
      bodySemibold: s(14, 20, FontWeight.w600, textPrimary),
      caption: s(12, 18, FontWeight.w500, textSecondary),
      captionStrong: s(12, 18, FontWeight.w600, textPrimary),
      overline: s(10, 16, FontWeight.w600, textSecondary),
      button: s(14, 20, FontWeight.w600, textPrimary),
      input: s(14, 20, FontWeight.w400, textPrimary),
    );
  }

  @override
  AppTypographyTokens copyWith() => this;

  @override
  ThemeExtension<AppTypographyTokens> lerp(covariant ThemeExtension<AppTypographyTokens>? other, double t) {
    if (other is! AppTypographyTokens) return this;
    return AppTypographyTokens(
      display: TextStyle.lerp(display, other.display, t)!,
      h1: TextStyle.lerp(h1, other.h1, t)!,
      h2: TextStyle.lerp(h2, other.h2, t)!,
      h3: TextStyle.lerp(h3, other.h3, t)!,
      bodyLg: TextStyle.lerp(bodyLg, other.bodyLg, t)!,
      bodyLgMedium: TextStyle.lerp(bodyLgMedium, other.bodyLgMedium, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyMedium: TextStyle.lerp(bodyMedium, other.bodyMedium, t)!,
      bodySemibold: TextStyle.lerp(bodySemibold, other.bodySemibold, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      captionStrong: TextStyle.lerp(captionStrong, other.captionStrong, t)!,
      overline: TextStyle.lerp(overline, other.overline, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      input: TextStyle.lerp(input, other.input, t)!,
    );
  }
}
