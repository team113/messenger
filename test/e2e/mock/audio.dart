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

import 'package:messenger/ui/worker/audio.dart';
import 'package:messenger/ui/worker/audio/active_playback.dart';
import 'package:messenger/ui/worker/audio/playback.dart';
import 'package:messenger/util/audio_utils.dart';

/// Mocked [AudioWorker] to use in the tests.
class MockAudioWorker extends AudioWorker {
  MockAudioWorker() : super(delegate: DummyDelegate());
}

/// Mocked dummy [AudioDelegate].
class DummyDelegate extends AudioDelegate {
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
    isPlaying.value = false;
  }

  @override
  Future<void> play() async {
    isCompleted.value = false;
    isLoading.value = true;
    duration.value = const Duration(minutes: 2);

    isLoading.value = false;
    isPlaying.value = true;
    _startFakeProgress();
  }

  @override
  Future<void> prepare(
    AudioSource source, {
    Duration knownDuration = Duration.zero,
  }) async {
    // No-op.
  }

  @override
  Future<void> seek(Duration position) async {
    // No-op.
  }

  @override
  Future<void> stop() async {
    isPlaying.value = false;
    position.value = const Duration();
  }

  /// Fakes progress via increasing [AudioPlayback.position].
  void _startFakeProgress() async {
    while (isPlaying.value) {
      await Future.delayed(const Duration(seconds: 1));

      if (!isPlaying.value) {
        break;
      }

      position.value = position.value + const Duration(seconds: 1);
    }
  }
}
