# ADR-0001: Clean Architecture per feature folder

- **Status**: accepted
- **Date**: 2026-05-31

## Context

The original codebase mixed business logic, data fetching, and widget code in
single files. Adding a new screen meant editing 3–4 unrelated areas, and
swapping the backend required edits across the presentation layer.

## Decision

Each feature follows the same triplet:

```
features/<name>/
├── data/
│   ├── datasources/    # remote + fake variants
│   ├── dtos/           # wire-format models (freezed)
│   └── repositories/   # *RepositoryImpl (returns Result<T>)
├── domain/
│   ├── entities/       # plain Dart business objects
│   ├── repositories/   # abstract interface
│   └── use_cases/      # one class per business action
└── presentation/
    ├── controllers/    # Riverpod notifiers (drive use cases)
    ├── models/         # view models (e.g. *Display)
    ├── widgets/        # feature-private widgets
    └── screens/        # widget trees only
```

Controllers depend on **use cases**, never on repositories directly.
Repositories return `Result<T>` (alias for `Either<AppFailure, T>`) so the
layer boundary is exception-free.

## Consequences

+ A new feature is mechanical: copy the `auth/` folder shape.
+ Swapping data sources (real ↔ fake) is one provider override.
+ Repository internals are mockable with `mocktail`.
- Boilerplate: ~6 files per simple feature.
- Onboarding cost — newcomers must learn the layering before contributing.
