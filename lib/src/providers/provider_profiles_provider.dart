import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/data/db/openiptv_db.dart';
import 'package:openiptv/data/repositories/provider_repository.dart';
import 'package:openiptv/storage/provider_profile_repository.dart';

/// Stream of saved provider profiles used by management screens.
final savedProfilesStreamProvider =
    StreamProvider.autoDispose<List<ProviderProfileRecord>>((ref) {
  final repository = ref.watch(providerProfileRepositoryProvider);
  return repository.watchProfiles();
});

/// Stream of provider records stored in the local database.
final providerRecordsStreamProvider =
    StreamProvider.autoDispose<List<ProviderRecord>>((ref) {
  final repository = ref.watch(providerRepositoryProvider);
  return repository.watchProviders();
});
