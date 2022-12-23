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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';

part 'preferences.g.dart';

/// Preferences of application.
@HiveType(typeId: ModelTypeId.preferencesData)
class PreferencesData extends HiveObject {
  /// Persisted [WindowPreferences] data.
  @HiveField(0)
  WindowPreferences? windowPreferences;
}

/// Information about windows position and size.
@HiveType(typeId: ModelTypeId.windowPreferences)
class WindowPreferences {
  WindowPreferences({this.width, this.height, this.dx, this.dy});

  /// Windows width.
  @HiveField(0)
  double? width;

  /// Windows height.
  @HiveField(1)
  double? height;

  /// Windows
  @HiveField(2)
  double? dx;

  @HiveField(3)
  double? dy;
}
