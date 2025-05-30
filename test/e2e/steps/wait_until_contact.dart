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

import 'package:flutter_gherkin/src/flutter/parameters/existence_parameter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/service/contact.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Waits until a [ChatContact] with the provided name is present or absent.
///
/// Examples:
/// - Then I wait until "Dummy" contact is absent
/// - Then I wait until "Dummy" contact is present
final StepDefinitionGeneric untilContactExists =
    then2<String, Existence, CustomWorld>(
      'I wait until {string} contact is {existence}',
      (name, existence, context) async {
        await context.world.appDriver.waitUntil(() async {
          await context.world.appDriver.waitForAppToSettle();

          final RxChatContact? contact = Get.find<ContactService>()
              .paginated[context.world.contacts[name]];

          final Finder finder = context.world.appDriver.findByKeySkipOffstage(
            'Contact_${contact?.id}',
          );

          return existence == Existence.absent
              ? context.world.appDriver.isAbsent(finder)
              : context.world.appDriver.isPresent(finder);
        }, timeout: const Duration(seconds: 30));
      },
    );
