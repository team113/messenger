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

import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/repository/settings.dart';

export 'view.dart';

/// Controller of a [TimelineSwitchView].
class TimelineSwitchController extends GetxController {
  TimelineSwitchController(this._settingsRepository);

  /// Settings repository updating the [ApplicationSettings.timelineEnabled].
  final AbstractSettingsRepository _settingsRepository;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings =>
      _settingsRepository.applicationSettings;

  /// Sets the [ApplicationSettings.timelineEnabled] value.
  Future<void> setTimelineEnabled(bool enabled) =>
      _settingsRepository.setTimelineEnabled(enabled);
}
