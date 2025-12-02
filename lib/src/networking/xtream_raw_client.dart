import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Raw TCP socket HTTP client for Xtream API and streaming.
///
/// Bypasses HttpClient to gain complete control over:
/// - Header order and casing
/// - No automatic gzip/chunked headers
/// - IPv4-only connections
/// - TiviMate-compatible fingerprinting
class XtreamRawClient {
  static const String _defaultUserAgent =
      'Dalvik/2.1.0 (Linux; U; Android 11; TiviMate)';

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
      await _sendRequest(socket, 'GET', host, path, headers);

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

  /// Open streaming connection using raw TCP socket.
  ///
  /// Returns StreamWithHeaders containing socket stream and HTTP status/headers.
  /// Caller is responsible for closing the stream.
  Future<StreamWithHeaders> openStream(
    String host,
    int port,
    String path,
    Map<String, String> headers,
  ) async {
    final socket = await _connect(host, port);

    try {
      // Send HTTP request
      await _sendRequest(socket, 'GET', host, path, headers);

      // Parse headers from socket stream without canceling subscription
      final headerResult = await _parseHeadersFromStream(socket);

      if (enableLogging) {
        print(
          '[xtream-raw] Stream opened: HTTP ${headerResult.statusCode} ${headerResult.reasonPhrase}',
        );
        print('[xtream-raw] Headers: ${headerResult.headers}');
      }

      // Check for HTTP errors
      if (headerResult.statusCode >= 400) {
        await socket.close();
        throw HttpException(
          'HTTP ${headerResult.statusCode}: ${headerResult.reasonPhrase}',
          uri: Uri(scheme: 'http', host: host, port: port, path: path),
        );
      }

      // Return the stream controller's stream that continues after headers
      return StreamWithHeaders(
        stream: headerResult.bodyStream,
        statusCode: headerResult.statusCode,
        reasonPhrase: headerResult.reasonPhrase,
        headers: headerResult.headers,
        socket: socket,
      );
    } catch (e) {
      await socket.close();
      rethrow;
    }
  }

  /// Connect to host using IPv4-only raw TCP socket
  Future<Socket> _connect(String host, int port) async {
    if (enableLogging) {
      print('[xtream-raw] Connecting to $host:$port (IPv4 only)');
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
        print(
          '[xtream-raw] Connected: ${socket.remoteAddress}:${socket.remotePort}',
        );
      }

      return socket;
    } catch (e) {
      if (enableLogging) {
        print('[xtream-raw] Connection failed: $e');
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
    String path,
    Map<String, String> customHeaders,
  ) async {
    // Build request as raw bytes for exact control over TCP packets
    final lines = <String>[];

    // Request line
    lines.add('$method $path HTTP/1.1');

    // Build headers in exact OkHttp/Android order for TCP fingerprinting
    // The order is critical - anti-restream guards check this!
    final orderedHeaders = <MapEntry<String, String>>[];

    // 1. Host (always first)
    orderedHeaders.add(MapEntry('Host', host));

    // 2. Connection (from custom or default)
    orderedHeaders.add(
      MapEntry('Connection', customHeaders['Connection'] ?? 'close'),
    );

    // 3. User-Agent (from custom or default)
    orderedHeaders.add(
      MapEntry('User-Agent', customHeaders['User-Agent'] ?? _defaultUserAgent),
    );

    // 4. Standard headers
    orderedHeaders.add(MapEntry('Accept', customHeaders['Accept'] ?? '*/*'));
    orderedHeaders.add(
      MapEntry('Accept-Language', customHeaders['Accept-Language'] ?? 'en-US'),
    );
    orderedHeaders.add(
      MapEntry(
        'Accept-Encoding',
        customHeaders['Accept-Encoding'] ?? 'identity',
      ),
    );

    // 5. Custom headers (excluding ones already added)
    final standardKeys = {
      'Host',
      'Connection',
      'User-Agent',
      'Accept',
      'Accept-Language',
      'Accept-Encoding',
    };
    for (final entry in customHeaders.entries) {
      if (!standardKeys.contains(entry.key)) {
        orderedHeaders.add(MapEntry(entry.key, entry.value));
      }
    }

    // 6. Icy-MetaData last (if not in custom)
    if (!customHeaders.containsKey('Icy-MetaData')) {
      orderedHeaders.add(MapEntry('Icy-MetaData', '1'));
    }

    // Add headers to lines (preserving exact order from orderedHeaders)
    for (final entry in orderedHeaders) {
      lines.add('${entry.key}: ${entry.value}');
    }

    // Join with CRLF and add final CRLF - exact byte boundaries
    final requestStr = '${lines.join('\r\n')}\r\n\r\n';

    if (enableLogging) {
      print('[xtream-raw] === RAW REQUEST ===');
      // Log each line separately to see exact formatting
      for (final line in lines) {
        print(line);
      }
      print('[xtream-raw] (followed by \\r\\n\\r\\n)');
      print('[xtream-raw] Request bytes length: ${requestStr.length}');

      // Debug: Show hex of first/last bytes to verify CRLF
      final bytes = requestStr.codeUnits;
      if (bytes.length > 20) {
        print(
          '[xtream-raw] First 20 bytes (hex): ${bytes.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );
        print(
          '[xtream-raw] Last 10 bytes (hex): ${bytes.skip(bytes.length - 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
        );
      }
      print('[xtream-raw] ==================');
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

  /// Parse headers from stream and return body stream continuation
  Future<_StreamHeaderResult> _parseHeadersFromStream(Socket socket) async {
    final buffer = <int>[];
    final bodyController = StreamController<List<int>>();
    final completer = Completer<_StreamHeaderResult>();
    var headersParsed = false;

    socket.listen(
      (chunk) {
        if (!headersParsed) {
          buffer.addAll(chunk);

          // Search for \r\n\r\n pattern
          for (var i = 0; i <= buffer.length - 4; i++) {
            if (buffer[i] == 13 &&
                buffer[i + 1] == 10 &&
                buffer[i + 2] == 13 &&
                buffer[i + 3] == 10) {
              // Found end of headers
              final headerBytes = buffer.sublist(0, i);
              final bodyPrefixBytes = buffer.sublist(i + 4);

              final headerText = utf8.decode(headerBytes, allowMalformed: true);
              final headerLines = headerText.split('\r\n');

              if (headerLines.isEmpty) {
                bodyController.addError(
                  const SocketException('No response received'),
                );
                bodyController.close();
                completer.completeError(
                  const SocketException('No response received'),
                );
                return;
              }

              // Parse status line
              final statusLine = headerLines[0];
              final statusMatch = RegExp(
                r'HTTP/\d\.\d\s+(\d+)\s+(.+)',
              ).firstMatch(statusLine);
              if (statusMatch == null) {
                bodyController.addError(
                  FormatException('Invalid HTTP status line: $statusLine'),
                );
                bodyController.close();
                completer.completeError(
                  FormatException('Invalid HTTP status line: $statusLine'),
                );
                return;
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

              headersParsed = true;

              // Add body prefix to stream if any
              if (bodyPrefixBytes.isNotEmpty) {
                bodyController.add(bodyPrefixBytes);
              }

              completer.complete(
                _StreamHeaderResult(
                  statusCode: statusCode,
                  reasonPhrase: reasonPhrase,
                  headers: headers,
                  bodyStream: bodyController.stream,
                ),
              );
              return;
            }
          }
        } else {
          // Headers already parsed, just forward body data
          bodyController.add(chunk);
        }
      },
      onError: (error) {
        bodyController.addError(error);
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        bodyController.close();
        if (!completer.isCompleted) {
          completer.completeError(
            const SocketException(
              'Connection closed before complete headers received',
            ),
          );
        }
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  /// Log response details
  void _logResponse(_HttpResponse response) {
    print('[xtream-raw] === RAW RESPONSE ===');
    print('[xtream-raw] HTTP ${response.statusCode} ${response.reasonPhrase}');
    print('[xtream-raw] Headers:');
    response.headers.forEach((key, value) {
      print('[xtream-raw]   $key: $value');
    });

    // Detect gzip
    if (response.headers['content-encoding']?.contains('gzip') ?? false) {
      print(
        '[xtream-raw] ⚠️  GZIP DETECTED - Server returned compressed response!',
      );
    }

    // Show first 256 bytes of body
    final preview = response.body.length > 256
        ? response.body.substring(0, 256)
        : response.body;
    print('[xtream-raw] Body preview (${response.body.length} bytes):');
    print(preview);
    print('[xtream-raw] ===================');
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

/// Stream header parse result with body stream
class _StreamHeaderResult {
  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final Stream<List<int>> bodyStream;

  _StreamHeaderResult({
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.bodyStream,
  });
}

/// Stream with HTTP headers
class StreamWithHeaders {
  final Stream<List<int>> stream;
  final int statusCode;
  final String reasonPhrase;
  final Map<String, String> headers;
  final Socket socket;

  StreamWithHeaders({
    required this.stream,
    required this.statusCode,
    required this.reasonPhrase,
    required this.headers,
    required this.socket,
  });

  /// Close the underlying socket
  Future<void> close() async {
    await socket.close();
  }
}
