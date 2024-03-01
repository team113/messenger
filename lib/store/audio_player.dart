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
import '/domain/model/audio_file.dart';
import '/util/audio_utils.dart';

class AudioStore extends GetxController {
  var currentAudio = 'Some id'.obs; // obs indicates observables for reactivity
  // var currentAudio = AudioFile(
  //   id: '2',
  //   name: 'Some id',
  //   ).obs; // obs indicates observables for reactivity

  var playlistQueue = <AudioFile>[].obs;

  // var playbackState = PlaybackState.stopped.obs;
  var playing = false.obs;
  var bufferedPosition = Duration.zero.obs;
  var currentSongPosition = Duration.zero.obs;
  var currentSongDuration = Duration.zero.obs;

  /// [StreamSubscription] for the audio playback.
  StreamSubscription? _audio;

  /// current audio stream player
  PlayerController? _audioStream;

  // Methods
  // void play(AudioFile audioFile) {
  void play(path, url) {
    playing.value = true;

    var asrc = path != null ? AudioSource.file(path!) : AudioSource.url(url!);
    _audioStream = AudioUtils.createPlayStream(asrc, loop: false, stop_others: true);
    _audio = _audioStream?.beginPlay(
      onData: (_) {
          print('get data');
          _audioStream?.getDurationStream().listen((event) {
            print('event');
            print(event);
            currentSongDuration.value = event;
          },
          onError: (e) {
            print('Error occurred while listening to duration stream: $e');
          }, );
          _audioStream?.getPositionStream().listen((event) {
            print('yoyoyo');
            currentSongPosition.value = event;
          });
      },
      onDone: () => {
        stop(external_call: true)
      }
    );
  }

  void stop({bool external_call=false}) {
    if (!external_call) {
      _audio?.cancel();
    }
    _audio = null;
    _audioStream = null;
  }

  void pause() {
    playing.value = false;
    // Implement pause logic, inheriting from AudioUtils (not provided)
  }

  // void seek(Duration position) {
  void seek(double position) {
    // Implement seek logic, inheriting from AudioUtils (not provided)
    // currentSongPosition.value = position; // TODO: convert to Duration
    _audioStream?.seek(position);
  }

  // void setCurrentAudio(AudioFile audioFile) {
  //   currentAudio.value = audioFile;
  // }

  void setCurrentAudio(String id) {
    currentAudio.value = id;
  }
}
