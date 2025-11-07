import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/repositories/provider_repository.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

final providerSyncServiceProvider = Provider<ProviderSyncService>((ref) {
  final repository = ref.watch(providerRepositoryProvider);
  return ProviderSyncService(repository);
});

class ProviderSyncService {
  ProviderSyncService(this._repository);

  final ProviderRepository _repository;

  Future<int?> ensureProviderForProfile(
    ProviderProfileRecord profile, {
    bool createIfMissing = true,
  }) async {
    final existing =
        await _repository.findByLegacyProfileId(profile.id);
    if (existing != null) {
      if (_needsUpdate(existing, profile)) {
        await _repository.updateProvider(
          ProvidersCompanion(
            id: Value(existing.id),
            kind: Value(profile.kind),
            displayName: Value(profile.displayName),
            lockedBase: Value(profile.lockedBase.toString()),
            needsUa: Value(profile.needsUserAgent),
            allowSelfSigned: Value(profile.allowSelfSignedTls),
            legacyProfileId: Value(profile.id),
          ),
        );
      }
      return existing.id;
    }

    if (!createIfMissing) {
      return null;
    }

    final id = await _repository.createProvider(
      ProvidersCompanion.insert(
        kind: profile.kind,
        lockedBase: profile.lockedBase.toString(),
        displayName: Value(profile.displayName),
        needsUa: Value(profile.needsUserAgent),
        allowSelfSigned: Value(profile.allowSelfSignedTls),
        legacyProfileId: Value(profile.id),
      ),
    );
    return id;
  }

  bool _needsUpdate(
    ProviderRecord record,
    ProviderProfileRecord profile,
  ) {
    return record.displayName != profile.displayName ||
        record.lockedBase != profile.lockedBase.toString() ||
        record.needsUa != profile.needsUserAgent ||
        record.allowSelfSigned != profile.allowSelfSignedTls;
  }
}
