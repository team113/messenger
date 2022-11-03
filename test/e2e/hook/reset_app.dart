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

import 'dart:async';

import 'package:dio/adapter.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:hive/hive.dart';
import 'package:messenger/main.dart';
import 'package:messenger/util/platform_utils.dart';

/// [Hook] resetting the [Hive] and [Get] states after a test.
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

    PlatformUtils.dio.httpClientAdapter = DefaultHttpClientAdapter();

    await Get.deleteAll(force: true);
    Get.reset();

    await Future.delayed(Duration.zero);
    await Hive.close();
    await Hive.clean('hive');
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) =>
      onBeforeScenario(config, scenario, tags);
}
