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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/ui/worker/audio_player.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Plays the audio in [AudioAttachment] when clicked.
///
/// Examples:
/// - When I play "test.mp3" audio file
final StepDefinitionGeneric playAudioAttachment = when1<String, CustomWorld>(
    'I play {string} audio file', (name, context) async {
  await context.world.appDriver.waitForAppToSettle();
  final AudioPlayerWorker audioPlayer = AudioPlayerWorker.instance;

  RxChat? chat =
      Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
  Attachment attachment = chat!.messages
      .map((e) => e.value)
      .whereType<ChatMessage>()
      .expand((e) => e.attachments)
      .firstWhere((a) => a.filename == name);

  await Future.delayed(const Duration(milliseconds: 500));
  Finder playButton = context.world.appDriver
      .findByKeySkipOffstage('AudioFile_${attachment.id}');
  await context.world.appDriver.nativeDriver.tap(playButton);
  await Future.delayed(const Duration(seconds: 3));

  while (audioPlayer.buffering.value) {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Delay to showcase audio is working
  await Future.delayed(const Duration(seconds: 3));
});

/// Indicates whether [AudioPlayer] is playing
/// and correct [AudioTrack] is playing.
///
/// Examples:
/// - Then audio "test.mp3" is playing
final StepDefinitionGeneric checkAudioPlaying = then1<String, CustomWorld>(
  'audio {string} is playing',
  (name, context) async {
    /// 1. See [AudioPlayer] is playing.
    final AudioPlayerWorker audioPlayer = AudioPlayerWorker.instance;
    var isPlaying = audioPlayer.playing.value;

    expect(isPlaying, true);

    /// 2. See [AudioPlayerWorker] has correct [AudioTrack].id.
    RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    Attachment attachment = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere((a) => a.filename == name);

    expect(audioPlayer.currentAudio.toString(), attachment.id.toString());
  },
);
