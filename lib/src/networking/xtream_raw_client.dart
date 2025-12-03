import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:openiptv/src/utils/playback_logger.dart';

/// Raw TCP socket HTTP client for Xtream API and streaming.
///
/// Bypasses HttpClient to gain complete control over:
/// - Header order and casing
/// - No automatic gzip/chunked headers
/// - IPv4-only connections
/// - okhttp-compatible fingerprinting (confirmed working)
class XtreamRawClient {
  static const String _defaultUserAgent = 'okhttp/4.9.3';

  /// Connection timeout for socket operations
  final Duration timeout;

  /// Enable detailed logging
  final bool enableLogging;

  XtreamRawClient({
    this.timeout = const Duration(seconds: 15),
    this.enableLogging = true,
  });

  /// Perform HTTP GET request using raw TCP socket.
  ///
  /// Returns response body as String.
  /// Throws SocketException, TimeoutException, or HttpException on errors.
  Future<String> get(
    String host,
    int port,
    String path,
    Map<String, String> headers,
  ) async {
    final socket = await _connect(host, port);

    try {
      // Send HTTP request
      await _sendRequest(socket, 'GET', host, port, path, headers);

      // Read response
      final response = await _readResponse(socket);

      if (enableLogging) {
        _logResponse(response);
      }

      // Check for HTTP errors
      if (response.statusCode >= 400) {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          uri: Uri(scheme: 'http', host: host, port: port, path: path),
        );
      }

      return response.body;
    } finally {
      await socket.close();
    }
  }

  /// Connect to host using IPv4-only raw TCP socket
  Future<Socket> _connect(String host, int port) async {
    if (enableLogging) {
      PlaybackLogger.log(
        'Connecting to $host:$port (IPv4 only)',
        tag: 'xtream-raw',
      );
    }

    try {
      // Force IPv4 by using anyIPv4 as source address
      final socket = await Socket.connect(
        host,
        port,
        sourceAddress: InternetAddress.anyIPv4,
        timeout: timeout,
      );

      if (enableLogging) {
        PlaybackLogger.log(
          'Connected: ${socket.remoteAddress}:${socket.remotePort}',
          tag: 'xtream-raw',
        );
      }

      return socket;
    } catch (e) {
      if (enableLogging) {
        PlaybackLogger.error('Connection failed', error: e, tag: 'xtream-raw');
      }
      rethrow;
    }
  }

  /// Send HTTP request with exact header order and casing
  ///
  /// CRITICAL: This mimics OkHttp/Android TCP packet boundaries to bypass
  /// anti-restream guards (xGuard, StormGuard, AntiPlayer) that fingerprint
  /// TCP behavior. The exact CRLF boundaries and single-packet flush are
  /// essential to match TiviMate's ExoPlayer implementation.
  Future<void> _sendRequest(
    Socket socket,
    String method,
    String host,
    int port,
    String path,
    Map<String, String> customHeaders,
  ) async {
    // Build request as raw bytes for exact control over TCP packets
    final lines = <String>[];

    // Request line
    lines.add('$method $path HTTP/1.1');

    // Build headers in exact OkHttp/Android order for TCP fingerprinting
    // CRITICAL: Only send headers that Android/OkHttp actually sends
    // Extra headers trigger Cloudflare bot detection
    final orderedHeaders = <MapEntry<String, String>>[];

    // 1. Host (always first) - include port if non-standard (not 80)
    final hostHeader = port == 80 ? host : '$host:$port';
    orderedHeaders.add(MapEntry('Host', hostHeader));

    // 2. Connection (from custom or default)
    orderedHeaders.add(
      MapEntry('Connection', customHeaders['Connection'] ?? 'close'),
    );

    // 3. User-Agent (from custom or default)
    orderedHeaders.add(
      MapEntry('User-Agent', customHeaders['User-Agent'] ?? _defaultUserAgent),
    );

    // 4. Accept-Encoding (only if explicitly provided - Android may not send for .ts)
    if (customHeaders.containsKey('Accept-Encoding')) {
      orderedHeaders.add(
        MapEntry('Accept-Encoding', customHeaders['Accept-Encoding']!),
      );
    }

    // 5. Custom headers (excluding standard ones already added)
    final standardKeys = {
      'Host',
      'Connection',
      'User-Agent',
      'Accept-Encoding', // Only added if explicitly provided
    };
    for (final entry in customHeaders.entries) {
      if (!standardKeys.contains(entry.key)) {
        orderedHeaders.add(MapEntry(entry.key, entry.value));
      }
    }

    // CRITICAL: DO NOT add Accept, Accept-Language, or Icy-MetaData
    // Android/TiviMate doesn't send these headers, and they trigger 401

    // Add headers to lines (preserving exact order from orderedHeaders)
    for (final entry in orderedHeaders) {
      lines.add('${entry.key}: ${entry.value}');
    }

    // Join with CRLF and add final CRLF - exact byte boundaries
    final requestStr = '${lines.join('\r\n')}\r\n\r\n';

    if (enableLogging) {
      PlaybackLogger.log('=== RAW REQUEST ===', tag: 'xtream-raw');
      // Log each line separately to see exact formatting
      for (final line in lines) {
        PlaybackLogger.log(line, tag: 'xtream-raw');
      }
      PlaybackLogger.log('(followed by \\r\\n\\r\\n)', tag: 'xtream-raw');
      PlaybackLogger.log(
        'Request bytes length: ${requestStr.length}',
        tag: 'xtream-raw',
      );

      // Debug: Show hex of first/last bytes to verify CRLF
      final bytes = requestStr.codeUnits;
      if (bytes.length > 20) {
        PlaybackLogger.log(
          'First 20 bytes (hex): ${bytes.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
          tag: 'xtream-raw',
        );
        PlaybackLogger.log(
          'Last 10 bytes (hex): ${bytes.skip(bytes.length - 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
          tag: 'xtream-raw',
        );
      }
      PlaybackLogger.log('==================', tag: 'xtream-raw');
    }

    // Send as single packet - critical for TCP fingerprint matching
    socket.write(requestStr);
    await socket.flush();
  }

  /// Read full HTTP response (headers + body)
  Future<_HttpResponse> _readResponse(Socket socket) async {
    final buffer = <int>[];
    _HttpResponseWithBodyPrefix? headerResult;

    // Read all data from socket in one go
    await for (final chunk in socket) {
      buffer.addAll(chunk);

      // If we haven't parsed headers yet, try to find them
      if (headerResult == null) {
        for (var i = 0; i <= buffer.length - 4; i++) {
          if (buffer[i] == 13 &&
              buffer[i + 1] == 10 &&
              buffer[i + 2] == 13 &&
              buffer[i + 3] == 10) {
            // Found end of headers
            final headerBytes = buffer.sublist(0, i);
            final headerText = utf8.decode(headerBytes, allowMalformed: true);
            final headerLines = headerText.split('\r\n');

            if (headerLines.isEmpty) {
              throw const SocketException('No response received');
            }

            // Parse status line
            final statusLine = headerLines[0];
            final statusMatch = RegExp(
              r'HTTP/\d\.\d\s+(\d+)\s+(.+)',
            ).firstMatch(statusLine);
            if (statusMatch == null) {
              throw FormatException('Invalid HTTP status line: $statusLine');
            }

            final statusCode = int.parse(statusMatch.group(1)!);
            final reasonPhrase = statusMatch.group(2)!;

            // Parse headers
            final headers = <String, String>{};
            for (var j = 1; j < headerLines.length; j++) {
              final line = headerLines[j];
              if (line.isEmpty) continue;

              final colonIndex = line.indexOf(':');
              if (colonIndex == -1) continue;

              final name = line.substring(0, colonIndex).trim().toLowerCase();
              final value = line.substring(colonIndex + 1).trim();
              headers[name] = value;
            }

            headerResult = _HttpResponseWithBodyPrefix(
              statusCode: statusCode,
              reasonPhrase: reasonPhrase,
              headers: headers,
              bodyPrefix: [],
            );

            // Remove headers from buffer, leaving only body
            buffer.removeRange(0, i + 4);
            break;
          }
        }
      }
    }

    if (headerResult == null) {
      throw const SocketException('Connection closed before headers received');
    }

    // Decode body based on transfer encoding
    String body;
    final transferEncoding = headerResult.headers['transfer-encoding'];
    if (transferEncoding != null && transferEncoding.contains('chunked')) {
      // Decode chunked transfer encoding
      body = _decodeChunkedBody(buffer);
    } else {
      // Plain body
      body = utf8.decode(buffer, allowMalformed: true);
    }

    return _HttpResponse(
      statusCode: headerResult.statusCode,
      reasonPhrase: headerResult.reasonPhrase,
      headers: headerResult.headers,
      body: body,
    );
  }

  /// Decode chunked transfer encoding body
  String _decodeChunkedBody(List<int> chunkedData) {
    final decodedBytes = <int>[];
    var offset = 0;

    while (offset < chunkedData.length) {
      // Find chunk size line (ends with \r\n)
      final crlfIndex = _findCRLF(chunkedData, offset);
      if (crlfIndex == -1) break;

      // Parse chunk size (hex)
      final chunkSizeLine = utf8
          .decode(chunkedData.sublist(offset, crlfIndex), allowMalformed: true)
          .trim();

      if (chunkSizeLine.isEmpty) break;

      // Parse hex chunk size
      final chunkSize = int.tryParse(chunkSizeLine, radix: 16);
      if (chunkSize == null) {
        // Invalid chunk size, might be end of chunks
        break;
      }

      if (chunkSize == 0) {
        // Last chunk
        break;
      }

      // Read chunk data
      final chunkStart = crlfIndex + 2; // Skip \r\n
      final chunkEnd = chunkStart + chunkSize;

      if (chunkEnd > chunkedData.length) {
        // Incomplete chunk
        break;
      }

      decodedBytes.addAll(chunkedData.sublist(chunkStart, chunkEnd));

      // Move to next chunk (skip chunk data + \r\n)
      offset = chunkEnd + 2;
    }

    return utf8.decode(decodedBytes, allowMalformed: true);
  }

  /// Find CRLF (\r\n) in byte list starting from offset
  int _findCRLF(List<int> bytes, int offset) {
    for (var i = offset; i < bytes.length - 1; i++) {
      if (bytes[i] == 13 && bytes[i + 1] == 10) {
        return i;
      }
    }
    return -1;
  }

  /// Log response details
  void _logResponse(_HttpResponse response) {
    PlaybackLogger.log('=== RAW RESPONSE ===', tag: 'xtream-raw');
    PlaybackLogger.log(
      'HTTP ${response.statusCode} ${response.reasonPhrase}',
      tag: 'xtream-raw',
    );
    PlaybackLogger.log('Headers:', tag: 'xtream-raw');
    response.headers.forEach((key, value) {
      PlaybackLogger.log('  $key: $value', tag: 'xtream-raw');
    });

    // Detect gzip
    if (response.headers['content-encoding']?.contains('gzip') ?? false) {
      PlaybackLogger.log(
        '⚠️  GZIP DETECTED - Server returned compressed response!',
        tag: 'xtream-raw',
      );
    }

    // Show first 256 bytes of body
    final preview = response.body.length > 256
        ? response.body.substring(0, 256)
        : response.body;
    PlaybackLogger.log(
      'Body preview (${response.body.length} bytes):',
      tag: 'xtream-raw',
    );
    PlaybackLogger.log(preview, tag: 'xtream-raw');
    PlaybackLogger.log('===================', tag: 'xtream-raw');
  }
}

/// HTTP response container
class _HttpResponse {
  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final String body;

  _HttpResponse({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.body,
  });
}

/// HTTP response headers with buffered body prefix
class _HttpResponseWithBodyPrefix {
  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final List<int> bodyPrefix;

  _HttpResponseWithBodyPrefix({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.bodyPrefix,
  });
}
