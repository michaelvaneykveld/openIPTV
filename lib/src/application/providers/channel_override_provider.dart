import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/core/models/channel_override.dart';
import 'package:openiptv/src/data/repository/channel_override_repository.dart';

final channelOverridesProvider = FutureProvider.family<List<ChannelOverride>, String>((ref, portalId) async {
  final repository = ref.watch(channelOverrideRepositoryProvider);
  return repository.getOverrides(portalId);
});

class ChannelOverrideController {
  ChannelOverrideController(this._ref);

  final Ref _ref;

  ChannelOverrideRepository get _repository => _ref.read(channelOverrideRepositoryProvider);

  Future<void> setHidden(String portalId, String channelId, bool hidden) async {
    final current = await _getOverride(portalId, channelId);
    await _repository.saveOverride(
      current.copyWith(isHidden: hidden),
    );
    _refresh(portalId);
  }

  Future<void> updateName(String portalId, String channelId, String? name) async {
    final current = await _getOverride(portalId, channelId);
    await _repository.saveOverride(
      current.copyWith(customName: name),
    );
    _refresh(portalId);
  }

  Future<void> updateGroup(String portalId, String channelId, String? group) async {
    final current = await _getOverride(portalId, channelId);
    await _repository.saveOverride(
      current.copyWith(customGroup: group),
    );
    _refresh(portalId);
  }

  Future<void> reorder(String portalId, List<ChannelOverride> overrides) async {
    await _repository.reorder(portalId, overrides);
    _refresh(portalId);
  }

  Future<void> removeOverride(String portalId, String channelId) async {
    await _repository.removeOverride(portalId, channelId);
    _refresh(portalId);
  }

  Future<ChannelOverride> _getOverride(String portalId, String channelId) async {
    final overrides = await _repository.getOverrides(portalId);
    return overrides.firstWhere(
      (override) => override.channelId == channelId,
      orElse: () => ChannelOverride(portalId: portalId, channelId: channelId),
    );
  }

  void _refresh(String portalId) {
    _ref.invalidate(channelOverridesProvider(portalId));
  }
}

final channelOverrideControllerProvider = Provider<ChannelOverrideController>((ref) {
  return ChannelOverrideController(ref);
});
