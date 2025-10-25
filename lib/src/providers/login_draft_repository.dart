import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_flow_controller.dart';

/// Represents a saved login draft that the user can revisit later.
class LoginDraft {
  final String id;
  final LoginProviderType providerType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> data;
  final Map<String, String> secrets;

  const LoginDraft({
    required this.id,
    required this.providerType,
    required this.createdAt,
    required this.updatedAt,
    this.data = const <String, dynamic>{},
    this.secrets = const <String, String>{},
  });

  Map<String, dynamic> toMetadataJson() {
    return <String, dynamic>{
      'id': id,
      'providerType': providerType.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'data': data,
    };
  }

  factory LoginDraft.fromJson(
    Map<String, dynamic> metadata,
    Map<String, String> secrets,
  ) {
    return LoginDraft(
      id: metadata['id'] as String,
      providerType: LoginProviderType.values.firstWhere(
        (value) => value.name == metadata['providerType'],
        orElse: () => LoginProviderType.m3u,
      ),
      createdAt: DateTime.parse(metadata['createdAt'] as String),
      updatedAt: DateTime.parse(metadata['updatedAt'] as String),
      data: Map<String, dynamic>.from(metadata['data'] as Map),
      secrets: secrets,
    );
  }

  LoginDraft copyWith({
    DateTime? updatedAt,
    Map<String, dynamic>? data,
    Map<String, String>? secrets,
  }) {
    return LoginDraft(
      id: id,
      providerType: providerType,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? this.data,
      secrets: secrets ?? this.secrets,
    );
  }
}

/// Handles persistence of login drafts across app launches while ensuring
/// sensitive fields live inside secure storage.
class LoginDraftRepository {
  LoginDraftRepository({
    required SharedPreferences preferences,
    required FlutterSecureStorage secureStorage,
  }) : _preferences = preferences,
       _secureStorage = secureStorage;

  final SharedPreferences _preferences;
  final FlutterSecureStorage _secureStorage;

  static const _indexKey = 'login_draft_index';

  static final _random = Random();

  /// Creates a unique identifier suitable for draft storage keys.
  static String allocateId() {
    final millis = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final suffix = _random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$millis-$suffix';
  }

  /// Returns all saved drafts, sorted by most recently updated first.
  Future<List<LoginDraft>> loadDrafts() async {
    final ids = _preferences.getStringList(_indexKey) ?? const <String>[];
    final drafts = <LoginDraft>[];
    for (final id in ids) {
      final raw = _preferences.getString(_metadataKey(id));
      if (raw == null) {
        continue;
      }
      try {
        final metadata = jsonDecode(raw) as Map<String, dynamic>;
        final secretJson = await _secureStorage.read(key: _secretKey(id));
        final secrets = secretJson == null
            ? const <String, String>{}
            : Map<String, String>.from(jsonDecode(secretJson) as Map);
        drafts.add(LoginDraft.fromJson(metadata, secrets));
      } catch (_) {
        // Skip corrupted entries silently; future cleanup tasks can prune them.
        continue;
      }
    }
    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return drafts;
  }

  /// Stores (or updates) the provided draft.
  Future<void> saveDraft(LoginDraft draft) async {
    final ids = _preferences.getStringList(_indexKey) ?? <String>[];
    if (!ids.contains(draft.id)) {
      ids.add(draft.id);
    }
    await _preferences.setStringList(_indexKey, ids);
    await _preferences.setString(
      _metadataKey(draft.id),
      jsonEncode(draft.toMetadataJson()),
    );
    if (draft.secrets.isEmpty) {
      await _secureStorage.delete(key: _secretKey(draft.id));
    } else {
      await _secureStorage.write(
        key: _secretKey(draft.id),
        value: jsonEncode(draft.secrets),
      );
    }
  }

  /// Removes a draft and its secrets permanently.
  Future<void> deleteDraft(String id) async {
    final ids = _preferences.getStringList(_indexKey) ?? <String>[];
    ids.remove(id);
    await _preferences.setStringList(_indexKey, ids);
    await _preferences.remove(_metadataKey(id));
    await _secureStorage.delete(key: _secretKey(id));
  }

  String _metadataKey(String id) => 'login_draft_meta:$id';

  String _secretKey(String id) => 'login_draft_secret:$id';
}

/// Provides access to the draft repository, guaranteeing the underlying
/// dependencies are initialised asynchronously.
final loginDraftRepositoryProvider = FutureProvider<LoginDraftRepository>((
  ref,
) async {
  final preferences = await SharedPreferences.getInstance();
  const storage = FlutterSecureStorage();
  return LoginDraftRepository(preferences: preferences, secureStorage: storage);
});
