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
      const UserId('me'),
      settingsProvider,
      backgroundProvider,
      callRectProvider,
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
