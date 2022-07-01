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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../mock/graphql.dart';
import '../world/custom_world.dart';

/// Sets requests delay to provided.
///
/// Examples:
/// - I have Internet with delay 1 second
/// - I have Internet with delay 2 seconds
final StepDefinitionGeneric haveInternetWithDelay = given1<int, CustomWorld>(
  'I have Internet with delay {int} second(s)?',
  (int delay, context) => Future.sync(() {
    GraphQlProvider provider = Get.find();
    if (provider is MockGraphQlProvider) {
      provider.client.delay = delay.seconds;
      provider.client.throwException = false;
    }
  }),
);

/// Removes requests delay.
///
/// Examples:
/// - I have Internet without delay
final StepDefinitionGeneric haveInternetWithoutDelay = given<CustomWorld>(
  'I have Internet without delay',
  (context) => Future.sync(() {
    GraphQlProvider provider = Get.find();
    if (provider is MockGraphQlProvider) {
      provider.client.delay = null;
      provider.client.throwException = false;
    }
  }),
);

/// Replaces [GraphQlProvider] to [MockGraphQlProvider] with `hasError`: true.
///
/// Examples:
/// - I do not have Internet
final StepDefinitionGeneric noInternetConnection = given<CustomWorld>(
  'I do not have Internet',
  (context) => Future.sync(() {
    GraphQlProvider provider = Get.find();
    if (provider is MockGraphQlProvider) {
      provider.client.delay = 2.seconds;
      provider.client.throwException = true;
    }
  }),
);
