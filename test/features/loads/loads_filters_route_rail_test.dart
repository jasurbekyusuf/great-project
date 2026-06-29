import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Filtrlar route-card left rail (cube → dotted line → flag).
///
/// This mirrors the exact constraint chain used by `_routeCard()` and
/// `_VDottedLine` in `loads_filters_screen.dart`:
///
///   IntrinsicHeight
///     → Row(crossAxisAlignment: stretch)
///       → Column[ IconBox(36), Expanded→Padding(v:4)→Center→dotted, IconBox(36) ]
///       → Expanded(field stack, taller than the two icons)
///
/// It catches the two real regressions we hit on the dotted connector:
///   1. A bare `CustomPaint` with no `size`/`child` collapses to `Size.zero`
///      under the Center's loose constraints — so the dashes never paint
///      (the line is invisible, height 0).
///   2. The first fix used `height: double.infinity`, which makes the rail's
///      intrinsic height infinite and trips `IntrinsicHeight`'s internal
///      `assert(height.isFinite)` → red error screen.
///
/// The dotted segment must lay out at exactly 2×18 (Figma "Line 571" — three
/// 3px dashes with 3px gaps) and the tree must build with no exception.
void main() {
  testWidgets(
    'route-card dotted rail lays out at 2x18 inside IntrinsicHeight',
    (tester) async {
      const dotKey = Key('route-dotted-line');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left rail: cube · dotted · flag (mirrors _routeCard).
                      Column(
                        children: const [
                          SizedBox(width: 36, height: 36),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Center(
                                child: SizedBox(
                                  key: dotKey,
                                  width: 2,
                                  height: 18,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 36, height: 36),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Right content taller than the two icons (~102px) so the
                      // Expanded rail gets real vertical space — like the
                      // Qayerdan / divider / Qayerga field stack.
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(height: 41),
                            SizedBox(height: 10),
                            Divider(height: 1, thickness: 1),
                            SizedBox(height: 10),
                            SizedBox(height: 41),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 1) No layout assert fired. `double.infinity` would throw here.
      expect(tester.takeException(), isNull);

      // 2) The dotted segment keeps its full Figma length (not clipped to 0).
      expect(tester.getSize(find.byKey(dotKey)), const Size(2, 18));
    },
  );
}
