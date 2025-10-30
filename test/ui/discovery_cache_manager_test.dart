import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';
import 'package:openiptv/src/ui/discovery_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns cached discovery result within TTL', () async {
    final manager = DiscoveryCacheManager(
      ttl: const Duration(hours: 24),
    );
    final cacheKey = DiscoveryCacheManager.buildKey(
      kind: ProviderKind.xtream,
      identifier: 'https://demo.example.com:8080/get.php?username=u&password=p',
      headers: const {'X-Test': 'value'},
      allowSelfSignedTls: true,
      userAgent: 'TestAgent/1.0',
    );
    final result = DiscoveryResult(
      kind: ProviderKind.xtream,
      lockedBase: Uri.parse('https://demo.example.com:8080/'),
      hints: const {'needsUserAgent': 'true'},
    );

    await manager.store(
      cacheKey: cacheKey,
      result: result,
      now: DateTime.utc(2024, 1, 1, 12),
    );

    final fetched = await manager.get(
      cacheKey: cacheKey,
      now: DateTime.utc(2024, 1, 1, 18),
    );

    expect(fetched, isNotNull);
    expect(fetched!.lockedBase, result.lockedBase);
    expect(fetched.hints['needsUserAgent'], equals('true'));
  });

  test('evicts expired cache entries based on TTL', () async {
    final manager = DiscoveryCacheManager(
      ttl: const Duration(hours: 24),
    );
    final cacheKey = DiscoveryCacheManager.buildKey(
      kind: ProviderKind.stalker,
      identifier: 'http://portal.example.com/c/',
    );
    final result = DiscoveryResult(
      kind: ProviderKind.stalker,
      lockedBase: Uri.parse('http://portal.example.com/c/'),
    );

    await manager.store(
      cacheKey: cacheKey,
      result: result,
      now: DateTime.utc(2024, 4, 1, 8),
    );

    final fetched = await manager.get(
      cacheKey: cacheKey,
      now: DateTime.utc(2024, 4, 2, 12),
    );

    expect(fetched, isNull);
  });

  test('buildKey redacts credential query parameters', () {
    final key = DiscoveryCacheManager.buildKey(
      kind: ProviderKind.m3u,
      identifier:
          'https://playlist.example.com/get.php?username=alice&password=secret&type=m3u_plus',
    );

    expect(key.contains('alice'), isFalse);
    expect(key.contains('secret'), isFalse);
    expect(key.contains('password'), isFalse);
  });
}
