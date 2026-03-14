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

import '/ui/worker/audio.dart';
import '/util/audio_utils.dart';

/// Controller for [AudioPlayer] managing state for a specific audio [source].
class AudioPlayerController extends GetxController {
  AudioPlayerController(
    this._audioWorker, {
    required this.id,
    required this.source,
    this.onForbidden,
  });

  /// Unique identifier for audio.
  final AudioId id;

  /// [AudioSource] of audio data itself.
  final AudioSource source;

  /// Indicator whether the view is being hovered.
  final RxBool hovered = RxBool(false);

  /// Callback, called when [source] fetch fails with `403` status code.
  final FutureOr<AudioSource?> Function()? onForbidden;

  /// Calculated duration of audio.
  final Rx<Duration> extractedDuration = Rx<Duration>(Duration.zero);

  /// Indicator whether [extractedDuration] is being fetched.
  final RxBool isDurationLoading = RxBool(true);

  /// [AudioWorker] handling actual playback and synchronization.
  final AudioWorker _audioWorker;

  /// Indicates whether this controller's audio is active in [AudioWorker].
  bool get isActive => _audioWorker.activeAudioId.value == id;

  /// Indicates whether audio is playing and this controller is active.
  bool get isPlaying => _audioWorker.playback.isPlaying.value && isActive;

  /// Indicates whether audio is loading and this controller is active.
  bool get isLoading => _audioWorker.playback.isLoading.value && isActive;

  /// Returns the current playback position.
  ///
  /// Returns [Duration.zero], if not active.
  Duration get position =>
      isActive ? _audioWorker.playback.position.value : Duration.zero;

  /// Returns total [Duration] of audio.
  ///
  /// Returns [Duration.zero], if not active.
  Duration get duration =>
      isActive ? _audioWorker.playback.duration.value : extractedDuration.value;

  /// Sets playback position in [AudioWorker].
  set position(Duration v) => _audioWorker.playback.position.value = v;

  @override
  void onInit() async {
    super.onInit();
    isDurationLoading.value = true;
    try {
      extractedDuration.value = await _audioWorker.extractDuration(
        source,
        onForbidden: onForbidden,
      );
    } finally {
      isDurationLoading.value = false;
    }
  }

  /// Toggles playback between playing and paused states.
  void togglePlay() {
    if (isActive && isPlaying) {
      _audioWorker.pause();
    } else {
      _audioWorker.play(id, source, onForbidden: onForbidden);
    }
  }

  /// Handles start of slider interaction.
  void onSliderChangeStart() {
    _audioWorker.beginSeek();
  }

  /// Handles end of slider interaction.
  void onSliderChangeEnd() async {
    await _audioWorker.endSeek(position);
  }

  /// Seeks to specific position in milliseconds.
  Future<void> seek(double ms) async {
    await _audioWorker.seek(Duration(milliseconds: ms.toInt()));
  }

  /// Stops playback and clears audio data.
  Future<void> stop() async {
    await _audioWorker.stop();
  }
}
