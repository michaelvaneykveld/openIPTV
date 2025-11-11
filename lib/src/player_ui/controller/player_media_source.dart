import 'package:openiptv/src/player_ui/controller/player_state.dart';

/// Describes a playable media item with optional track metadata.
class PlayerMediaSource {
  const PlayerMediaSource({
    required this.uri,
    this.title,
    this.isLive = false,
    this.bitrateKbps,
    this.audioTracks = const [],
    this.textTracks = const [],
    this.defaultAudioTrackId,
    this.defaultTextTrackId,
  });

  final Uri uri;
  final String? title;
  final bool isLive;
  final int? bitrateKbps;
  final List<PlayerTrack> audioTracks;
  final List<PlayerTrack> textTracks;
  final String? defaultAudioTrackId;
  final String? defaultTextTrackId;

  PlayerTrack? defaultAudioTrack() {
    if (audioTracks.isEmpty) {
      return null;
    }
    if (defaultAudioTrackId == null) {
      return audioTracks.first;
    }
    return audioTracks.firstWhere(
      (track) => track.id == defaultAudioTrackId,
      orElse: () => audioTracks.first,
    );
  }

  PlayerTrack? defaultTextTrack() {
    if (textTracks.isEmpty) {
      return null;
    }
    if (defaultTextTrackId == null) {
      return textTracks.first;
    }
    return textTracks.firstWhere(
      (track) => track.id == defaultTextTrackId,
      orElse: () => textTracks.first,
    );
  }
}
