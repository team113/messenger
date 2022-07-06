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

part 'application_settings.g.dart';

/// Overall application settings used by the whole app.
@HiveType(typeId: ModelTypeId.applicationSettings)
class ApplicationSettings extends HiveObject {
  ApplicationSettings({this.enablePopups});

  /// Indicator whether [OngoingCall]s are preferred to be displayed in the
  /// separate popup windows, or otherwise inside the main application.
  @HiveField(0)
  bool? enablePopups;

  /// Preferred [MyUser]'s language of the application.
  @HiveField(1)
  String? locale;
}
