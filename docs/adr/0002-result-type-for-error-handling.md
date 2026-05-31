# ADR-0002: `Result<T>` everywhere — no exceptions across layers

- **Status**: accepted
- **Date**: 2026-05-31

## Context

`try/catch` scattered across UI made it impossible to tell from a method
signature whether a call could fail or what failure modes existed. Untyped
errors meant snackbars showed `DioException [connection error]…` to users.

## Decision

Adopt `fpdart`'s `Either<L, R>` aliased as `Result<T>`:

```dart
typedef Result<T>      = Either<AppFailure, T>;
typedef AsyncResult<T> = Future<Result<T>>;
```

`AppFailure` is a **sealed** class with concrete subtypes
(`NetworkFailure`, `UnauthorizedFailure`, `NotFoundFailure`,
`ValidationFailure`, `CacheFailure`, `UnknownFailure`).

Every repository method returns `AsyncResult<T>` — implementations funnel
through `Guard.run` which maps `DioException` → `AppFailure` and logs.

Presentation collapses results to either:
- `(T?, AppFailure?)` tuple for one-shot calls (login, save), or
- Rethrows the failure into Riverpod `AsyncError` for stream-like state.

`AppFailure implements Exception` so the rethrow path satisfies
`only_throw_errors` without losing typing.

## Consequences

+ Failure handling is visible in the type system.
+ UI can switch on `failure.runtimeType` for branch-specific messages.
+ Tests assert exact failure types via pattern matching.
- Slightly more verbose call sites (one `.fold` per call).
- Devs must learn `fpdart` — but the surface used is tiny.
