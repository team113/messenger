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

import '/ui/worker/audio/active_session.dart';
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
  final FutureOr<AudioSource?> Function()? onForbidden;

  /// Calculated duration of audio.
  final Rx<Duration> extractedDuration = Rx<Duration>(Duration.zero);

  /// Whether [extractedDuration] is being fetched.
  final RxBool isDurationLoading = RxBool(true);

  /// [AudioWorker] handling actual playback and synchronization.
  final AudioWorker _audioWorker;

  /// Returns active session if it belongs to this controller, otherwise `null`.
  ActiveAudioSession? get _session {
    final active = _audioWorker.activeSession.value;
    return active?.item.id == item.id ? active : null;
  }

  /// Indicates whether this controller's [item] is active.
  bool get isActive => _session != null;

  /// Indicates whether the current [item] is playing.
  bool get isPlaying => _session?.isPlaying ?? false;

  /// Indicates whether the current [item] is loading.
  bool get isLoading => _session?.isLoading ?? false;

  /// Returns the current playback position.
  ///
  /// Returns [Duration.zero], if not active.
  Duration get position => _session?.position ?? Duration.zero;

  /// Returns total [Duration] of audio.
  ///
  /// Returns [extractedDuration], if not active.
  Duration get duration => _session?.duration ?? extractedDuration.value;

  /// Sets playback position.
  set position(Duration v) => _session?.position = v;

  @override
  void onInit() async {
    super.onInit();

    isDurationLoading.value = true;

    try {
      extractedDuration.value = await _audioWorker.extract(
        item.source,
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
      await _audioWorker.play(item, onForbidden: onForbidden);
    }
  }

  /// Notifies that seek has started.
  Future<void> onSliderChangeStart() async => await _session?.beginSeek();

  /// Notifies that seek has ended.
  Future<void> onSliderChangeEnd() async => await _session?.endSeek(position);

  /// Stops playback and clears audio data.
  Future<void> stop() async => await _audioWorker.stop();
}
