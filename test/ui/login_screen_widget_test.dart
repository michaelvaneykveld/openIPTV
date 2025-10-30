import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/src/ui/login_screen.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/storage/provider_database.dart';

class _InMemoryVault implements CredentialsVault {
  final Map<String, Map<String, String>> _storage = {};

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> read(String key) async {
    return _storage[key] ?? const <String, String>{};
  }

  @override
  Future<void> write(String key, Map<String, String> secrets) async {
    _storage[key] = Map<String, String>.from(secrets);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderDatabase database;
  late ProviderProfileRepository repository;

  setUp(() {
    database = ProviderDatabase.forTesting(NativeDatabase.memory());
    repository = ProviderProfileRepository(
      database: database,
      vault: _InMemoryVault(),
      clock: () => DateTime.utc(2024, 1, 1),
    );
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets(
    'Advanced sections expose shared controls across providers',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerProfileRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      Future<void> expectCommonAdvancedControls(ValueKey<String> key) async {
        final tileFinder = find.byKey(key);
        expect(tileFinder, findsOneWidget);
        await tester.tap(tileFinder);
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: tileFinder,
            matching: find.text('User-Agent override'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tileFinder,
            matching: find.text('Custom headers'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tileFinder,
            matching: find.text('Allow self-signed TLS'),
          ),
          findsOneWidget,
        );
      }

      await expectCommonAdvancedControls(
        const ValueKey<String>('stalkerAdvancedTile'),
      );

      await tester.tap(find.text('Xtream'));
      await tester.pumpAndSettle();
      await expectCommonAdvancedControls(
        const ValueKey<String>('xtreamAdvancedTile'),
      );

      await tester.tap(find.text('M3U'));
      await tester.pumpAndSettle();
      await expectCommonAdvancedControls(
        const ValueKey<String>('m3uAdvancedTile'),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('m3uAdvancedTile')),
          matching: find.text('Follow redirects automatically'),
        ),
        findsOneWidget,
      );
    },
  );
}
