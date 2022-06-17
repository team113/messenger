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

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart'
    as integration_test_driver;

/// Entry point of a Flutter integration test driver.
Future<void> main() {
  // Flutter driver logs all messages to STDERR by default.
  driverLog = (String source, String message) {
    final msg = '$source: $message';
    if (message.toLowerCase().contains('error')) {
      stderr.writeln(msg);
    } else {
      stdout.writeln(msg);
    }
  };

  // If available, test report will be saved in this directory.
  integration_test_driver.testOutputsDirectory = 'test/e2e/reports';

  return integration_test_driver.integrationDriver(
    timeout: const Duration(minutes: 30),
  );
}
