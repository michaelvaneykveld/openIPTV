import 'dart:async';

import 'package:openiptv/src/player_ui/controller/player_controller.dart';
import 'package:openiptv/src/player_ui/controller/player_state.dart';

/// Simple in-memory adapter so the Player UI can be exercised before the real backend exists.
class MockPlayerAdapter implements PlayerAdapter {
  MockPlayerAdapter({
    Duration totalDuration = const Duration(minutes: 42),
    bool isLive = false,
  }) : _controller = StreamController<PlayerSnapshot>.broadcast(),
       _isLive = isLive,
       _snapshot = PlayerSnapshot(
         phase: PlayerPhase.idle,
         isLive: isLive,
         position: Duration.zero,
         buffered: Duration.zero,
         duration: isLive ? null : totalDuration,
         bitrateKbps: 5200,
         audioTracks: const [
           PlayerTrack(
             id: 'en-main',
             label: 'English • Stereo',
             language: 'en',
             channels: '2.0',
             codec: 'AAC',
           ),
           PlayerTrack(
             id: 'es-main',
             label: 'Spanish • Stereo',
             language: 'es',
             channels: '2.0',
             codec: 'AAC',
           ),
         ],
         textTracks: const [
           PlayerTrack(id: 'subs-en', label: 'English CC', language: 'en'),
           PlayerTrack(id: 'subs-es', label: 'Spanish', language: 'es'),
         ],
         selectedAudio: const PlayerTrack(
           id: 'en-main',
           label: 'English • Stereo',
           language: 'en',
           channels: '2.0',
           codec: 'AAC',
         ),
       ) {
    _emit();
  }

  final StreamController<PlayerSnapshot> _controller;
  final bool _isLive;

  PlayerSnapshot _snapshot;
  Timer? _ticker;
  bool _isDisposed = false;

  @override
  Stream<PlayerSnapshot> get snapshotStream => _controller.stream;

  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _ticker?.cancel();
    await _controller.close();
  }

  @override
  Future<void> pause() async {
    _stopTicker();
    _setSnapshot(_snapshot.copyWith(phase: PlayerPhase.paused));
  }

  @override
  Future<void> play() async {
    _setSnapshot(_snapshot.copyWith(phase: PlayerPhase.playing));
    _startTicker();
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (_isLive) {
      return;
    }
    final duration = _snapshot.duration ?? Duration.zero;
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > duration ? duration : position);
    _setSnapshot(
      _snapshot.copyWith(
        position: clamped,
        buffered: clamped + const Duration(seconds: 10),
      ),
    );
  }

  @override
  Future<void> selectAudio(String trackId) async {
    final audioTrack = _snapshot.audioTracks.firstWhere(
      (track) => track.id == trackId,
      orElse: () => _snapshot.audioTracks.first,
    );
    _setSnapshot(_snapshot.copyWith(selectedAudio: audioTrack));
  }

  @override
  Future<void> selectText(String? trackId) async {
    if (trackId == null || trackId.isEmpty) {
      _setSnapshot(_snapshot.copyWith(selectedText: null));
      return;
    }
    final textTrack = _snapshot.textTracks.firstWhere(
      (track) => track.id == trackId,
      orElse: () => _snapshot.textTracks.first,
    );
    _setSnapshot(_snapshot.copyWith(selectedText: textTrack));
  }

  @override
  Future<void> zapNext() async {
    _simulateZap(directionLabel: 'Next');
  }

  @override
  Future<void> zapPrevious() async {
    _simulateZap(directionLabel: 'Previous');
  }

  void _simulateZap({required String directionLabel}) {
    _setSnapshot(
      _snapshot.copyWith(
        phase: PlayerPhase.loading,
        error: null,
        position: Duration.zero,
        buffered: Duration.zero,
      ),
    );
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (_isDisposed) return;
      _setSnapshot(
        _snapshot.copyWith(
          phase: PlayerPhase.playing,
          position: Duration.zero,
          buffered: const Duration(seconds: 8),
        ),
      );
    });
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed) return;
      final newPosition = _snapshot.position + const Duration(seconds: 1);
      if (!_isLive && _snapshot.duration != null) {
        if (newPosition >= _snapshot.duration!) {
          _setSnapshot(
            _snapshot.copyWith(
              phase: PlayerPhase.paused,
              position: _snapshot.duration!,
            ),
          );
          _stopTicker();
          return;
        }
      }
      _setSnapshot(
        _snapshot.copyWith(
          position: newPosition,
          buffered: newPosition + const Duration(seconds: 10),
        ),
      );
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _setSnapshot(PlayerSnapshot snapshot) {
    _snapshot = snapshot;
    _emit();
  }

  void _emit() {
    if (_isDisposed || _controller.isClosed) {
      return;
    }
    _controller.add(_snapshot);
  }
}
