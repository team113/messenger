// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/chat.dart';

import '../world/custom_world.dart';

/// Dismisses the [Chat] with the provided name.
///
/// Examples:
/// - When I dismiss "Name" chat
final StepDefinitionGeneric dismissChat = given1<String, CustomWorld>(
  'I dismiss {string} chat',
  (String name, context) async {
    final ChatId chatId = context.world.groups[name]!;

    await context.world.appDriver.waitUntil(() async {
      final finder = context.world.appDriver
          .findBy(Key('Chat_${chatId.val}'), FindType.key);

      if (await context.world.appDriver.isAbsent(finder)) {
        return false;
      }

      await context.world.appDriver.nativeDriver
          .fling(finder, const Offset(-400, 0), 800);

      return true;
    });
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
