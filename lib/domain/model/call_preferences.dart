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

import 'package:hive/hive.dart';

import '../model_type_id.dart';

part 'call_preferences.g.dart';

/// Preferences of a call containing its in app and popup [CallPreference]s.
@HiveType(typeId: ModelTypeId.callPreferences)
class CallPreferences extends HiveObject {
  CallPreferences({this.inAppPrefs, this.popupPrefs});

  /// In app [CallPreference]s.
  @HiveField(0)
  CallPreference? inAppPrefs;

  /// Popup [CallPreference]s.
  @HiveField(1)
  CallPreference? popupPrefs;
}

/// Preferences of a call containing its [width], [height] and position.
@HiveType(typeId: ModelTypeId.callPreference)
class CallPreference extends HiveObject {
  CallPreference({this.width, this.height, this.left, this.top});

  /// Width of the call these [CallPreference] are about.
  @HiveField(0)
  double? width;

  /// Height of the call these [CallPreference] are about.
  @HiveField(1)
  double? height;

  /// Left position of the call these [CallPreference] are about.
  @HiveField(2)
  double? left;

  /// Top position of the call these [CallPreference] are about.
  @HiveField(3)
  double? top;

  /// Constructs a [CallPreference] from the provided [data].
  factory CallPreference.fromJson(Map<dynamic, dynamic> data) => CallPreference(
        width: data['width'],
        height: data['height'],
        left: data['left'],
        top: data['top'],
      );

  /// Returns a [Map] containing data of these [CallPreference].
  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'left': left,
        'top': top,
      };
}
