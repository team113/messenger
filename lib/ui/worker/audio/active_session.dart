// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';

import '/util/audio_utils.dart';
import 'playback.dart';

/// Represents the currently active audio session with metadata and controls.
class ActiveAudioSession {
  ActiveAudioSession(this._playback, {required this.item}) {
    _setupListeners();
  }

  /// Metadata of the audio.
  final AudioItem item;

  /// Delegate responsible for actual playback operations.
  final AudioPlayback _playback;

  /// [StreamSubscription] for handling playback completion.
  StreamSubscription? _completedSubscription;

  /// Whether playback was active before a seek interaction.
  bool _wasPlaying = false;

  /// Indicates the audio is currently playing.
  bool get isPlaying => _playback.isPlaying.value;

  /// Indicates the audio is currently loading.
  bool get isLoading => _playback.isLoading.value;

  /// Returns total duration of the audio.
  Duration get duration => _playback.duration.value;

  /// Current playback position.
  Duration get position => _playback.position.value;
  set position(Duration v) => _playback.position.value = v;

  /// Starts a seek interaction, pausing playback if it was active.
  Future<void> beginSeek() async {
    _wasPlaying = _playback.isPlaying.value;
    if (_wasPlaying) await _playback.pause();
  }

  /// Ends a seek interaction, seeking to [position] and resuming if needed.
  Future<void> endSeek(Duration position) async {
    await _playback.seek(position);
    if (_wasPlaying) await _playback.play();
    _wasPlaying = false;
  }

  /// Cancels the completion listener.
  void dispose() => _completedSubscription?.cancel();

  /// Wires up completion handling.
  void _setupListeners() {
    _completedSubscription = _playback.isCompleted.listen((completed) async {
      if (completed) {
        await _playback.pause();
        await _playback.seek(Duration.zero);
      }
    });
  }
}
