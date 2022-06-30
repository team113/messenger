import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/localization_settings.dart';
import '/domain/repository/localization_settings.dart';
import '/provider/hive/localization_settings.dart';
import '/provider/hive/media_settings.dart';

/// Application settings repository.
class LocalizationSettingsRepository extends DisposableInterface
    implements AbstractLocalizationSettingsRepository {
  LocalizationSettingsRepository(this._localizationLocal)
      : localizationSettings =
            Rx<LocalizationSettings?>(_localizationLocal.settings);

  @override
  final Rx<LocalizationSettings?> localizationSettings;

  final LocalizationSettingsHiveProvider _localizationLocal;

  StreamIterator? _localizationSubscription;

  @override
  Future<void> setLocale(String locale) async {
    await _localizationLocal.setLocale(locale);
  }

  @override
  void onInit() {
    super.onInit();
    localizationSettings.value = _localizationLocal.settings;
    _initLocalizationSubscription();
  }

  @override
  void onClose() {
    _localizationSubscription?.cancel();
    super.onClose();
  }

  /// Initializes [MediaSettingsHiveProvider.boxEvents] subscription.
  Future<void> _initLocalizationSubscription() async {
    _localizationSubscription = StreamIterator(_localizationLocal.boxEvents);
    while (await _localizationSubscription!.moveNext()) {
      BoxEvent event = _localizationSubscription!.current;
      if (event.deleted) {
        localizationSettings.value = null;
      } else {
        localizationSettings.value = event.value;
        localizationSettings.refresh();
      }
    }
  }
}
