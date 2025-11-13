import 'dart:async';

import 'package:openiptv/src/player_ui/controller/player_media_source.dart';

typedef PlaybackFactory = Future<ResolvedPlayback?> Function();

class ResolvedPlayback {
  ResolvedPlayback({
    required this.source,
    this.dispose,
    required this.useMediaKit,
  });

  final PlayerMediaSource source;
  final Future<void> Function()? dispose;
  final bool useMediaKit;
}

class LazyPlaybackEntry {
  const LazyPlaybackEntry({
    required this.factory,
    this.id,
  });

  final PlaybackFactory factory;
  final int? id;
}

class ResolveConfig {
  const ResolveConfig({
    this.neighborRadius = 1,
    this.minGap = const Duration(milliseconds: 650),
  });

  final int neighborRadius;
  final Duration minGap;
}

class ResolveScheduler {
  ResolveScheduler({required this.minGap});

  final Duration minGap;
  Future<void> _pending = Future<void>.value();
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);

  Future<T> schedule<T>(
    Future<T> Function() action, {
    bool highPriority = false,
  }) {
    if (highPriority) {
      _pending = Future<void>.value();
    }
    final completer = Completer<T>();
    _pending = _pending.then((_) async {
      final delta = DateTime.now().difference(_lastStart);
      if (delta < minGap) {
        await Future<void>.delayed(minGap - delta);
      }
      _lastStart = DateTime.now();
      final result = await action();
      completer.complete(result);
    }).catchError((Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void reset() {
    _pending = Future<void>.value();
  }
}
