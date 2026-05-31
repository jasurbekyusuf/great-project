# ADR-0004: Auth tokens live in encrypted storage, not SharedPreferences

- **Status**: accepted
- **Date**: 2026-05-31

## Context

The initial implementation persisted access and refresh tokens via
`SharedPreferences`, which writes plain text on disk. Any other process with
shared user-id access (or a malicious app on a rooted device) can read them.

## Consequences of the leak

Stolen access tokens grant full API access for their TTL — including phone
reveal, posting/archiving loads, and reading personal data.

## Decision

Add `SecureTokenStorage` (abstract) + `SecureTokenStorageImpl`
(backed by `flutter_secure_storage`) and split persistence:

- **Encrypted** (`SecureTokenStorage`):  access token, refresh token.
- **Plain** (`SharedPreferences` / `KeyValueStorage`):  cached non-sensitive
  user profile JSON, locale, theme mode.

`AuthRepositoryImpl` takes both storages. Dio's `Authorization` interceptor
reads from `SecureTokenStorage` only.

On Android `EncryptedSharedPreferences` (AES-256, hardware-backed where
available) is used; on iOS, Keychain.

## Consequences

+ Tokens unreadable without root + key material — meets normal mobile
  security baseline.
+ Logout = `secure.clear()` cannot leave a stale token behind.
- Secure reads are async and slightly slower (~1ms typical).
- Hot-restart can occasionally clear EncryptedSharedPreferences on emulator
  — known Android quirk, not a prod issue.
