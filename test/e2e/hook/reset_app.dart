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

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/provider/drift/connection/connection.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/util/get.dart';
import 'package:messenger/util/log.dart';
import 'package:messenger/util/platform_utils.dart';

import '../steps/internet.dart';

/// [Hook] resetting the [Get] states after a test.
class ResetAppHook extends Hook {
  @override
  int get priority => 1;

  @override
  Future<void> onBeforeRun(TestConfiguration config) async {
    Log.debug('onBeforeRun($config)...', 'E2E.$runtimeType');

    await clearDb();
    await super.onBeforeRun(config);

    Log.debug('onBeforeRun($config)... done!', 'E2E.$runtimeType');
  }

  @override
  Future<void> onBeforeScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    Log.debug('onBeforeScenario($config, $scenario)...', 'E2E.$runtimeType');

    // Ensure any ongoing `drift` connections are indeed closed and cleared.
    await Future.delayed(const Duration(seconds: 1));

    FocusManager.instance.primaryFocus?.unfocus();

    final drift = Get.findOrNull<CommonDriftProvider>();
    await drift?.reset();

    await Get.deleteAll();

    PlatformUtils.client?.interceptors.removeWhere(
      (e) => e is DelayedInterceptor,
    );

    svg.cache.clear();

    // Ensure any ongoing `drift` connections are indeed closed and cleared.
    await Future.delayed(const Duration(seconds: 1));

    Log.debug(
      'onBeforeScenario($config, $scenario)... done!',
      'E2E.$runtimeType',
    );
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    Log.debug('onAfterScenario($config, $scenario)...', 'E2E.$runtimeType');

    // Ensure any ongoing `drift` connections are indeed closed and cleared.
    await Future.delayed(const Duration(seconds: 1));

    FocusManager.instance.primaryFocus?.unfocus();

    final drift = Get.findOrNull<CommonDriftProvider>();
    await drift?.reset();

    await Get.deleteAll();

    PlatformUtils.client?.interceptors.removeWhere(
      (e) => e is DelayedInterceptor,
    );

    svg.cache.clear();

    // Ensure any ongoing `drift` connections are indeed closed and cleared.
    await Future.delayed(const Duration(seconds: 1));

    Log.debug(
      'onAfterScenario($config, $scenario)... done!',
      'E2E.$runtimeType',
    );
  }

  @override
  Future<void> onAfterRun(TestConfiguration config) async {
    Log.debug('onAfterRun($config)...', 'E2E.$runtimeType');

    await Get.deleteAll(force: true);

    await clearDb();
    await super.onAfterRun(config);

    Log.debug('onAfterScenario($config)... done!', 'E2E.$runtimeType');
  }
}
