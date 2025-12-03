// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '/routes.dart';
import '/util/platform_utils.dart';

/// Localization of this application.
class L10n {
  /// Currently selected [Language].
  static final Rx<Language?> chosen = Rx(null);

  /// Supported [Language]s.
  ///
  /// First [Language] in the list is guaranteed to be English.
  static List<Language> languages = const [
    Language('English', Locale('en', 'US')),
    Language('Español', Locale('es', 'ES')),
    Language('Русский', Locale('ru', 'RU')),
  ];

  /// [FluentBundle] providing translation.
  static FluentBundle _bundle = FluentBundle('');

  /// Initializes this [L10n] with the default [Locale] of the device, or
  /// optionally with the provided [Language].
  static Future<void> init([Language? lang]) async {
    await initializeDateFormatting();

    if (lang == null) {
      final Language? language = Language.fromLocale(
        basicLocaleListResolution(
          WidgetsBinding.instance.platformDispatcher.locales,
          L10n.languages.map((e) => e.locale),
        ),
      );

      if (language != null) {
        await set(language, refresh: false);
      }
    } else {
      await set(lang, refresh: false);
    }

    if (chosen.value == null) {
      await set(languages.first, refresh: false);
    }
  }

  /// Sets the [chosen] language to the provided [Language].
  static Future<void> set(Language? lang, {bool refresh = true}) async {
    if (lang == chosen.value || lang == null) {
      return;
    }

    if (languages.contains(lang)) {
      Intl.defaultLocale = lang.locale.toString();
      chosen.value = lang;

      _bundle = FluentBundle(lang.toString())
        ..addMessages(await PlatformUtils.loadString('assets/l10n/$lang.ftl'));
      if (refresh) {
        await Get.forceAppUpdate();
      }
    } else {
      throw ArgumentError.value(lang);
    }
  }

  /// Returns the translated value of the provided [key] from the [_bundle].
  static String _format(String key, {Map<String, dynamic> args = const {}}) =>
      _bundle.format(key, args: args) ?? key;
}

/// Language entity along with its [Locale].
class Language {
  const Language(this.name, this.locale);

  /// Localized local name of this [Language].
  final String name;

  /// [Locale] of this [Language].
  final Locale locale;

  /// Returns a [Language] identified by its [tag] from the [L10n.languages], if
  /// any.
  static Language? fromTag(String? tag) {
    return L10n.languages.firstWhereOrNull((e) => e.toString() == tag);
  }

  /// Returns a [Language] from the [L10n.languages] matching the provided
  /// [locale], if any.
  static Language? fromLocale(Locale locale) {
    return L10n.languages.firstWhereOrNull((e) => e.locale == locale);
  }

  @override
  String toString() => locale.toLanguageTag();
}

/// Extension adding an ability to get a translated [String] in the current
/// [L10n].
extension L10nExtension on String {
  /// Returns a value identified by this [String] from the current [L10n].
  String get l10n => L10n._format(this);

  /// Returns a value identified by this [String] from the current [L10n] with
  /// the provided [args].
  String l10nfmt(Map<String, dynamic> args) => L10n._format(this, args: args);
}

/// Extension adding an ability to get [DateTime] formatted according to [L10n].
extension L10nDateExtension on DateTime {
  /// Returns this [DateTime] formatted in `Hm` format.
  String get hm => DateFormat.Hm().format(this);

  /// Returns this [DateTime] formatted in `Hms` format.
  String get hms => DateFormat.Hms().format(this);

  /// Returns this [DateTime] formatted in `yMd` format.
  String get yMd => DateFormat.yMd().format(this);

  // TODO: Shouldn't do replacements here.
  /// Returns this [DateTime] formatted in `yyMd` format.
  String get yyMd => DateFormat.yMd()
      .format(this)
      .replaceFirst(
        DateTime.now().year.toString(),
        DateFormat('yy').format(this),
      );

  /// Returns this [DateTime] formatted as short weekday name.
  String get e => DateFormat.E().format(this);

  /// Returns this [DateTime] formatted in `yMdHm` format.
  String get yMdHm => '$yMd${'space'.l10n}$hm';

  /// Returns this [DateTime] formatted in `HmyMd` format.
  String get hmyMd => '$hm${'space'.l10n}$yMd';

  /// Returns short text representing this [DateTime].
  ///
  /// Returns string in format `Hm`, if [DateTime] is within today. Returns a
  /// short weekday name, if [difference] between this [DateTime] and
  /// [DateTime.now] is less than 7 days. Otherwise returns a string in `yMdHm`
  /// format.
  String get short {
    final DateTime now = DateTime.now();
    final DateTime from = DateTime(now.year, now.month, now.day);
    final DateTime to = DateTime(year, month, day);

    final int differenceInDays = from.difference(to).inDays;

    if (differenceInDays > 6) {
      return yMd;
    } else if (differenceInDays < 1) {
      return hm;
    } else {
      return 'label_days_short'.l10nfmt({'days': differenceInDays});
    }
  }

  /// Returns relative to [now] text representation.
  ///
  /// [DateTime.now] is used if [now] is `null`.
  String toRelative([DateTime? now]) {
    DateTime local = isUtc ? toLocal() : this;
    DateTime relative = now ?? DateTime.now();
    int days = relative._julianDayNumber() - local._julianDayNumber();

    int months = 0;
    if (days >= 28) {
      months =
          relative.month + relative.year * 12 - local.month - local.year * 12;
      if (relative.day < local.day) {
        months--;
      }
    }

    if (days > 6) {
      return yMd;
    }

    return 'label_ago_date'.l10nfmt({
      'years': months ~/ 12,
      'months': months,
      'weeks': days ~/ 7,
      'days': days,
    });
  }

  /// Returns a Julian day number of this [DateTime].
  int _julianDayNumber() {
    final int c0 = ((month - 3) / 12).floor();
    final int x4 = year + c0;
    final int x3 = (x4 / 100).floor();
    final int x2 = x4 % 100;
    final int x1 = month - (12 * c0) - 3;
    return ((146097 * x3) / 4).floor() +
        ((36525 * x2) / 100).floor() +
        (((153 * x1) + 2) / 5).floor() +
        day +
        1721119;
  }
}

/// Extension adding an ability to get [Duration] formatted according to [L10n].
extension L10nDurationExtension on Duration {
  /// Returns a string representation of this [Duration] in `HH:MM:SS` format.
  ///
  /// `HH` part is omitted if this [Duration] is less than an one hour.
  String hhMmSs() {
    var microseconds = inMicroseconds;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);
    var hoursPadding = hours < 10 ? '0' : '';

    if (microseconds < 0) microseconds = -microseconds;

    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);
    var minutesPadding = minutes < 10 ? '0' : '';

    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);
    var secondsPadding = seconds < 10 ? '0' : '';

    if (hours == 0) {
      return '$minutesPadding$minutes:$secondsPadding$seconds';
    }

    return '$hoursPadding$hours:$minutesPadding$minutes:$secondsPadding$seconds';
  }

  /// Returns localized string representing this [Duration] in
  /// `HH h, MM m, SS s` format.
  ///
  /// `MM` part is omitted if this [Duration] is less than an one minute.
  /// `HH` part is omitted if this [Duration] is less than an one hour.
  String localizedString() {
    var microseconds = inMicroseconds;

    if (microseconds < 0) microseconds = -microseconds;

    var hours = microseconds ~/ Duration.microsecondsPerHour;
    microseconds = microseconds.remainder(Duration.microsecondsPerHour);

    var minutes = microseconds ~/ Duration.microsecondsPerMinute;
    microseconds = microseconds.remainder(Duration.microsecondsPerMinute);

    var seconds = microseconds ~/ Duration.microsecondsPerSecond;
    microseconds = microseconds.remainder(Duration.microsecondsPerSecond);

    String result = '$seconds ${'label_duration_second_short'.l10n}';

    if (minutes != 0) {
      result = '$minutes ${'label_duration_minute_short'.l10n} $result';
    }

    if (hours != 0) {
      result = '$hours ${'label_duration_hour_short'.l10n} $result';
    }

    return result;
  }
}

/// Extension adding an ability to get [ProfileTab] localized title.
extension L10nProfileTabExtension on ProfileTab {
  /// Returns localized title of this [ProfileTab].
  String get l10n {
    return switch (this) {
      ProfileTab.public => 'label_profile'.l10n,
      ProfileTab.signing => 'label_login_options'.l10n,
      ProfileTab.link => 'label_link_to_chat'.l10n,
      ProfileTab.interface => 'label_interface'.l10n,
      ProfileTab.media => 'label_media_devices'.l10n,
      ProfileTab.welcome => 'label_welcome_message'.l10n,
      ProfileTab.notifications => 'label_notifications'.l10n,
      ProfileTab.storage => 'label_storage'.l10n,
      ProfileTab.confidential => 'label_confidentiality'.l10n,
      ProfileTab.devices => 'label_linked_devices'.l10n,
      ProfileTab.download => 'label_download_and_update'.l10n,
      ProfileTab.danger => 'btn_delete_account'.l10n,
      ProfileTab.legal => 'label_terms_and_privacy_policy'.l10n,
      ProfileTab.logout => 'btn_logout'.l10n,
    };
  }
}

/// Extension adding [int] formatting as a human-readable localized bytes.
extension L10nSizeInBytesExtension on int? {
  /// Returns bytes formatted into a human-readable, localized string.
  ///
  /// ```dart
  /// print(null.asBytes()); // ...
  /// print(0.asBytes()); // 0 B
  /// print(10.asBytes()); // 10 B
  /// print(1024.asBytes()); // 1 KB
  /// print((1024 + 50).asBytes()); // 1 KB
  /// print((1024 + 100).asBytes()); // 1.1 KB
  /// ```
  String asBytes() {
    final bytes = this;

    if (bytes == null) {
      return 'dot'.l10n * 3;
    }

    /// Precision to use in [toStringAsFixed] method.
    const precision = 1;

    // Define as `const`s instead of `pow()`s to decrease possible runtime CPU
    // computations.
    const kilobyte = 1024;
    const megabyte = kilobyte * 1024;
    const gigabyte = megabyte * 1024;
    const terabyte = gigabyte * 1024;
    const petabyte = terabyte * 1024;

    if (bytes < kilobyte) {
      return 'label_b'.l10nfmt({'amount': bytes.toString()});
    } else if (bytes < megabyte) {
      return 'label_kb'.l10nfmt({
        'amount': (bytes / kilobyte).toStringAsFixed(precision),
      });
    } else if (bytes < gigabyte) {
      return 'label_mb'.l10nfmt({
        'amount': (bytes / megabyte).toStringAsFixed(precision),
      });
    } else if (bytes < terabyte) {
      return 'label_gb'.l10nfmt({
        'amount': (bytes / gigabyte).toStringAsFixed(precision),
      });
    } else if (bytes < petabyte) {
      return 'label_tb'.l10nfmt({
        'amount': (bytes / terabyte).toStringAsFixed(precision),
      });
    }

    return 'label_pb'.l10nfmt({
      'amount': (bytes / petabyte).toStringAsFixed(precision),
    });
  }
}

/// Extension capitalizing the first letter of the [String].
extension CapitalizedString on String {
  /// Returns this [String] with its first letter capitalized.
  String get capitalized {
    if (length <= 1) {
      return substring(0).toUpperCase();
    }

    return '${substring(0, 1).toUpperCase()}${substring(1, length)}';
  }
}

/// Extension adding method converting a [num] to a [String] with digits spaced.
extension SpacesNumExtension on num {
  /// Returns this [num] parsed with spaces between thousands.
  String get withSpaces {
    if (this is double) {
      return toStringAsFixed(2);
    }

    String value = toString();

    int len = value.length;
    int thousand = 3;

    while (len > thousand) {
      value =
          '${value.substring(0, len - thousand)} ${value.substring(len - thousand, value.length)}';
      thousand += 4;
      len += 1;
    }

    return value;
  }
}
