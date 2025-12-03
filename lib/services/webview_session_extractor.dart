import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:openiptv/src/utils/playback_logger.dart';

class WebViewSessionExtractor {
  // Cache sessions by domain to avoid spinning up WebView for every request
  static final Map<String, Map<String, String>> _cache = {};

  /// Launches a headless WebView to pass Cloudflare challenges and extract session cookies.
  ///
  /// This uses the native WebView2 runtime on Windows, which shares the same
  /// TLS fingerprint and capabilities as Microsoft Edge.
  static Future<Map<String, String>> getSession(
    String url, {
    String? verificationUrl,
    bool forceRefresh = false,
  }) async {
    final uri = WebUri(url);
    final domain = uri.host;

    if (!forceRefresh && _cache.containsKey(domain)) {
      PlaybackLogger.videoInfo('webview-cache-hit', extra: {'domain': domain});
      return _cache[domain]!;
    }

    final completer = Completer<Map<String, String>>();
    HeadlessInAppWebView? headlessWebView;

    // Use Mobile Chrome UA to avoid desktop-blocking rules and mimic a phone
    const userAgent =
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36";

    PlaybackLogger.videoInfo('webview-start', extra: {'url': url});

    headlessWebView = HeadlessInAppWebView(
      // Start with about:blank to avoid native crash on Windows if the initial URL returns 401/404
      initialUrlRequest: URLRequest(url: WebUri('about:blank')),
      initialSettings: InAppWebViewSettings(
        isInspectable: true, // For debugging
        userAgent: userAgent,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useShouldInterceptRequest: false,
        // Ensure we don't block popups if the challenge opens one (unlikely but possible)
        javaScriptCanOpenWindowsAutomatically: true,
      ),
      onConsoleMessage: (controller, consoleMessage) {
        PlaybackLogger.videoInfo(
          'webview-console',
          extra: {
            'message': consoleMessage.message,
            'level': consoleMessage.messageLevel.toString(),
          },
        );
      },
      onLoadStop: (controller, loadedUrl) async {
        PlaybackLogger.videoInfo(
          'webview-page-loaded',
          extra: {'url': loadedUrl.toString()},
        );

        // Safe Init Pattern:
        // 1. Load about:blank (safe)
        // 2. Once loaded, navigate to the real URL (risky but handled)
        if (loadedUrl.toString() == 'about:blank') {
          PlaybackLogger.videoInfo(
            'webview-safe-init-complete',
            extra: {'target': url},
          );
          // Delay to avoid native race conditions on Windows
          await Future.delayed(const Duration(milliseconds: 800));
          await controller.loadUrl(urlRequest: URLRequest(url: uri));
          return;
        }

        // Log page details to understand what we are looking at
        final title = await controller.getTitle();
        final body = await controller.evaluateJavascript(
          source: "document.body.innerText",
        );
        PlaybackLogger.videoInfo(
          'webview-page-details',
          extra: {
            'title': title,
            'bodyPreview': (body as String?)?.substring(
              0,
              100.clamp(0, (body?.length ?? 0)),
            ),
          },
        );

        // Optimization: If the body is JSON, we are likely through (API response).
        // No need to wait for cf_clearance if the server didn't set it.
        if (body is String && body.trim().startsWith('{')) {
          PlaybackLogger.videoInfo(
            'webview-json-detected',
            extra: {
              'message':
                  'JSON response detected, returning cookies immediately',
            },
          );
          try {
            final cookies = await CookieManager.instance().getCookies(url: uri);
            final cookieString = cookies
                .map((c) => '${c.name}=${c.value}')
                .join('; ');

            final result = {'User-Agent': userAgent, 'Cookie': cookieString};
            _cache[domain] = result;
            completer.complete(result);

            await Future.delayed(const Duration(milliseconds: 500));
            headlessWebView?.dispose();
            return;
          } catch (e) {
            PlaybackLogger.videoError('webview-json-cookie-error', error: e);
          }
        }

        // Polling Strategy:
        // Cloudflare challenges take time to solve (5-15s).
        // We must poll the CookieManager until we see the clearance cookie.
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline)) {
          if (completer.isCompleted) return;

          try {
            final cookies = await CookieManager.instance().getCookies(url: uri);

            // Check for Cloudflare cookies specifically, or any cookies if we're desperate
            final hasClearance = cookies.any(
              (c) => c.name == 'cf_clearance' || c.name == '__cf_bm',
            );

            if (cookies.isNotEmpty) {
              final cookieString = cookies
                  .map((c) => '${c.name}=${c.value}')
                  .join('; ');

              // If we found the golden ticket (cf_clearance), or if we have cookies and time is running out
              if (hasClearance ||
                  DateTime.now()
                      .add(const Duration(seconds: 5))
                      .isAfter(deadline)) {
                PlaybackLogger.videoInfo(
                  'webview-cookies-found',
                  extra: {
                    'cookies': cookieString,
                    'hasClearance': hasClearance,
                  },
                );

                final result = {
                  'User-Agent': userAgent,
                  'Cookie': cookieString,
                };
                _cache[domain] = result;
                completer.complete(result);

                // Keep alive briefly to ensure everything settles
                await Future.delayed(const Duration(milliseconds: 500));
                headlessWebView?.dispose();
                return;
              }
            }
          } catch (e) {
            PlaybackLogger.videoError('webview-cookie-poll-error', error: e);
          }

          // Wait before next poll
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // If we timed out but have *some* cookies, return them
        // (Logic handled by the loop above near deadline, but safety check here)
        if (!completer.isCompleted) {
          PlaybackLogger.videoInfo(
            'webview-polling-timeout',
            extra: {'message': 'No clearance cookie found'},
          );
          // Don't complete with error, just let the outer timeout handle it or return empty if needed
        }
      },
      onDownloadStartRequest: (controller, downloadRequest) async {
        PlaybackLogger.videoInfo(
          'webview-download-started',
          extra: {'message': 'Challenge passed'},
        );
        // If we get here, it means the request was successful and the server is sending the file!
        // This means we have passed the challenge.

        try {
          final cookies = await CookieManager.instance().getCookies(url: uri);
          final cookieString = cookies
              .map((c) => '${c.name}=${c.value}')
              .join('; ');

          if (!completer.isCompleted) {
            final result = {'User-Agent': userAgent, 'Cookie': cookieString};
            _cache[domain] = result; // Cache the result
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) completer.completeError(e);
        } finally {
          headlessWebView?.dispose();
        }
      },
      onReceivedHttpError: (controller, request, errorResponse) async {
        PlaybackLogger.videoError(
          'webview-http-error',
          description: 'HTTP Error: ${errorResponse.statusCode}',
        );

        // Check if we got cookies despite the error (common with Cloudflare 403/503 or Auth 401)
        try {
          final cookies = await CookieManager.instance().getCookies(url: uri);
          if (cookies.isNotEmpty) {
            PlaybackLogger.videoInfo(
              'webview-cookies-on-error',
              extra: {'count': cookies.length},
            );
            if (!completer.isCompleted) {
              final cookieString = cookies
                  .map((c) => '${c.name}=${c.value}')
                  .join('; ');
              final result = {'User-Agent': userAgent, 'Cookie': cookieString};
              _cache[domain] = result;
              completer.complete(result);
              headlessWebView?.dispose();
            }
          }
        } catch (_) {}
      },
    );

    await headlessWebView.run();

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        headlessWebView?.dispose();
        throw TimeoutException(
          'WebView timed out waiting for Cloudflare challenge',
        );
      },
    );
  }
}
