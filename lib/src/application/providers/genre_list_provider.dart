import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repository/channel_repository.dart';
import '../../core/models/genre.dart';

part 'genre_list_provider.g.dart';

@riverpod
Future<List<Genre>> genreList(Ref ref, String portalId) {
  final repository = ref.watch(channelRepositoryProvider);
  return repository.getGenres(portalId);
}
