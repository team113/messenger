import 'package:get/get.dart';

import '/domain/model/localization_settings.dart';

abstract class AbstractLocalizationSettingsRepository {
  Rx<LocalizationSettings?> get localizationSettings;

  /// Clears the stored settings.
  void clearCache();

  Future<void> setLocale(String locale);
}
