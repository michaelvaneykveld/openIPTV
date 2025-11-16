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

  Future<void> _startProcess(HttpRequest request) async {
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
        PlaybackLogger.videoInfo(
          'ffmpeg-restream-command',
          extra: {'command': args.join(' ')},
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
      'error',
      '-nostats',
      '-reconnect',
      '1',
      '-reconnect_streamed',
      '1',
      '-reconnect_delay_max',
      '2',
      '-i',
      original.playable.rawUrl ?? original.playable.url.toString(),
      '-c',
      'copy',
      '-f',
      'mpegts',
      'pipe:1',
    ];
    final headers = _composeHeaders(original.playable.headers);
    if (headers == null || headers.isEmpty) {
      return baseArgs;
    }
    return _insertHeaders(baseArgs, headers);
  }

  String? _composeHeaders(Map<String, String> headers) {
    if (headers.isEmpty) {
      return null;
    }
    final buffer = StringBuffer();
    headers.forEach((key, value) {
      if (value.isEmpty) return;
      buffer
        ..write(key)
        ..write(': ')
        ..write(value)
        ..write('\r\n');
    });
    final result = buffer.toString();
    return result.isEmpty ? null : result;
  }

  List<String> _insertHeaders(List<String> args, String headers) {
    final idx = args.indexWhere((arg) => arg.toLowerCase() == '-i');
    if (idx != -1) {
      final updated = List<String>.from(args);
      updated.insertAll(idx, ['-headers', headers]);
      return updated;
    }
    final firstInputIdx = args.indexWhere(
      (arg) => !arg.startsWith('-') && arg.isNotEmpty,
    );
    if (firstInputIdx != -1) {
      final updated = List<String>.from(args);
      updated.insertAll(firstInputIdx, ['-headers', headers]);
      return updated;
    }
    return [...args, '-headers', headers];
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
