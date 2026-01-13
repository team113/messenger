// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/log.dart';

import '../parameters/availability_status.dart';
import '../world/custom_world.dart';

/// Indicates whether a [Chat]-monolog has the specified [AvailabilityStatus].
///
/// Examples:
/// - Then monolog is indeed local
/// - Then monolog is indeed remote
final StepDefinitionGeneric
monologAvailability = then1<AvailabilityStatus, CustomWorld>(
  'monolog is indeed {availability}',
  (status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        Log.debug(
          'monologAvailability -> await waitForAppToSettle()...',
          'E2E',
        );

        Log.debug(
          'monologAvailability -> await waitForAppToSettle()... done!',
          'E2E',
        );

        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false;

        final AuthService authService = Get.find();
        provider.token = authService.credentials.value!.access.secret;

        final mixin = await provider.getMonolog();

        final bool isLocal = mixin == null;

        Log.debug(
          'monologAvailability -> isLocal($isLocal), `getMonolog()` -> $mixin',
          'E2E',
        );

        provider.disconnect();

        switch (status) {
          case AvailabilityStatus.local:
            return isLocal;

          case AvailabilityStatus.remote:
            return !isLocal;
        }
      },
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(seconds: 4),
    );
  },
);
