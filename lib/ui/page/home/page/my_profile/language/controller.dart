// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/repository/settings.dart';
import '/l10n/l10n.dart';
import '/util/custom_scroll_controller.dart';

export 'view.dart';

/// Controller of a [LanguageSelectionView].
class LanguageSelectionController extends GetxController {
  LanguageSelectionController(this._settingsRepository);

  /// Currently selected [Language].
  late final Rx<Language?> selected;

  /// [CustomScrollController] to pass to a [Scrollbar].
  final CustomScrollController scrollController = CustomScrollController();

  /// Settings repository updating the [ApplicationSettings.locale].
  final AbstractSettingsRepository? _settingsRepository;

  @override
  void onInit() {
    selected = Rx(L10n.chosen.value);
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Sets the provided [language] to be [L10n.chosen].
  Future<void> setLocalization(Language language) async {
    await Future.wait([
      L10n.set(language),
      _settingsRepository?.setLocale(language.toString()),
    ].whereNotNull());
  }
}
