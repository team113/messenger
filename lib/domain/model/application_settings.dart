// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

/// Overall application settings used by the whole app.
class ApplicationSettings {
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
    this.muteKeys,
  });

  /// Indicator whether [OngoingCall]s are preferred to be displayed in the
  /// separate popup windows, or otherwise inside the main application.
  bool? enablePopups;

  /// Preferred language to use in the application.
  String? locale;

  /// Indicator whether an [IntroductionView] should be displayed upon opening
  /// the application.
  bool? showIntroduction;

  /// Width of the [HomeView]'s side bar.
  double? sideBarWidth;

  /// [CallButton]s placed in a [Dock] of an [OngoingCall].
  List<String> callButtons;

  /// Indicator whether a drag and drop videos hint should be displayed in an
  /// [OngoingCall].
  bool? showDragAndDropVideosHint;

  /// Indicator whether a drag and drop buttons hint should be displayed in an
  /// [OngoingCall].
  bool? showDragAndDropButtonsHint;

  /// [ChatButton]s pinned to the [MessageFieldView] in [Chat].
  List<String> pinnedActions;

  /// [CallButtonsPosition] of the call buttons in [Chat].
  CallButtonsPosition? callButtonsPosition;

  /// Indicator whether [WorkTabView] should be displayed in the
  /// [CustomNavigationBar] of [HomeView].
  bool workWithUsTabEnabled;

  /// String representation of the [HotKey]s used to mute/unmute [OngoingCall]s.
  List<String>? muteKeys;

  @override
  bool operator ==(Object other) {
    return other is ApplicationSettings &&
        enablePopups == other.enablePopups &&
        locale == other.locale &&
        showIntroduction == other.showIntroduction &&
        sideBarWidth == other.sideBarWidth &&
        callButtons.toString() == other.callButtons.toString() &&
        showDragAndDropVideosHint == other.showDragAndDropVideosHint &&
        showDragAndDropButtonsHint == other.showDragAndDropButtonsHint &&
        pinnedActions.toString() == other.pinnedActions.toString() &&
        callButtonsPosition == other.callButtonsPosition &&
        workWithUsTabEnabled == other.workWithUsTabEnabled &&
        muteKeys?.toString() == other.muteKeys?.toString();
  }

  @override
  int get hashCode => Object.hash(
    enablePopups,
    locale,
    showIntroduction,
    sideBarWidth,
    callButtons.toString(),
    showDragAndDropVideosHint,
    showDragAndDropButtonsHint,
    pinnedActions.toString(),
    callButtonsPosition,
    workWithUsTabEnabled,
    muteKeys.toString(),
  );
}

/// Possible call buttons position.
enum CallButtonsPosition {
  /// [AppBar] position.
  appBar,

  /// [ContextMenu] position.
  contextMenu,

  /// Top position in [ChatView] body.
  top,

  /// Bottom position in [ChatView] body.
  bottom,

  /// [ChatMoreWidget] button position.
  more,
}
