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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/resource_location.dart';
import '../world/custom_world.dart';

/// Indicates whether a [Chat]-monolog has the specified [ResourceLocation].
///
/// Examples:
/// - And chat monolog is indeed local
/// - Then chat monolog is indeed remote
final StepDefinitionGeneric chatMonologLocation =
    then1<ResourceLocation, CustomWorld>(
  RegExp('chat monolog is indeed {resource_location}'),
  (status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();

        final provider = GraphQlProvider();
        final AuthService authService = Get.find();
        provider.token = authService.credentials.value!.session.token;

        final isLocal = (await provider.getMonolog()) == null;

        switch (status) {
          case ResourceLocation.local:
            return isLocal;

          case ResourceLocation.remote:
            return !isLocal;
        }
      },
    );
  },
);
