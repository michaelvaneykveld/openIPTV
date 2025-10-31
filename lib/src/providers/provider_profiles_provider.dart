import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/storage/provider_profile_repository.dart';

/// Stream of saved provider profiles used by management screens.
final savedProfilesStreamProvider =
    StreamProvider.autoDispose<List<ProviderProfileRecord>>((ref) {
  final repository = ref.watch(providerProfileRepositoryProvider);
  return repository.watchProfiles();
});
