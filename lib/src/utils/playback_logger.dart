import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:openiptv/src/utils/url_redaction.dart';

/// Lightweight, redacted logging utilities for playback flows.
class PlaybackLogger {
  const PlaybackLogger._();

  static bool get _enabled =>
      true; // Always enabled for debugging playback issues

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
      if (includeFullUrl && uri != null)
        'url': redactSensitiveText(uri.toString()),
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

  /// Log media opening attempts with full details
  static void mediaOpen(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    String? title,
    bool isLive = false,
  }) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'action': 'open',
      'url': redactSensitiveText(_truncate(url, max: 200)),
      'isLive': isLive,
      if (title != null) 'title': title,
      if (headers != null && headers.isNotEmpty)
        'headers': headers.keys.toList(growable: false),
      if (contentType != null) 'contentType': contentType,
    };
    debugPrint('[Playback][Media] ${jsonEncode(payload)}');
  }

  /// Log successful playback start
  static void playbackStarted(String url, {String? title}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'action': 'started',
      'url': redactSensitiveText(_truncate(url, max: 150)),
      if (title != null) 'title': title,
    };
    debugPrint('[Playback][Success] ${jsonEncode(payload)}');
  }

  /// Log playback state changes
  static void playbackState(String state, {Map<String, Object?>? extra}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'state': state,
      if (extra != null) ...extra,
    };
    debugPrint('[Playback][State] ${jsonEncode(payload)}');
  }

  /// Log resolver activity
  static void resolverActivity(
    String activity, {
    String? bucket,
    String? providerKind,
    Map<String, Object?>? extra,
  }) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'activity': activity,
      if (bucket != null) 'bucket': bucket,
      if (providerKind != null) 'provider': providerKind,
      if (extra != null) ...extra,
    };
    debugPrint('[Playback][Resolver] ${jsonEncode(payload)}');
  }

  /// Log user actions and interactions
  static void userAction(String action, {Map<String, Object?>? extra}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'action': action,
      if (extra != null) ...extra,
    };
    debugPrint('[Playback][UserAction] ${jsonEncode(payload)}');
  }

  /// Generic log method
  static void log(String message, {String? tag, Map<String, Object?>? extra}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'message': message,
      if (tag != null) 'tag': tag,
      if (extra != null) ...extra,
    };
    debugPrint('[Playback][Log] ${jsonEncode(payload)}');
  }

  /// Generic error method
  static void error(String message, {Object? error, String? tag}) {
    if (!_enabled) return;
    final payload = <String, Object?>{
      'message': message,
      if (tag != null) 'tag': tag,
      if (error != null) 'error': '$error',
    };
    debugPrint('[Playback][Error] ${jsonEncode(payload)}');
  }
}
