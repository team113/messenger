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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';

part 'application_settings.g.dart';

/// Overall application settings used by the whole app.
@HiveType(typeId: ModelTypeId.applicationSettings)
class ApplicationSettings extends HiveObject {
  ApplicationSettings({
    this.enablePopups,
    this.locale,
    this.showIntroduction,
    this.sideBarWidth,
    this.callButtons = const [],
    this.showDragAndDropVideosHint = false,
    this.showDragAndDropButtonsHint = false,
    this.pinnedActions = const [],
    this.callButtonsPosition = CallButtonsPosition.appBar,
    this.workWithUsTabEnabled = true,
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

  /// [ChatButton]s pinned to the [MessageFieldView] in [Chat].
  @HiveField(7)
  List<String> pinnedActions;

  /// [CallButtonsPosition] of the call buttons in [Chat].
  @HiveField(8)
  CallButtonsPosition? callButtonsPosition;

  /// Indicator whether [WorkTabView] should be displayed in the
  /// [CustomNavigationBar] of [HomeView].
  @HiveField(9)
  bool workWithUsTabEnabled;
}

/// Possible call buttons position.
@HiveType(typeId: ModelTypeId.callButtonsPosition)
enum CallButtonsPosition {
  /// [AppBar] position.
  @HiveField(0)
  appBar,

  /// [ContextMenu] position.
  @HiveField(1)
  contextMenu,

  /// Top position in [ChatView] body.
  @HiveField(2)
  top,

  /// Bottom position in [ChatView] body.
  @HiveField(3)
  bottom,

  /// [ChatMoreWidget] button position.
  @HiveField(4)
  more,
}
