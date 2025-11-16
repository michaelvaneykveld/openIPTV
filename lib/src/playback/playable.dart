import 'package:collection/collection.dart';

class DrmHint {
  const DrmHint({
    required this.scheme,
    required this.licenseUri,
    this.headers = const {},
  });

  final String scheme;
  final Uri licenseUri;
  final Map<String, String> headers;
}

class Playable {
  const Playable({
    required this.url,
    required this.isLive,
    this.headers = const {},
    this.mimeHint,
    this.containerExtension,
    this.drm,
    this.seekStart,
    this.durationHint,
    this.ffmpegCommand,
    this.rawUrl,
  });

  final Uri url;
  final bool isLive;
  final Map<String, String> headers;
  final String? mimeHint;
  final String? containerExtension;
  final DrmHint? drm;
  final Duration? seekStart;
  final Duration? durationHint;
  final String? ffmpegCommand;

  /// Raw URL string to use instead of url.toString() when available.
  /// Used to preserve unencoded query parameters (e.g., Stalker MAC addresses).
  final String? rawUrl;

  Playable copyWith({
    Uri? url,
    bool? isLive,
    Map<String, String>? headers,
    String? mimeHint,
    String? containerExtension,
    DrmHint? drm,
    Duration? seekStart,
    Duration? durationHint,
    String? ffmpegCommand,
    String? rawUrl,
  }) {
    return Playable(
      url: url ?? this.url,
      isLive: isLive ?? this.isLive,
      headers: headers ?? this.headers,
      mimeHint: mimeHint ?? this.mimeHint,
      containerExtension: containerExtension ?? this.containerExtension,
      drm: drm ?? this.drm,
      seekStart: seekStart ?? this.seekStart,
      durationHint: durationHint ?? this.durationHint,
      ffmpegCommand: ffmpegCommand ?? this.ffmpegCommand,
      rawUrl: rawUrl ?? this.rawUrl,
    );
  }
}

String guessExtensionFromUri(Uri uri) {
  final path = uri.path.toLowerCase();
  final candidates = [
    '.m3u8',
    '.mpd',
    '.mp4',
    '.ts',
    '.aac',
    '.mp3',
    '.m4a',
    '.mkv',
  ];
  for (final candidate in candidates) {
    if (path.endsWith(candidate)) {
      return candidate.substring(1);
    }
  }
  return path.split('.').lastWhereOrNull((_) => true) ?? 'unknown';
}

String? guessMimeFromUri(Uri uri) {
  switch (guessExtensionFromUri(uri)) {
    case 'm3u8':
      return 'application/vnd.apple.mpegurl';
    case 'mpd':
      return 'application/dash+xml';
    case 'mp4':
      return 'video/mp4';
    case 'ts':
      return 'video/mp2t';
    case 'aac':
      return 'audio/aac';
    case 'mp3':
      return 'audio/mpeg';
    case 'm4a':
      return 'audio/mp4';
    default:
      return null;
  }
}
