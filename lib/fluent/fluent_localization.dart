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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:universal_io/io.dart';

/// Class that provides [FluentBundle] functionality.
class FluentLocalization {
  /// [FluentBundle] class that provides functionality of translating values.
  static FluentBundle? bundle;

  /// Currently selected [MyUser]'s locale.
  static Rx<String?> chosen = Rx(null);

  /// [List] of [LocalizationsDelegate] that are available in the app.
  static List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    const _FluentLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Supported languages as locales with its names.
  static Map<String, String> languages = const {
    'en_US': 'English',
    'ru_RU': 'Русский',
  };

  /// Supported locales.
  static Map<String, Locale> locales = const {
    'en_US': Locale('en', 'US'),
    'ru_RU': Locale('ru', 'RU'),
  };

  /// Loads [chosen] locale to the [bundle].
  static Future load() async {
    bundle?.messages.clear();
    bundle?.addMessages(await rootBundle
        .loadString('assets/translates/${chosen.value}.ftl'.toLowerCase()));
  }

  /// Changes current locale and loads it.
  static Future<void> setLocale(String locale) async {
    if (chosen.value != locale) {
      chosen.value = locale;
      await load();
      chosen.refresh();
      Get.forceAppUpdate();
    } else {
      chosen.refresh();
    }
  }

  /// Returns translated value due to loaded [bundle] locale.
  static String getTranslatedValue(String key,
      {Map<String, dynamic> args = const {}}) {
    return bundle == null ? key : bundle!.format(key, args: args);
  }
}

/// Custom Fluent localization delegate.
class _FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalization> {
  const _FluentLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) {
    return FluentLocalization.locales.keys
        .any((key) => key == locale.toString());
  }

  @override
  Future<FluentLocalization> load(Locale locale) async {
    final String deviceLocale = Platform.localeName.replaceAll('-', '_');
    FluentLocalization.bundle = FluentBundle(deviceLocale);
    FluentLocalization.chosen.value = deviceLocale;
    await FluentLocalization.load();
    return FluentLocalization();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalization> old) =>
      false;
}
