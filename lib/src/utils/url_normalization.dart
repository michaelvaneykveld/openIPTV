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

/// Attempts to parse [value] into an HTTP(S) [Uri] even when the scheme is
/// missing. Returns `null` when the input cannot reasonably be interpreted as
/// a web URL.
Uri? tryParseLenientHttpUri(
  String value, {
  String defaultScheme = 'https',
}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  if (isLikelyFilesystemPath(trimmed)) {
    return null;
  }

  Uri? parsed = Uri.tryParse(trimmed);
  if (_isHttpUri(parsed)) {
    return parsed;
  }

  final withScheme =
      _schemePattern.hasMatch(trimmed) ? trimmed : '$defaultScheme://$trimmed';
  parsed = Uri.tryParse(withScheme);
  if (_isHttpUri(parsed)) {
    return parsed;
  }

  final ipv6Adjusted = _ensureBracketedIpv6(withScheme);
  if (ipv6Adjusted != null) {
    final retry = Uri.tryParse(ipv6Adjusted);
    if (_isHttpUri(retry)) {
      return retry;
    }
  }

  return null;
}

/// Returns true when [uri] represents an HTTP(S) endpoint with a non-empty host.
bool _isHttpUri(Uri? uri) {
  if (uri == null) return false;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return false;
  }
  return uri.host.isNotEmpty;
}

/// Detects local filesystem-style paths (Windows, UNC, Unix).
bool isLikelyFilesystemPath(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final windowsDrive = RegExp(r'^[a-zA-Z]:[\\/]');
  if (windowsDrive.hasMatch(trimmed)) return true;
  if (trimmed.startsWith('\\\\')) return true;
  if (trimmed.startsWith('/')) return true;
  if (trimmed.startsWith('~/')) return true;
  return false;
}

String? _ensureBracketedIpv6(String value) {
  final schemeBreak = value.indexOf('://');
  if (schemeBreak == -1) {
    return null;
  }

  final scheme = value.substring(0, schemeBreak);
  final remainder = value.substring(schemeBreak + 3);
  final pathStart = remainder.indexOf('/');
  final authority =
      pathStart == -1 ? remainder : remainder.substring(0, pathStart);
  final tail = pathStart == -1 ? '' : remainder.substring(pathStart);

  if (authority.isEmpty ||
      authority.contains('[') ||
      !authority.contains(':')) {
    return null;
  }

  final atIndex = authority.lastIndexOf('@');
  final userInfo =
      atIndex == -1 ? '' : authority.substring(0, atIndex + 1);
  final hostPort =
      atIndex == -1 ? authority : authority.substring(atIndex + 1);

  var host = hostPort;
  var portSuffix = '';
  final lastColon = hostPort.lastIndexOf(':');
  if (lastColon != -1) {
    final potentialPort = hostPort.substring(lastColon + 1);
    if (RegExp(r'^\d+$').hasMatch(potentialPort)) {
      host = hostPort.substring(0, lastColon);
      portSuffix = ':$potentialPort';
    }
  }

  if (!_looksLikeIpv6Host(host)) {
    return null;
  }

  return '$scheme://$userInfo[$host]$portSuffix$tail';
}

bool _looksLikeIpv6Host(String host) {
  if (host.isEmpty) return false;
  final zoneIndex = host.indexOf('%');
  final plainHost = zoneIndex == -1 ? host : host.substring(0, zoneIndex);
  if (!plainHost.contains(':')) return false;

  final doubleColon = plainHost.indexOf('::');
  if (doubleColon != -1 &&
      plainHost.indexOf('::', doubleColon + 1) != -1) {
    return false;
  }

  final parts = plainHost.split(':');
  if (parts.length > 8) return false;
  final hexPattern = RegExp(r'^[0-9A-Fa-f]{0,4}$');
  for (final part in parts) {
    if (part.isEmpty) continue;
    if (!hexPattern.hasMatch(part)) {
      return false;
    }
  }
  return true;
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
