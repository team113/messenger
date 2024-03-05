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
import 'disposable_service.dart';

/// Service implementing the [AudioPlayerInterface] to manage audio player.
/// Exposes properties and methods for interacting with the player.
class AudioPlayerService extends DisposableService {
  /// Initializes audio player instance
  late AudioPlayerInterface player;
  // late AudioPlayerInterface player = AudioUtils.player();

  /// Id of the currently selected playing audio. Later we will store some
  /// Song object here most likely.
  final RxnString currentAudio = RxnString(null);

  // Boolean indicating whether player is playing.
  final RxBool playing = false.obs;

  // Boolean indicating whether player is buffering.
  final RxBool buffering = false.obs;

  // Current song position.
  final Rx<Duration> currentSongPosition = Duration.zero.obs;

  // Current song duration.
  final Rx<Duration> currentSongDuration = Duration.zero.obs;

  // Current song buffered position.
  final Rx<Duration> bufferedPosition = Duration.zero.obs;

  /// Indicates whether [ja.AudioPlayer] or [mk.Player] should be used.
  bool get _isMobile => PlatformUtils.isMobile && !PlatformUtils.isWeb;

  /// Initializes the player and subscribes to the streams.
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

  // void togglePlay(Attachment audioAttachment) {
  //   if (audioAttachment.id === currentAudioId.value) {
  //     if (playing.value) {
  //       player.pause();
  //     } else {
  //       player.play();
  //     }
  //   } else {
  //     String? path = (e is LocalAttachment) ? audioAttachment.file.path : null;
  //     String? url = audioAttachment.original.url;

  //     AudioSource audioSource = path != null
  //         ? AudioSource.file(path)
  //         : AudioSource.url(url);

  //     currentAudioId.value = audioAttachment.id.toString();

  //     player.setTrack(audioSource);
  //     player.play();
  //   }
  // }

  /// Dispose the player instance on close.
  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  /// Initializes the audio player based on the platform.
  void _initPlayer() {
    if (_isMobile) {
      player = JustAudioPlayerAdapter();
    } else {
      player = MediaKitPlayerAdapter();
    }
  }
}
