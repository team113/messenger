// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart'
    as integration_test_driver;
import 'package:log_me/log_me.dart';

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

  return integration_test_driver.integrationDriver(
    timeout: const Duration(minutes: 120),
    responseDataCallback: (data) async {
      // Retrieve the [LogLevel] from the [data], as accessing [Config] here
      // isn't possible due to Flutter imports happening in [Config].
      final int? level = data?['level'] is int ? data!['level'] as int : null;

      final Map<String, dynamic> traces = data?['traces'] ?? {};
      for (var e in traces.entries) {
        if (e.value is! Map<String, dynamic>) {
          continue;
        }

        final Timeline timeline = Timeline.fromJson(
          e.value as Map<String, dynamic>,
        );

        // Convert the [Timeline] into a [TimelineSummary] that's easier to read
        // and understand.
        final summary = TimelineSummary.summarize(timeline);

        const String directory = 'test/e2e/reports';

        // Write the whole [Timeline] to the disk, if [Config.logLevel] is or
        // bigger than [LogLevel.trace].
        //
        // Or write only the summary otherwise.
        if ((level ?? 0) >= LogLevel.trace.index) {
          await summary.writeTimelineToFile(
            e.key,
            destinationDirectory: directory,
            pretty: true,
            includeSummary: true,
          );
        } else {
          await fs.directory(directory).create(recursive: true);
          final File file = fs.file(
            '$directory/${e.key}.timeline_summary.json',
          );
          await file.writeAsString(
            const JsonEncoder.withIndent('  ').convert(summary.summaryJson),
          );
        }
      }
    },
  );
}
