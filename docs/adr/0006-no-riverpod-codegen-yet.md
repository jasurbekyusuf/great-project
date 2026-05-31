# ADR-0006: Plain Riverpod providers (no `riverpod_generator` yet)

- **Status**: accepted
- **Date**: 2026-05-31

## Context

`riverpod_generator` lets us write providers as annotated classes/functions
and have the generator emit boilerplate plus stricter typing. The trade-off
is a build-runner step on every provider edit.

## Decision

Keep hand-written `Provider`, `NotifierProvider`,
`AsyncNotifierProvider`, `FutureProvider.family.autoDispose` declarations.

Project size today (~30 providers) does not justify the codegen overhead.
Naming conventions enforce structure:

- `<noun>RepositoryProvider`
- `<verb><Noun>UseCaseProvider`
- `<noun>ControllerProvider`
- `<noun>DisplayProvider` (pure view-model transforms)

## When to revisit

Migrate the moment any of these become true:
- Provider count > ~80
- We adopt offline-first state with derived providers chains > 3 deep
- Riverpod 3.x makes annotations the default

## Consequences

+ `flutter run` works without a codegen warm-up.
+ Stack traces remain hand-written code — easy to debug.
- Slight risk of typo in `ref.read(wrongProvider)` because providers are
  ad-hoc symbols. Mitigated by `prefer_const_constructors` lint and IDE
  refactor support.
