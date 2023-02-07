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
import 'package:flutter/services.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/web/web_utils.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset =
      paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

/// Long presses a [Chat] with the provided name.
///
/// Examples:
/// - When I long press "Name" chat.
final StepDefinitionGeneric selectText = when3<String, int, int, CustomWorld>(
  'I select {string} text from {int} to {int} symbols',
  (text, from, to, context) async {
    await context.world.appDriver.waitForAppToSettle();

    RxChat? chat =
        Get.find<ChatService>().chats[ChatId(router.route.split('/').last)];
    ChatMessage message = chat!.messages
        .map((e) => e.value)
        .whereType<ChatMessage>()
        .firstWhere((e) => e.text?.val == text);

    Finder finder = context.world.appDriver
        .findByKeySkipOffstage('MyMessage_${message.id}');
    final RenderParagraph paragraph =
        context.world.appDriver.nativeDriver.renderObject<RenderParagraph>(
      find.descendant(
        of: finder,
        matching: find.byType(RichText, skipOffstage: false),
        skipOffstage: false,
      ),
      // context.world.appDriver.findByDescendant(
      //   finder,
      //   context.world.appDriver.findBy(RichText, FindType.type),
      //   matchRoot: true,
      // ),
    );
    print(paragraph);

    final TestGesture gesture = await context.world.appDriver.nativeDriver
        .startGesture(textOffsetToPosition(paragraph, from),
            kind: PointerDeviceKind.mouse);
    await context.world.appDriver.nativeDriver.pump();

    await gesture.moveTo(textOffsetToPosition(paragraph, to));

    await gesture.up();

    await context.world.appDriver.nativeDriver.pump();
    await gesture.removePointer();
  },
);

/// Long presses a [Chat] with the provided name.
///
/// Examples:
/// - When I long press "Name" chat.
final StepDefinitionGeneric checkCopyText = when1<String, CustomWorld>(
  'copied text is {string}',
  (text, context) async {
    await context.world.appDriver.waitForAppToSettle();
    // ClipboardData? cdata = await Clipboard.getData(Clipboard.kTextPlain);
    var data = await WebUtils.getCopied();
    // print('selected text:');
    expect(text, data);
    // print(cdata?.text);
  },
);
