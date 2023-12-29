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
  Future<void> set(ApplicationSettings settings) async {
    Log.debug('set($settings)', '$runtimeType');
    await putSafe(0, settings);
  }

  /// Stores a new [enabled] value of [ApplicationSettings.enablePopups] to
  /// [Hive].
  Future<void> setPopupsEnabled(bool enabled) async {
    Log.debug('setPopupsEnabled($enabled)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..enablePopups = enabled,
    );
  }

  /// Stores a new [locale] value of [ApplicationSettings.locale] to [Hive].
  Future<void> setLocale(String locale) async {
    Log.debug('setLocale($locale)', '$runtimeType');
    await putSafe(0, (box.get(0) ?? ApplicationSettings())..locale = locale);
  }

  /// Stores a new [show] value of [ApplicationSettings.showIntroduction] to
  /// [Hive].
  Future<void> setShowIntroduction(bool show) async {
    Log.debug('setShowIntroduction($show)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..showIntroduction = show,
    );
  }

  /// Stores a new [width] value of [ApplicationSettings.sideBarWidth] to
  /// [Hive].
  Future<void> setSideBarWidth(double width) async {
    Log.debug('setSideBarWidth($width)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..sideBarWidth = width,
    );
  }

  /// Stores a new [buttons] value of [ApplicationSettings.callButtons] to
  /// [Hive].
  Future<void> setCallButtons(List<String> buttons) async {
    Log.debug('setCallButtons($buttons)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..callButtons = buttons,
    );
  }

  /// Stores a new [show] value of
  /// [ApplicationSettings.showDragAndDropVideosHint] to [Hive].
  Future<void> setShowDragAndDropVideosHint(bool show) async {
    Log.debug('setShowDragAndDropVideosHint($show)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..showDragAndDropVideosHint = show,
    );
  }

  /// Stores a new [show] value of
  /// [ApplicationSettings.showDragAndDropButtonsHint] to [Hive].
  Future<void> setShowDragAndDropButtonsHint(bool show) async {
    Log.debug('setShowDragAndDropButtonsHint($show)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..showDragAndDropButtonsHint = show,
    );
  }

  /// Stores a new [enabled] value of [ApplicationSettings.loadImages]
  /// to [Hive].
  Future<void> setLoadImages(bool enabled) async {
    Log.debug('setLoadImages($enabled)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..loadImages = enabled,
    );
  }

  /// Stores a new [enabled] value of [ApplicationSettings.timelineEnabled]
  /// to [Hive].
  Future<void> setTimelineEnabled(bool enabled) async {
    Log.debug('setTimelineEnabled($enabled)', '$runtimeType');

    await putSafe(
      0,
      (box.get(0) ?? ApplicationSettings())..timelineEnabled = enabled,
    );
  }

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
}
