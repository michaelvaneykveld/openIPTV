// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelListHash() => r'cb4506e8aa9c91ffd96baf0a896ea64f8b839e96';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A provider that fetches and provides the list of channels.
///
/// It depends on the [channelRepositoryProvider] to get the data.
/// The UI can watch this provider to get the channel list asynchronously
/// and handle loading/error states.
///
/// Copied from [channelList].
@ProviderFor(channelList)
const channelListProvider = ChannelListFamily();

/// A provider that fetches and provides the list of channels.
///
/// It depends on the [channelRepositoryProvider] to get the data.
/// The UI can watch this provider to get the channel list asynchronously
/// and handle loading/error states.
///
/// Copied from [channelList].
class ChannelListFamily extends Family<AsyncValue<List<Channel>>> {
  /// A provider that fetches and provides the list of channels.
  ///
  /// It depends on the [channelRepositoryProvider] to get the data.
  /// The UI can watch this provider to get the channel list asynchronously
  /// and handle loading/error states.
  ///
  /// Copied from [channelList].
  const ChannelListFamily();

  /// A provider that fetches and provides the list of channels.
  ///
  /// It depends on the [channelRepositoryProvider] to get the data.
  /// The UI can watch this provider to get the channel list asynchronously
  /// and handle loading/error states.
  ///
  /// Copied from [channelList].
  ChannelListProvider call(String portalId) {
    return ChannelListProvider(portalId);
  }

  @override
  ChannelListProvider getProviderOverride(
    covariant ChannelListProvider provider,
  ) {
    return call(provider.portalId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'channelListProvider';
}

/// A provider that fetches and provides the list of channels.
///
/// It depends on the [channelRepositoryProvider] to get the data.
/// The UI can watch this provider to get the channel list asynchronously
/// and handle loading/error states.
///
/// Copied from [channelList].
class ChannelListProvider extends AutoDisposeFutureProvider<List<Channel>> {
  /// A provider that fetches and provides the list of channels.
  ///
  /// It depends on the [channelRepositoryProvider] to get the data.
  /// The UI can watch this provider to get the channel list asynchronously
  /// and handle loading/error states.
  ///
  /// Copied from [channelList].
  ChannelListProvider(String portalId)
    : this._internal(
        (ref) => channelList(ref as ChannelListRef, portalId),
        from: channelListProvider,
        name: r'channelListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$channelListHash,
        dependencies: ChannelListFamily._dependencies,
        allTransitiveDependencies: ChannelListFamily._allTransitiveDependencies,
        portalId: portalId,
      );

  ChannelListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.portalId,
  }) : super.internal();

  final String portalId;

  @override
  Override overrideWith(
    FutureOr<List<Channel>> Function(ChannelListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChannelListProvider._internal(
        (ref) => create(ref as ChannelListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        portalId: portalId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Channel>> createElement() {
    return _ChannelListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelListProvider && other.portalId == portalId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, portalId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChannelListRef on AutoDisposeFutureProviderRef<List<Channel>> {
  /// The parameter `portalId` of this provider.
  String get portalId;
}

class _ChannelListProviderElement
    extends AutoDisposeFutureProviderElement<List<Channel>>
    with ChannelListRef {
  _ChannelListProviderElement(super.provider);

  @override
  String get portalId => (origin as ChannelListProvider).portalId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
