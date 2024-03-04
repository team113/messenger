// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import '/util/platform_utils.dart';

class AudioPlayerController extends GetxController {
  late AudioPlayerInterface player;
  bool get _isMobile => PlatformUtils.isMobile && !PlatformUtils.isWeb;

  var currentAudio = 'Some id'.obs;
  var playing = false.obs;
  var buffering = false.obs;
  var currentSongPosition = Duration.zero.obs;
  var currentSongDuration = Duration.zero.obs;
  var bufferedPosition = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    _initPlayer();

    player.positionStream.listen((position) {
      currentSongPosition.value = position;
    });

    player.durationStream.listen((duration) {
      currentSongDuration.value = duration;
    });

    player.playingStream.listen((isPlaying) {
      playing.value = isPlaying;
    });

    player.playingStream.listen((isBuffering) {
      buffering.value = isBuffering;
    });

    player.bufferedPositionStream.listen((buffered) {
      bufferedPosition.value = buffered;
    });
  }

  void _initPlayer() {
    if (_isMobile) {
      player = JustAudioPlayerAdapter();
    } else {
      player = MediaKitPlayerAdapter();
    }
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }
}
