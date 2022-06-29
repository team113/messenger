import 'package:get/get.dart';

import '/domain/model/localization_settings.dart';
import '/domain/repository/localization_settings.dart';

import 'disposable_service.dart';

class LocalizationService extends DisposableService {
  LocalizationService(this._localizationRepository)
      : localizationSettings = _localizationRepository.localizationSettings;

  final AbstractLocalizationSettingsRepository _localizationRepository;

  Rx<LocalizationSettings?> localizationSettings;

  Future<void> setLocale(String locale) async {
    _localizationRepository.setLocale(locale);
  }
}
