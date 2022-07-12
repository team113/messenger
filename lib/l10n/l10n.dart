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

import 'dart:async';

import 'package:fluent/fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Localization of this application.
class L10n {
  /// Currently selected language.
  static Rx<String?> chosen = Rx(null);

  /// Supported [Language]s.
  static Map<String, Language> languages = const {
    'en_US': Language('English', Locale('en', 'US')),
    'ru_RU': Language('Русский', Locale('ru', 'RU')),
  };

  /// [FluentBundle] providing translation.
  static FluentBundle _bundle = FluentBundle('');

  /// Initializes this [L10n] due to preferred locale of user's platform.
  static Future<void> ensureInitialized() async {
    final List<Locale> preferredLocales =
        WidgetsBinding.instance.window.locales;
    final List<Locale> supported =
        languages.values.map((lang) => lang.locale).toList();
    for (var loc in preferredLocales) {
      for (var supp in supported) {
        if (supp.languageCode == loc.languageCode) {
          await setLocale(supp.toString(), forceUpdateApp: false);
          return;
        }
      }
    }
    await setLocale('en_US');
  }

  /// Changes current locale and loads it.
  static Future<void> setLocale(String locale,
      {bool forceUpdateApp = true}) async {
    if (chosen.value != locale && languages.containsKey(locale)) {
      chosen.value = locale;
      _bundle = FluentBundle(locale.toString());
      _bundle.addMessages(
          await rootBundle.loadString('assets/l10n/${chosen.value}.ftl'));
      if (forceUpdateApp) await Get.forceAppUpdate();
    }
    chosen.refresh();
  }

  /// Returns translated value due to loaded locale.
  static String _format(String key, {Map<String, dynamic> args = const {}}) =>
      _bundle.format(key, args: args);
}

/// [Language] entity that is available in the app.
class Language {
  final String name;
  final Locale locale;

  const Language(this.name, this.locale);
}

/// Extension adding an ability to get translated [String] from the [L10n].
extension L10nExtension on String {
  /// Returns a value identified by this [String] from the [L10n].
  String get td => L10n._format(this);

  /// Returns a value identified by this [String] from the [L10n] with the
  /// provided [args].
  String tdp(Map<String, dynamic> args) => L10n._format(this, args: args);
}
