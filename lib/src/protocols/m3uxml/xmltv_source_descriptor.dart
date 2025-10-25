/// Describes the origin of an XMLTV Electronic Programme Guide.
///
/// Just like M3U playlists, EPG data may come from a remote URL or from a
/// locally imported file. Keeping the source details in dedicated classes
/// allows the ingestion pipeline to stay agnostic of where the bytes come
/// from, making it trivial to add caching, background sync, or validation.
abstract class XmltvSourceDescriptor {
  /// Optional name displayed in settings or logs.
  final String? displayName;

  const XmltvSourceDescriptor({this.displayName});

  /// Flags whether the source requires network access.
  bool get isRemote;
}

/// XMLTV source retrieved over HTTP(S).
class XmltvUrlSource extends XmltvSourceDescriptor {
  /// URL of the XMLTV feed. Many providers offer compressed XMLTV files
  /// (gzip/xz) which the client must detect and decompress.
  final Uri epgUri;

  /// Extra headers to send while downloading the guide. Some providers cache
  /// responses aggressively and expect `If-Modified-Since`/`ETag`, but those
  /// will be handled at a higher layer; the field exists so we can forward
  /// custom `User-Agent` values or API keys as necessary.
  final Map<String, String> headers;

  const XmltvUrlSource({
    required this.epgUri,
    Map<String, String>? headers,
    String? displayName,
  })  : headers = headers ?? const {},
        super(displayName: displayName);

  @override
  bool get isRemote => true;
}

/// XMLTV source backed by a local file.
class XmltvFileSource extends XmltvSourceDescriptor {
  /// Absolute path to the XMLTV document on disk.
  final String filePath;

  /// Optional original filename preserved for presentation purposes.
  final String? originalFileName;

  const XmltvFileSource({
    required this.filePath,
    this.originalFileName,
    String? displayName,
  }) : super(displayName: displayName);

  @override
  bool get isRemote => false;
}

