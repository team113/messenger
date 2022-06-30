import 'package:get/get.dart';

import '/domain/model/localization_settings.dart';
import '/domain/repository/localization_settings.dart';

import 'disposable_service.dart';

/// [LocalizationService] provides possibilities of getting
/// [localizationSettings] and setting localization to storage.
class LocalizationService extends DisposableService {
  LocalizationService(this._localizationRepository)
      : localizationSettings = _localizationRepository.localizationSettings;

  /// Uses for setting localization.
  final AbstractLocalizationSettingsRepository _localizationRepository;

  /// Reactive value of [LocalizationSettings] from [_localizationRepository].
  Rx<LocalizationSettings?> localizationSettings;

  /// Puts the [locale] to the store.
  Future<void> setLocale(String locale) async {
    _localizationRepository.setLocale(locale);
  }
}
