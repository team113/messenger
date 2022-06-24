import 'package:fluent/fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FluentLocalization {
  final Locale locale;
  final FluentBundle bundle;

  FluentLocalization(this.locale) : bundle = FluentBundle(locale.toString());

  static FluentLocalization? of(BuildContext context) {
    return Localizations.of<FluentLocalization>(context, FluentLocalization);
  }

  Future load() async {
    bundle.addMessages(await rootBundle.loadString(
        'assets/translates/${locale.toString()}.ftl'.toLowerCase()));
    bundle.messages.forEach((key, value) {});
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
    return LocalizationsConstants.supportedLocales.contains(locale);
  }

  @override
  Future<FluentLocalization> load(Locale locale) async {
    FluentLocalization localization = FluentLocalization(locale);
    await localization.load();
    return localization;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalization> old) =>
      false;
}

class LocalizationsConstants {
  static List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    FluentLocalization.delegate,
  ];
  static List<Locale> supportedLocales = [
    const Locale('en', 'US'),
    const Locale('ru', 'RU')
  ];
}
