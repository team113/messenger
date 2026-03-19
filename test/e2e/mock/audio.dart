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
import 'package:messenger/domain/service/disposable_service.dart';
import 'package:messenger/ui/worker/audio.dart';
import 'package:messenger/ui/worker/audio/active_session.dart';
import 'package:messenger/ui/worker/audio/playback.dart';
import 'package:messenger/util/audio_utils.dart';

/// Mocked [AudioWorker] to use in the tests.
class MockAudioWorker extends Dependency implements AudioWorker {
  /// [AudioPlayback] to use.
  final AudioPlayback _playback = DummyPlayback();

  /// Currently active session.
  final Rx<ActiveAudioSession?> _activeSession = Rx(null);

  @override
  Future<void> play(
    AudioId id,
    AudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) async {
    _playback.isLoading.value = true;

    _playback.duration.value = const Duration(minutes: 2);
    _playback.isCompleted.value = false;

    _activeSession.value?.dispose();
    _activeSession.value = ActiveAudioSession(
      _playback,
      id: id,
      source: source,
    );

    await Future.delayed(const Duration(milliseconds: 100));

    _playback.isLoading.value = false;
    _playback.isPlaying.value = true;

    _startFakeProgress();
  }

  @override
  Future<void> pause() async {
    _playback.isPlaying.value = false;
  }

  @override
  Future<void> stop() async {
    _playback.isPlaying.value = false;
    _playback.position.value = const Duration();
    _activeSession.value?.dispose();
    _activeSession.value = null;
  }

  @override
  Future<Duration> extract(
    AudioSource source, {
    FutureOr<AudioSource?> Function()? onForbidden,
  }) {
    return _playback.extract(source);
  }

  /// Fakes progress via increasing [AudioPlayback.position].
  void _startFakeProgress() async {
    while (_playback.isPlaying.value) {
      await Future.delayed(const Duration(seconds: 1));

      if (!_playback.isPlaying.value) {
        break;
      }

      _playback.position.value =
          _playback.position.value + const Duration(seconds: 1);
    }
  }

  @override
  Rx<ActiveAudioSession?> get activeSession => _activeSession;
}

/// Mocked dummy [AudioPlayback].
class DummyPlayback extends AudioPlayback {
  @override
  Future<void> dispose() async {
    // No-op.
  }

  @override
  Future<Duration> extract(AudioSource source) => Future.delayed(
    const Duration(milliseconds: 100),
    () => const Duration(minutes: 2),
  );

  @override
  Future<void> pause() async {
    // No-op.
  }

  @override
  Future<void> play() async {
    // No-op.
  }

  @override
  Future<void> prepare(AudioSource source) async {
    // No-op.
  }

  @override
  Future<void> seek(Duration position) async {
    // No-op.
  }

  @override
  Future<void> stop() async {
    // No-op.
  }
}
