// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:medea_jason/medea_jason.dart' show LogLevel;

import '/domain/model/application_settings.dart';
import '/domain/repository/settings.dart';
import '/domain/service/disposable_service.dart';
import '/l10n/l10n.dart';
import '/util/media_utils.dart';

/// Worker updating the [L10n.chosen] on the [ApplicationSettings.locale]
/// changes and exposing its [onChanged] callback.
class SettingsWorker extends Dependency {
  SettingsWorker(this._settingsRepository, {this.onChanged});

  /// Callback, called on the [ApplicationSettings.locale] changes.
  final void Function(String? locale)? onChanged;

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

    int? logLevel = _settingsRepository.applicationSettings.value?.logLevel;
    _worker = ever(_settingsRepository.applicationSettings, (
      ApplicationSettings? settings,
    ) async {
      if (locale != settings?.locale) {
        locale = settings?.locale;
        L10n.set(Language.fromTag(locale) ?? L10n.languages.first);
        onChanged?.call(locale);
      }

      if (logLevel != settings?.logLevel) {
        logLevel = settings?.logLevel;

        if (logLevel != null) {
          await MediaUtils.setLogLevel(logLevel!.asLogLevel());
        }
      }
    });

    if (logLevel != null) {
      await MediaUtils.setLogLevel(logLevel!.asLogLevel());
    }
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }
}

/// Extension mapping [int]s to [LogLevel].
extension on int {
  /// Returns a [LogLevel] corresponding to this [int].
  LogLevel asLogLevel() => switch (this) {
    1 => LogLevel.warn,
    2 => LogLevel.info,
    3 => LogLevel.debug,
    (_) => LogLevel.error,
  };
}
