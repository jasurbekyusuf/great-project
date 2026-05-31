# Loadme Mobile

Native Flutter port of [loadme.uz](https://loadme.uz) — load/truck marketplace
for Central Asia. Currently runs against a built-in fake data layer so the UI
is fully explorable without a backend.

## Architecture

Clean Architecture (data → domain → presentation) per feature, with strict
typing of errors through `Result<T>`:

```
lib/
├── app.dart                  # MaterialApp + theme + router
├── main.dart                 # Bootstrap: prefs, DI, runApp
│
├── core/                     # Cross-feature primitives
│   ├── di/                   # GetIt service locator
│   ├── errors/               # Sealed AppFailure hierarchy
│   ├── logging/              # AppLogger (Logger wrapper)
│   ├── network/              # Dio client + interceptors
│   ├── result/               # Result<T> = Either<AppFailure, T>  (fpdart)
│   ├── services/             # app_l10n, locale/theme providers
│   ├── storage/              # KeyValueStorage abstraction
│   ├── theme/                # Color, spacing, typography tokens
│   └── use_case/             # Base UseCase<Input, Output>
│
├── features/
│   ├── auth/                 # ← reference implementation, copy this shape
│   │   ├── data/
│   │   │   ├── datasources/  # AuthRemoteDataSource + FakeAuthRemoteDataSource
│   │   │   ├── dtos/         # @freezed wire-format objects
│   │   │   └── repositories/ # AuthRepositoryImpl: returns Result<T>
│   │   ├── domain/
│   │   │   ├── entities/     # Plain Dart business objects
│   │   │   ├── repositories/ # Abstract interface
│   │   │   └── use_cases/    # One class per business action
│   │   └── presentation/
│   │       ├── controllers/  # Riverpod Notifiers (drive use cases)
│   │       └── screens/      # Widget tree only — no business logic
│   ├── loads/
│   ├── trucks/
│   ├── profile/
│   ├── notifications/
│   └── info/
│
├── shared/
│   ├── design_system/        # DsButton, DsCard, DsLoader, DsConfirmationModal …
│   ├── widgets/              # AppBottomNav, MobilePageHead, MobileSegmentedTab …
│   └── models/               # Reusable shapes (PaginatedResponse)
│
└── config/
    ├── env/                  # AppEnv (toggle fake vs live data)
    └── routes/               # go_router config
```

### Error handling

No method throws across the layer boundary. Every fallible operation returns
`Result<T>` (alias for `Either<AppFailure, T>` from `fpdart`):

```dart
final result = await usecase.call(input);
result.fold(
  (failure) => /* show UI */,
  (data)    => /* render */,
);
```

`AppFailure` is a sealed class with concrete subtypes (`NetworkFailure`,
`UnauthorizedFailure`, `NotFoundFailure`, `ValidationFailure`,
`CacheFailure`, `UnknownFailure`). Dio errors are mapped at the repository
boundary via `mapDioException`.

### State management

- **Riverpod** owns UI-tied state and feature controllers
  (`AsyncNotifier` / `Notifier`).
- **GetIt** holds app-level singletons (`AppLogger`, …).
- Use cases are wired via `Provider<UseCaseX>` so they can be overridden in
  tests with `mocktail` mocks.

### Fake data

`AppEnv.useFakeData` (default `true`) flips every repository's upstream
data source between the real `Dio`-backed one and an in-memory fake. Fake
samples live in `*_remote_data_source.dart` files under `data/datasources/`
— never inline in widgets.

## Commands

```bash
make get          # flutter pub get
make analyze      # static analysis (very_good_analysis + custom rules)
make test         # run unit + widget tests
make build-runner # one-shot codegen
make watch        # codegen in watch mode
make run          # launch on the default device
make clean        # nuke build artifacts
```

## Strict lints

`analysis_options.yaml` extends `very_good_analysis` and turns on:

- `strict-casts`, `strict-inference`, `strict-raw-types`
- `prefer_const_constructors`, `prefer_final_locals`
- `require_trailing_commas`, `sort_constructors_first`
- `unawaited_futures`, `use_super_parameters`
- `avoid_print` (use `AppLogger` instead)

Generated files (`*.g.dart`, `*.freezed.dart`) are excluded.

## Adding a new feature

Mirror the `auth/` folder structure:

1. **Domain** — write `Entity`, `Repository` interface (returning
   `AsyncResult`), and one `UseCase` per business action.
2. **Data** — implement the repository, wrap remote/local sources, add a
   `FakeRemoteDataSource` extending the real one for offline development.
3. **Presentation** — create Riverpod providers wiring use cases, then a
   controller (`Notifier` / `AsyncNotifier`) that exposes ergonomic methods.
4. **Tests** — add a unit test for at least one use case using `mocktail`
   to mock the repository.

## Tests

`flutter test` runs all tests under `test/`. Seed coverage:

- Use cases (auth login, loads fetch/update, trucks fetch/update, profile)
- Shared design system (`DsButton`)
- Shared widgets (`MobileSegmentedTab`, `MobileListRow`, `MobileListGroup`)
- Core helpers (`Guard.run`)

Run with coverage:
```bash
make test-coverage     # writes coverage/lcov.info
make coverage-html     # opens HTML report (needs `lcov`)
```

Use `mocktail` for mocking; never depend on a real network in tests.

## Pre-commit hooks

We use [lefthook](https://github.com/evilmartians/lefthook) — install once:

```bash
make hooks-install
```

After that every commit runs `dart format` + `flutter analyze`, and every
push runs the test suite.

## Security

Auth tokens never touch `SharedPreferences`. They live in
`flutter_secure_storage` (Android `EncryptedSharedPreferences`,
iOS Keychain) — see [ADR-0004](docs/adr/0004-secure-token-storage.md).

## Architecture Decision Records

See [`docs/adr/`](docs/adr/) for the rationale behind:

1. Clean Architecture per feature folder
2. `Result<T>` + sealed `AppFailure` for error handling
3. Riverpod + GetIt coexistence
4. Secure token storage
5. No codegen i18n yet (in-memory map + type-safe key constants)
6. Plain Riverpod providers (no `riverpod_generator` yet)

## Type-safe i18n keys

For new strings, prefer the `LK.*` constants in
`lib/core/services/l10n_keys.dart` — they give compile-time safety:

```dart
Text(LK.profileLogout.tr(ref))   // ← red squiggle if key is deleted
```

Raw `'foo.bar'.tr(ref)` works too but won't catch typos.
