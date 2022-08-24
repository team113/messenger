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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';

/// Controller of the [Routes.settings] page.
class SettingsController extends GetxController {
  SettingsController(this._settingsRepo);

  /// [GlobalKey] of a button opening the [Language] selection.
  final GlobalKey languageKey = GlobalKey();

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settingsRepo.applicationSettings;

  /// Sets the [ApplicationSettings.enablePopups] value.
  Future<void> setPopupsEnabled(bool enabled) =>
      _settingsRepo.setPopupsEnabled(enabled);

  /// Sets the [ApplicationSettings.locale] value.
  Future<void> setLocale(Language? locale) =>
      _settingsRepo.setLocale(locale!.toString());

  final FlutterListViewController controller = FlutterListViewController();

  final RxInt selected = RxInt(0);

  final List<Recent> recent = [
    const Recent('A'),
    const Recent('B'),
    const Recent('C'),
    const Recent('D'),
    const Recent('E'),
    const Recent('F'),
  ];

  final List<Contact> contacts = [
    const Contact('A'),
    const Contact('B'),
    const Contact('C'),
    const Contact('D'),
    const Contact('E'),
    const Contact('F'),
  ];

  final List<User> users = [
    const User('A'),
    const User('B'),
    const User('C'),
    const User('D'),
    const User('E'),
    const User('F'),
  ];

  @override
  void onInit() {
    controller.sliverController.onPaintItemPositionsCallback = (d, list) {
      int? first = list.firstOrNull?.index;

      if (first != null) {
        if (first >= recent.length + contacts.length) {
          selected.value = 2;
        } else if (first >= recent.length) {
          selected.value = 1;
        } else {
          selected.value = 0;
        }
      }
    };
    super.onInit();
  }

  void scrollTo(List<dynamic> list) {
    if (list == recent) {
      controller.sliverController.jumpToIndex(0);
    } else if (list == contacts) {
      controller.sliverController.jumpToIndex(recent.length);
    } else if (list == users) {
      controller.sliverController.jumpToIndex(contacts.length + recent.length);
    }
  }
}

class Recent {
  const Recent(this.name);
  final String name;
}

class User {
  const User(this.name);
  final String name;
}

class Contact {
  const Contact(this.name);
  final String name;
}
