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

import 'dart:async';

import 'package:gherkin/gherkin.dart';
import 'package:integration_test/integration_test.dart';
import 'package:messenger/config.dart';

/// [Hook] gathering performance results of a test.
///
/// Results are embedded into the
/// [IntegrationTestWidgetsFlutterBinding.reportData] after all the tests run.
class PerformanceHook extends Hook {
  /// [Completer] measuring the performance between [onBeforeScenario] and
  /// [onAfterScenario].
  Completer? _completer;

  /// [Future]s of the [IntegrationTestWidgetsFlutterBinding.traceAction].
  final List<Future> _futures = [];

  /// [IntegrationTestWidgetsFlutterBinding.reportData]s accumulated.
  ///
  /// This is populated at every [onAfterScenario], since [onAfterRun] callback
  /// replaces the data stored in the binding with gherkin reports, and we
  /// don't want to lose the performance stats.
  final Map<String, dynamic> _data = {};

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

    // [_futures] aren't removed, because already completed [Future]s aren't
    // awaited at all, causing no microtask and no async code.
    await Future.wait(_futures);
    _data.addAll(
      IntegrationTestWidgetsFlutterBinding.instance.reportData ?? {},
    );
  }

  @override
  Future<void> onAfterRun(TestConfiguration config) async {
    if (_data.isNotEmpty) {
      IntegrationTestWidgetsFlutterBinding.instance.reportData?['traces'] =
          _data;
      IntegrationTestWidgetsFlutterBinding.instance.reportData?['level'] =
          Config.logLevel.index;
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
