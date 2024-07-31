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

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/ui/worker/cache.dart';
import 'package:messenger/util/get.dart';
import 'package:messenger/util/platform_utils.dart';

import '../steps/internet.dart';

/// [Hook] resetting the [Get] states after a test.
class ResetAppHook extends Hook {
  @override
  int get priority => 1;

  @override
  Future<void> onBeforeScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final drift = Get.findOrNull<CommonDriftProvider>();
    await drift?.reset();

    if (drift == null) {
      final database = Get.put(
        CommonDriftProvider.from(
          Get.putOrGet(() => CommonDatabase(), permanent: true),
        ),
      );

      await database.reset();
    }

    await Get.deleteAll();

    PlatformUtils.client?.interceptors
        .removeWhere((e) => e is DelayedInterceptor);

    svg.cache.clear();

    FIFOCache.clear();

    // Ensure any ongoing `drift` connections are indeed closed and cleared.
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) =>
      onBeforeScenario(config, scenario, tags);

  @override
  Future<void> onAfterRun(TestConfiguration config) async {
    await Get.deleteAll(force: true);
  }
}
