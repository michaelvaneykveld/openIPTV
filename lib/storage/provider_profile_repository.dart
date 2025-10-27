import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/storage/provider_database.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

/// Domain representation of a persisted provider profile.
class ProviderProfileRecord {
  final String id;
  final ProviderKind kind;
  final String displayName;
  final Uri lockedBase;
  final bool needsUserAgent;
  final bool allowSelfSignedTls;
  final bool followRedirects;
  final Map<String, String> configuration;
  final Map<String, String> hints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOkAt;
  final String? lastError;
  final bool hasSecrets;

  const ProviderProfileRecord({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.lockedBase,
    required this.needsUserAgent,
    required this.allowSelfSignedTls,
    required this.followRedirects,
    required this.configuration,
    required this.hints,
    required this.createdAt,
    required this.updatedAt,
    this.lastOkAt,
    this.lastError,
    this.hasSecrets = false,
  });
}

/// Snapshot of secrets fetched from the secure credentials vault.
class ProviderSecretSnapshot {
  final String providerId;
  final Map<String, String> secrets;

  const ProviderSecretSnapshot({
    required this.providerId,
    this.secrets = const <String, String>{},
  });
}

/// Abstraction over the secure storage backend so the repository can be tested.
abstract class CredentialsVault {
  Future<void> write(String key, Map<String, String> secrets);
  Future<Map<String, String>> read(String key);
  Future<void> delete(String key);
}

/// Flutter-secure-storage backed implementation used in production.
class SecureCredentialsVault implements CredentialsVault {
  SecureCredentialsVault({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, Map<String, String> secrets) {
    return _storage.write(key: key, value: jsonEncode(secrets));
  }

  @override
  Future<Map<String, String>> read(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) {
      return const <String, String>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map((entryKey, value) => MapEntry('$entryKey', '$value'));
    }
    return const <String, String>{};
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}

/// Repository orchestrating drift persistence and secure credential storage.
class ProviderProfileRepository {
  ProviderProfileRepository({
    required ProviderDatabase database,
    required CredentialsVault vault,
    DateTime Function()? clock,
  }) : _database = database,
       _vault = vault,
       _now = clock ?? DateTime.now;

  final ProviderDatabase _database;
  final CredentialsVault _vault;
  final DateTime Function() _now;

  static final Random _random = Random.secure();

  /// Allocates a stable identifier for provider profiles.
  static String allocateProfileId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final entropy = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'prov-$timestamp$entropy';
  }

  String _allocateVaultKey(String providerId) {
    final entropy = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'provider:$providerId:$entropy';
  }

  /// Creates or updates a provider profile and its associated secret payload.
  Future<ProviderProfileRecord> saveProfile({
    String? profileId,
    required ProviderKind kind,
    required Uri lockedBase,
    String? displayName,
    Map<String, String> configuration = const <String, String>{},
    Map<String, String> hints = const <String, String>{},
    Map<String, String> secrets = const <String, String>{},
    bool needsUserAgent = false,
    bool allowSelfSignedTls = false,
    bool followRedirects = true,
    DateTime? successAt,
    String? lastError,
  }) async {
    final id = profileId ?? allocateProfileId();
    final now = _now().toUtc();
    return _database.transaction(() async {
      final existing = await _getProfileRow(id);

      final cleanedConfig = _cleanMap(configuration);
      final cleanedHints = _cleanMap(hints);

      final profileCompanion = ProviderProfilesCompanion(
        id: Value(id),
        kind: Value(kind),
        displayName: Value(
          displayName?.trim().isNotEmpty == true
              ? displayName!.trim()
              : _deriveDisplayName(kind, lockedBase),
        ),
        lockedBase: Value(lockedBase.toString()),
        needsUserAgent: Value(needsUserAgent),
        allowSelfSignedTls: Value(allowSelfSignedTls),
        followRedirects: Value(followRedirects),
        configuration: Value(cleanedConfig),
        hints: Value(cleanedHints),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        lastOkAt: Value(successAt ?? existing?.lastOkAt),
        lastError: lastError == null
            ? const Value<String?>.absent()
            : Value<String?>(lastError),
      );

      await _database
          .into(_database.providerProfiles)
          .insertOnConflictUpdate(profileCompanion);

      final existingSecret = await _getSecretRow(id);

      final hasSecrets = secrets.isNotEmpty;
      if (hasSecrets) {
        final vaultKey = existingSecret?.vaultKey ?? _allocateVaultKey(id);
        await _vault.write(vaultKey, _cleanMap(secrets));
        final secretCompanion = ProviderSecretsCompanion(
          providerId: Value(id),
          vaultKey: Value(vaultKey),
          createdAt: Value(existingSecret?.createdAt ?? now),
          updatedAt: Value(now),
        );
        await _database
            .into(_database.providerSecrets)
            .insertOnConflictUpdate(secretCompanion);
      } else if (existingSecret != null) {
        await _vault.delete(existingSecret.vaultKey);
        await (_database.delete(
          _database.providerSecrets,
        )..where((tbl) => tbl.providerId.equals(id))).go();
      }

      final stored = await _getProfileRow(id);
      if (stored == null) {
        throw StateError('Profile $id missing after save.');
      }
      final bool persistedSecrets = hasSecrets ? true : await _secretExists(id);
      return _mapProfile(stored, hasSecrets: persistedSecrets);
    });
  }

  /// Deletes the profile and erases any secrets living in secure storage.
  Future<void> deleteProfile(String id) async {
    await _database.transaction(() async {
      final secret = await _getSecretRow(id);
      if (secret != null) {
        await _vault.delete(secret.vaultKey);
      }
      await (_database.delete(
        _database.providerProfiles,
      )..where((tbl) => tbl.id.equals(id))).go();
    });
  }

  /// Returns all persisted provider profiles sorted by most recent activity.
  Future<List<ProviderProfileRecord>> listProfiles() async {
    final rows = await (_database.select(
      _database.providerProfiles,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)])).get();
    final secrets = await _database.select(_database.providerSecrets).get();
    final secretIds = secrets.map((row) => row.providerId).toSet();
    return rows
        .map((row) => _mapProfile(row, hasSecrets: secretIds.contains(row.id)))
        .toList(growable: false);
  }

  /// Loads a single profile, including a flag describing whether secrets exist.
  Future<ProviderProfileRecord?> getProfile(String id) async {
    final row = await _getProfileRow(id);
    if (row == null) return null;
    final hasSecrets = await _secretExists(id);
    return _mapProfile(row, hasSecrets: hasSecrets);
  }

  /// Records a successful verification ping and clears the last error.
  Future<void> recordSuccessfulHandshake(String id, {DateTime? at}) async {
    final when = (at ?? _now()).toUtc();
    await (_database.update(
      _database.providerProfiles,
    )..where((tbl) => tbl.id.equals(id))).write(
      ProviderProfilesCompanion(
        lastOkAt: Value(when),
        lastError: const Value<String?>(null),
        updatedAt: Value(when),
      ),
    );
  }

  /// Records an authentication failure message for later diagnostics.
  Future<void> recordFailure(String id, String message, {DateTime? at}) async {
    final when = (at ?? _now()).toUtc();
    await (_database.update(
      _database.providerProfiles,
    )..where((tbl) => tbl.id.equals(id))).write(
      ProviderProfilesCompanion(
        lastError: Value(message),
        updatedAt: Value(when),
      ),
    );
  }

  /// Retrieves decrypted secrets for a provider, if any are stored.
  Future<ProviderSecretSnapshot?> loadSecrets(String providerId) async {
    final row = await _getSecretRow(providerId);
    if (row == null) return null;
    final secrets = await _vault.read(row.vaultKey);
    return ProviderSecretSnapshot(providerId: providerId, secrets: secrets);
  }

  ProviderProfileRecord _mapProfile(
    ProviderProfile row, {
    required bool hasSecrets,
  }) {
    return ProviderProfileRecord(
      id: row.id,
      kind: row.kind,
      displayName: row.displayName,
      lockedBase: Uri.parse(row.lockedBase),
      needsUserAgent: row.needsUserAgent,
      allowSelfSignedTls: row.allowSelfSignedTls,
      followRedirects: row.followRedirects,
      configuration: Map.unmodifiable(row.configuration),
      hints: Map.unmodifiable(row.hints),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastOkAt: row.lastOkAt,
      lastError: row.lastError,
      hasSecrets: hasSecrets,
    );
  }

  Future<ProviderProfile?> _getProfileRow(String id) {
    return (_database.select(
      _database.providerProfiles,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<ProviderSecret?> _getSecretRow(String id) {
    return (_database.select(
      _database.providerSecrets,
    )..where((tbl) => tbl.providerId.equals(id))).getSingleOrNull();
  }

  Future<bool> _secretExists(String id) async {
    final query = _database.selectOnly(_database.providerSecrets)
      ..addColumns([_database.providerSecrets.providerId])
      ..where(_database.providerSecrets.providerId.equals(id))
      ..limit(1);
    final result = await query.get();
    return result.isNotEmpty;
  }

  Map<String, String> _cleanMap(Map<String, String> source) {
    if (source.isEmpty) return const <String, String>{};
    final cleaned = <String, String>{};
    source.forEach((key, value) {
      final trimmedKey = key.trim();
      final trimmedValue = value.trim();
      if (trimmedKey.isEmpty || trimmedValue.isEmpty) {
        return;
      }
      cleaned[trimmedKey] = trimmedValue;
    });
    return cleaned;
  }

  String _deriveDisplayName(ProviderKind kind, Uri lockedBase) {
    final buffer = StringBuffer();
    buffer.write(kind.name.toUpperCase());
    if (lockedBase.host.isNotEmpty) {
      buffer.write(' @ ');
      buffer.write(lockedBase.host);
    }
    return buffer.toString();
  }
}

/// Riverpod provider exposing the repository as a shared singleton.
final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>((
  ref,
) {
  final database = ProviderDatabase();
  ref.onDispose(database.close);
  final vault = SecureCredentialsVault();
  return ProviderProfileRepository(database: database, vault: vault);
});
