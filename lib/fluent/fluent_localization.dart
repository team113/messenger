import 'dart:async';

import 'package:devicelocale/devicelocale.dart';
import 'package:fluent/fluent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/provider/hive/application_settings.dart';
import '/util/platform_utils.dart';

/// Class that provides [FluentBundle] functionality.
class FluentLocalization {
  /// [FluentBundle] class that provides functionality of translating values.
  final FluentBundle bundle;

  FluentLocalization(String locale) : bundle = FluentBundle(locale);

  /// Loads provided [locale] to the [bundle].
  Future load({String? newLocale}) async {
    bundle.messages.clear();
    bundle.addMessages(await rootBundle.loadString(
        'assets/translates/${newLocale ?? bundle.locale}.ftl'.toLowerCase()));
  }

  /// Returns translated value due to loaded [bundle] locale.
  String getTranslatedValue(String key,
      {Map<String, dynamic> args = const {}}) {
    return bundle.format(key, args: args);
  }
}

/// Custom Fluent localization delegate.
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
    return LocalizationUtils.localization == null
        ? FluentLocalization('')
        : LocalizationUtils.localization!;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<FluentLocalization> old) =>
      false;
}

/// Class that provides functionality of manipulating of language inside app.
/// Needs to call [init] before other operations.
abstract class LocalizationUtils {
  /// Class that is responsible for localization itself.
  static FluentLocalization? localization;

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

  /// Currently selected [MyUser]'s locale.
  static late Rx<String> chosen;

  /// Locale that is present on auth page.
  static Rx<String?> authPageLocale = Rx(null);

  /// Used for loading localization due to [MyUser].
  static ApplicationSettingsHiveProvider? _settingsProvider;

  /// [ApplicationSettingsHiveProvider.boxEvents] subscription.
  static StreamIterator? _localSubscription;

  /// [StreamSubscription] for [AuthService] auth status.
  static StreamSubscription? _authStatusSubscription;

  /// [User]'s id that is subscribed for auth status changes.
  static UserId? _subscribedUserId;

  /// Sets [authPageLocale].
  static Future<void> setAuthPageLocale(String newLocale) async {
    await localization?.load(newLocale: newLocale);
    authPageLocale.value = newLocale;
    await Get.forceAppUpdate();
  }

  /// Sets selected [User]'s locale to the [Hive] storage.
  static Future<void> setUsersLocale(String newLocale) async {
    await _settingsProvider?.setLocale(newLocale);
  }

  /// Initializes dependencies for fluent localization and loads localization.
  static Future<void> init({AuthService? auth}) async {
    authPageLocale.value = await getDeviceLocale();
    String? userLocale;
    if (auth != null && auth.status.value.isSuccess) {
      _settingsProvider = ApplicationSettingsHiveProvider();
      await _settingsProvider!.init(userId: auth.userId);
      userLocale = _settingsProvider!.settings?.locale;
    }
    localization = FluentLocalization(userLocale ?? authPageLocale.value!);
    await localization?.load();
    chosen = Rx(userLocale ?? authPageLocale.value!);
    chosen.refresh();
    if (userLocale == null) {
      await setUsersLocale(authPageLocale.value!);
    }
    if (auth?.status.value.isSuccess ?? false) {
      _initLocalSubscription();
    }
    _authStatusSubscription ??= auth?.status.listen((p0) async {
      if (p0.isSuccess && auth.userId != _subscribedUserId) {
        _subscribedUserId = auth.userId;
        _settingsProvider = ApplicationSettingsHiveProvider();
        await _settingsProvider!.init(userId: auth.userId);

        if ((_settingsProvider?.settings?.locale !=
            (userLocale ?? authPageLocale.value))) {
          userLocale = _settingsProvider?.settings?.locale;
          await localization?.load(
              newLocale: userLocale ?? authPageLocale.value);
          chosen.value = userLocale ?? authPageLocale.value!;
          chosen.refresh();
          if (userLocale == null) {
            await setUsersLocale(authPageLocale.value!);
          }
          await Get.forceAppUpdate();
        }
        _initLocalSubscription();
      } else if (p0.isEmpty) {
        await _localSubscription?.cancel();
        authPageLocale.value = await getDeviceLocale();
        _settingsProvider = null;
        _localSubscription = null;
        _subscribedUserId = null;
        await localization?.load(newLocale: authPageLocale.value);
        await Get.forceAppUpdate();
      }
    });
  }

  /// Initializes [ApplicationSettingsHiveProvider.boxEvents] subscription.
  static void _initLocalSubscription() async {
    _localSubscription = StreamIterator(_settingsProvider!.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      if (!event.deleted && chosen.value != event.value?.locale) {
        chosen.value = event.value?.locale ?? authPageLocale;
        await localization?.load(newLocale: chosen.value);
        chosen.refresh();
        await Get.forceAppUpdate();
      }
    }
  }
}

/// Returns current device locale or default locale.
Future<String> getDeviceLocale() async {
  if (PlatformUtils.isMobile || PlatformUtils.isLinux || PlatformUtils.isWeb) {
    return (await Devicelocale.currentLocale)?.replaceFirst('-', '_') ??
        LocalizationUtils.locales.keys.first;
  }
  return LocalizationUtils.locales.keys.first;
}
