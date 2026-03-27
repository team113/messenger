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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/config.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/util/get.dart';

import '../world/custom_world.dart';

/// Changes [Config.version] to a `test.0.0.1` string.
///
/// Examples:
/// - When application version is updated
final StepDefinitionGeneric updateAppVersion = then<CustomWorld>(
  'application version is updated',
  (context) async {
    Config.commonVersion += 1;

    final CommonDriftProvider? drift = Get.findOrNull<CommonDriftProvider>();

    await drift?.db?.migration.onUpgrade(
      drift.db!.createMigrator(),
      Config.commonVersion - 1,
      Config.commonVersion,
    );
  },
);
