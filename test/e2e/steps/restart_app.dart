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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/main.dart';
import 'package:messenger/provider/geo/geo.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';

import '../mock/geo.dart';
import '../mock/graphql.dart';
import '../world/custom_world.dart';

/// Restarts the application.
///
/// Examples:
/// - Then I restart app
final StepDefinitionGeneric restartApp = then<CustomWorld>('I restart app', (
  context,
) async {
  print('======2 restartApp started...');

  // Going to [Routes.restart] page ensures all [GetxController]s are properly
  // released since they depend on the [router].
  router.go(Routes.restart);

  print('======2 restartApp waitForAppToSettle0 awaiting...');
  await context.world.appDriver.waitForAppToSettle();
  print('======2 restartApp waitForAppToSettle0 awaiting... done');

  final MockGraphQlProvider provider =
      Get.find<GraphQlProvider>() as MockGraphQlProvider;

  print('======2 restartApp Get.deleteAll awaiting...');
  await Get.deleteAll();
  print('======2 restartApp Get.deleteAll awaiting... done');

  print('======2 restartApp Future.delayed awaiting...');
  await Future.delayed(const Duration(seconds: 1));
  print('======2 restartApp Future.delayed awaiting... done');

  Get.put<GraphQlProvider>(
    MockGraphQlProvider()
      ..client.delay = provider.client.delay
      ..client.throwException = provider.client.throwException,
  );

  Get.put<GeoLocationProvider>(MockGeoLocationProvider());

  print('======2 restartApp main() awaiting...');
  await main();
  print('======2 restartApp main() awaiting... done');

  print('======2 restartApp waitForAppToSettle1 awaiting...');
  await context.world.appDriver.waitForAppToSettle();
  print('======2 restartApp waitForAppToSettle1 awaiting... done');

  print('======2 restartApp done');
});
