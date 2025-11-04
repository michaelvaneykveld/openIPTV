/// Centralised flags controlling optional database capabilities.
///
/// These values are sourced from `--dart-define` switches at build time.
/// We fall back to sane defaults when the defines are absent so local
/// development remains frictionless.
class DatabaseFlags {
  /// Enables SQLCipher-backed storage when available.
  static const bool enableSqlCipher =
      bool.fromEnvironment('DB_ENABLE_SQLCIPHER', defaultValue: false);

  /// Enables FTS-specific features (virtual tables, triggers, etc).
  static const bool enableFts =
      bool.fromEnvironment('DB_ENABLE_FTS', defaultValue: false);
}
