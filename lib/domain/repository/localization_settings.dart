import 'package:get/get.dart';

import '/domain/model/localization_settings.dart';

/// [LocalizationSettings] repository interface.
abstract class AbstractLocalizationSettingsRepository {
  Rx<LocalizationSettings?> get localizationSettings;

  /// Puts the [locale] to the store.
  Future<void> setLocale(String locale);
}
