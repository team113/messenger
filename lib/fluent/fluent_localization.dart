import 'package:fluent/fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '/fluent/controller.dart';

class FluentLocalization {
  Locale locale;
  final FluentBundle bundle;

  FluentLocalization(this.locale) : bundle = FluentBundle(locale.toString());

  static FluentLocalization? of(BuildContext context) {
    return Localizations.of<FluentLocalization>(context, FluentLocalization);
  }

  Future load() async {
    bundle.messages.clear();
    bundle.addMessages(await rootBundle.loadString(
        'assets/translates/${locale.toString()}.ftl'.toLowerCase()));
  }

  String getTranslatedValue(String key,
      {Map<String, dynamic> args = const {}}) {
    return bundle.format(key, args: args);
  }

  static const LocalizationsDelegate<FluentLocalization> delegate =
      _FluentLocalizationsDelegate();
}

class _FluentLocalizationsDelegate
    extends LocalizationsDelegate<FluentLocalization> {
  const _FluentLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) {
    return LocalizationUtils.locales.keys
        .any((key) => key == locale.toString());
  }

  @override
  Future<FluentLocalization> load(Locale locale) async {
    LocalizationUtils.bundle = FluentLocalization(locale);
    await LocalizationUtils.bundle.load();
    return LocalizationUtils.bundle;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalization> old) =>
      false;
}

abstract class LocalizationUtils {
  static late FluentLocalization bundle;

  static List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    FluentLocalization.delegate,
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

  /// Currently selected locale.
  static String? get chosen => Get.find<LocalizationController>()
      .localizationService
      .localizationSettings
      .value!
      .locale;

  static Future<void> setLocale(String locale) async {
    var newLocale = localeFromString(locale);
    bundle.locale = newLocale;
    await bundle.load();
    Get.find<LocalizationController>().setLocale(locale);
  }
}

Locale localeFromString(String arg) {
  final splitted = arg.split('_');
  var res = Locale(splitted[0], splitted[1]);
  return res;
}
