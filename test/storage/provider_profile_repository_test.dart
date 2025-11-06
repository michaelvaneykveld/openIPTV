import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/storage/provider_database.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

class FakeVault implements CredentialsVault {
  final Map<String, Map<String, String>> store =
      <String, Map<String, String>>{};
  String? lastWriteKey;

  @override
  Future<void> write(String key, Map<String, String> secrets) async {
    store[key] = Map<String, String>.from(secrets);
    lastWriteKey = key;
  }

  @override
  Future<Map<String, String>> read(String key) async {
    final secrets = store[key];
    if (secrets == null) {
      return const <String, String>{};
    }
    return Map<String, String>.from(secrets);
  }

  @override
  Future<void> delete(String key) async {
    store.remove(key);
    if (lastWriteKey == key) {
      lastWriteKey = null;
    }
  }
}

void main() {
  late ProviderDatabase database;
  late FakeVault vault;
  late ProviderProfileRepository repository;

  setUp(() {
    database = ProviderDatabase.forTesting(NativeDatabase.memory());
    vault = FakeVault();
    repository = ProviderProfileRepository(
      database: database,
      vault: vault,
      clock: () => DateTime.utc(2025, 1, 1),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saveProfile stores sensitive entries in vault only', () async {
    final record = await repository.saveProfile(
      profileId: 'prov-test',
      kind: ProviderKind.xtream,
      lockedBase: Uri.parse('https://example.com/'),
      configuration: {
        'userAgent': 'Agent',
        'customHeaders': '{"Authorization":"Bearer secret"}',
        'username': 'alice',
      },
      hints: {'token': 'abc123', 'note': 'ok'},
      secrets: {'password': 'hunter2'},
      needsUserAgent: true,
      allowSelfSignedTls: false,
      followRedirects: true,
    );

    expect(record.configuration['userAgent'], 'Agent');
    expect(record.configuration.containsKey('customHeaders'), isFalse);
    expect(record.configuration.containsKey('username'), isFalse);
    expect(record.configuration['hasCustomHeaders'], 'true');
    expect(record.hints['note'], 'ok');
    expect(record.hints.containsKey('token'), isFalse);
    expect(record.hasSecrets, isTrue);

    final storedSecrets = vault.lastWriteKey == null
        ? const <String, String>{}
        : vault.store[vault.lastWriteKey!] ?? const <String, String>{};

    expect(storedSecrets['password'], 'hunter2');
    expect(storedSecrets['customHeaders'], '{"Authorization":"Bearer secret"}');
    expect(storedSecrets['username'], 'alice');
    expect(storedSecrets['token'], 'abc123');

    final profile = await repository.getProfile('prov-test');
    expect(profile, isNotNull);
    expect(profile!.hasSecrets, isTrue);

    final storedRow = await (database.select(database.providerProfiles)
          ..where((tbl) => tbl.id.equals('prov-test')))
        .getSingle();
    expect(storedRow.configuration.containsKey('username'), isFalse);
    expect(storedRow.configuration.containsKey('customHeaders'), isFalse);
    expect(storedRow.hints.containsKey('token'), isFalse);
  });
}
