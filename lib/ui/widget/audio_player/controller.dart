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

import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/util/audio_utils.dart';
import '/ui/worker/audio.dart';

/// Controller for audio playback that manages state for a specific audio attachment.
class AudioPlayerController extends GetxController {
  AudioPlayerController(
    this._audioWorker, {
    required this.id,
    required this.source,
    this.onForbidden,
  });

  /// Identifier for audio attachment.
  final AttachmentId id;

  /// Source of audio data.
  final AudioSource source;

  /// UI State for hover effect.
  final RxBool isHovered = RxBool(false);

  /// Whether audio was playing before interaction started.
  bool _wasPlaying = false;

  /// Handles actual playback and synchronization.
  final AudioWorker _audioWorker;

  /// Whether this controller's audio is active in [AudioWorker].
  bool get isActive => _audioWorker.activeAudioId.value == id.val;

  /// Whether audio is playing and this controller is active.
  bool get isPlaying => _audioWorker.isPlaying.value && isActive;

  /// Whether audio is loading and this controller is active.
  bool get isLoading => _audioWorker.isLoading.value && isActive;

  /// Current playback position. Returns [Duration.zero] if not active.
  Duration get position =>
      isActive ? _audioWorker.position.value : Duration.zero;

  /// Total duration of audio. Returns [Duration.zero] if not active.
  Duration get duration =>
      isActive ? _audioWorker.duration.value : Duration.zero;

  /// Returns hover state.
  bool get hovered => isHovered.value;

  /// Sets hover state.
  set hovered(bool value) => isHovered.value = value;

  /// Sets playback position in [AudioWorker].
  set position(Duration v) => _audioWorker.position.value = v;

  /// Callback, called when [source] fetch fails with `403` status code.
  final FutureOr<AudioSource?> Function()? onForbidden;

  /// Toggles playback between playing and paused states.
  void togglePlay() {
    if (isActive && isPlaying) {
      _audioWorker.pause();
    } else {
      _audioWorker.play(id.val, source, onForbidden: onForbidden);
    }
  }

  /// Handles start of slider interaction.
  ///
  /// Pauses playback if it was playing to allow smooth seeking.
  void onSliderChangeStart() async {
    _wasPlaying = isPlaying;
    if (_wasPlaying) {
      togglePlay();
    }
  }

  /// Handles end of slider interaction.
  ///
  /// Seeks to current slider value and resumes playback if it was
  /// playing before interaction started.
  void onSliderChangeEnd() async {
    await seek(getSliderValue());
    if (_wasPlaying) {
      togglePlay();
    }
  }

  /// Seeks to specific position in milliseconds.
  Future<void> seek(double ms) async {
    await _audioWorker.seek(Duration(milliseconds: ms.toInt()));
  }

  /// Returns current position in milliseconds, clamped between 0 and [duration].
  double getSliderValue() {
    final durMs = duration.inMilliseconds.toDouble();
    if (durMs <= 0) return 0.0;
    return position.inMilliseconds.toDouble().clamp(0.0, durMs);
  }
}
