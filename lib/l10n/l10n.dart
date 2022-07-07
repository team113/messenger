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

/// Extension adding an ability to get translated [String] from the [L10n].
extension Translate on String {
  /// Returns a value identified by this [String] from the [L10n].
  String get td => L10n.format(this);

  /// Returns a value identified by this [String] from the [L10n]
  /// with the provided [args].
  String tdp(Map<String, dynamic> args) => L10n.format(this, args: args);
}

class Language {
  const Language(this.name, this.locale);
  final String name;
  final Locale locale;
}

/// Class that provides [FluentBundle] functionality.
class L10n {
  /// Currently selected language.
  static Rx<String?> chosen = Rx(null);

  /// [List] of [LocalizationsDelegate] that are available in the app.
  static List<LocalizationsDelegate<dynamic>> delegates = [
    const _FluentLocalizationsDelegate(),
  ];

  /// Supported [Language]s.
  static Map<String, Language> languages = const {
    'en_US': Language('English', Locale('en', 'US')),
    'ru_RU': Language('Русский', Locale('ru', 'RU')),
  };

  /// [FluentBundle] providing translation.
  static FluentBundle _bundle = FluentBundle('');

  /// Loads [chosen] locale to the [_bundle].
  static Future load() async {
    _bundle.messages.clear();
    _bundle.addMessages(
        await rootBundle.loadString('assets/l10n/${chosen.value}.ftl'));
  }

  /// Changes current locale and loads it.
  static Future<void> setLocale(String locale) async {
    if (chosen.value != locale) {
      chosen.value = locale;
      await load();
      await Get.forceAppUpdate();
    }
    chosen.refresh();
  }

  /// Returns translated value due to loaded [_bundle] locale.
  static String format(String key, {Map<String, dynamic> args = const {}}) {
    return _bundle.format(key, args: args);
  }
}

/// Custom `Fluent` [LocalizationsDelegate].
class _FluentLocalizationsDelegate extends LocalizationsDelegate<L10n> {
  const _FluentLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) {
    return L10n.languages.keys.any((k) => k == locale.toString());
  }

  @override
  Future<L10n> load(Locale locale) async {
    final String deviceLocale = locale.toString();
    L10n._bundle = FluentBundle(deviceLocale);
    L10n.chosen.value = deviceLocale;
    await L10n.load();
    return L10n();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<L10n> old) => false;
}
