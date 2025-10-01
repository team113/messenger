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
    this.pinnedActions = const [],
    this.muteKeys,
    this.videoVolume = 1,
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

  /// [ChatButton]s pinned to the [MessageFieldView] in [Chat].
  List<String> pinnedActions;

  /// String representation of the [HotKey]s used to mute/unmute [OngoingCall]s.
  List<String>? muteKeys;

  /// Volume that should be applied a video being played.
  double videoVolume;

  @override
  bool operator ==(Object other) {
    return other is ApplicationSettings &&
        enablePopups == other.enablePopups &&
        locale == other.locale &&
        showIntroduction == other.showIntroduction &&
        sideBarWidth == other.sideBarWidth &&
        callButtons.toString() == other.callButtons.toString() &&
        pinnedActions.toString() == other.pinnedActions.toString() &&
        muteKeys?.toString() == other.muteKeys?.toString() &&
        videoVolume == other.videoVolume;
  }

  @override
  int get hashCode => Object.hash(
    enablePopups,
    locale,
    showIntroduction,
    sideBarWidth,
    callButtons.toString(),
    pinnedActions.toString(),
    muteKeys.toString(),
    videoVolume,
  );
}
