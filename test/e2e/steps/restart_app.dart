// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:hive/hive.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/notification.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/ui/worker/background/background.dart';

import '../configuration.dart';
import '../world/custom_world.dart';

/// Restarts application.
///
/// Examples:
/// - Then I restart app
final StepDefinitionGeneric restartApp = then<CustomWorld>(
  'I restart app',
  (context) async {
    await Get.deleteAll(force: true);
    Get.reset();

    await Future.delayed(Duration.zero);
    await Hive.close();

    await Get.put(SessionDataHiveProvider()).init();
    await Get.put(NotificationService()).init();
    var graphQlProvider = Get.put(GraphQlProvider());

    Get.put<AbstractAuthRepository>(AuthRepository(graphQlProvider));
    var authService =
        Get.put(AuthService(AuthRepository(graphQlProvider), Get.find()));
    await authService.init();
    Get.put(BackgroundWorker(Get.find()));

    await (router.delegate as AppRouterDelegate)
        .createHomeViewDependencies(authService.userId!);

    BuildContext ctx = context.world.appDriver.nativeDriver
        .element(context.world.appDriver.findByKeySkipOffstage('HomeView'));
    Phoenix.rebirth(ctx);
  },
);
