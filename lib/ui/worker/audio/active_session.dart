import 'dart:async';

import '/util/audio_utils.dart';
import 'playback.dart';

/// Represents the currently active audio session with metadata and controls.
class ActiveAudioSession {
  ActiveAudioSession(this.playback, {required this.id, required this.source}) {
    _setupListeners();
  }

  /// Unique identifier of the audio.
  final AudioId id;

  /// Currently active [AudioSource].
  final AudioSource source;

  /// Delegate responsible for actual playback operations.
  final AudioPlayback playback;

  /// [StreamSubscription] for handling playback completion.
  StreamSubscription? _completedSubscription;

  /// Whether playback was active before a seek interaction.
  bool _wasPlaying = false;

  /// Starts a seek interaction, pausing playback if it was active.
  Future<void> beginSeek() async {
    _wasPlaying = playback.isPlaying.value;
    if (_wasPlaying) await playback.pause();
  }

  /// Ends a seek interaction, seeking to [position] and resuming if needed.
  Future<void> endSeek(Duration position) async {
    await playback.seek(position);
    if (_wasPlaying) await playback.play();
    _wasPlaying = false;
  }

  /// Cancels the completion listener.
  void dispose() => _completedSubscription?.cancel();

  /// Wires up completion handling.
  void _setupListeners() {
    _completedSubscription = playback.isCompleted.listen((completed) async {
      if (completed) {
        await playback.pause();
        await playback.seek(Duration.zero);
      }
    });
  }
}
