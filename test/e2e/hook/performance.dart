// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:gherkin/gherkin.dart';
import 'package:integration_test/integration_test.dart';

/// [Hook] gathering performance results of a test.
class PerformanceHook extends Hook {
  /// [Completer] measuring the performance between [onBeforeScenario] and
  /// [onAfterScenario].
  Completer? _completer;

  /// [Future]s of the [IntegrationTestWidgetsFlutterBinding.traceAction].
  final List<Future> _futures = [];

  Map<String, dynamic>? _data;

  @override
  int get priority => 0;

  @override
  Future<void> onBeforeScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    if (!(_completer?.isCompleted ?? true)) {
      _completer?.completeError(TimeoutException('Next scenario is being run'));
    }

    _completer = Completer();

    _futures.add(
      IntegrationTestWidgetsFlutterBinding.instance.traceAction(
        () => _completer!.future,
        reportKey: scenario.asPath,
      ),
    );
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    _completer?.complete();
    _completer = null;

    await Future.wait(_futures);
    _data = IntegrationTestWidgetsFlutterBinding.instance.reportData;
  }

  @override
  Future<void> onAfterRun(TestConfiguration config) async {
    if (_data != null) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData?.addAll(_data!);
    }
  }
}

/// Extension adding method removing any prohibited for filename symbols.
extension on String {
  /// Returns this [String] with any prohibited for a filename symbols removed.
  String get asPath {
    return replaceAll(' ', '_').replaceAll('\'', '_').replaceAll('"', '_');
  }
}
