import 'package:meta/meta.dart';
import 'package:openiptv/src/utils/url_normalization.dart';

import '../protocols/discovery/portal_discovery.dart';

/// Outcome produced by the [InputClassifier].
@immutable
class InputClassification {
  final ProviderKind? provider;
  final bool isConfident;
  final XtreamClassification? xtream;
  final M3uClassification? m3u;
  final Uri? uri;
  final String original;

  const InputClassification._({
    required this.provider,
    required this.isConfident,
    this.xtream,
    this.m3u,
    this.uri,
    required this.original,
  });

  factory InputClassification.none(String original) => InputClassification._(
    provider: null,
    isConfident: false,
    original: original,
  );

  factory InputClassification.stalker({
    required Uri? uri,
    required String original,
    bool isConfident = false,
  }) => InputClassification._(
    provider: ProviderKind.stalker,
    isConfident: isConfident,
    uri: uri,
    original: original,
  );

  factory InputClassification.xtream({
    required XtreamClassification details,
    required String original,
    M3uClassification? playlist,
  }) => InputClassification._(
    provider: ProviderKind.xtream,
    isConfident: true,
    xtream: details,
    m3u: playlist,
    uri: details.baseUri,
    original: original,
  );

  factory InputClassification.m3u({
    required M3uClassification details,
    required String original,
  }) => InputClassification._(
    provider: ProviderKind.m3u,
    isConfident: true,
    m3u: details,
    uri: details.playlistUri,
    original: original,
  );

  bool get hasMatch => provider != null;
}

/// Details extracted when an Xtream URL is detected.
@immutable
class XtreamClassification {
  final Uri baseUri;
  final Uri? originalUri;
  final String? username;
  final String? password;

  const XtreamClassification({
    required this.baseUri,
    this.originalUri,
    this.username,
    this.password,
  });

  bool get hasCredentials =>
      (username != null && username!.isNotEmpty) &&
      (password != null && password!.isNotEmpty);
}

/// Details extracted when an M3U playlist is detected.
@immutable
class M3uClassification {
  final Uri? playlistUri;
  final String? localPath;
  final bool isLocalFile;
  final String? username;
  final String? password;

  const M3uClassification({
    this.playlistUri,
    this.localPath,
    required this.isLocalFile,
    this.username,
    this.password,
  });

  String get resolvedInput =>
      isLocalFile ? (localPath ?? '') : playlistUri?.toString() ?? '';
}

/// Offers protocol-aware classification heuristics for pasted/typed input.
class InputClassifier {
  const InputClassifier();

  static const _m3uExtensions = ['.m3u', '.m3u8'];

  InputClassification classify(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return InputClassification.none(raw);
    }

    final lowered = trimmed.toLowerCase();
    final uri = _parseFlexibleHttpUri(trimmed);

    final xtream = _detectXtream(trimmed, lowered, uri);
    if (xtream != null) {
      final m3u = _detectM3u(trimmed, lowered, uri);
      return InputClassification.xtream(
        details: xtream,
        original: raw,
        playlist: m3u,
      );
    }

    final bareXtream = _detectBareXtreamHost(trimmed);
    if (bareXtream != null) {
      return InputClassification.xtream(details: bareXtream, original: raw);
    }

    final m3u = _detectM3u(trimmed, lowered, uri);
    if (m3u != null) {
      return InputClassification.m3u(details: m3u, original: raw);
    }

    final stalkerUri = uri ?? _parseFlexibleHttpUri('https://$trimmed');
    final isConfidentStalker =
        stalkerUri != null &&
        (stalkerUri.path.toLowerCase().contains('stalker') ||
            stalkerUri.path.toLowerCase().contains('portal'));
    return InputClassification.stalker(
      uri: stalkerUri,
      original: raw,
      isConfident: isConfidentStalker,
    );
  }

  XtreamClassification? _detectXtream(
    String trimmed,
    String lowered,
    Uri? uri,
  ) {
    Uri? workingUri = uri;
    if (workingUri == null &&
        lowered.contains('username=') &&
        lowered.contains('password=')) {
      workingUri = _parseFlexibleHttpUri('https://$trimmed');
    }

    if (workingUri == null || workingUri.host.isEmpty) {
      return null;
    }

    final pathLower = workingUri.path.toLowerCase();
    final query = workingUri.queryParameters;
    final hasCredentialParams =
        query.containsKey('username') && query.containsKey('password');

    // Only treat as Xtream if it has player_api.php endpoint
    // get.php alone is just an M3U playlist provider, not full Xtream API
    final hasXtreamMarkers =
        pathLower.contains('player_api.php') ||
        pathLower.contains('xmltv.php') ||
        pathLower.contains('portal.php?type=stalker'); // rare fallback

    if (!hasXtreamMarkers && !hasCredentialParams) {
      return null;
    }

    final baseUri = _deriveXtreamBaseUri(workingUri);
    return XtreamClassification(
      baseUri: baseUri,
      originalUri: workingUri,
      username: query['username'],
      password: query['password'],
    );
  }

  M3uClassification? _detectM3u(String trimmed, String lowered, Uri? uri) {
    if (lowered.contains('#extm3u')) {
      return const M3uClassification(isLocalFile: false);
    }

    if (_looksLikeLocalPlaylist(trimmed, lowered)) {
      return M3uClassification(localPath: trimmed, isLocalFile: true);
    }

    final candidate = uri ?? _parseFlexibleHttpUri('https://$trimmed');
    if (candidate == null || candidate.host.isEmpty) {
      return null;
    }

    final pathLower = candidate.path.toLowerCase();
    final endsWithM3u = _m3uExtensions.any(pathLower.endsWith);
    final looksLikeGetEndpoint = pathLower.contains('get.php');
    final query = candidate.queryParameters;
    final playlistHints = _looksLikePlaylistQuery(query);
    if (!endsWithM3u && !(looksLikeGetEndpoint && playlistHints)) {
      return null;
    }

    final carriesCredentials =
        query.containsKey('username') && query.containsKey('password');

    return M3uClassification(
      playlistUri: candidate,
      isLocalFile: false,
      username: carriesCredentials ? query['username'] : null,
      password: carriesCredentials ? query['password'] : null,
    );
  }

  Uri? _parseFlexibleHttpUri(String input) {
    final candidate = tryParseLenientHttpUri(input);
    if (_isHttpUri(candidate)) {
      return candidate;
    }
    return null;
  }

  bool _isHttpUri(Uri? uri) {
    if (uri == null) return false;
    if (!uri.hasScheme) return false;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return false;
    }
    return uri.host.isNotEmpty;
  }

  bool _looksLikeLocalPlaylist(String original, String lowered) {
    if (!isLikelyFilesystemPath(original)) {
      return false;
    }
    return _m3uExtensions.any(lowered.endsWith);
  }

  bool _looksLikePlaylistQuery(Map<String, String> query) {
    if (query.isEmpty) return false;
    final playlistIndicators = [
      query['type'],
      query['output'],
      query['format'],
      query['extension'],
    ];
    for (final value in playlistIndicators) {
      if (value == null) continue;
      final lowered = value.toLowerCase();
      if (lowered.contains('m3u') || lowered.contains('playlist')) {
        return true;
      }
    }
    return false;
  }

  XtreamClassification? _detectBareXtreamHost(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.contains('://')) return null;
    final hasPort = trimmed.contains(':');
    final hasIllegalPath = trimmed.contains('/') || trimmed.contains('?');
    if (!hasPort || hasIllegalPath) {
      return null;
    }

    final canonical = canonicalizeScheme(trimmed, defaultScheme: 'https');
    final parsed = Uri.tryParse(canonical);
    if (parsed == null || parsed.host.isEmpty || !parsed.hasPort) {
      return null;
    }

    final port = parsed.port;
    const likelyXtreamPorts = {8000, 8080, 8081, 8880, 8881, 2086};
    final looksXtreamHost = _isLikelyXtreamHost(trimmed);
    if (!looksXtreamHost && !likelyXtreamPorts.contains(port)) {
      return null;
    }

    final base = _deriveXtreamHostOnly(trimmed);
    return XtreamClassification(baseUri: base, originalUri: parsed);
  }

  bool _isLikelyXtreamHost(String input) {
    final value = input.trim();
    if (value.isEmpty || value.contains('://')) return false;
    final withScheme = canonicalizeScheme(value, defaultScheme: 'https');
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return host.contains('xtream') ||
        host.contains('stbt') ||
        host.contains('iptv');
  }

  Uri _deriveXtreamHostOnly(String input) {
    final canonical = canonicalizeScheme(input, defaultScheme: 'https');
    final uri = Uri.parse(canonical);
    return ensureTrailingSlash(uri);
  }

  Uri _deriveXtreamBaseUri(Uri uri) {
    final lowered = uri.replace(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
    );
    final stripped = stripKnownFiles(lowered);
    return ensureTrailingSlash(stripped);
  }
}
