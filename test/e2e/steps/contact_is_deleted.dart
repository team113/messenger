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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../world/custom_world.dart';

/// Indicates whether a [ChatContact] with the provided name is indeed deleted.
///
/// Examples:
/// - And "Name" chat is indeed deleted
final StepDefinitionGeneric contactIsIndeedDeleted =
    given1<String, CustomWorld>(
      '{string} contact is indeed deleted',
      (String name, context) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false;

        final AuthService authService = Get.find();
        provider.token = authService.credentials.value!.access.secret;

        await context.world.appDriver.waitUntil(() async {
          // TODO: Wait for backend to support querying single [ChatContact].
          final response = await provider.chatContacts();
          final isNone = response.edges.none((e) => e.node.name.val == name);

          if (isNone) {
            provider.disconnect();
          }

          return isNone;
        }, timeout: const Duration(seconds: 30));
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );
