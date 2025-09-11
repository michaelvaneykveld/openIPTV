// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioHash() => r'587ef6b98b30060e3f764de7dddf936991bf16d5';

/// See also [dio].
@ProviderFor(dio)
final dioProvider = AutoDisposeProvider<Dio>.internal(
  dio,
  name: r'dioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioRef = AutoDisposeProviderRef<Dio>;
String _$stalkerApiHash() => r'37c46b366a54d23c15f3fe98d45c9fc9965e652a';

/// See also [stalkerApi].
@ProviderFor(stalkerApi)
final stalkerApiProvider = AutoDisposeProvider<StalkerApiProvider>.internal(
  stalkerApi,
  name: r'stalkerApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$stalkerApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StalkerApiRef = AutoDisposeProviderRef<StalkerApiProvider>;
String _$xtreamApiHash() => r'383947c3381595789138b627fbf4d73ff55c1499';

/// See also [xtreamApi].
@ProviderFor(xtreamApi)
final xtreamApiProvider = AutoDisposeProvider<XtreamApiService>.internal(
  xtreamApi,
  name: r'xtreamApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$xtreamApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef XtreamApiRef = AutoDisposeProviderRef<XtreamApiService>;
String _$m3uApiHash() => r'74b44a1c2bd7aa5f7060245415ea123c21a03a23';

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

/// See also [m3uApi].
@ProviderFor(m3uApi)
const m3uApiProvider = M3uApiFamily();

/// See also [m3uApi].
class M3uApiFamily extends Family<M3uApiService> {
  /// See also [m3uApi].
  const M3uApiFamily();

  /// See also [m3uApi].
  M3uApiProvider call(M3uCredentials credentials) {
    return M3uApiProvider(credentials);
  }

  @override
  M3uApiProvider getProviderOverride(covariant M3uApiProvider provider) {
    return call(provider.credentials);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'm3uApiProvider';
}

/// See also [m3uApi].
class M3uApiProvider extends AutoDisposeProvider<M3uApiService> {
  /// See also [m3uApi].
  M3uApiProvider(M3uCredentials credentials)
    : this._internal(
        (ref) => m3uApi(ref as M3uApiRef, credentials),
        from: m3uApiProvider,
        name: r'm3uApiProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$m3uApiHash,
        dependencies: M3uApiFamily._dependencies,
        allTransitiveDependencies: M3uApiFamily._allTransitiveDependencies,
        credentials: credentials,
      );

  M3uApiProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.credentials,
  }) : super.internal();

  final M3uCredentials credentials;

  @override
  Override overrideWith(M3uApiService Function(M3uApiRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: M3uApiProvider._internal(
        (ref) => create(ref as M3uApiRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        credentials: credentials,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<M3uApiService> createElement() {
    return _M3uApiProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is M3uApiProvider && other.credentials == credentials;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, credentials.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin M3uApiRef on AutoDisposeProviderRef<M3uApiService> {
  /// The parameter `credentials` of this provider.
  M3uCredentials get credentials;
}

class _M3uApiProviderElement extends AutoDisposeProviderElement<M3uApiService>
    with M3uApiRef {
  _M3uApiProviderElement(super.provider);

  @override
  M3uCredentials get credentials => (origin as M3uApiProvider).credentials;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
