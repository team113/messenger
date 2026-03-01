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
import 'package:messenger/util/audio_utils.dart';

class MockAudioWorker extends Dependency implements AudioWorker {

  @override
  final RxnString activeAudioId = RxnString(null);

  @override
  final RxBool isPlaying = RxBool(false);

  @override
  final RxBool isLoading = RxBool(false);

  @override
  final Rx<Duration> position = Rx<Duration>(const Duration());

  @override
  final Rx<Duration> duration = Rx<Duration>(const Duration(minutes: 2));

  @override
  Future<void> play(String id, AudioSource source) async {
    activeAudioId.value = id;
    isLoading.value = true;

    await Future.delayed(const Duration(milliseconds: 100));

    isLoading.value = false;
    isPlaying.value = true;

    _startFakeProgress();
  }

  @override
  Future<void> pause() async {
    isPlaying.value = false;
  }

  @override
  Future<void> seek(Duration pos) async {
    position.value = pos;
  }

  void _startFakeProgress() async {
    while(isPlaying.value) {
      await Future.delayed(const Duration(seconds: 1));
      if (!isPlaying.value) break;
      position.value = position.value + const Duration(seconds: 1);
    }
  }

  @override
  Future<void> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

}
