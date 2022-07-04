import 'dart:async';

import 'package:devicelocale/devicelocale.dart';
import 'package:fluent/fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/util/platform_utils.dart';

class FluentLocalization {
  String locale;
  final FluentBundle bundle;

  FluentLocalization(this.locale) : bundle = FluentBundle(locale);

  static FluentLocalization? of(BuildContext context) {
    return Localizations.of<FluentLocalization>(context, FluentLocalization);
  }

  Future load() async {
    bundle.messages.clear();
    bundle.addMessages(await rootBundle
        .loadString('assets/translates/$locale.ftl'.toLowerCase()));
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
  static late Rx<String> chosen;

  static late Rx<String> authPageLocale;

  static ApplicationSettingsHiveProvider? _settingsProvider;

  static StreamIterator? _localSubscription;

  static StreamSubscription? _authSubscription;

  static UserId? _subscribedUserId;

  static Future<void> setAuthPageLocale(String newLocale) async {
    bundle.locale = newLocale;
    await bundle.load();
    authPageLocale.value = newLocale;
    await Get.forceAppUpdate();
  }

  static Future<void> setUserLocale(String newLocale) async {
    await _settingsProvider?.setLocale(newLocale);
  }

  /// Initializes dependencies for fluent localization and loads localization;
  static Future<void> init({AuthService? auth}) async {
    authPageLocale = Rx(await getDeviceLocale());
    String? userLocale;
    if (auth != null && auth.status.value.isSuccess) {
      _settingsProvider = ApplicationSettingsHiveProvider();
      await _settingsProvider!.init(userId: auth.userId);
      userLocale = _settingsProvider!.settings?.locale ?? authPageLocale.value;
    }
    bundle = FluentLocalization(userLocale ?? authPageLocale.value);
    await bundle.load();
    chosen = Rx(userLocale ?? authPageLocale.value);
    chosen.refresh();
    _authSubscription ??= auth?.status.listen((p0) async {
      if (p0.isSuccess && auth.userId != _subscribedUserId) {
        _subscribedUserId = auth.userId;
        _settingsProvider = ApplicationSettingsHiveProvider();
        await _settingsProvider!.init(userId: auth.userId);

        if ((_settingsProvider?.settings?.locale != null) &&
            (_settingsProvider?.settings?.locale !=
                (userLocale ?? authPageLocale.value))) {
          userLocale = _settingsProvider!.settings!.locale!;
          bundle.locale = userLocale!;
          await bundle.load();
          chosen.value = userLocale!;
          chosen.refresh();
          await Get.forceAppUpdate();
        }
        _initLocalSubscription();
      } else if (p0.isEmpty) {
        await _localSubscription?.cancel();
        _settingsProvider = null;
        _localSubscription = null;
        _subscribedUserId = null;
        bundle.locale = authPageLocale.value;
        await bundle.load();
        await Get.forceAppUpdate();
      }
    });
  }

  static void _initLocalSubscription() async {
    _localSubscription = StreamIterator(_settingsProvider!.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      if (!event.deleted) {
        chosen.value = event.value?.locale ?? authPageLocale;
        bundle.locale = chosen.value;
        await bundle.load();
        chosen.refresh();
        await Get.forceAppUpdate();
      }
    }
  }
}

Locale localeFromString(String arg) {
  final splitted = arg.split('_');
  var res = Locale(splitted[0], splitted[1]);
  return res;
}

Future<String> getDeviceLocale() async {
  if (PlatformUtils.isMobile || PlatformUtils.isLinux || PlatformUtils.isWeb) {
    return (await Devicelocale.currentLocale)?.replaceFirst('-', '_') ??
        LocalizationUtils.locales.keys.first;
  }
  return LocalizationUtils.locales.keys.first;
}
