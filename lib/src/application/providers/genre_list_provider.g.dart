// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'genre_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$genreListHash() => r'b985a7fbda953d99f379936caacbcdb08ff380a3';

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

/// See also [genreList].
@ProviderFor(genreList)
const genreListProvider = GenreListFamily();

/// See also [genreList].
class GenreListFamily extends Family<AsyncValue<List<Genre>>> {
  /// See also [genreList].
  const GenreListFamily();

  /// See also [genreList].
  GenreListProvider call(String portalId) {
    return GenreListProvider(portalId);
  }

  @override
  GenreListProvider getProviderOverride(covariant GenreListProvider provider) {
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
  String? get name => r'genreListProvider';
}

/// See also [genreList].
class GenreListProvider extends AutoDisposeFutureProvider<List<Genre>> {
  /// See also [genreList].
  GenreListProvider(String portalId)
    : this._internal(
        (ref) => genreList(ref as GenreListRef, portalId),
        from: genreListProvider,
        name: r'genreListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$genreListHash,
        dependencies: GenreListFamily._dependencies,
        allTransitiveDependencies: GenreListFamily._allTransitiveDependencies,
        portalId: portalId,
      );

  GenreListProvider._internal(
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
    FutureOr<List<Genre>> Function(GenreListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GenreListProvider._internal(
        (ref) => create(ref as GenreListRef),
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
  AutoDisposeFutureProviderElement<List<Genre>> createElement() {
    return _GenreListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GenreListProvider && other.portalId == portalId;
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
mixin GenreListRef on AutoDisposeFutureProviderRef<List<Genre>> {
  /// The parameter `portalId` of this provider.
  String get portalId;
}

class _GenreListProviderElement
    extends AutoDisposeFutureProviderElement<List<Genre>>
    with GenreListRef {
  _GenreListProviderElement(super.provider);

  @override
  String get portalId => (origin as GenreListProvider).portalId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
