import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/app_color_tokens.dart';
import 'package:loadme_mobile/core/theme/app_spacing_tokens.dart';
import 'package:loadme_mobile/core/theme/app_typography_tokens.dart';

extension ThemeX on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
  AppSpacingTokens get space => Theme.of(this).extension<AppSpacingTokens>()!;
  AppTypographyTokens get types => Theme.of(this).extension<AppTypographyTokens>()!;
}
