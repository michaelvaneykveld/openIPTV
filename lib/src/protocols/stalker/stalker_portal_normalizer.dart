import 'dart:core';

/// Result returned after normalising a user-supplied Stalker/Ministra portal
/// address into a canonical URI that downstream discovery steps can consume.
class StalkerPortalNormalizationResult {
  final Uri canonicalUri;
  final bool hadExplicitScheme;
  final bool hadExplicitPort;

  const StalkerPortalNormalizationResult({
    required this.canonicalUri,
    required this.hadExplicitScheme,
    required this.hadExplicitPort,
  });

  @override
  String toString() => canonicalUri.toString();
}

/// Normalises raw user input into a canonical portal URI.
///
/// Responsibilities:
/// * apply default scheme (https) when missing;
/// * ensure host is present and lower-cased;
/// * trim query/fragment noise;
/// * strip well-known file paths (portal.php, index.php, server/load.php, ...);
/// * collapse duplicate slashes and ensure directory semantics (trailing slash).
///
/// The routine intentionally keeps any user-specified scheme or port so that
/// later discovery/probe stages can respect those preferences.
///
/// Throws [FormatException] when the input cannot be parsed into a usable URI.
StalkerPortalNormalizationResult normalizeStalkerPortalInput(String rawInput) {
  final trimmed = rawInput.trim();
  if (trimmed.isEmpty) {
    throw const FormatException(
      'Enter the portal address provided by your operator.',
    );
  }

  final hasScheme = _looksLikeScheme(trimmed);
  final provisional = hasScheme ? trimmed : 'https://$trimmed';

  late Uri parsed;
  try {
    parsed = Uri.parse(provisional);
  } on FormatException {
    throw const FormatException('Portal address is not a valid URL.');
  }

  if (parsed.host.isEmpty) {
    throw const FormatException('Portal address is missing a host name.');
  }

  final scheme = (hasScheme ? parsed.scheme : 'https').toLowerCase();

  final sanitizedSegments = _sanitizeSegments(parsed.pathSegments, parsed.path);
  final canonicalPath = sanitizedSegments.isEmpty
      ? '/'
      : '/${sanitizedSegments.join('/')}/';

  final canonical = Uri(
    scheme: scheme,
    host: parsed.host.toLowerCase(),
    port: parsed.hasPort ? parsed.port : null,
    path: canonicalPath == '//' ? '/' : canonicalPath,
  );

  return StalkerPortalNormalizationResult(
    canonicalUri: canonical,
    hadExplicitScheme: hasScheme,
    hadExplicitPort: parsed.hasPort,
  );
}

bool _looksLikeScheme(String value) {
  final schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-.]*://');
  return schemePattern.hasMatch(value);
}

List<String> _sanitizeSegments(List<String> segments, String originalPath) {
  if (segments.isEmpty) {
    return const [];
  }

  final cleaned = <String>[];
  final buffer = List<String>.from(segments);

  // Remove empty segments caused by leading/trailing slashes.
  buffer.removeWhere((segment) => segment.isEmpty);

  if (buffer.isEmpty) {
    return const [];
  }

  // Drop file-like trailing segments (portal.php, index.php, load.php, etc.).
  while (buffer.isNotEmpty && _isFileSegment(buffer.last)) {
    buffer.removeLast();
  }

  cleaned.addAll(buffer);

  // Preserve original trailing slash semantics when the path already ended in "/".
  final hadTrailingSlash =
      originalPath.isNotEmpty && originalPath.endsWith('/');
  if (!hadTrailingSlash && cleaned.isNotEmpty) {
    // No-op: canonical path builder will append a trailing slash anyway.
  }

  return cleaned;
}

bool _isFileSegment(String segment) {
  final lower = segment.toLowerCase();
  if (!lower.contains('.')) {
    return false;
  }
  const knownFiles = {'portal.php', 'index.php', 'load.php', 'server.php'};
  return knownFiles.contains(lower) || lower.endsWith('.php');
}
