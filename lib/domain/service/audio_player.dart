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

import 'dart:async';
import 'package:get/get.dart';

import '/domain/model/audio_track.dart';
import '/util/audio_utils.dart';
import '/util/platform_utils.dart';
import 'disposable_service.dart';

/// Service implementing the [AudioPlayer] to manage audio player.
/// Exposes properties and methods for interacting with the player.
class AudioPlayerService extends DisposableService {
  /// Id of the currently selected playing audio. Later we will store some
  /// Song object here most likely.
  final RxnString currentAudio = RxnString(null);

  // Boolean indicating whether player is playing.
  final RxBool playing = false.obs;

  // Boolean indicating whether player is buffering.
  final RxBool buffering = false.obs;

  // Boolean indicating whether player has finished playing.
  final RxBool completed = false.obs;

  // Current song position.
  final Rx<Duration> currentSongPosition = Duration.zero.obs;

  // Current song duration.
  final Rx<Duration> currentSongDuration = Duration.zero.obs;

  // Current song buffered position.
  final Rx<Duration> bufferedPosition = Duration.zero.obs;

  /// Initializes audio player instance
  late AudioPlayer _player;

  /// Indicates whether [ja.AudioPlayer] or [mk.Player] should be used.
  bool get _isMobile => PlatformUtils.isMobile && !PlatformUtils.isWeb;

  // Reason why not using "late":
  // https://stackoverflow.com/questions/67401385/lateinitializationerror-field-data-has-not-been-initialized-got-error
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;

  /// Plays the [AudioTrack] in the [AudioPlayer].
  /// If it's previously selected track being played again - just resume.
  /// if it's a new track - set the audioSource and play.
  void play(AudioTrack audio) async {
    var isCurrent = currentAudio.value == audio.id;

    if (isCurrent) {
      _player.resume();
    } else {
      currentAudio.value = audio.id;
      _player.play(audio.audioSource);
    }
  }

  /// Pauses the [AudioPlayer].
  void pause() {
    _player.pause();
  }

  /// Rewinds [AudioPlayer] to a given position.
  void seek(Duration seekPosition) {
    _player.seek(seekPosition);
    _player.seek(seekPosition);
  }

  /// Stops the [AudioPlayer]
  void stop() {
    _player.stop();
    currentAudio.value = null;
  }

  /// Initializes the _player and subscribes to the streams.
  @override
  void onInit() {
    super.onInit();
    _initPlayer();
  }

  /// Dispose the _player instance on close.
  @override
  void onClose() {
    _playingSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _completedSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _player.dispose();
    super.onClose();
  }

  /// Initializes the audio _player based on the platform.
  void _initPlayer() {
    if (_isMobile) {
      _player = JustAudioPlayerAdapter();
    } else {
      _player = MediaKitPlayerAdapter();
    }

    _playingSubscription = _player.playingStream.listen((isPlaying) {
      playing.value = isPlaying;
    });

    _bufferingSubscription = _player.bufferingStream.listen((isBuffering) {
      buffering.value = isBuffering;
    });

    _completedSubscription = _player.completedStream.listen((isCompleted) {
      completed.value = isCompleted;
      playing.value = !isCompleted;
    });

    _positionSubscription = _player.positionStream.listen((position) {
      currentSongPosition.value = position;
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      currentSongDuration.value = duration;
    });

    _bufferedPositionSubscription =
        _player.bufferedPositionStream.listen((buffered) {
      bufferedPosition.value = buffered;
    });
  }
}
