import 'package:flutter/widgets.dart';

/// Exact Figma (Dev Mode) colours for the ported Search / Details screens.
///
/// These are literal design values that intentionally differ from the
/// theme `AppColorTokens` in a few places (e.g. page bg #F6F7F9 vs the
/// token #F9FAFB), so the screens stay pixel-1:1 with the design. Keep them
/// here as the single source of truth instead of inlining hex everywhere.
abstract final class FigmaPalette {
  static const primary = Color(0xFF004EEB);

  // Text
  static const ink = Color(0xFF101828); // gray/900
  static const inkStrong = Color(0xFF131313); // city titles
  static const gray700 = Color(0xFF727E97);
  static const muted = Color(0xFF8A93A8);
  static const label = Color(0xFF98A2B3); // gray/400
  static const countLabel = Color(0xFF0B1020);
  static const tertiary = Color(0xFF475467);

  // Surfaces / lines
  static const pageBg = Color(0xFFF6F7F9);
  static const sheetBg = Color(0xFFF3F4F7);
  static const chipBg = Color(0xFFF2F4F7); // gray/100
  static const divider = Color(0xFFEAECF0); // gray/200
  static const dividerStrong = Color(0xFFE1E4EA);
  static const avatarBg = Color(0xFFE0E0E0);

  // Accents
  static const star = Color(0xFFFEC84B);
  static const moneyGreen = Color(0xFF00C853);
  static const navInactive = Color(0xFF6C7A93);
  static const roleBlueBg = Color(0xFFEFF4FF);
  static const dangerText = Color(0xFFB42318); // error/700
  static const dangerBg = Color(0xFFFEF3F2); // error/50

  // Shadows
  static const cardShadow = Color(0x0A101828); // #101828 @ 4%
}
