# Security & Storage Guardrails

## Secrets stay in secure storage

- Profiles stored via `ProviderProfileRepository` scrub usernames, passwords, tokens, and custom headers before writing to Drift (`lib/storage/provider_profile_repository.dart`).  
- Sensitive values are routed to the secure storage vault only; the accompanying regression test exercises this behaviour (`test/storage/provider_profile_repository_test.dart`).  
- Database schemas avoid columns for credentials to ensure “no secrets in DB” stays enforced.

## Optional SQLCipher build flag

- Passing `--dart-define=DB_ENABLE_SQLCIPHER=true` enables an encrypted main database.  
- When enabled, `OpenIptvDb` now acquires/generates a key through `SecureDatabaseKeyStore` (stored in `flutter_secure_storage`) and opens the file with `sqflite_sqlcipher`.  
- Keys are generated with `Random.secure()` and Base64-url encoded; a `MemoryDatabaseKeyStore` is available for tests.
- Launch commands:
  ```bash
  flutter run --dart-define=DB_ENABLE_SQLCIPHER=true
  flutter test --dart-define=DB_ENABLE_SQLCIPHER=true
  ```

## Log redaction

- All networking, discovery, and login flows log through helpers in `src/utils/url_redaction.dart`, guaranteeing tokens and credentials are scrubbed before hitting logs or crash reports.  
- Sanity coverage lives in `test/utils/url_redaction_test.dart`.

## Backup & restore considerations

- Both `openiptv.db` and the SQLite secure-storage mapping live in the app support directory on mobile/desktop platforms (`getApplicationSupportDirectory`).  
- Release builds should explicitly exclude this directory from automatic OS backups (e.g. `android:allowBackup="false"` in `AndroidManifest.xml`, `NSURLIsExcludedFromBackupKey` on iOS/macOS).  
- Encrypted builds rely on the secure-storage key, so restoring the raw database file without the key intentionally renders it unreadable.
- For validation, run `flutter test test/storage/provider_profile_repository_test.dart` to confirm credentials never persist in the Drift tables.

## Quick checklist

- [x] Secrets are sanitized before hitting Drift (`ProviderProfileRepository`, covered by unit test).
- [x] SQLCipher path gated by `DB_ENABLE_SQLCIPHER` define with secure key management.
- [x] Logging utilities (`url_redaction.dart`) redact URLs and text before output.
- [x] Backup guidance documented for Android/iOS/macOS along with encrypted restore behaviour.
