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

import 'dart:ui';

import 'en_us.dart';
import 'ru_ru.dart';

/// Localization of this application.
abstract class L10n {
  /// Supported languages as locales with its names.
  static Map<String, String> languages = const {
    'en_US': 'English',
    'ru_RU': 'Русский',
  };

  /// Translated phrases for each supported locale.
  static Map<String, Map<String, String>> phrases = {
    'en_US': enUS,
    'ru_RU': ruRU,
  };

  // TODO: Make it reactive.
  // TODO: Should be persisted in storage.
  /// Currently selected locale.
  static String chosen = 'ru_RU';

  /// Supported locales.
  static Map<String, Locale> locales = const {
    'en_US': Locale('en', 'US'),
    'ru_RU': Locale('ru', 'RU'),
  };
}
