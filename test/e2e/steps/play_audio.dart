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

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart' hide Attachment;
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/audio_player/slider.dart';
import 'package:messenger/ui/worker/audio.dart';
import 'package:messenger/util/audio_utils.dart';
import 'package:messenger/util/log.dart';

import '../configuration.dart';
import '../parameters/play_pause.dart';
import '../parameters/playback_status.dart';
import '../world/custom_world.dart';

/// Plays or pauses the provided audio file in a [Chat].
///
/// Examples:
/// - When I play "test.mp3" audio
/// - When I pause "test.mp3" audio
final StepDefinitionGeneric toggleAudioPlay =
    when2<PlayPauseAction, String, CustomWorld>(
      r'I {play_action} {string} audio$',
      (action, name, context) async {
        await context.world.appDriver.waitUntil(() async {
          final AudioId? id = _resolve(name);

          if (id == null) {
            Log.debug(
              'toggleAudioPlay($name, ${action.name}) -> `AudioId` is `null`',
              'E2E',
            );

            return false;
          }

          final String key = switch (action) {
            PlayPauseAction.play => 'Play',
            PlayPauseAction.pause => 'Pause',
          };

          final Finder toggleButton = context.world.appDriver
              .findByKeySkipOffstage('${key}Audio_$id');

          if (!toggleButton.tryEvaluate()) {
            return false;
          }

          await context.world.appDriver.nativeDriver.tap(toggleButton);

          return true;
        }, timeout: const Duration(seconds: 30));
      },
    );

/// Verifies that the specific audio file is the current [PlaybackStatus].
///
/// Examples:
/// - Then I see "test.mp3" audio is playing
/// - Then I see "test.mp3" audio is paused
final StepDefinitionGeneric audioIsPlayingOrPaused =
    then2<String, PlaybackStatus, CustomWorld>(
      'I see {string} audio is {playback_status}',
      (name, status, context) async {
        await context.world.appDriver.waitUntil(() async {
          final AudioWorker worker = Get.find<AudioWorker>();
          final AudioId? id = _resolve(name);

          if (id == null) {
            Log.debug(
              'audioIsPlayingOrPaused($name) -> `AudioId` is `null`',
              'E2E',
            );

            return false;
          }

          final bool isOursActive = worker.playback.value?.item.id == id;
          final bool isPlaying = worker.playback.value?.isPlaying.value == true;

          return switch (status) {
            PlaybackStatus.playing => isOursActive && isPlaying,
            PlaybackStatus.paused => !isOursActive || !isPlaying,
          };
        }, timeout: const Duration(seconds: 30));
      },
    );

/// Verifies that audio slider position changes while the audio is playing.
///
/// Examples:
/// - Then I see "test.mp3" audio slider position changes while playing
final StepDefinitionGeneric
audioSliderPositionChangesWhilePlaying = then1<String, CustomWorld>(
  'I see {string} audio slider position changes while playing',
  (name, context) async {
    await context.world.appDriver.waitUntil(() async {
      await context.world.appDriver.waitForAppToSettle();

      final AudioId? id = _resolve(name);

      if (id == null) {
        Log.debug(
          'audioSliderPositionChangesWhilePlaying($name) -> `AudioId` is `null`',
          'E2E',
        );

        return false;
      }

      final Finder slider = context.world.appDriver.findByKeySkipOffstage(
        'AudioSlider$id',
      );

      if (slider.evaluate().isEmpty) {
        Log.debug(
          'audioSliderPositionChangesWhilePlaying($name) -> `AudioSlider$id` seems to be missing: $slider',
          'E2E',
        );

        return false;
      }

      Duration sliderValue() {
        return (slider.evaluate().first.widget as SeekSlider).position;
      }

      final Duration initial = sliderValue();

      await Future.delayed(const Duration(seconds: 2));

      return sliderValue() > initial;
    }, timeout: const Duration(seconds: 30));
  },
);

/// Verifies that audio position is at [expectedSeconds].
///
/// Examples:
/// - Then I see "test.mp3" audio position is 0
final StepDefinitionGeneric audioPositionIs = then2<String, int, CustomWorld>(
  'I see {string} audio position is {int}',
  (name, expectedSeconds, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final worker = Get.find<AudioWorker>();

    expect(
      worker.playback.value!.position.value,
      Duration(seconds: expectedSeconds),
      reason: 'Worker progress is not 0',
    );
  },
);

/// Resolves [AudioId] for an [FileAttachment] with the provided [name].
AudioId? _resolve(String name) {
  final RxChat? chat = Get.find<ChatService>()
      .chats[ChatId(router.route.split('/').lastOrNull ?? '')];

  final ChatItem? item = chat?.messages
      .map((e) => e.value)
      .whereType<ChatMessage>()
      .firstWhereOrNull((i) => i.attachments.any((a) => a.filename == name));

  final Attachment? attachment = chat?.messages
      .map((e) => e.value)
      .whereType<ChatMessage>()
      .expand((e) => e.attachments)
      .firstWhereOrNull((a) => a.filename == name);

  if (item == null || attachment == null) {
    return null;
  }

  return AudioId.fromMessage(item.id, attachment.id);
}
