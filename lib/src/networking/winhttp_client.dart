// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// Windows native HTTP client using WinHTTP via FFI
///
/// This uses the native Windows HTTP stack (same as Edge/Windows apps)
/// to bypass Cloudflare's TLS fingerprinting.
class WinHttpClient {
  static final _winhttp = ffi.DynamicLibrary.open('winhttp.dll');

  // WinHTTP function signatures
  static final _WinHttpOpen = _winhttp
      .lookupFunction<
        ffi.IntPtr Function(
          ffi.Pointer<ffi.Uint16> userAgent,
          ffi.Uint32 accessType,
          ffi.Pointer<ffi.Uint16> proxy,
          ffi.Pointer<ffi.Uint16> proxyBypass,
          ffi.Uint32 flags,
        ),
        int Function(
          ffi.Pointer<ffi.Uint16>,
          int,
          ffi.Pointer<ffi.Uint16>,
          ffi.Pointer<ffi.Uint16>,
          int,
        )
      >('WinHttpOpen');

  static final _WinHttpConnect = _winhttp
      .lookupFunction<
        ffi.IntPtr Function(
          ffi.IntPtr session,
          ffi.Pointer<ffi.Uint16> serverName,
          ffi.Uint32 port,
          ffi.Uint32 reserved,
        ),
        int Function(int, ffi.Pointer<ffi.Uint16>, int, int)
      >('WinHttpConnect');

  static final _WinHttpOpenRequest = _winhttp
      .lookupFunction<
        ffi.IntPtr Function(
          ffi.IntPtr connect,
          ffi.Pointer<ffi.Uint16> verb,
          ffi.Pointer<ffi.Uint16> objectName,
          ffi.Pointer<ffi.Uint16> version,
          ffi.Pointer<ffi.Uint16> referrer,
          ffi.Pointer<ffi.Pointer<ffi.Uint16>> acceptTypes,
          ffi.Uint32 flags,
        ),
        int Function(
          int,
          ffi.Pointer<ffi.Uint16>,
          ffi.Pointer<ffi.Uint16>,
          ffi.Pointer<ffi.Uint16>,
          ffi.Pointer<ffi.Uint16>,
          ffi.Pointer<ffi.Pointer<ffi.Uint16>>,
          int,
        )
      >('WinHttpOpenRequest');

  static final _WinHttpAddRequestHeaders = _winhttp
      .lookupFunction<
        ffi.Int32 Function(
          ffi.IntPtr request,
          ffi.Pointer<ffi.Uint16> headers,
          ffi.Uint32 headersLength,
          ffi.Uint32 modifiers,
        ),
        int Function(int, ffi.Pointer<ffi.Uint16>, int, int)
      >('WinHttpAddRequestHeaders');

  static final _WinHttpSendRequest = _winhttp
      .lookupFunction<
        ffi.Int32 Function(
          ffi.IntPtr request,
          ffi.Pointer<ffi.Uint16> headers,
          ffi.Uint32 headersLength,
          ffi.Pointer<ffi.Void> optional,
          ffi.Uint32 optionalLength,
          ffi.Uint32 totalLength,
          ffi.IntPtr context,
        ),
        int Function(
          int,
          ffi.Pointer<ffi.Uint16>,
          int,
          ffi.Pointer<ffi.Void>,
          int,
          int,
          int,
        )
      >('WinHttpSendRequest');

  static final _WinHttpReceiveResponse = _winhttp
      .lookupFunction<
        ffi.Int32 Function(ffi.IntPtr request, ffi.Pointer<ffi.Void> reserved),
        int Function(int, ffi.Pointer<ffi.Void>)
      >('WinHttpReceiveResponse');

  static final _WinHttpQueryHeaders = _winhttp
      .lookupFunction<
        ffi.Int32 Function(
          ffi.IntPtr request,
          ffi.Uint32 infoLevel,
          ffi.Pointer<ffi.Uint16> name,
          ffi.Pointer<ffi.Void> buffer,
          ffi.Pointer<ffi.Uint32> bufferLength,
          ffi.Pointer<ffi.Uint32> index,
        ),
        int Function(
          int,
          int,
          ffi.Pointer<ffi.Uint16>,
          ffi.Pointer<ffi.Void>,
          ffi.Pointer<ffi.Uint32>,
          ffi.Pointer<ffi.Uint32>,
        )
      >('WinHttpQueryHeaders');

  static final _WinHttpCloseHandle = _winhttp
      .lookupFunction<ffi.Int32 Function(ffi.IntPtr handle), int Function(int)>(
        'WinHttpCloseHandle',
      );

  // Constants
  static const WINHTTP_ACCESS_TYPE_DEFAULT_PROXY = 0;
  static const WINHTTP_NO_PROXY_NAME = 0;
  static const WINHTTP_NO_PROXY_BYPASS = 0;
  static const WINHTTP_FLAG_SECURE = 0x00800000;
  static const WINHTTP_QUERY_STATUS_CODE = 19;
  static const WINHTTP_QUERY_FLAG_NUMBER = 0x20000000;
  static const WINHTTP_ADDREQ_FLAG_ADD = 0x20000000;

  /// Test connection using WinHTTP
  static Future<Map<String, dynamic>> testConnection(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);

    // Open session
    final userAgent = 'okhttp/4.9.0'.toWinHttpUtf16();
    final session = _WinHttpOpen(
      userAgent,
      WINHTTP_ACCESS_TYPE_DEFAULT_PROXY,
      ffi.nullptr,
      ffi.nullptr,
      0,
    );

    if (session == 0) {
      malloc.free(userAgent);
      throw Exception('WinHttpOpen failed');
    }

    try {
      // Connect to server
      final serverName = uri.host.toWinHttpUtf16();
      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

      final connect = _WinHttpConnect(session, serverName, port, 0);
      malloc.free(serverName);

      if (connect == 0) {
        throw Exception('WinHttpConnect failed');
      }

      try {
        // Open request
        final verb = 'GET'.toWinHttpUtf16();
        final objectName = uri.path.toWinHttpUtf16();
        final flags = uri.scheme == 'https' ? WINHTTP_FLAG_SECURE : 0;

        final request = _WinHttpOpenRequest(
          connect,
          verb,
          objectName,
          ffi.nullptr,
          ffi.nullptr,
          ffi.nullptr,
          flags,
        );

        malloc.free(verb);
        malloc.free(objectName);

        if (request == 0) {
          throw Exception('WinHttpOpenRequest failed');
        }

        try {
          // Add custom headers
          if (headers != null && headers.isNotEmpty) {
            final headerStr = headers.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\r\n');
            final headerPtr = headerStr.toWinHttpUtf16();

            _WinHttpAddRequestHeaders(
              request,
              headerPtr,
              -1, // null-terminated
              WINHTTP_ADDREQ_FLAG_ADD,
            );

            malloc.free(headerPtr);
          }

          // Send request
          final sendResult = _WinHttpSendRequest(
            request,
            ffi.nullptr,
            0,
            ffi.nullptr,
            0,
            0,
            0,
          );

          if (sendResult == 0) {
            throw Exception('WinHttpSendRequest failed');
          }

          // Receive response
          final receiveResult = _WinHttpReceiveResponse(request, ffi.nullptr);

          if (receiveResult == 0) {
            throw Exception('WinHttpReceiveResponse failed');
          }

          // Query status code
          final statusCodePtr = malloc<ffi.Uint32>();
          final bufferLength = malloc<ffi.Uint32>();
          bufferLength.value = 4;

          final queryResult = _WinHttpQueryHeaders(
            request,
            WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER,
            ffi.nullptr,
            statusCodePtr.cast(),
            bufferLength,
            ffi.nullptr,
          );

          final statusCode = queryResult != 0 ? statusCodePtr.value : 0;

          malloc.free(statusCodePtr);
          malloc.free(bufferLength);

          return {
            'statusCode': statusCode,
            'statusMessage': statusCode == 200 ? 'OK' : 'Error',
            'success': statusCode >= 200 && statusCode < 300,
          };
        } finally {
          _WinHttpCloseHandle(request);
        }
      } finally {
        _WinHttpCloseHandle(connect);
      }
    } finally {
      _WinHttpCloseHandle(session);
      malloc.free(userAgent);
    }
  }
}

extension _WinHttpStringExt on String {
  ffi.Pointer<ffi.Uint16> toWinHttpUtf16() {
    final units = codeUnits;
    final ptr = malloc<ffi.Uint16>(units.length + 1);
    for (var i = 0; i < units.length; i++) {
      ptr[i] = units[i];
    }
    ptr[units.length] = 0; // null terminator
    return ptr;
  }
}
