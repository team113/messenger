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

import 'package:just_audio/just_audio.dart' as ja;

import '../playback.dart';
import '/util/audio_utils.dart';

/// [AudioPlayback] implemented by using a [ja.AudioPlayer].
class JustAudioPlayback extends AudioPlayback {
  JustAudioPlayback() {
    _subscriptions.addAll([
      _player.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
        isLoading.value =
            state.processingState == ja.ProcessingState.buffering ||
            state.processingState == ja.ProcessingState.loading;
        isCompleted.value =
            state.processingState == ja.ProcessingState.completed;
      }),
      _player.positionStream.distinct().listen(
        (value) => position.value = value,
      ),
      _player.durationStream.listen(
        (value) => duration.value = value ?? Duration.zero,
      ),
    ]);
  }

  /// Underlying [ja.AudioPlayer] player.
  final ja.AudioPlayer _player = ja.AudioPlayer();

  /// List of [_player] subscriptions.
  final List<StreamSubscription> _subscriptions = [];

  @override
  Future<void> prepare(AudioSource source) async {
    _resetState();
    sourceName.value = source.name;
    await _player.setAudioSource(source.source);
  }

  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _resetState();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    await _player.dispose();
  }

  @override
  Future<Duration> extractDuration(AudioSource source) async {
    final player = ja.AudioPlayer();
    try {
      final duration = await player.setAudioSource(source.source);
      return duration ?? Duration.zero;
    } finally {
      await player.dispose();
    }
  }

  /// Resets state.
  void _resetState() {
    isPlaying.value = false;
    isLoading.value = true;
    isCompleted.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
  }
}
