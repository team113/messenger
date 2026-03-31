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

import 'package:get/get.dart';

import '/util/audio_utils.dart';

/// Audio playback delegate playing the [AudioSource] provided.
abstract class AudioDelegate {
  /// Indicator whether playback is currently active.
  final RxBool isPlaying = RxBool(false);

  /// Indicator whether playback is currently loading or buffering.
  final RxBool isLoading = RxBool(false);

  /// Indicator whether playback reached the end of the source.
  final RxBool isCompleted = RxBool(false);

  /// Current playback position.
  final Rx<Duration> position = Rx(Duration.zero);

  /// Total [Duration] of the active source.
  final Rx<Duration> duration = Rx(Duration.zero);

  /// Resets state and prepares the provided [source] to be played.
  Future<void> prepare(AudioSource source, {Duration knownDuration});

  /// Disposes this [AudioDelegate].
  Future<void> dispose();

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback, if any is being played.
  Future<void> pause();

  /// Stops playback and releases source-specific resources.
  Future<void> stop();

  /// Seeks to the specified [position].
  Future<void> seek(Duration position);

  /// Extracts [Duration] from the [source] without starting a playback.
  Future<Duration> extract(AudioSource source);

  /// Resets playback state.
  void resetState() {
    isPlaying.value = false;
    isLoading.value = true;
    isCompleted.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }
}
