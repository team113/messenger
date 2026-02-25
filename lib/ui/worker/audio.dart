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

import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as ja;

import '/domain/service/disposable_service.dart';
import '/util/audio_utils.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';

/// Worker responsible for [AudioUtils] related scoped functionality.
class AudioWorker extends Dependency {
  AudioWorker();

  final ja.AudioPlayer _player = ja.AudioPlayer();
  StreamSubscription? _audioIntentSubscription;

  final RxnString activeAudioId = RxnString();
  final RxBool isPlaying = RxBool(false);
  final RxBool isLoading = RxBool(false);
  final Rx<Duration> position = Rx<Duration>(Duration.zero);
  final Rx<Duration> duration = Rx<Duration>(Duration.zero);

  /// [StreamSubscription] to [AudioUtilsImpl.routeChangeStream].
  StreamSubscription? _routeSubscription;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    if (PlatformUtils.isIOS && !PlatformUtils.isWeb) {
      _initialize();
    }

    super.onInit();

    _player.playerStateStream.listen(
      (state) {
        isPlaying.value = state.playing;
        isLoading.value = [
          ja.ProcessingState.buffering,
          ja.ProcessingState.loading
        ].contains(state.processingState);
      } ,
    );
    _player.positionStream.listen((p) => position.value = p);
    _player.durationStream.listen(
      (d) => duration.value = d ?? Duration.zero,
    );
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');
    _routeSubscription?.cancel();
    _player.dispose();
    _audioIntentSubscription?.cancel();
    super.onClose();
  }

  /// Initializes the [_routeSubscription].
  Future<void> _initialize() async {
    _routeSubscription = AudioUtils.routeChangeStream.listen((e) async {
      Log.debug(
        'AudioUtils.routeChangeStream -> ${e.reason.name}',
        '$runtimeType',
      );

      switch (e.reason) {
        case AVAudioSessionRouteChangeReason.newDeviceAvailable:
        case AVAudioSessionRouteChangeReason.override:
        case AVAudioSessionRouteChangeReason.oldDeviceUnavailable:
        case AVAudioSessionRouteChangeReason.wakeFromSleep:
        case AVAudioSessionRouteChangeReason.noSuitableRouteForCategory:
          // No-op.
          break;

        case AVAudioSessionRouteChangeReason.categoryChange:
        case AVAudioSessionRouteChangeReason.routeConfigurationChange:
        case AVAudioSessionRouteChangeReason.unknown:
          // This may happen due to `media_kit` overriding the category, which
          // we shouldn't allow to happen.
          await AudioUtils.reconfigure(force: true);
          break;
      }
    });
  }

  Future<void> play(String id, AudioSource source) async {
    _audioIntentSubscription ??= AudioUtils.acquire(AudioMode.music).listen((_) {});

    if (activeAudioId.value == id) {
      await _player.play();
    } else {
      activeAudioId.value = id;
      await _player.setAudioSource(source.source);
      await _player.play();
    }
  }

  Future<void> pause() async => await _player.pause();

  Future<void> stop() async {
    await _player.stop();
    activeAudioId.value = null;

    await _audioIntentSubscription?.cancel();
    _audioIntentSubscription = null;
  }
  Future<void> seek(Duration pos) async => await _player.seek(pos);
}
