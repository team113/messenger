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

import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

import '/store/model/window_preferences.dart';
import 'base.dart';

/// [Hive] storage for a [WindowPreferences].
class WindowPreferencesHiveProvider
    extends HiveBaseProvider<WindowPreferences> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'window_preferences_data';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(WindowPreferencesAdapter());
  }

  /// Returns the stored [WindowPreferences] from [Hive].
  WindowPreferences? getWindowPreferences() => getSafe(0);

  /// Stores a new [WindowPreferences] to [Hive].
  void setWindowPreferences({Size? size, Offset? position}) {
    WindowPreferences? prefs = getSafe(0);
    putSafe(
      0,
      WindowPreferences(
        width: size?.width ?? prefs?.width,
        height: size?.height ?? prefs?.height,
        dx: position?.dx ?? prefs?.dx,
        dy: position?.dy ?? prefs?.dy,
      ),
    );
  }
}
