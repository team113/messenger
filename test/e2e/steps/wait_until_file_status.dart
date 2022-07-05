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

import 'package:gherkin/gherkin.dart';

import '../configuration.dart';
import '../parameters/sending_status.dart';
import '../world/custom_world.dart';

/// Waits until file attachment with provided status is present.
///
/// Examples:
/// - Then I wait until file status is sending
/// - Then I wait until file status is error
/// - Then I wait until file status is sent
final StepDefinitionGeneric waitUntilFileStatus =
    then1<SendingStatus, CustomWorld>(
  'I wait until file status is {sendingStatus}',
  (status, context) async {
    await context.world.appDriver.waitUntil(
      () async {
        await context.world.appDriver.waitForAppToSettle();
        return status == SendingStatus.sending
            ? context.world.appDriver.isPresent(
                context.world.appDriver.findByKeySkipOffstage('SendingFile'),
              )
            : status == SendingStatus.error
                ? context.world.appDriver.isPresent(
                    context.world.appDriver.findByKeySkipOffstage('ErrorFile'),
                  )
                : context.world.appDriver.isPresent(
                    context.world.appDriver.findByKeySkipOffstage('SentFile'),
                  );
      },
    );
  },
);
