// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/application_settings.dart';
import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [ApplicationSettings].
class ApplicationSettingsHiveProvider
    extends HiveBaseProvider<ApplicationSettings> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'application_settings';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');
    Hive.maybeRegisterAdapter(ApplicationSettingsAdapter());
    Hive.maybeRegisterAdapter(CallButtonsPositionAdapter());
  }

  /// Returns the stored [ApplicationSettings] from [Hive].
  ApplicationSettings? get settings => getSafe(0);

  /// Saves the provided [ApplicationSettings] in [Hive].
  Future<void> set(ApplicationSettings settings) => putSafe(0, settings);

  /// Stores a new [enabled] value of [ApplicationSettings.enablePopups] to
  /// [Hive].
  Future<void> setPopupsEnabled(bool enabled) =>
      putSafe(0, (box.get(0) ?? ApplicationSettings())..enablePopups = enabled);

  /// Stores a new [locale] value of [ApplicationSettings.locale] to [Hive].
  Future<void> setLocale(String locale) =>
      putSafe(0, (box.get(0) ?? ApplicationSettings())..locale = locale);

  /// Stores a new [show] value of [ApplicationSettings.showIntroduction] to
  /// [Hive].
  Future<void> setShowIntroduction(bool show) => putSafe(
      0, (box.get(0) ?? ApplicationSettings())..showIntroduction = show);

  /// Stores a new [width] value of [ApplicationSettings.sideBarWidth] to
  /// [Hive].
  Future<void> setSideBarWidth(double width) =>
      putSafe(0, (box.get(0) ?? ApplicationSettings())..sideBarWidth = width);

  /// Stores a new [buttons] value of [ApplicationSettings.callButtons] to
  /// [Hive].
  Future<void> setCallButtons(List<String> buttons) =>
      putSafe(0, (box.get(0) ?? ApplicationSettings())..callButtons = buttons);

  /// Stores a new [show] value of
  /// [ApplicationSettings.showDragAndDropVideosHint] to [Hive].
  Future<void> setShowDragAndDropVideosHint(bool show) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..showDragAndDropVideosHint = show,
      );

  /// Stores a new [show] value of
  /// [ApplicationSettings.showDragAndDropButtonsHint] to [Hive].
  Future<void> setShowDragAndDropButtonsHint(bool show) async {
    // Log.debug('setShowDragAndDropButtonsHint($show)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..showDragAndDropButtonsHint = show,
    );
  }

  Future<void> setDisplayFunds(bool enabled) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..displayFunds = enabled,
      );

  Future<void> setDisplayTransactions(bool enabled) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..displayTransactions = enabled,
      );

  /// Stores a new [buttons] value of [ApplicationSettings.pinnedActions] to
  /// [Hive].
  Future<void> setPinnedActions(List<String> buttons) async {
    Log.debug('setPinnedActions($buttons)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..pinnedActions = buttons,
    );
  }

  /// Stores a new [position] value of
  /// [ApplicationSettings.callButtonsPosition] to [Hive].
  Future<void> setCallButtonsPosition(CallButtonsPosition position) async {
    Log.debug('setCallButtonsPosition($position)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..callButtonsPosition = position,
    );
  }

  /// Stores a new [enabled] value of [ApplicationSettings.workWithUsTabEnabled]
  /// to [Hive].
  Future<void> setWorkWithUsTabEnabled(bool enabled) async {
    Log.debug('setWorkWithUsTabEnabled($enabled)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..workWithUsTabEnabled = enabled,
    );
  }

  Future<void> setLeaveWhenAlone(bool enabled) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..leaveWhenAlone = enabled,
      );

  Future<void> setBalanceTabEnabled(bool enabled) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..balanceTabEnabled = enabled,
      );

  Future<void> setPublicsTabEnabled(bool enabled) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..publicsTabEnabled = enabled,
      );

  Future<void> setDisplayRates(bool enabled) => putSafe(
        0,
        (box.get(0) ?? ApplicationSettings())..displayRates = enabled,
      );
}
