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

import '../world/custom_world.dart';
import '../configuration.dart';

/// Replaces [GraphQlProvider] to [MockGraphQlProvider] with provided delay.
///
/// Examples:
/// - I have internet with delay 1 second
/// - I have internet with delay 2 seconds
final StepDefinitionGeneric hasInternetWithDelay = given1<int, CustomWorld>(
  'I have internet with delay {int} second(s)?',
  (int delay, context) async {
    GraphQlProvider provider = Get.find();
    if (provider is MockGraphQlProvider) {
      provider.delay = delay.seconds;
      provider.hasError = false;
    }
  },
);
