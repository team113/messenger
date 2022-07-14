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
import 'package:mutex/mutex.dart';

/// Localization of this application.
class L10n {
  /// Currently selected [Language].
  static final Rx<Language?> chosen = Rx(null);

  /// Supported [Language]s.
  ///
  /// First [Language] in the list is guaranteed to be English.
  static List<Language> languages = const [
    Language('English', Locale('en', 'US')),
    Language('Русский', Locale('ru', 'RU')),
  ];

  /// [FluentBundle] providing translation.
  static FluentBundle _bundle = FluentBundle('');

  /// Protects from async localization changes.
  static final Mutex _mutex = Mutex();

  /// Initializes this [L10n] with a default [Locale] of the device.
  static Future<void> init({Language? lang}) async {
    if (lang == null) {
      List<Locale> locales = WidgetsBinding.instance.platformDispatcher.locales;
      for (int i = 0; i < locales.length && chosen.value == null; ++i) {
        Language? language = Language.from(locales[i].toLanguageTag());
        if (language != null) {
          await set(language, refresh: false);
        }
      }
    } else {
      await set(lang);
    }

    if (chosen.value == null) {
      await set(languages.first, refresh: false);
    }
  }

  /// Sets the [chosen] language to the provided [lang].
  static Future<void> set(Language? lang, {bool refresh = true}) {
    if (lang == chosen.value || lang == null) {
      return Future.value();
    }

    if (languages.contains(lang)) {
      chosen.value = lang;
      return _mutex.protect(() async {
        _bundle = FluentBundle(lang.toString())
          ..addMessages(await rootBundle.loadString('assets/l10n/$lang.ftl'));
        if (refresh) {
          await Get.forceAppUpdate();
        }
      });
    } else {
      throw ArgumentError.value(lang);
    }
  }

  /// Returns translated value due to loaded locale.
  static String _format(String key, {Map<String, dynamic> args = const {}}) =>
      _bundle.format(key, args: args);
}

/// [Language] entity that is available in the app.
class Language {
  const Language(this.name, this.locale);

  /// Localized local name of this [Language].
  final String name;

  /// [Locale] this [Language] has.
  final Locale locale;

  /// Returns a [Language] identified by its [tag] from the [L10n.languages], if
  /// any.
  static Language? from(String? tag) {
    return L10n.languages.firstWhereOrNull((e) => e.toString() == tag);
  }

  @override
  String toString() => locale.toLanguageTag();
}

/// Extension adding an ability to get translated [String] from the [L10n].
extension L10nExtension on String {
  /// Returns a value identified by this [String] from the [L10n].
  String get td => L10n._format(this);

  /// Returns a value identified by this [String] from the [L10n] with the
  /// provided [args].
  String tdp(Map<String, dynamic> args) => L10n._format(this, args: args);
}
