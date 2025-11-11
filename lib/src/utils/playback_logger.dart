import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:openiptv/src/utils/url_redaction.dart';

/// Lightweight, redacted logging utilities for playback flows.
class PlaybackLogger {
  const PlaybackLogger._();

  static bool get _enabled => kDebugMode;

  static void stalker(
    String stage, {
    required Uri portal,
    required String module,
    String? command,
    Uri? resolvedUri,
    Map<String, String>? headers,
    Object? error,
  }) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'stage': stage,
      'portal': portal.host,
      'module': module,
      if (command != null && command.isNotEmpty)
        'cmd': _truncate(redactSensitiveText(command)),
      if (resolvedUri != null) 'stream': _summarizeUri(resolvedUri),
      if (headers != null && headers.isNotEmpty)
        'headers': headers.keys.toList(growable: false),
      if (error != null) 'error': '$error',
    };
    debugPrint('[Playback][Stalker] ${jsonEncode(payload)}');
  }

  static void playableDrop(String reason, {Uri? uri, Object? error}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'reason': reason,
      if (uri != null) 'stream': _summarizeUri(uri),
      if (error != null) 'error': '$error',
    };
    debugPrint('[Playback][Playable] ${jsonEncode(payload)}');
  }

  static void videoError(String stage, {String? description, Object? error}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'stage': stage,
      if (description != null) 'description': description,
      if (error != null) 'error': '$error',
    };
    debugPrint('[Playback][Video] ${jsonEncode(payload)}');
  }

  static void videoInfo(
    String stage, {
    Uri? uri,
    Map<String, String>? headers,
    Map<String, Object?>? extra,
    bool includeFullUrl = false,
  }) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'stage': stage,
      if (uri != null) 'stream': _summarizeUri(uri),
      if (includeFullUrl && uri != null) 'url': redactSensitiveText(uri.toString()),
      if (headers != null && headers.isNotEmpty)
        'headers': headers.keys.toList(growable: false),
      if (extra != null) ...extra,
    };
    debugPrint('[Playback][VideoInfo] ${jsonEncode(payload)}');
  }

  static Map<String, Object?> _summarizeUri(Uri uri) {
    return {
      'scheme': uri.scheme,
      'host': uri.host,
      if (uri.hasPort) 'port': uri.port,
      'path': uri.pathSegments.take(2).join('/'),
      'hasQuery': uri.hasQuery,
      'hash': uri.toString().hashCode,
    };
  }

  static String _truncate(String value, {int max = 96}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max - 3)}...';
  }
}
