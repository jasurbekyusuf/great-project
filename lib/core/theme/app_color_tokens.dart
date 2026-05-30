import 'package:flutter/material.dart';

// Mirrors client_frontend_web-master/src/theme/colors.ts 1:1.
// Do not invent new shades — add them to the web token file first.
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    // Brand
    required this.primary700,
    required this.primary600,
    required this.primary500,
    required this.primary400,
    required this.primary300,
    required this.primary50,
    // Gray
    required this.grayLight,
    required this.gray950,
    required this.gray900,
    required this.gray800,
    required this.gray700,
    required this.gray600,
    required this.gray400,
    required this.gray300,
    required this.gray200,
    required this.gray100,
    required this.gray50,
    // Red / Error
    required this.red900,
    required this.red800,
    required this.red700,
    required this.red600,
    required this.red500,
    required this.red400,
    required this.red300,
    required this.red200,
    required this.red100,
    required this.red50,
    // Yellow / Warning
    required this.yellow700,
    required this.yellow600,
    required this.yellow400,
    required this.yellow100,
    required this.warning300,
    // Green / Success
    required this.green700,
    required this.green600,
    // Dark surfaces
    required this.darkBg0,
    required this.darkBg1,
    required this.darkBg2,
    required this.darkBg3,
    required this.darkBorder,
    required this.darkHr,
    required this.darkTextMuted,
    required this.darkLink,
    required this.darkPill,
    // Semantic (mode-aware shortcuts)
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryHover,
    required this.primaryDisabled,
    required this.success,
    required this.warning,
    required this.error,
    required this.link,
    required this.inputBorder,
    required this.inputFocusBorder,
    required this.tabsTrack,
    required this.tabsThumb,
  });

  // Brand
  final Color primary700;
  final Color primary600;
  final Color primary500;
  final Color primary400;
  final Color primary300;
  final Color primary50;
  // Gray
  final Color grayLight;
  final Color gray950;
  final Color gray900;
  final Color gray800;
  final Color gray700;
  final Color gray600;
  final Color gray400;
  final Color gray300;
  final Color gray200;
  final Color gray100;
  final Color gray50;
  // Red
  final Color red900;
  final Color red800;
  final Color red700;
  final Color red600;
  final Color red500;
  final Color red400;
  final Color red300;
  final Color red200;
  final Color red100;
  final Color red50;
  // Yellow / warning
  final Color yellow700;
  final Color yellow600;
  final Color yellow400;
  final Color yellow100;
  final Color warning300;
  // Green
  final Color green700;
  final Color green600;
  // Dark
  final Color darkBg0;
  final Color darkBg1;
  final Color darkBg2;
  final Color darkBg3;
  final Color darkBorder;
  final Color darkHr;
  final Color darkTextMuted;
  final Color darkLink;
  final Color darkPill;
  // Semantic
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color primaryHover;
  final Color primaryDisabled;
  final Color success;
  final Color warning;
  final Color error;
  final Color link;
  final Color inputBorder;
  final Color inputFocusBorder;
  final Color tabsTrack;
  final Color tabsThumb;

  // Raw scale constants (shared across modes)
  static const _grayLight = Color(0xFFD5DADD);
  static const _gray950 = Color(0xFF0C111D);
  static const _gray900 = Color(0xFF101828);
  static const _gray800 = Color(0xFF1D2939);
  static const _gray700 = Color(0xFF344054);
  static const _gray600 = Color(0xFF475467);
  static const _gray400 = Color(0xFF98A2B3);
  static const _gray300 = Color(0xFFD0D5DD);
  static const _gray200 = Color(0xFFEAECF0);
  static const _gray100 = Color(0xFFF2F4F7);
  static const _gray50 = Color(0xFFF9FAFB);

  static const _primary700 = Color(0xFF004EEB);
  static const _primary600 = Color(0xFF0F5FFF);
  static const _primary500 = Color(0xFF2970FF);
  static const _primary400 = Color(0xFF84ADFF);
  static const _primary300 = Color(0xFF92B7FD);
  static const _primary50 = Color(0xFFEFF4FF);

  static const _red900 = Color(0xFF7F1D1D);
  static const _red800 = Color(0xFF9B1C1C);
  static const _red700 = Color(0xFFB42318);
  static const _red600 = Color(0xFFD92D20);
  static const _red500 = Color(0xFFF04438);
  static const _red400 = Color(0xFFF87171);
  static const _red300 = Color(0xFFFCA5A5);
  static const _red200 = Color(0xFFFECACA);
  static const _red100 = Color(0xFFFEE2E2);
  static const _red50 = Color(0xFFFEF2F2);

  static const _yellow700 = Color(0xFFA15C07);
  static const _yellow600 = Color(0xFFD97706);
  static const _yellow400 = Color(0xFFFAC515);
  static const _yellow100 = Color(0xFFFEF7C3);
  static const _warning300 = Color(0xFFFEC84B);

  static const _green700 = Color(0xFF087443);
  static const _green600 = Color(0xFF099250);

  static const _darkBg0 = Color(0xFF0B1220);
  static const _darkBg1 = Color(0xFF0F172A);
  static const _darkBg2 = Color(0xFF111827);
  static const _darkBg3 = Color(0xFF0E1524);
  static const _darkBorder = Color(0xFF232B3B);
  static const _darkHr = Color(0xFF1C2434);
  static const _darkTextMuted = Color(0xFF7E8AAE);
  static const _darkLink = Color(0xFF528BFF);
  static const _darkPill = Color(0x1F004EEB);

  static const light = AppColorTokens(
    primary700: _primary700,
    primary600: _primary600,
    primary500: _primary500,
    primary400: _primary400,
    primary300: _primary300,
    primary50: _primary50,
    grayLight: _grayLight,
    gray950: _gray950,
    gray900: _gray900,
    gray800: _gray800,
    gray700: _gray700,
    gray600: _gray600,
    gray400: _gray400,
    gray300: _gray300,
    gray200: _gray200,
    gray100: _gray100,
    gray50: _gray50,
    red900: _red900,
    red800: _red800,
    red700: _red700,
    red600: _red600,
    red500: _red500,
    red400: _red400,
    red300: _red300,
    red200: _red200,
    red100: _red100,
    red50: _red50,
    yellow700: _yellow700,
    yellow600: _yellow600,
    yellow400: _yellow400,
    yellow100: _yellow100,
    warning300: _warning300,
    green700: _green700,
    green600: _green600,
    darkBg0: _darkBg0,
    darkBg1: _darkBg1,
    darkBg2: _darkBg2,
    darkBg3: _darkBg3,
    darkBorder: _darkBorder,
    darkHr: _darkHr,
    darkTextMuted: _darkTextMuted,
    darkLink: _darkLink,
    darkPill: _darkPill,
    // Semantic — light
    background: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: _gray50,
    border: _gray200,
    borderSubtle: _gray100,
    textPrimary: _gray900,
    textSecondary: _gray700,
    textMuted: _gray400,
    primary: _primary700,
    primaryHover: _primary500,
    primaryDisabled: _primary300,
    success: _green600,
    warning: _yellow600,
    error: _red600,
    link: _primary700,
    inputBorder: Color(0x00000000), // transparent until focus
    inputFocusBorder: _primary700,
    tabsTrack: Color(0xFFF2F3F5),
    tabsThumb: Color(0xFFFFFFFF),
  );

  static const dark = AppColorTokens(
    primary700: _primary700,
    primary600: _primary600,
    primary500: _primary500,
    primary400: _primary400,
    primary300: _primary300,
    primary50: _primary50,
    grayLight: _grayLight,
    gray950: _gray950,
    gray900: _gray900,
    gray800: _gray800,
    gray700: _gray700,
    gray600: _gray600,
    gray400: _gray400,
    gray300: _gray300,
    gray200: _gray200,
    gray100: _gray100,
    gray50: _gray50,
    red900: _red900,
    red800: _red800,
    red700: _red700,
    red600: _red600,
    red500: _red500,
    red400: _red400,
    red300: _red300,
    red200: _red200,
    red100: _red100,
    red50: _red50,
    yellow700: _yellow700,
    yellow600: _yellow600,
    yellow400: _yellow400,
    yellow100: _yellow100,
    warning300: _warning300,
    green700: _green700,
    green600: _green600,
    darkBg0: _darkBg0,
    darkBg1: _darkBg1,
    darkBg2: _darkBg2,
    darkBg3: _darkBg3,
    darkBorder: _darkBorder,
    darkHr: _darkHr,
    darkTextMuted: _darkTextMuted,
    darkLink: _darkLink,
    darkPill: _darkPill,
    // Semantic — dark
    background: _darkBg0,
    surface: _darkBg2,
    surfaceMuted: _darkBg1,
    border: _darkBorder,
    borderSubtle: _darkHr,
    textPrimary: _gray100,
    textSecondary: _gray400,
    textMuted: _darkTextMuted,
    primary: _primary500,
    primaryHover: _primary400,
    primaryDisabled: _primary300,
    success: _green600,
    warning: _yellow600,
    error: _red500,
    link: _darkLink,
    inputBorder: Color(0x00000000),
    inputFocusBorder: _primary500,
    tabsTrack: _darkBg1,
    tabsThumb: _darkBg2,
  );

  @override
  AppColorTokens copyWith({Color? background, Color? surface, Color? border, Color? textPrimary, Color? textSecondary, Color? primary, Color? error, Color? success, Color? warning}) {
    return AppColorTokens(
      primary700: primary700,
      primary600: primary600,
      primary500: primary500,
      primary400: primary400,
      primary300: primary300,
      primary50: primary50,
      grayLight: grayLight,
      gray950: gray950,
      gray900: gray900,
      gray800: gray800,
      gray700: gray700,
      gray600: gray600,
      gray400: gray400,
      gray300: gray300,
      gray200: gray200,
      gray100: gray100,
      gray50: gray50,
      red900: red900,
      red800: red800,
      red700: red700,
      red600: red600,
      red500: red500,
      red400: red400,
      red300: red300,
      red200: red200,
      red100: red100,
      red50: red50,
      yellow700: yellow700,
      yellow600: yellow600,
      yellow400: yellow400,
      yellow100: yellow100,
      warning300: warning300,
      green700: green700,
      green600: green600,
      darkBg0: darkBg0,
      darkBg1: darkBg1,
      darkBg2: darkBg2,
      darkBg3: darkBg3,
      darkBorder: darkBorder,
      darkHr: darkHr,
      darkTextMuted: darkTextMuted,
      darkLink: darkLink,
      darkPill: darkPill,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted,
      border: border ?? this.border,
      borderSubtle: borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted,
      primary: primary ?? this.primary,
      primaryHover: primaryHover,
      primaryDisabled: primaryDisabled,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      link: link,
      inputBorder: inputBorder,
      inputFocusBorder: inputFocusBorder,
      tabsTrack: tabsTrack,
      tabsThumb: tabsThumb,
    );
  }

  @override
  ThemeExtension<AppColorTokens> lerp(covariant ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppColorTokens(
      primary700: l(primary700, other.primary700),
      primary600: l(primary600, other.primary600),
      primary500: l(primary500, other.primary500),
      primary400: l(primary400, other.primary400),
      primary300: l(primary300, other.primary300),
      primary50: l(primary50, other.primary50),
      grayLight: l(grayLight, other.grayLight),
      gray950: l(gray950, other.gray950),
      gray900: l(gray900, other.gray900),
      gray800: l(gray800, other.gray800),
      gray700: l(gray700, other.gray700),
      gray600: l(gray600, other.gray600),
      gray400: l(gray400, other.gray400),
      gray300: l(gray300, other.gray300),
      gray200: l(gray200, other.gray200),
      gray100: l(gray100, other.gray100),
      gray50: l(gray50, other.gray50),
      red900: l(red900, other.red900),
      red800: l(red800, other.red800),
      red700: l(red700, other.red700),
      red600: l(red600, other.red600),
      red500: l(red500, other.red500),
      red400: l(red400, other.red400),
      red300: l(red300, other.red300),
      red200: l(red200, other.red200),
      red100: l(red100, other.red100),
      red50: l(red50, other.red50),
      yellow700: l(yellow700, other.yellow700),
      yellow600: l(yellow600, other.yellow600),
      yellow400: l(yellow400, other.yellow400),
      yellow100: l(yellow100, other.yellow100),
      warning300: l(warning300, other.warning300),
      green700: l(green700, other.green700),
      green600: l(green600, other.green600),
      darkBg0: l(darkBg0, other.darkBg0),
      darkBg1: l(darkBg1, other.darkBg1),
      darkBg2: l(darkBg2, other.darkBg2),
      darkBg3: l(darkBg3, other.darkBg3),
      darkBorder: l(darkBorder, other.darkBorder),
      darkHr: l(darkHr, other.darkHr),
      darkTextMuted: l(darkTextMuted, other.darkTextMuted),
      darkLink: l(darkLink, other.darkLink),
      darkPill: l(darkPill, other.darkPill),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      primary: l(primary, other.primary),
      primaryHover: l(primaryHover, other.primaryHover),
      primaryDisabled: l(primaryDisabled, other.primaryDisabled),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      link: l(link, other.link),
      inputBorder: l(inputBorder, other.inputBorder),
      inputFocusBorder: l(inputFocusBorder, other.inputFocusBorder),
      tabsTrack: l(tabsTrack, other.tabsTrack),
      tabsThumb: l(tabsThumb, other.tabsThumb),
    );
  }
}
