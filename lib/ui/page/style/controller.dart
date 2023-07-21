// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rive/rive.dart';

export 'view.dart';

/// List of [StyleView] page sections.
enum StyleTab { colors, typography, multimedia, elements }

/// Controller of a [StyleView].
class StyleController extends GetxController {
  StyleController();

  /// Indicator whether the colors should be inverted.
  final RxBool inverted = RxBool(false);

  /// Selected [StyleTab].
  final Rx<StyleTab> tab = Rx(StyleTab.colors);

  /// Current logo's animation frame.
  RxInt logoFrame = RxInt(0);

  /// TODO: docs
  RxBool isPlaying = RxBool(false);

  /// [SMITrigger] triggering the blinking animation.
  SMITrigger? blink;

  /// [Timer] periodically increasing the [logoFrame].
  Timer? _animationTimer;

  /// [AudioPlayer] currently playing an audio.
  AudioPlayer? _audioPlayer;

  /// [Timer] increasing the [_audioPlayer] volume gradually in [play] method.
  Timer? _fadeTimer;

  @override
  void onInit() {
    _initAudio();
    super.onInit();
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    AudioCache.instance.clearAll();
    super.onClose();
  }

  /// Resets the [logoFrame] and starts the blinking animation.
  void animate() {
    blink?.fire();

    logoFrame.value = 1;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 45),
      (t) {
        ++logoFrame.value;
        if (logoFrame >= 9) t.cancel();
      },
    );
  }

  final Map<String, bool> isPlayingMap = {
    'chinese.mp3': false,
    'chinese-web.mp3': false,
    'ringing.mp3': false,
    'reconnect.mp3': false,
    'message_sent.mp3': false,
    'notification.mp3': false,
    'pop.mp3': false,
  }.obs;

  /// Plays the given [asset].
  Future<void> play(String asset, {bool fade = false}) async {
    runZonedGuarded(() async {
      await _audioPlayer?.play(
        AssetSource('audio/$asset'),
        volume: fade ? 0 : 1,
        position: Duration.zero,
        mode: PlayerMode.lowLatency,
      );

      isPlayingMap[asset] = true;

      _audioPlayer?.onPlayerComplete.listen((event) {
        isPlayingMap[asset] = false;
      });

      if (fade) {
        _fadeTimer?.cancel();
        _fadeTimer = Timer.periodic(
          const Duration(milliseconds: 100),
          (timer) async {
            if (timer.tick > 9) {
              timer.cancel();
            } else {
              await _audioPlayer?.setVolume((timer.tick + 1) / 10);
            }
          },
        );
      }
    }, (e, _) {
      if (!e.toString().contains('NotAllowedError')) {
        throw e;
      }
    });
  }

  /// Stops the audio that is currently playing.
  Future<void> stop(String asset) async {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    isPlayingMap[asset] = false;
    await _audioPlayer?.setReleaseMode(ReleaseMode.release);
    await _audioPlayer?.release();
  }

  /// Initializes the [_audioPlayer].
  Future<void> _initAudio() async {
    // [AudioPlayer] constructor creates a hanging [Future], which can't be
    // awaited.
    await runZonedGuarded(
      () async {
        _audioPlayer = AudioPlayer();
        await AudioCache.instance.loadAll([
          'audio/chinese.mp3',
          'audio/chinese-web.mp3',
          'audio/message-sent.mp3',
          'audio/notification.mp3',
          'audio/pop.mp3',
          'audio/ringing.mp3'
        ]);
      },
      (e, _) {
        if (e is MissingPluginException) {
          _audioPlayer = null;
        } else {
          throw e;
        }
      },
    );
  }
}
