// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelListHash() => r'17fc55fbbcef60c66dd27646946d866926f25182';

/// A provider that fetches and provides the list of channels.
///
/// It depends on the [channelRepositoryProvider] to get the data.
/// The UI can watch this provider to get the channel list asynchronously
/// and handle loading/error states.
///
/// Copied from [channelList].
@ProviderFor(channelList)
final channelListProvider = AutoDisposeFutureProvider<List<Channel>>.internal(
  channelList,
  name: r'channelListProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$channelListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ChannelListRef = AutoDisposeFutureProviderRef<List<Channel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
