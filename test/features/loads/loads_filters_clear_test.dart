import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/features/loads/domain/entities/load_entity.dart';
import 'package:loadme_mobile/features/loads/presentation/controllers/loads_controller.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_filters_screen.dart';

// The real LoadsController.build() pages the live /loads feed over the network
// (blocked in the sandbox). We only need applyLocationFilter, which the fake
// inherits unchanged — it just writes activeLoadsFilterProvider.
class _FakeLoads extends LoadsController {
  @override
  Future<List<LoadEntity>> build() async => const [];
}

void main() {
  testWidgets(
      '"Filterni tozalash" clears the applied server filter and pops back to the list',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        // `.tr(ref)` resolves via appL10nProvider; pin uz so the strings match.
        appL10nProvider.overrideWithValue(AppL10n(const Locale('uz'))),
        loadsControllerProvider.overrideWith(_FakeLoads.new),
      ],
    );
    addTearDown(container.dispose);

    // The feed is already narrowed by an applied filter — the exact state the
    // tester was stuck in ("filterni tozalash ishlamayabdi").
    container.read(activeLoadsFilterProvider.notifier).state =
        Map<String, String>.unmodifiable({'pickup_region': '7'});

    final router = GoRouter(
      initialLocation: '/loads',
      routes: [
        GoRoute(
          path: '/loads',
          builder: (_, __) => const Scaffold(body: Text('LIST')),
        ),
        GoRoute(
          path: '/loads/filters',
          builder: (_, __) => const LoadsFiltersScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    // Push Filtrlar on top of the list so context.canPop() is true (the path
    // _reset takes for a normally-opened filter screen). The push Future only
    // completes when the route pops, so it is intentionally not awaited.
    unawaited(router.push('/loads/filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filterni tozalash'), findsOneWidget);

    await tester.tap(find.text('Filterni tozalash'));
    await tester.pumpAndSettle();

    // The applied server filter is gone…
    expect(container.read(activeLoadsFilterProvider), isEmpty);
    // …and we're back on the list, with the filters screen popped.
    expect(find.text('LIST'), findsOneWidget);
    expect(find.text('Filterni tozalash'), findsNothing);
  });
}
