import 'package:openiptv/src/playback/playable.dart';

enum WindowsPlaybackSupport {
  okDirect,
  needsHeaders,
  hlsOrDash,
  unsupportedScheme,
  likelyCodecIssue,
}

WindowsPlaybackSupport classifyWindowsPlayable(Playable playable) {
  final scheme = playable.url.scheme.toLowerCase();
  if (scheme == 'udp' || scheme == 'rtmp' || scheme == 'rtsp') {
    return WindowsPlaybackSupport.unsupportedScheme;
  }

  final ext =
      (playable.containerExtension ?? guessExtensionFromUri(playable.url))
          .toLowerCase();
  if (_adaptiveExtensions.contains(ext)) {
    return WindowsPlaybackSupport.hlsOrDash;
  }

  if (_requiresHeaders(playable.headers)) {
    return WindowsPlaybackSupport.needsHeaders;
  }

  if (_likelyCodecExtensions.contains(ext)) {
    return WindowsPlaybackSupport.likelyCodecIssue;
  }

  return WindowsPlaybackSupport.okDirect;
}

String windowsSupportMessage(WindowsPlaybackSupport support) {
  return switch (support) {
    WindowsPlaybackSupport.okDirect =>
      'Playing stream with native Windows decoder.',
    WindowsPlaybackSupport.needsHeaders =>
      'This stream requires custom headers/cookies that Windows Media Foundation cannot send. Use an alternate player.',
    WindowsPlaybackSupport.hlsOrDash =>
      'Adaptive playlists (.m3u8/.mpd) are not supported by the Windows decoder. Use an alternate player.',
    WindowsPlaybackSupport.unsupportedScheme =>
      'This stream uses a protocol (udp://, rtmp://, …) unsupported by the Windows decoder.',
    WindowsPlaybackSupport.likelyCodecIssue =>
      'This stream uses a container/codec combination that is often unsupported on Windows (TS/MKV/HEVC).',
  };
}

bool _requiresHeaders(Map<String, String> headers) {
  if (headers.isEmpty) return false;
  const sensitiveKeys = {'user-agent', 'referer', 'cookie', 'authorization'};
  for (final entry in headers.entries) {
    if (sensitiveKeys.contains(entry.key.toLowerCase())) {
      return true;
    }
  }
  return false;
}

const Set<String> _adaptiveExtensions = {'m3u8', 'mpd'};

const Set<String> _likelyCodecExtensions = {'ts', 'mkv', 'hevc', '265', 'ac3'};
