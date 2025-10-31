import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openiptv/src/ui/login_screen.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/storage/provider_database.dart';
import 'package:openiptv/src/providers/login_draft_repository.dart';

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

  testWidgets(
    'Save for later requires provider details before persisting',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final draftRepository = _RecordingDraftRepository(
        preferences: preferences,
        secureStorage: const FlutterSecureStorage(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerProfileRepositoryProvider.overrideWithValue(repository),
            loginDraftRepositoryProvider.overrideWith(
              (ref) => Future.value(draftRepository),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('M3U'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save for later'));
      await tester.pump();

      expect(draftRepository.saveCalled, isFalse);
      expect(
        find.text('Add provider details before saving a draft.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Save for later persists drafts when details are provided',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final draftRepository = _RecordingDraftRepository(
        preferences: preferences,
        secureStorage: const FlutterSecureStorage(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerProfileRepositoryProvider.overrideWithValue(repository),
            loginDraftRepositoryProvider.overrideWith(
              (ref) => Future.value(draftRepository),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Portal URL'),
        'http://portal.example.com',
      );
      await tester.pump();

      await tester.tap(find.text('Save for later'));
      await tester.pump();

      expect(draftRepository.saveCalled, isTrue);
      expect(
        find.text('Draft saved for later.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Shows banner when validation fails before probing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final draftRepository = _RecordingDraftRepository(
        preferences: preferences,
        secureStorage: const FlutterSecureStorage(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            providerProfileRepositoryProvider.overrideWithValue(repository),
            loginDraftRepositoryProvider.overrideWith(
              (ref) => Future.value(draftRepository),
            ),
          ],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Test & Connect'));
      await tester.pump();

      expect(
        find.text('Please review the highlighted fields.'),
        findsOneWidget,
      );
    },
  );
}

class _RecordingDraftRepository extends LoginDraftRepository {
  _RecordingDraftRepository({
    required super.preferences,
    required super.secureStorage,
  });

  bool saveCalled = false;
  LoginDraft? capturedDraft;

  @override
  Future<void> saveDraft(LoginDraft draft) async {
    saveCalled = true;
    capturedDraft = draft;
  }
}
