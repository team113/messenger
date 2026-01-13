// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/provider/drift/background.dart';
import 'package:messenger/provider/drift/call_rect.dart';
import 'package:messenger/provider/drift/drift.dart';
import 'package:messenger/provider/drift/settings.dart';
import 'package:messenger/store/settings.dart';

void main() {
  setUp(Get.reset);

  final CommonDriftProvider common = CommonDriftProvider.memory();
  final ScopedDriftProvider scoped = ScopedDriftProvider.memory();

  final settingsProvider = Get.put(SettingsDriftProvider(common));
  final backgroundProvider = Get.put(BackgroundDriftProvider(common));
  final callRectProvider = Get.put(CallRectDriftProvider(common, scoped));

  final AbstractSettingsRepository repo = Get.put(
    SettingsRepository(
      settingsProvider,
      backgroundProvider,
      callRectProvider,
      me: const UserId('me'),
    ),
  );

  test('Noise suppression settings are stored', () async {
    await repo.init();

    expect(repo.mediaSettings.value?.noiseSuppression, true);
    await repo.setNoiseSuppression(enabled: false);
    await Future.delayed(Duration(microseconds: 16));
    expect(repo.mediaSettings.value?.noiseSuppression, false);

    expect(
      repo.mediaSettings.value?.noiseSuppressionLevel,
      NoiseSuppressionLevel.veryHigh,
    );
    await repo.setNoiseSuppression(
      enabled: true,
      level: NoiseSuppressionLevel.high,
    );
    await Future.delayed(Duration(microseconds: 16));
    expect(
      repo.mediaSettings.value?.noiseSuppressionLevel,
      NoiseSuppressionLevel.high,
    );

    expect(repo.mediaSettings.value?.echoCancellation, true);
    await repo.setEchoCancellation(false);
    await Future.delayed(Duration(microseconds: 16));
    expect(repo.mediaSettings.value?.echoCancellation, false);

    expect(repo.mediaSettings.value?.autoGainControl, true);
    await repo.setAutoGainControl(false);
    await Future.delayed(Duration(microseconds: 16));
    expect(repo.mediaSettings.value?.autoGainControl, false);

    expect(repo.mediaSettings.value?.highPassFilter, true);
    await repo.setHighPassFilter(false);
    await Future.delayed(Duration(microseconds: 16));
    expect(repo.mediaSettings.value?.highPassFilter, false);
  });

  tearDown(() async => Future.wait([common.close(), scoped.close()]));
}
