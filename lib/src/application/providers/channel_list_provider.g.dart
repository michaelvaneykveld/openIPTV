// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelListHash() => r'e566cfe5c35c0abe8e5a284b9a628120f069c4dd';

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
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$channelListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChannelListRef = AutoDisposeFutureProviderRef<List<Channel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
