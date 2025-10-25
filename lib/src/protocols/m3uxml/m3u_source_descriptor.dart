/// Describes the origin of an M3U playlist.
///
/// M3U ingestion can happen via remote URLs (most providers) or by importing
/// a local file (user-supplied playlist). The source descriptor hierarchy
/// captures these two cases so higher-level code can treat both uniformly
/// without scattering `if (isUrl)` checks throughout the application.
abstract class M3uSourceDescriptor {
  /// Optional friendly label that helps UI surfaces (profile pickers, logs)
  /// show human-readable information about the playlist source.
  final String? displayName;

  const M3uSourceDescriptor({this.displayName});

  /// Indicates whether this source requires network access.
  bool get isRemote;
}

/// M3U source backed by an HTTP(S) URL.
class M3uUrlSource extends M3uSourceDescriptor {
  /// Absolute playlist URL. It can already contain query parameters for
  /// username/password or token-based access as used by many providers.
  final Uri playlistUri;

  /// Optional HTTP headers to send when retrieving the playlist.
  /// Hypnotix highlights that some providers demand a specific `User-Agent`
  /// or additional authentication headers, so we expose a hook here.
  final Map<String, String> headers;

  /// Optional query override used when the provider expects the classic
  /// Xtream-style `get.php` endpoint with additional parameters. Caller
  /// can supply a map and the client will merge it with the URI query.
  final Map<String, dynamic> extraQuery;

  const M3uUrlSource({
    required this.playlistUri,
    super.displayName,
    Map<String, String>? headers,
    Map<String, dynamic>? extraQuery,
  }) : headers = headers ?? const {},
       extraQuery = extraQuery ?? const {};

  @override
  bool get isRemote => true;
}

/// M3U source backed by a file on disk (local import).
class M3uFileSource extends M3uSourceDescriptor {
  /// Absolute path to the playlist file on disk.
  final String filePath;

  /// Optional filename as supplied by the user. Useful when the path is a
  /// temporary upload but the original filename needs to be preserved in UI.
  final String? originalFileName;

  const M3uFileSource({
    required this.filePath,
    this.originalFileName,
    super.displayName,
  });

  @override
  bool get isRemote => false;
}
