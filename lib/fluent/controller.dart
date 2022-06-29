import 'package:get/get.dart';

import '/domain/model/localization_settings.dart';
import '/domain/service/localization_settings.dart';

class LocalizationController extends GetxController {
  LocalizationController(this.localizationService)
      : localizationSettings = localizationService.localizationSettings;

  final Rx<LocalizationSettings?> localizationSettings;
  final LocalizationService localizationService;

  Future<void> setLocale(String locale) async {
    await localizationService.setLocale(locale);
  }
}
