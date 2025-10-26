import 'dart:core';

import 'package:openiptv/src/utils/url_normalization.dart';

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
/// Throws [FormatException] when the input cannot be parsed into a usable URI.
StalkerPortalNormalizationResult normalizeStalkerPortalInput(String rawInput) {
  final trimmed = rawInput.trim();
  if (trimmed.isEmpty) {
    throw const FormatException(
      'Enter the portal address provided by your operator.',
    );
  }

  final hasScheme = _looksLikeScheme(trimmed);
  final provisional = canonicalizeScheme(trimmed, defaultScheme: 'http');

  late Uri parsed;
  try {
    parsed = Uri.parse(provisional);
  } on FormatException {
    throw const FormatException('Portal address is not a valid URL.');
  }

  if (parsed.host.isEmpty) {
    throw const FormatException('Portal address is missing a host name.');
  }

  final lowered = parsed.replace(
    scheme: parsed.scheme.toLowerCase(),
    host: parsed.host.toLowerCase(),
  );

  final stripped = stripKnownFiles(
    lowered,
    knownFiles: const {'portal.php', 'index.php', 'load.php', 'server.php'},
  );

  final canonical = ensureTrailingSlash(stripped);

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

/// Represents a portal discovery candidate: the base URI that should be probed
/// along with backend endpoints commonly exposed by Ministra/Stalker installs.
class StalkerPortalCandidate {
  final Uri baseUri;
  final Uri portalPhpUri;
  final Uri? serverLoadUri;

  const StalkerPortalCandidate({
    required this.baseUri,
    required this.portalPhpUri,
    this.serverLoadUri,
  });

  @override
  String toString() => baseUri.toString();
}

/// Generates an ordered set of candidate portal locations derived from the
/// normalised URI. The ordering mirrors the typical deployment layout:
/// `/stalker_portal/c/` → `/c/` → `/stalker_portal/` → root.
///
/// Each candidate includes the corresponding `portal.php` endpoint and, when
/// appropriate, the neighbouring `server/load.php` path that powers the STB API.
List<StalkerPortalCandidate> generateStalkerPortalCandidates(
  StalkerPortalNormalizationResult normalized,
) {
  final canonical = normalized.canonicalUri;
  final basePaths = _deriveCandidateBasePaths(canonical);
  final candidates = <StalkerPortalCandidate>[];

  for (final path in basePaths) {
    final base = canonical.replace(path: path, query: null, fragment: null);
    final portalPhp = base.resolve('portal.php');

    Uri? serverLoad;
    final lowerPath = base.path.toLowerCase();
    if (lowerPath.endsWith('/c/')) {
      serverLoad = base.resolve('../server/load.php');
    } else if (lowerPath.endsWith('/stalker_portal/')) {
      serverLoad = base.resolve('server/load.php');
    }

    candidates.add(
      StalkerPortalCandidate(
        baseUri: base,
        portalPhpUri: portalPhp,
        serverLoadUri: serverLoad,
      ),
    );
  }

  return candidates;
}

List<String> _deriveCandidateBasePaths(Uri canonical) {
  final added = <String>{};
  final ordered = <String>[];

  void add(String path) {
    if (added.add(path)) {
      ordered.add(path);
    }
  }

  final segments = canonical.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList();
  final lowerSegments = segments
      .map((segment) => segment.toLowerCase())
      .toList();
  final isClassic =
      lowerSegments.length >= 2 &&
      lowerSegments[0] == 'stalker_portal' &&
      lowerSegments[1] == 'c';
  final isBareC = lowerSegments.length == 1 && lowerSegments.first == 'c';
  final existingPath = segments.isEmpty ? '/' : '/${segments.join('/')}/';

  if (segments.isNotEmpty) {
    add(existingPath);
  }

  if (!isClassic) {
    add('/stalker_portal/c/');
  } else {
    add(existingPath);
  }

  if (!isBareC) {
    add('/c/');
  } else {
    add(existingPath);
  }

  add('/stalker_portal/');
  add('/');

  return ordered;
}
