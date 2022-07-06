// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import '/fluent/fluent_localization.dart';

/// Controller of the [Routes.settings] page.
class SettingsController extends GetxController {
  SettingsController(this._settingsRepo);

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settingsRepo.applicationSettings;

  /// Sets the [ApplicationSettings.enablePopups] value.
  Future<void> setPopupsEnabled(bool enabled) =>
      _settingsRepo.setPopupsEnabled(enabled);

  /// Sets the [ApplicationSettings.locale] value.
  Future<void> setLocale(String? locale) async {
    await _settingsRepo.setLocale(locale!);
    await FluentLocalization.setLocale(locale);
  }
}
