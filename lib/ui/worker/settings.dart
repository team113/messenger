// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/repository/settings.dart';
import '/domain/service/disposable_service.dart';
import '/l10n/l10n.dart';

/// Worker updating the [L10n.chosen] on the [ApplicationSettings.locale]
/// changes.
class SettingsWorker extends DisposableService {
  SettingsWorker(this._settingsRepository);

  /// [AbstractSettingsRepository] storing the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepository;

  /// [Worker] updating the [L10n] on
  /// [AbstractSettingsRepository.applicationSettings] changes.
  Worker? _worker;

  /// Initializes this [SettingsWorker] and bootstraps the
  /// [ApplicationSettings.locale], if needed.
  Future<void> init() async {
    String? locale = _settingsRepository.applicationSettings.value?.locale;
    if (locale == null) {
      _settingsRepository.setLocale(L10n.chosen.value!.toString());
    } else {
      await L10n.set(Language.fromTag(locale));
    }

    _worker = ever(
      _settingsRepository.applicationSettings,
      (ApplicationSettings? settings) {
        if (locale != settings?.locale) {
          locale = settings?.locale;
          L10n.set(Language.fromTag(locale) ?? L10n.languages.first);
        }
      },
    );
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }
}
