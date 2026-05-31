# ADR-0003: Riverpod + GetIt coexistence

- **Status**: accepted
- **Date**: 2026-05-31

## Context

We needed dependency injection that works for both:
- **UI-tied state** that wants to react to widgets rebuilding
  (auth session, current locale, list of loads…)
- **Pure-Dart singletons** that have no Flutter context
  (Logger, ApiClient, Stripe SDK…)

Forcing everything through Riverpod would require fake widgets in unit tests
and create `ProviderContainer` instances for plain Dart code. Forcing
everything through GetIt loses Riverpod's reactivity and override-in-test
ergonomics.

## Decision

- **Riverpod** owns:
  - Feature controllers (`AsyncNotifier`, `Notifier`)
  - Per-feature data sources, repositories, and use cases
    (so tests override one provider in isolation)
  - Locale, theme, current user role
- **GetIt** owns:
  - App-level singletons that survive across the entire process
    (`Logger`, any third-party SDK client)
  - Pure-Dart services with no UI dependency

Registered once in `core/di/register_dependencies.dart` from `main()`.

## Consequences

+ Tests override exactly the layer they care about.
+ Pure-Dart units don't pull `flutter_riverpod` transitively.
- Two DI systems to remember — kept manageable because GetIt holds only
  a tiny set of well-known singletons.
