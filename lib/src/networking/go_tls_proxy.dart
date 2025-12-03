import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Manages the Go TLS Proxy subprocess
///
/// This proxy uses Go's TLS stack which has a different fingerprint
/// than Dart/Windows and can bypass Cloudflare's bot detection.
class GoTlsProxy {
  static Process? _process;
  static int _port = 8765;
  static bool _isRunning = false;

  /// Start the Go proxy if not already running
  static Future<void> start({int port = 8765}) async {
    if (_isRunning) {
      print('[GoTlsProxy] Already running on port $_port');
      return;
    }

    _port = port;

    // Extract bundled executable to temp directory
    final exePath = await _extractExecutable();

    print('[GoTlsProxy] Starting proxy: $exePath');
    print('[GoTlsProxy] Port: $_port');

    // Start the proxy process
    _process = await Process.start(
      exePath,
      [],
      environment: {'PROXY_PORT': _port.toString()},
      runInShell: false,
    );

    // Listen to output
    _process!.stdout.listen((data) {
      print('[GoTlsProxy] ${String.fromCharCodes(data).trim()}');
    });

    _process!.stderr.listen((data) {
      print('[GoTlsProxy] ERROR: ${String.fromCharCodes(data).trim()}');
    });

    // Wait a bit for startup
    await Future.delayed(const Duration(milliseconds: 500));

    // Verify it's running
    try {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://127.0.0.1:$_port/health'))
          .timeout(const Duration(seconds: 2));
      final httpResponse = await (await response.close())
          .transform(utf8.decoder)
          .join();

      if (httpResponse.contains('OK')) {
        _isRunning = true;
        print('[GoTlsProxy] ✅ Started successfully on port $_port');
      } else {
        throw Exception('Health check failed');
      }
    } catch (e) {
      print('[GoTlsProxy] ❌ Failed to start: $e');
      await stop();
      throw Exception('Go TLS Proxy failed to start: $e');
    }
  }

  /// Stop the proxy
  static Future<void> stop() async {
    if (_process != null) {
      print('[GoTlsProxy] Stopping proxy...');
      _process!.kill();
      await _process!.exitCode;
      _process = null;
      _isRunning = false;
      print('[GoTlsProxy] Stopped');
    }
  }

  /// Create proxy URL for a target URL with headers
  static String createProxyUrl(String targetUrl, Map<String, String> headers) {
    if (!_isRunning) {
      throw StateError('Go TLS Proxy is not running. Call start() first.');
    }

    final uri = Uri.parse('http://127.0.0.1:$_port/proxy');
    final params = <String, String>{'url': targetUrl};

    // Add headers as h_ prefixed query parameters
    headers.forEach((key, value) {
      params['h_$key'] = value;
    });

    return uri.replace(queryParameters: params).toString();
  }

  /// Check if proxy is running
  static bool get isRunning => _isRunning;

  /// Get current port
  static int get port => _port;

  /// Extract the bundled executable to a temporary directory
  static Future<String> _extractExecutable() async {
    final tempDir = await getTemporaryDirectory();
    final exeName = Platform.isWindows ? 'go-tls-proxy.exe' : 'go-tls-proxy';
    final exePath = path.join(tempDir.path, exeName);

    // Check if already extracted and up to date
    final exeFile = File(exePath);
    if (await exeFile.exists()) {
      // TODO: Add version check here
      print('[GoTlsProxy] Using existing executable: $exePath');
      return exePath;
    }

    // Extract from assets
    print('[GoTlsProxy] Extracting executable to: $exePath');
    final byteData = await rootBundle.load('assets/bin/$exeName');
    await exeFile.writeAsBytes(byteData.buffer.asUint8List());

    // Make executable on Unix
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', exePath]);
    }

    print('[GoTlsProxy] Extracted successfully');
    return exePath;
  }
}
