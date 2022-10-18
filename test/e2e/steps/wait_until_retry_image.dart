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

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/keys.dart';
import '../parameters/retry_image.dart';

/// Waits until the provided [WidgetKey] is present or absent.
///
/// Examples:
/// - Then I wait until image is loading
/// - Then I wait until image is loaded
final StepDefinitionGeneric waitUntilImage =
    then1<RetryImageStatus, FlutterWorld>(
  'I wait until image is {retry_status}',
  (status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        return status == RetryImageStatus.loading
            ? context.world.appDriver.isPresent(
                context.world.appDriver
                    .findByKeySkipOffstage('RetryImageLoading'),
              )
            : context.world.appDriver.isPresent(
                context.world.appDriver
                    .findByKeySkipOffstage('RetryImageLoaded'),
              );
      },
      pollInterval: const Duration(milliseconds: 1),
      timeout: const Duration(seconds: 60),
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(seconds: 60),
);
