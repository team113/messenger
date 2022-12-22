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
import 'chat.dart';

part 'application_settings.g.dart';

/// Overall application settings used by the whole app.
@HiveType(typeId: ModelTypeId.applicationSettings)
class ApplicationSettings extends HiveObject {
  ApplicationSettings({
    this.enablePopups,
    this.locale,
    this.showIntroduction,
    this.sideBarWidth,
    this.sortContactsByName = true,
    this.callButtons = const [],
  });

  /// Indicator whether [OngoingCall]s are preferred to be displayed in the
  /// separate popup windows, or otherwise inside the main application.
  @HiveField(0)
  bool? enablePopups;

  /// Preferred language to use in the application.
  @HiveField(1)
  String? locale;

  /// Indicator whether an [IntroductionView] should be displayed upon opening
  /// the application.
  @HiveField(2)
  bool? showIntroduction;

  /// Width of the [HomeView]'s side bar.
  @HiveField(3)
  double? sideBarWidth;

  /// [CallButton]s placed in a [Dock] of an [OngoingCall].
  @HiveField(4)
  List<String> callButtons;

  /// Indicator whether a drag and drop videos hint should be displayed in an
  /// [OngoingCall].
  @HiveField(5)
  bool? showDragAndDropVideosHint;

  /// Indicator whether a drag and drop buttons hint should be displayed in an
  /// [OngoingCall].
  @HiveField(6)
  bool? showDragAndDropButtonsHint;

  /// Indicator whether [ChatContact]s should be sorted by their names.
  @HiveField(7)
  bool sortContactsByName;

  /// [Map] of [CallPreferences].
  @HiveField(8)
  Map<ChatId, CallPreferences> callsPreferences = {};
}

/// Preferences of a call containing its [width], [height] and position.
@HiveType(typeId: ModelTypeId.callPreferences)
class CallPreferences {
  CallPreferences({this.width, this.height, this.left, this.top});

  /// Width of the call these [CallPreferences] are about.
  @HiveField(0)
  double? width;

  /// Height of the call these [CallPreferences] are about.
  @HiveField(1)
  double? height;

  /// Left position of the call these [CallPreferences] are about.
  @HiveField(2)
  double? left;

  /// Top position of the call these [CallPreferences] are about.
  @HiveField(3)
  double? top;

  /// Constructs a [CallPreferences] from the provided [data].
  factory CallPreferences.fromJson(Map<dynamic, dynamic> data) {
    return CallPreferences(
      width: data['width'],
      height: data['height'],
      left: data['left'],
      top: data['top'],
    );
  }

  /// Returns a [Map] containing data of these [CallPreferences].
  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height, 'left': left, 'top': top};
  }
}
