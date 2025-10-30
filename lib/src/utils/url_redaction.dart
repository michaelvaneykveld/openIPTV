import 'dart:convert';

import 'package:dio/dio.dart';

/// Keywords that indicate a query parameter should never be logged.
const Set<String> _sensitiveQueryKeywords = {
  'user',
  'username',
  'login',
  'password',
  'pass',
  'pwd',
  'token',
  'access_token',
  'auth',
  'authorization',
  'apikey',
  'api_key',
  'key',
  'secret',
  'signature',
  'sid',
  'session',
};

/// Keywords that indicate the path segment contains sensitive data.
const Set<String> _sensitivePathKeywords = {
  'token',
  'secret',
  'signature',
  'password',
  'auth',
  'key',
  'session',
  'sid',
};

final RegExp _sensitiveKeyValue = RegExp(
  r'\b(user|username|login|password|token|access_token|auth|apikey|api_key|key|secret|signature)\s*([:=])\s*([^\s,&]+)',
  caseSensitive: false,
);

/// Returns a sanitised [Uri] with user info stripped, fragments removed, and
/// sensitive query/path components redacted.
Uri redactSensitiveUri(Uri uri, {bool dropAllQuery = false}) {
  final sanitizedSegments = <String>[];
  var previousSensitive = false;
  for (final segment in uri.pathSegments) {
    final lower = segment.toLowerCase();
    final isSensitive = _sensitivePathKeywords.any(
      (keyword) => lower.contains(keyword),
    );
    if (isSensitive || previousSensitive) {
      sanitizedSegments.add('***');
    } else {
      sanitizedSegments.add(segment);
    }
    previousSensitive = isSensitive;
  }

  final sanitizedPath = _rebuildPath(uri.path, sanitizedSegments);

  String? redactedQuery;
  if (!dropAllQuery && uri.hasQuery) {
    try {
      final parsed = Uri.splitQueryString(uri.query, encoding: utf8);
      final mutable = <String, String>{};
      parsed.forEach((key, value) {
        final keyLower = key.toLowerCase();
        final isSensitive = _sensitiveQueryKeywords.any(
          (keyword) => keyLower.contains(keyword),
        );
        if (!isSensitive) {
          mutable[key] = value;
        }
      });
      if (mutable.isNotEmpty) {
        redactedQuery = Uri(queryParameters: mutable).query;
      }
    } catch (_) {
      redactedQuery = null;
    }
  }

  if (dropAllQuery) {
    redactedQuery = null;
  }

  if (uri.host.isEmpty && uri.scheme.isEmpty) {
    return Uri(path: sanitizedPath, query: redactedQuery);
  }

  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: sanitizedPath,
    query: redactedQuery,
  );
}

/// Redacts common credential-like patterns in plain text.
String redactSensitiveText(String text) {
  var sanitized = text;
  sanitized = sanitized.replaceAllMapped(_sensitiveKeyValue, (match) {
    final key = match.group(1) ?? '';
    final separator = match.group(2) ?? '=';
    return '$key$separator***';
  });
  return sanitized;
}

/// Builds a short, redacted description for a [DioException] that avoids
/// leaking credentials in logs.
String describeDioError(DioException error) {
  final buffer = StringBuffer('DioException(${error.type.name})');
  final uri = error.requestOptions.uri;
  buffer
    ..write(' ')
    ..write(redactSensitiveUri(uri));

  final status = error.response?.statusCode;
  if (status != null) {
    buffer.write(' status=$status');
  }

  final message = error.message ?? error.error?.toString() ?? '';
  final sanitizedMessage = redactSensitiveText(message);
  if (sanitizedMessage.isNotEmpty) {
    buffer
      ..write(': ')
      ..write(sanitizedMessage);
  }

  return buffer.toString();
}

String _rebuildPath(String originalPath, List<String> sanitizedSegments) {
  if (sanitizedSegments.isEmpty) {
    if (originalPath == '/' || originalPath == '') {
      return originalPath;
    }
    return originalPath.startsWith('/') ? '/' : '';
  }

  final leadingSlash = originalPath.startsWith('/');
  final trailingSlash = originalPath.endsWith('/') && originalPath.length > 1;

  var rebuilt = sanitizedSegments.join('/');
  if (leadingSlash) {
    rebuilt = '/$rebuilt';
  }
  if (trailingSlash && !rebuilt.endsWith('/')) {
    rebuilt = '$rebuilt/';
  }
  return rebuilt;
}
