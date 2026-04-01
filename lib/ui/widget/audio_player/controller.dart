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

import '/ui/worker/audio/active_playback.dart';
import '/ui/worker/audio.dart';
import '/util/audio_utils.dart';

/// [AudioPlayer] controller managing state for a specific audio [item].
class AudioPlayerController extends GetxController {
  AudioPlayerController(
    this._audioWorker, {
    required this.item,
    this.onForbidden,
  });

  /// Metadata of the audio.
  final AudioItem item;

  /// Whether the view is being hovered.
  final RxBool hovered = RxBool(false);

  /// Callback, called when [item.source] fetch fails with `403` status code.
  final Future<AudioSource?> Function()? onForbidden;

  /// Calculated duration of audio.
  final Rx<Duration> extractedDuration = Rx(Duration.zero);

  /// Whether [extractedDuration] is being fetched.
  final RxBool isDurationLoading = RxBool(true);

  /// [AudioWorker] handling actual playback and synchronization.
  final AudioWorker _audioWorker;

  /// Indicates whether [AudioPlayback] being played is the [item] this
  /// [AudioPlayerController] represents.
  bool get isActive => _playback.value?.item.id == item.id;

  /// Indicates whether this controller's [item] is currently playing.
  bool get isPlaying => isActive && _playback.value?.isPlaying.value == true;

  /// Indicates whether this controller's [item] is currently loading.
  bool get isLoading => isActive && _playback.value?.isLoading.value == true;

  /// Returns the current playback visual position.
  ///
  /// Returns [Duration.zero], if not active.
  Duration get position {
    if (isActive && _playback.value != null) {
      return _playback.value!.visualPosition;
    } else {
      return Duration.zero;
    }
  }

  /// Returns the total audio duration.
  ///
  /// When active, prefers live playback data, otherwise falls back to
  /// [extractedDuration].
  Duration get duration {
    if (isActive && _playback.value != null) {
      return _playback.value!.duration.value;
    } else {
      return extractedDuration.value;
    }
  }

  /// Returns currently active [AudioPlayback], if any.
  Rx<AudioPlayback?> get _playback => _audioWorker.playback;

  @override
  void onInit() async {
    super.onInit();

    isDurationLoading.value = true;
    try {
      extractedDuration.value = await _audioWorker.extract(
        item,
        onForbidden: onForbidden,
      );
    } finally {
      isDurationLoading.value = false;
    }
  }

  /// Toggles playback between playing and paused states.
  Future<void> playOrPause() async {
    if (isPlaying) {
      await _audioWorker.pause();
    } else {
      await _audioWorker.play(
        AudioItem(id: item.id, source: item.source, title: item.title),
        onForbidden: onForbidden,
      );
    }
  }

  /// Notifies that seek has started.
  Future<void> onSliderChangeStart() async {
    if (isActive) {
      _playback.value?.beginSeek();
    }
  }

  /// Notifies that playback position is being updated.
  void onSliderChange(double value) {
    if (isActive) {
      _playback.value?.updatePosition(value);
    }
  }

  /// Notifies that seek has ended.
  Future<void> onSliderChangeEnd() async {
    if (isActive) {
      await _playback.value?.endSeek();
    }
  }

  /// Stops playback for this controller's [item].
  Future<void> stop() async => await _audioWorker.stop();
}
