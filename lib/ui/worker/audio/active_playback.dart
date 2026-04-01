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
import 'delegate.dart';

/// Manages playback state for a single active [AudioItem].
class AudioPlayback {
  AudioPlayback(this._delegate, this.item);

  /// [AudioItem] for this [AudioPlayback] session.
  final AudioItem item;

  /// Whether the current playback position is being dragged.
  final RxBool _isDragging = RxBool(false);

  /// Temporary playback position while dragging.
  final Rx<Duration> _dragPosition = Rx(Duration.zero);

  /// [AudioDelegate] responsible for actual playback operations.
  final AudioDelegate _delegate;

  /// Indicates the audio is currently playing.
  RxBool get isPlaying => _delegate.isPlaying;

  /// Indicates the audio is currently loading.
  RxBool get isLoading => _delegate.isLoading;

  /// Returns total [Duration] of the audio.
  Rx<Duration> get duration => _delegate.duration;

  /// Returns current playback position.
  Rx<Duration> get position => _delegate.position;

  /// Returns current playback visual position.
  Duration get visualPosition {
    if (_isDragging.value) {
      return _dragPosition.value;
    }
    return position.value;
  }

  /// Starts a seek interaction.
  void beginSeek() {
    _isDragging.value = true;
    _dragPosition.value = position.value;
  }

  /// Updates temporary [_dragPosition] while active seek interaction.
  void updatePosition(double v) {
    if (_isDragging.value) {
      _dragPosition.value = Duration(milliseconds: v.toInt());
    }
  }

  /// Ends a seek interaction, seeking to [_dragPosition].
  Future<void> endSeek() async {
    await _delegate.seek(_dragPosition.value);
    _isDragging.value = false;
  }
}
