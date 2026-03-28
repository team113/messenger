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

import '../audio.dart';
import 'playback.dart';

/// Manages playback state for a single active [AudioItem].
class AudioPlayback {
  AudioPlayback(this._delegate, this.item) {
    _setupListeners();
  }

  /// [AudioItem] for this [AudioPlayback] session.
  final AudioItem item;

  /// [AudioDelegate] responsible for actual playback operations.
  final AudioDelegate _delegate;

  /// [StreamSubscription] for handling playback completion.
  StreamSubscription? _completedSubscription;

  /// Indicator whether playback was active before a seek interaction.
  bool _wasPlaying = false;

  /// Indicates the audio is currently playing.
  RxBool get isPlaying => _delegate.isPlaying;

  /// Indicates the audio is currently loading.
  RxBool get isLoading => _delegate.isLoading;

  /// Returns total [Duration] of the audio.
  Rx<Duration> get duration => _delegate.duration;

  /// Returns current playback position.
  Rx<Duration> get position => _delegate.position;

  /// Sets the playback position to be [value].
  set position(Duration value) => _delegate.position.value = value;

  /// Starts a seek interaction, pausing playback if it was active.
  Future<void> beginSeek() async {
    _wasPlaying = _delegate.isPlaying.value;
    if (_wasPlaying) await _delegate.pause();
  }

  /// Ends a seek interaction, seeking to [position] and resuming, if needed.
  Future<void> endSeek(Duration position) async {
    await _delegate.seek(position);
    if (_wasPlaying) await _delegate.play();
    _wasPlaying = false;
  }

  /// Cancels the completion listener.
  void dispose() => _completedSubscription?.cancel();

  /// Wires up completion handling.
  void _setupListeners() {
    _completedSubscription = _delegate.isCompleted.listen((completed) async {
      if (completed) {
        await _delegate.pause();
        await _delegate.seek(Duration.zero);
      }
    });
  }
}
