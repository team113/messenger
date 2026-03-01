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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/ui/worker/audio.dart';
import 'package:messenger/routes.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Returns [RxChat] by the current route.
RxChat? _getChat() {
  final String route = router.route;
  final String? id = route.split('/').lastOrNull;

  if (id == null) {
    return null;
  }

  final ChatService service = Get.find<ChatService>();

  RxChat? chat = service.chats[ChatId(id)];

  if (chat == null && id.startsWith('d_')) {
    final UserId userId = UserId(id.replaceFirst('d_', ''));
    chat = service.chats.values.firstWhereOrNull(
      (e) => e.chat.value.isDialog && e.chat.value.members.any((m) => m.user.id == userId),
    );
  }

  return chat;
}

/// Toggles the audio player.
///
/// Examples:
/// - When I toggle play for "test.mp3" audio
final StepDefinitionGeneric toggleAudioPlay = when1<String, CustomWorld>(
  'I toggle play for {string} audio',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final RxChat? chat = _getChat();

    final Attachment attachment = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere(
          (a) => a.filename == name,
          orElse: () =>
              throw Exception('Audio file "$name" not found in current chat'),
        );

    Finder toggleButton = context.world.appDriver.findByKeySkipOffstage(
      'PlayerButton${attachment.id.val}',
    );
    await context.world.appDriver.nativeDriver.tap(toggleButton);
  },
);

/// Verifies that the specific audio file is currently playing.
///
/// Examples:
/// - Then audio "test.mp3" is playing
final StepDefinitionGeneric audioIsPlaying = then1<String, CustomWorld>(
  'I see {string} audio is playing',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle();
    await Future.delayed(const Duration(milliseconds: 500));

    final RxChat? chat = _getChat();

    final Attachment attachment = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere(
          (a) => a.filename == name,
          orElse: () =>
              throw Exception('Audio file "$name" not found in current chat'),
        );

    final AudioWorker worker = Get.find<AudioWorker>();

    bool isPlaying =
        (worker.activeAudioId.value == attachment.id.val &&
        worker.isPlaying.value);

    expect(isPlaying, true);
  },
);

/// Verifies that the specific audio file is currently paused.
///
/// Examples:
/// - Then I see "test.mp3" audio is paused
final StepDefinitionGeneric audioIsPaused = then1<String, CustomWorld>(
  'I see {string} audio is paused',
  (name, context) async {
    await context.world.appDriver.waitForAppToSettle();
    await Future.delayed(const Duration(milliseconds: 500));

    final RxChat? chat = _getChat();

    final Attachment attachment = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .expand((e) => e.attachments)
        .firstWhere((a) => a.filename == name);

    final AudioWorker worker = Get.find<AudioWorker>();

    bool isPaused =
        (worker.activeAudioId.value == attachment.id.val &&
            !worker.isPlaying.value) ||
        (worker.activeAudioId.value != attachment.id.val);

    if (!isPaused) {
      throw Exception(
        'Expected audio "$name" to be paused, but it is playing.',
      );
    }
  },
);
