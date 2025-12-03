import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openiptv/src/player_ui/controller/player_media_source.dart';
import 'package:openiptv/src/utils/playback_logger.dart';

class RestreamHandle {
  const RestreamHandle({required this.source, required this.dispose});

  final PlayerMediaSource source;
  final Future<void> Function() dispose;
}

class FfmpegRestreamer {
  FfmpegRestreamer._();

  static final FfmpegRestreamer instance = FfmpegRestreamer._();

  static bool? _ffmpegAvailable;
  static Future<bool>? _ffmpegCheck;

  Future<RestreamHandle?> restream(PlayerMediaSource source) async {
    final session = _FfmpegRestreamSession(
      original: source,
      sessionId: DateTime.now().millisecondsSinceEpoch,
    );
    return session.start();
  }

  static Future<bool> _ensureFfmpegAvailable() async {
    if (_ffmpegAvailable != null) {
      return _ffmpegAvailable!;
    }
    if (_ffmpegCheck != null) {
      return _ffmpegCheck!;
    }
    final completer = Completer<bool>();
    _ffmpegCheck = completer.future;
    try {
      final process = await Process.start('ffmpeg', ['-version']);
      unawaited(process.stdout.drain());
      unawaited(process.stderr.drain());
      final code = await process.exitCode;
      _ffmpegAvailable = code == 0;
      completer.complete(_ffmpegAvailable!);
    } catch (error) {
      _ffmpegAvailable = false;
      completer.complete(false);
    } finally {
      _ffmpegCheck = null;
    }
    return _ffmpegAvailable!;
  }
}

class _FfmpegRestreamSession {
  _FfmpegRestreamSession({required this.original, required this.sessionId});

  final PlayerMediaSource original;
  final int sessionId;

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _serverSub;
  Process? _process;
  bool _disposed = false;
  bool _processStarted = false;
  final _activeRequests = <HttpRequest>{};

  Future<RestreamHandle?> start() async {
    if (!await FfmpegRestreamer._ensureFfmpegAvailable()) {
      PlaybackLogger.videoError(
        'ffmpeg-restream-unavailable',
        error: 'ffmpeg executable not found on PATH.',
      );
      return null;
    }
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
        shared: false,
      );
    } catch (error) {
      PlaybackLogger.videoError('ffmpeg-restream-bind', error: error);
      await dispose();
      return null;
    }
    final path = '/stream/$sessionId';
    _serverSub = _server?.listen(
      (request) => _handleRequest(path, request),
      onError: (error) {
        PlaybackLogger.videoError('ffmpeg-restream-server', error: error);
      },
      cancelOnError: true,
    );
    final restreamUri = Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: _server!.port,
      path: path.substring(1),
    );
    final restreamedPlayable = original.playable.copyWith(
      url: restreamUri,
      rawUrl: restreamUri.toString(), // Clear original rawUrl, use restream URL
      headers: const <String, String>{},
      containerExtension: 'ts',
      mimeHint: 'video/mp2t',
    );
    final restreamedSource = PlayerMediaSource(
      playable: restreamedPlayable,
      title: original.title,
      bitrateKbps: original.bitrateKbps,
      audioTracks: original.audioTracks,
      textTracks: original.textTracks,
      defaultAudioTrackId: original.defaultAudioTrackId,
      defaultTextTrackId: original.defaultTextTrackId,
    );
    return RestreamHandle(source: restreamedSource, dispose: dispose);
  }

  Future<void> _handleRequest(String path, HttpRequest request) async {
    if (_disposed) {
      request.response.statusCode = HttpStatus.gone;
      await request.response.close();
      return;
    }
    if (request.uri.path != path) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.headers.contentType = ContentType(
      'video',
      'MP2T',
      charset: 'utf-8',
    );
    _activeRequests.add(request);
    try {
      await _startProcess(request);
    } finally {
      _activeRequests.remove(request);
    }
  }

  /// Warm up Xtream session with quick player_api.php call
  /// This establishes IP-based session for servers with max_connections=1
  Future<void> _warmupXtreamSession() async {
    try {
      // Extract credentials from URL
      final url = original.playable.rawUrl ?? original.playable.url.toString();
      final uri = Uri.parse(url);

      // Check if this is an Xtream URL pattern
      if (!url.contains('/live/') && !url.contains('/movie/')) {
        return; // Not Xtream, skip warmup
      }

      // Extract username/password from path like /live/user/pass/stream.ts
      final pathParts = uri.path.split('/');
      if (pathParts.length < 4) return;

      final username = pathParts[2];
      final password = pathParts[3];

      // Make quick player_api.php call with Connection: close
      final apiUrl =
          'http://${uri.host}:${uri.port}/player_api.php?username=$username&password=$password';

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);

      final request = await client.getUrl(Uri.parse(apiUrl));
      request.headers.set('Connection', 'close');
      request.headers.set('User-Agent', 'okhttp/4.9.3');

      final response = await request.close();
      await response.drain(); // Discard response body
      client.close();

      PlaybackLogger.videoInfo(
        'xtream-warmup-complete',
        extra: {'status': response.statusCode},
      );

      // Small delay to ensure connection closes before ffmpeg starts
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Warmup failure is non-fatal, continue with streaming attempt
      PlaybackLogger.videoInfo(
        'xtream-warmup-failed',
        extra: {'error': e.toString()},
      );
    }
  }

  Future<void> _startProcess(HttpRequest request) async {
    // Prevent starting multiple ffmpeg processes in the same session
    if (_processStarted) {
      PlaybackLogger.videoInfo(
        'ffmpeg-restream-skip',
        extra: {'reason': 'Process already started for this session'},
      );
      request.response.statusCode = HttpStatus.gone;
      await request.response.close();
      return;
    }
    _processStarted = true;

    // CRITICAL: Warm up the session with player_api.php call right before streaming
    // Xtream servers with max_connections=1 require a recent API call from the same IP
    await _warmupXtreamSession();

    final args = _buildArgs();
    Process? process;
    StreamSubscription<List<int>>? stdoutSub;
    StreamSubscription<String>? stderrSub;
    final responseDone = Completer<void>();

    void safeClose() {
      if (!responseDone.isCompleted) {
        responseDone.complete();
      }
    }

    try {
      if (args.isNotEmpty) {
        // Log args as list to see actual argument boundaries
        PlaybackLogger.videoInfo(
          'ffmpeg-restream-command',
          extra: {
            'argCount': args.length,
            'args': args.map((a) {
              if (a.contains('\r') || a.contains('\n')) {
                return a.replaceAll('\r', '\\r').replaceAll('\n', '\\n');
              }
              return a;
            }).toList(),
          },
        );
      }
      process = await Process.start('ffmpeg', args);
      _process = process;
      stdoutSub = process.stdout.listen(
        request.response.add,
        onError: (error) {
          PlaybackLogger.videoError('ffmpeg-restream-stdout', error: error);
        },
        onDone: () async {
          await request.response.close();
          safeClose();
        },
      );
      stderrSub = process.stderr
          .transform(utf8.decoder)
          .listen(
            (line) => PlaybackLogger.videoInfo(
              'ffmpeg-restream',
              extra: {'stderr': line.trim()},
            ),
          );
      unawaited(
        request.response.done.whenComplete(() async {
          await stdoutSub?.cancel();
          await stderrSub?.cancel();
          if (process != null && process.pid != 0) {
            process.kill(ProcessSignal.sigint);
          }
          safeClose();
        }),
      );
      unawaited(
        process.exitCode.then((code) async {
          if (code != 0) {
            PlaybackLogger.videoError(
              'ffmpeg-restream-exit',
              error: 'ffmpeg exited with code $code',
            );
          }
          await request.response.close();
          safeClose();
        }),
      );
      await responseDone.future;
    } on ProcessException catch (error) {
      PlaybackLogger.videoError('ffmpeg-restream-start', error: error);
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    } finally {
      await stdoutSub?.cancel();
      await stderrSub?.cancel();
      if (process != null && process.pid != 0) {
        process.kill(ProcessSignal.sigint);
      }
      _process = null;
    }
  }

  List<String> _buildArgs() {
    final commandArgs = _commandArgs(original.playable.ffmpegCommand);
    if (commandArgs.isNotEmpty) {
      return commandArgs;
    }
    final baseArgs = <String>[
      '-loglevel',
      'debug', // Changed from 'error' to see HTTP request details
      '-nostats',
      '-seekable', '0', // Disable seeking to prevent Range headers
      '-icy',
      '0', // CRITICAL: Disable Icy-MetaData header
      '-icy_metadata_headers',
      '0', // CRITICAL: Extra safety for newer FFmpeg versions
      '-auth_type',
      'none', // CRITICAL: Prevent FFmpeg from parsing /live/user/pass/ as HTTP auth
      '-method',
      'GET', // Explicitly set method (prevents FFmpeg from adding extra headers)
      '-i',
      original.playable.rawUrl ?? original.playable.url.toString(),
      '-c',
      'copy',
      '-f',
      'mpegts',
      'pipe:1',
    ];
    if (original.playable.headers.isEmpty) {
      return baseArgs;
    }
    return _insertHeaders(baseArgs, original.playable.headers);
  }

  List<String> _insertHeaders(List<String> args, Map<String, String> headers) {
    final idx = args.indexWhere((arg) => arg.toLowerCase() == '-i');
    final insertionPoint = idx != -1
        ? idx
        : args.indexWhere((arg) => !arg.startsWith('-') && arg.isNotEmpty);

    if (insertionPoint == -1) {
      return args;
    }

    final updated = List<String>.from(args);
    final headerArgs = <String>[];

    // CRITICAL: Must put ALL headers in -headers string to control exact order
    // FFmpeg's -user_agent flag puts User-Agent FIRST (wrong for Android)
    // Android/TiviMate order: Host (auto), Connection, User-Agent, Accept-Encoding, custom

    final headerLines = <String>[];

    // 1. Connection header (Android sends this before User-Agent)
    final connection = headers['Connection'];
    if (connection != null && connection.isNotEmpty) {
      headerLines.add('Connection: $connection');
    }

    // 2. User-Agent (MUST come after Connection in Android)
    final userAgent = headers['User-Agent'];
    if (userAgent != null && userAgent.isNotEmpty) {
      headerLines.add('User-Agent: $userAgent');
    }

    // 3. Accept-Encoding (Android default - gzip)
    headerLines.add('Accept-Encoding: gzip');

    // 4. Custom headers (Referer, X-Device-Id, etc.) in original order
    headers.forEach((key, value) {
      if (value.isNotEmpty &&
          key != 'User-Agent' &&
          key != 'Connection' &&
          key != 'Accept-Encoding') {
        headerLines.add('$key: $value');
      }
    });

    if (headerLines.isNotEmpty) {
      final headersString = '${headerLines.join('\r\n')}\r\n';
      headerArgs.addAll(['-headers', headersString]);
    }

    PlaybackLogger.videoInfo(
      'ffmpeg-headers-combined',
      extra: {
        'headerCount': headers.length,
        'userAgent': userAgent,
        'connection': connection,
        'totalArgsGenerated': headerArgs.length,
        'insertionIndex': insertionPoint,
        'headerLines': headerLines,
      },
    );

    updated.insertAll(insertionPoint, headerArgs);
    return updated;
  }

  List<String> _commandArgs(String? command) {
    if (command == null || command.trim().isEmpty) {
      return const [];
    }
    final tokens = _tokenizeCommand(command);
    if (tokens.isEmpty) {
      return const [];
    }
    final first = tokens.first.toLowerCase();
    if (first.endsWith('ffmpeg')) {
      tokens.removeAt(0);
    }
    return tokens;
  }

  List<String> _tokenizeCommand(String command) {
    final regex = RegExp(r'''("[^"]+"|'[^']+'|[^ \t]+)''');
    final matches = regex.allMatches(command.trim());
    final result = <String>[];
    for (final match in matches) {
      var token = match.group(0);
      if (token == null) continue;
      token = token.trim();
      if (token.startsWith('"') && token.endsWith('"') && token.length > 1) {
        token = token.substring(1, token.length - 1);
      } else if (token.startsWith("'") &&
          token.endsWith("'") &&
          token.length > 1) {
        token = token.substring(1, token.length - 1);
      }
      if (token.isNotEmpty) {
        result.add(token);
      }
    }
    return result;
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final request in _activeRequests) {
      try {
        request.response.statusCode = HttpStatus.gone;
        await request.response.close();
      } catch (_) {}
    }
    _activeRequests.clear();
    _serverSub?.cancel();
    _serverSub = null;
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
    final process = _process;
    _process = null;
    if (process != null && process.pid != 0) {
      process.kill(ProcessSignal.sigint);
    }
  }
}
