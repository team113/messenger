import 'package:get/get.dart';

import '/domain/model/localization_settings.dart';
import '/domain/service/localization_settings.dart';

class LocalizationController extends GetxController {
  LocalizationController(this.localizationService)
      : localizationSettings = localizationService.localizationSettings;

  /// Reactive value of [LocalizationSettings].
  final Rx<LocalizationSettings?> localizationSettings;

  /// [LocalizationService] provides possibilities of getting
  /// [localizationSettings] and setting localization to storage.
  final LocalizationService localizationService;

  /// Sets [locale] to the store.
  Future<void> setLocale(String locale) async {
    await localizationService.setLocale(locale);
  }
}
