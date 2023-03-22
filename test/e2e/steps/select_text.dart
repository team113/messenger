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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/platform_utils.dart';

import '../configuration.dart';
import '../mock/platform_utils.dart';
import '../world/custom_world.dart';

/// Selects specified symbols in the text message.
///
/// Examples:
/// - When I select "Example" text from 1 to 5 symbols
final StepDefinitionGeneric selectMessageText =
    when3<String, int, int, CustomWorld>(
  'I select {string} message from {int} to {int} symbols',
  (text, from, to, context) async {
    await context.world.appDriver.waitForAppToSettle();

    final RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    final ChatMessage message = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .firstWhere((e) => e.text?.val == text);

    final Finder finder =
        context.world.appDriver.findByKeySkipOffstage('Text_${message.id}');
    final RenderParagraph paragraph =
        context.world.appDriver.nativeDriver.renderObject<RenderParagraph>(
      find.descendant(
        of: finder,
        matching: find.byType(RichText, skipOffstage: false),
        skipOffstage: false,
      ),
    );

    // Returns an [Offset] of the provided [paragraph].
    Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
      const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
      final Offset localOffset =
          paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
      return paragraph.localToGlobal(localOffset);
    }

    final TestGesture gesture =
        await context.world.appDriver.nativeDriver.startGesture(
      textOffsetToPosition(paragraph, from),
      kind: PointerDeviceKind.mouse,
    );
    await gesture
        .moveTo(textOffsetToPosition(paragraph, from).translate(0, 10));
    await gesture.moveTo(textOffsetToPosition(paragraph, to));
    await context.world.appDriver.nativeDriver.pump();
    await gesture.cancel();
    await context.world.appDriver.nativeDriver.pump();
  },
);

/// Indicates whether the copied text matches the specified text.
///
/// Examples:
/// - Then copied text is "Example"
final StepDefinitionGeneric checkCopyText = then1<String, CustomWorld>(
  'copied text is {string}',
  (text, context) async {
    expect(text, (PlatformUtils as PlatformUtilsMock).clipboard);
  },
);
