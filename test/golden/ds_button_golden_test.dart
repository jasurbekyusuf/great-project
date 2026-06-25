import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/theme/app_color_tokens.dart';
import 'package:loadme_mobile/core/theme/app_spacing_tokens.dart';
import 'package:loadme_mobile/core/theme/app_typography_tokens.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

/// Golden ("visual freeze") test for the design-system button.
///
/// This is the safety net for refactoring: it captures the *current* pixels of
/// the DsButton variants. If a later refactor changes the rendered output by
/// even one pixel, this test fails — proving the UI did NOT stay identical.
///
/// It freezes the **real** [DsButton] using the **real** production design
/// tokens ([AppColorTokens.light] colors, [AppSpacingTokens.base] geometry) and
/// the production typography *metrics* (size / line-height / weight / letter
/// spacing). The one thing it deliberately does NOT use is the app's GoogleFonts
/// Inter: the real theme fetches Inter over the network, which is unavailable
/// offline / in CI and non-deterministic — useless for a pixel freeze. The label
/// therefore renders with the deterministic flutter_test font. Layout, colors,
/// borders, and sizing are identical to production; only the glyph outlines
/// differ, so the test still catches any structural/visual regression in the
/// button itself.
///
/// Regenerate the baseline intentionally with:
///   flutter test --update-goldens
void main() {
  // Real production tokens — the exact values a refactor must not silently change.
  final colors = AppColorTokens.light;
  const spacing = AppSpacingTokens.base;

  // Production typography metrics, minus the GoogleFonts network dependency.
  TextStyle ts(double size, double height, FontWeight weight, Color color) =>
      TextStyle(
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        color: color,
        letterSpacing: 0,
      );
  final types = AppTypographyTokens(
    display: ts(28, 36, FontWeight.w700, colors.textPrimary),
    h1: ts(24, 32, FontWeight.w700, colors.textPrimary),
    h2: ts(20, 28, FontWeight.w600, colors.textPrimary),
    h3: ts(18, 26, FontWeight.w600, colors.textPrimary),
    bodyLg: ts(16, 24, FontWeight.w400, colors.textPrimary),
    bodyLgMedium: ts(16, 24, FontWeight.w500, colors.textPrimary),
    body: ts(14, 20, FontWeight.w400, colors.textPrimary),
    bodyMedium: ts(14, 20, FontWeight.w500, colors.textPrimary),
    bodySemibold: ts(14, 20, FontWeight.w600, colors.textPrimary),
    caption: ts(12, 18, FontWeight.w500, colors.textSecondary),
    captionStrong: ts(12, 18, FontWeight.w600, colors.textPrimary),
    overline: ts(10, 16, FontWeight.w600, colors.textSecondary),
    button: ts(14, 20, FontWeight.w600, colors.textPrimary),
    input: ts(14, 20, FontWeight.w400, colors.textPrimary),
  );

  Widget frame(Widget child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: colors.background,
          extensions: <ThemeExtension<dynamic>>[colors, spacing, types],
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
        ),
      );

  testWidgets('DsButton variants — visual freeze', (tester) async {
    await tester.pumpWidget(
      frame(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsButton(label: 'Solid', onPressed: () {}),
            const SizedBox(height: 12),
            DsButton(
              label: 'Outline',
              variant: DsButtonVariant.outline,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            DsButton(
              label: 'Secondary',
              variant: DsButtonVariant.secondary,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            const DsButton(label: 'Disabled', onPressed: null),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/ds_button_variants.png'),
    );
  });
}
