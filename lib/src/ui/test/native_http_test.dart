import 'package:flutter/material.dart';
import 'package:openiptv/src/networking/native_http_client.dart';

/// Test widget to verify native HTTP client works
class NativeHttpTest extends StatefulWidget {
  const NativeHttpTest({super.key});

  @override
  State<NativeHttpTest> createState() => _NativeHttpTestState();
}

class _NativeHttpTestState extends State<NativeHttpTest> {
  String _result = 'Ready to test';
  bool _testing = false;

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _result = 'Testing...';
    });

    try {
      // Test the problematic URL that returns 401 with Dart's HTTP
      const url =
          'http://portal-iptv.net:8080/live/611627758292/611627758292/25497.ts';

      final headers = {
        'User-Agent': 'okhttp/4.9.0',
        'Connection': 'close',
        'Referer': 'http://portal-iptv.net:8080',
        'X-Device-Id': '954e6faa-89de-4e3d-8e2c-a135fd9906a1',
      };

      debugPrint(
        '[NativeHttpTest] Testing with ${NativeHttpClient.clientDescription}',
      );
      debugPrint('[NativeHttpTest] URL: $url');
      debugPrint('[NativeHttpTest] Headers: $headers');

      final result = await NativeHttpClient.testConnection(
        url,
        headers: headers,
      );

      final statusCode = result['statusCode'] as int;
      final statusMessage = result['statusMessage'] as String;
      final success = result['success'] as bool;

      setState(() {
        _result =
            '''
✅ Native HTTP Test Result:

Status: $statusCode $statusMessage
Success: $success
Client: ${NativeHttpClient.clientDescription}

${success ? '🎉 SUCCESS! Stream URL is accessible!' : '❌ FAILED: Still getting error'}

Expected: 200 OK (if Android with OkHttp)
Dart Socket got: 401 Unauthorized
        ''';
        _testing = false;
      });

      debugPrint('[NativeHttpTest] Result: $statusCode $statusMessage');
    } catch (e, stackTrace) {
      setState(() {
        _result = '❌ Error: $e\n\nStack trace:\n$stackTrace';
        _testing = false;
      });
      debugPrint('[NativeHttpTest] Error: $e');
      debugPrint('[NativeHttpTest] Stack: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native HTTP Client Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform: ${NativeHttpClient.clientDescription}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available: ${NativeHttpClient.isAvailable ? "Yes" : "No"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testing ? null : _runTest,
              child: _testing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Test Stream URL'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _result,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
