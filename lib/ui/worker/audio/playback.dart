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

/// Audio playback helper playing the [AudioSource] provided.
abstract class AudioPlayback {
  /// Name of the currently active [AudioSource].
  final Rx<String?> sourceName = Rx(null);

  /// Whether playback is currently active.
  final RxBool isPlaying = RxBool(false);

  /// Whether playback is currently loading or buffering.
  final RxBool isLoading = RxBool(false);

  /// Current playback position.
  final Rx<Duration> position = Rx(Duration.zero);

  /// Total duration of the active source.
  final Rx<Duration> duration = Rx(Duration.zero);

  /// Whether playback reached the end of the source.
  final RxBool isCompleted = RxBool(false);

  /// Prepares the [source] to play.
  Future<void> prepare(AudioSource source);

  /// Disposes this [AudioPlayback].
  Future<void> dispose();

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback and releases source-specific resources.
  Future<void> stop();

  /// Seeks to the specified position.
  Future<void> seek(Duration position);

  /// Extracts duration from the [source] not starting a playback.
  Future<Duration> extractDuration(AudioSource source);
}
