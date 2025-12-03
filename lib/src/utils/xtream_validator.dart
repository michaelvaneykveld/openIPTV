// Xtream Validator - TiviMate style server diagnostics
// Standalone validation for Xtream Codes API servers
// Tests authentication, encoding rules, header requirements, and content delivery

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class XtreamValidationResult {
  final bool apiOk;
  final bool loginOk;
  final bool liveOk;
  final bool vodOk;
  final bool uaRequired;
  final bool proxyRequired;
  final bool rawColonsAllowed;
  final bool encodedColonsAllowed;
  final Map<String, dynamic> details;
  final String report;

  XtreamValidationResult({
    required this.apiOk,
    required this.loginOk,
    required this.liveOk,
    required this.vodOk,
    required this.uaRequired,
    required this.proxyRequired,
    required this.rawColonsAllowed,
    required this.encodedColonsAllowed,
    required this.details,
    required this.report,
  });

  @override
  String toString() => report;
}

class XtreamValidator {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useHttps;

  XtreamValidator({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.useHttps = false,
  });

  String _buildUrl(String path) {
    final scheme = useHttps ? 'https' : 'http';
    final portPart = (port == 80 || port == 443) ? '' : ':$port';
    return '$scheme://$host$portPart/$path';
  }

  Future<http.Response?> _request(
    String url, {
    Map<String, String>? headers,
    bool allowBadCert = true,
  }) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient()
        ..badCertificateCallback = allowBadCert
            ? (cert, host, port) => true
            : null
        ..connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);

      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      client.close();

      // Convert HttpHeaders to Map<String, String>
      final headerMap = <String, String>{};
      response.headers.forEach((name, values) {
        headerMap[name] = values.join(', ');
      });

      return http.Response(
        responseBody,
        response.statusCode,
        headers: headerMap,
      );
    } catch (e) {
      // Error during request - validator handles null responses
      return null;
    }
  }

  Future<XtreamValidationResult> validate() async {
    final buffer = StringBuffer();
    final details = <String, dynamic>{};

    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('         XTREAM CODES VALIDATION REPORT');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('Server: $host:$port');
    buffer.writeln('Username: $username');
    buffer.writeln(
      'Password: ${password.substring(0, password.length > 4 ? 4 : password.length)}***',
    );
    buffer.writeln('═══════════════════════════════════════════════════\n');

    // Step 1: API Authentication Check
    buffer.writeln('STEP 1: API Authentication');
    buffer.writeln('─────────────────────────────────────────────────');
    final apiUrl = _buildUrl(
      'player_api.php?username=$username&password=$password',
    );
    buffer.writeln('URL: $apiUrl');

    final apiResponse = await _request(apiUrl);
    final apiOk =
        apiResponse != null &&
        apiResponse.statusCode == 200 &&
        apiResponse.body.contains('user_info');

    buffer.writeln('Status: ${apiResponse?.statusCode ?? "TIMEOUT"}');
    buffer.writeln('Result: ${apiOk ? "✓ OK" : "✗ FAIL"}');

    details['api_status'] = apiResponse?.statusCode;
    details['api_ok'] = apiOk;

    bool loginOk = false;
    if (apiOk) {
      try {
        final apiData = jsonDecode(apiResponse.body);
        loginOk = apiData['user_info']?['auth'] == 1;
        buffer.writeln(
          'Auth Status: ${loginOk ? "✓ AUTHENTICATED" : "✗ NOT AUTHORIZED"}',
        );
        details['user_info'] = apiData['user_info'];
      } catch (e) {
        buffer.writeln('Auth Parse Error: $e');
        details['api_parse_error'] = e.toString();
      }
    }
    buffer.writeln('');

    // Step 2: Live Stream Test (Raw Credentials)
    buffer.writeln('STEP 2: Live Stream Test (Raw Credentials)');
    buffer.writeln('─────────────────────────────────────────────────');
    final liveTestRaw = _buildUrl('live/$username/$password/1.ts');
    buffer.writeln('URL: $liveTestRaw');

    final rawResponse = await _request(liveTestRaw);
    final rawStatus = rawResponse?.statusCode ?? 0;
    final rawContentType = rawResponse?.headers['content-type'] ?? 'unknown';

    buffer.writeln('Status: ${rawStatus == 0 ? "TIMEOUT" : rawStatus}');
    buffer.writeln('Content-Type: $rawContentType');

    final rawColonsAllowed =
        rawStatus == 200 && rawContentType.contains('video');
    buffer.writeln('Result: ${rawColonsAllowed ? "✓ OK" : "✗ FAIL"}');

    details['live_raw_status'] = rawStatus;
    details['live_raw_content_type'] = rawContentType;
    details['raw_colons_allowed'] = rawColonsAllowed;
    buffer.writeln('');

    // Step 3: Live Stream Test (Encoded Credentials)
    buffer.writeln('STEP 3: Live Stream Test (Encoded Credentials)');
    buffer.writeln('─────────────────────────────────────────────────');
    final liveTestEncoded = _buildUrl(
      'live/${Uri.encodeComponent(username)}/${Uri.encodeComponent(password)}/1.ts',
    );
    buffer.writeln('URL: $liveTestEncoded');

    final encResponse = await _request(liveTestEncoded);
    final encStatus = encResponse?.statusCode ?? 0;
    final encContentType = encResponse?.headers['content-type'] ?? 'unknown';

    buffer.writeln('Status: ${encStatus == 0 ? "TIMEOUT" : encStatus}');
    buffer.writeln('Content-Type: $encContentType');

    final encodedColonsAllowed =
        encStatus == 200 && encContentType.contains('video');
    buffer.writeln('Result: ${encodedColonsAllowed ? "✓ OK" : "✗ FAIL"}');

    details['live_encoded_status'] = encStatus;
    details['live_encoded_content_type'] = encContentType;
    details['encoded_colons_allowed'] = encodedColonsAllowed;
    buffer.writeln('');

    // Step 4: User-Agent Requirement Test
    buffer.writeln('STEP 4: User-Agent Requirement Test');
    buffer.writeln('─────────────────────────────────────────────────');
    final uaHeaders = {'User-Agent': 'okhttp/4.9.3'};
    final uaResponse = await _request(liveTestRaw, headers: uaHeaders);
    final uaStatus = uaResponse?.statusCode ?? 0;
    final uaContentType = uaResponse?.headers['content-type'] ?? 'unknown';

    buffer.writeln('URL: $liveTestRaw');
    buffer.writeln('Headers: User-Agent: okhttp/4.9.3');
    buffer.writeln('Status: ${uaStatus == 0 ? "TIMEOUT" : uaStatus}');
    buffer.writeln('Content-Type: $uaContentType');

    final uaRequired =
        uaStatus == 200 && uaContentType.contains('video') && !rawColonsAllowed;

    buffer.writeln(
      'Result: ${uaRequired ? "✓ USER-AGENT REQUIRED" : "✗ NOT REQUIRED"}',
    );

    details['ua_status'] = uaStatus;
    details['ua_required'] = uaRequired;
    buffer.writeln('');

    // Step 5: VOD Test
    buffer.writeln('STEP 5: VOD (Movies) Test');
    buffer.writeln('─────────────────────────────────────────────────');
    final vodTestRaw = _buildUrl('movie/$username/$password/1.mp4');
    buffer.writeln('URL: $vodTestRaw');

    final vodHeaders = uaRequired ? uaHeaders : <String, String>{};
    final vodResponse = await _request(vodTestRaw, headers: vodHeaders);
    final vodStatus = vodResponse?.statusCode ?? 0;
    final vodContentType = vodResponse?.headers['content-type'] ?? 'unknown';

    buffer.writeln('Status: ${vodStatus == 0 ? "TIMEOUT" : vodStatus}');
    buffer.writeln('Content-Type: $vodContentType');

    final vodOk = vodStatus == 200 && vodContentType.contains('video');
    buffer.writeln('Result: ${vodOk ? "✓ OK" : "✗ FAIL"}');

    details['vod_status'] = vodStatus;
    details['vod_content_type'] = vodContentType;
    details['vod_ok'] = vodOk;
    buffer.writeln('');

    // Step 6: Proxy Requirement Detection
    buffer.writeln('STEP 6: Proxy Requirement Analysis');
    buffer.writeln('─────────────────────────────────────────────────');

    final htmlDetected =
        rawContentType.contains('html') ||
        encContentType.contains('html') ||
        vodContentType.contains('html');

    final fake200Detected =
        (rawStatus == 200 && rawContentType.contains('html')) ||
        (encStatus == 200 && encContentType.contains('html')) ||
        (vodStatus == 200 && vodContentType.contains('html'));

    final proxyRequired = htmlDetected || fake200Detected;

    buffer.writeln(
      'HTML Response: ${htmlDetected ? "✓ DETECTED" : "✗ NOT DETECTED"}',
    );
    buffer.writeln(
      'Fake 200 Response: ${fake200Detected ? "✓ DETECTED" : "✗ NOT DETECTED"}',
    );
    buffer.writeln('Proxy Required: ${proxyRequired ? "✓ YES" : "✗ NO"}');

    details['html_detected'] = htmlDetected;
    details['fake_200_detected'] = fake200Detected;
    details['proxy_required'] = proxyRequired;
    buffer.writeln('');

    // Final Assessment
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('              FINAL ASSESSMENT');
    buffer.writeln('═══════════════════════════════════════════════════');

    final liveOk = rawColonsAllowed || encodedColonsAllowed;

    buffer.writeln('API Authentication:    ${apiOk ? "✓" : "✗"}');
    buffer.writeln('Login Valid:           ${loginOk ? "✓" : "✗"}');
    buffer.writeln('Live Streams:          ${liveOk ? "✓" : "✗"}');
    buffer.writeln('VOD/Movies:            ${vodOk ? "✓" : "✗"}');
    buffer.writeln('');
    buffer.writeln('CONFIGURATION RECOMMENDATIONS:');
    buffer.writeln('─────────────────────────────────────────────────');

    if (rawColonsAllowed) {
      buffer.writeln('• Use RAW credentials (no encoding)');
    } else if (encodedColonsAllowed) {
      buffer.writeln('• Use ENCODED credentials (URL encode colons)');
    } else {
      buffer.writeln('• ⚠ Neither RAW nor ENCODED credentials work!');
    }

    if (uaRequired) {
      buffer.writeln('• User-Agent REQUIRED: okhttp/4.9.3');
    } else {
      buffer.writeln('• User-Agent: Optional');
    }

    if (proxyRequired) {
      buffer.writeln('• Direct Access: BLOCKED (Server returns HTML/Fake 200)');
    } else {
      buffer.writeln('• Direct Access: OK');
    }

    if (!apiOk || !loginOk) {
      buffer.writeln(
        '• ⚠ CRITICAL: Authentication failed - check credentials!',
      );
    }

    buffer.writeln('═══════════════════════════════════════════════════');

    return XtreamValidationResult(
      apiOk: apiOk,
      loginOk: loginOk,
      liveOk: liveOk,
      vodOk: vodOk,
      uaRequired: uaRequired,
      proxyRequired: proxyRequired,
      rawColonsAllowed: rawColonsAllowed,
      encodedColonsAllowed: encodedColonsAllowed,
      details: details,
      report: buffer.toString(),
    );
  }
}
