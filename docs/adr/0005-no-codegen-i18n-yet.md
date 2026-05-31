# ADR-0005: Keep i18n as in-memory map for now (no slang / flutter_intl)

- **Status**: accepted
- **Date**: 2026-05-31

## Context

The app needs four locales (`uz`, `uz_Cyrl`, `ru`, `en`) and ~250 strings.
Two codegen alternatives were evaluated:

| Tool          | Pros                                   | Cons                                  |
|---------------|----------------------------------------|---------------------------------------|
| `slang`       | Type-safe, plural/gender, hot reload   | Build-step on every translation edit; new dependency surface |
| `flutter_intl`| Standard, arb format, IDE support      | XML-like arb files; rebuilds on every key |

## Decision

Stay with the existing in-memory map in `core/services/app_l10n.dart`, but
add **type-safe key constants** in `core/services/l10n_keys.dart`:

```dart
LK.profileEdit.tr(ref)   // compile-time error if removed
```

This gives 90 % of the codegen safety with zero build-runner overhead.

When string count crosses ~600 or we need ICU plurals, migrate to `slang`.

## Consequences

+ No build-runner pre-step before `flutter run` works.
+ Translations live in one file — easy to scan in code review.
+ `LK.someKey` callers get red squiggles when a key is removed.
- Adding a key still requires editing five places (4 langs + key constant).
  Trade-off accepted for simplicity at current scale.
