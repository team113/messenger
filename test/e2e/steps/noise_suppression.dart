// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/domain/repository/settings.dart';

import '../configuration.dart';
import '../parameters/enabled_status.dart';
import '../world/custom_world.dart';

/// Drags the noise suppression slider to the provided [NoiseSuppressionLevel]
///
/// Examples:
/// - When I drag `NoiseSuppressionSlider` to high
final StepDefinitionGeneric dragNoiseSuppression =
    when1<NoiseSuppressionLevel, CustomWorld>(
      'I drag `NoiseSuppressionSlider` to {noise_level}',
      (level, context) async {
        await context.world.appDriver.waitUntil(() async {
          await context.world.appDriver.waitForAppToSettle();
          try {
            final finder = context.world.appDriver
                .findByKeySkipOffstage('NoiseSuppressionSlider')
                .first;

            final int index = NoiseSuppressionLevel.values.indexOf(level);
            await context.world.appDriver.nativeDriver.drag(
              finder,
              Offset(100.0 * index, 0),
            );
            await context.world.appDriver.waitForAppToSettle();
            return true;
          } catch (_) {
            return false;
          }
        });
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );

/// Indicates whether noise suppression is indeed [EnabledStatus.enabled] or not.
///
/// Examples:
/// - Then noise suppression is indeed enabled
final StepDefinitionGeneric noiseSuppressionIsIndeed =
    then1<EnabledStatus, CustomWorld>('noise suppression is indeed {enabled}', (
      enabled,
      context,
    ) async {
      await context.world.appDriver.waitUntil(() async {
        final repo = Get.find<AbstractSettingsRepository>();
        final bool? isEnabled =
            repo.mediaSettings.value?.noiseSuppressionEnabled;
        return isEnabled == (enabled == EnabledStatus.enabled);
      }, timeout: const Duration(seconds: 30));
    });

/// Indicates whether noise suppression level matched the provided value.
///
/// Examples:
/// - Then noise suppression level is indeed high
final StepDefinitionGeneric noiseSuppressionLevelIsIndeed =
    then1<NoiseSuppressionLevel, CustomWorld>(
      'noise suppression level is indeed {noise_level}',
      (level, context) async {
        await context.world.appDriver.waitUntil(() async {
          final repo = Get.find<AbstractSettingsRepository>();
          return repo.mediaSettings.value?.noiseSuppressionLevel == level;
        }, timeout: const Duration(seconds: 30));
      },
    );
