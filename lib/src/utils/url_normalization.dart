/// Regular expression used to detect whether a URL already contains a scheme.
final RegExp _schemePattern = RegExp(
  r'^[a-zA-Z][a-zA-Z0-9+\-.]*://',
  caseSensitive: false,
);

const Set<String> _defaultKnownFiles = {
  'portal.php',
  'index.php',
  'load.php',
  'server.php',
  'player_api.php',
  'get.php',
  'xmltv.php',
  'api.php',
};

/// Ensures the provided [value] has a scheme, defaulting to [defaultScheme].
///
/// Returns the canonicalised string. Callers are expected to parse the result
/// into a [Uri]. Throws [FormatException] when the input is empty.
String canonicalizeScheme(String value, {String defaultScheme = 'https'}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('URL cannot be empty.');
  }
  if (_schemePattern.hasMatch(trimmed)) {
    return trimmed;
  }
  return '$defaultScheme://$trimmed';
}

/// Returns a new [Uri] with an explicit port. If the original URI already
/// contains a port, it is preserved. Otherwise defaults to 443 for HTTPS and
/// 80 for HTTP.
Uri normalizePort(Uri uri) {
  if (uri.hasPort) {
    return uri;
  }

  final scheme = uri.scheme.toLowerCase();
  final defaultPort = switch (scheme) {
    'https' => 443,
    'http' => 80,
    _ => null,
  };

  if (defaultPort == null) {
    return uri;
  }

  return uri.replace(port: defaultPort);
}

/// Removes trailing known file segments (e.g. `player_api.php`) from the URI
/// path and clears the query/fragment components.
Uri stripKnownFiles(Uri uri, {Iterable<String>? knownFiles}) {
  final files = (knownFiles ?? _defaultKnownFiles)
      .map((entry) => entry.toLowerCase())
      .toSet();

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  while (segments.isNotEmpty) {
    final last = segments.last.toLowerCase();
    if (files.contains(last)) {
      segments.removeLast();
    } else {
      break;
    }
  }

  final path = segments.isEmpty ? '' : '/${segments.join('/')}';

  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
  );
}

/// Ensures the path ends with a trailing slash and collapses duplicate slashes.
Uri ensureTrailingSlash(Uri uri) {
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final path = segments.isEmpty ? '/' : '/${segments.join('/')}/';
  return uri.replace(path: path);
}
