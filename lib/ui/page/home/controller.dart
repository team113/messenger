// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/application_settings.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/ui/page/home/introduction/view.dart';
import '/ui/worker/upgrade.dart';
import '/util/message_popup.dart';
import 'introduction/controller.dart';

export 'view.dart';

/// [Routes.home] page controller.
class HomeController extends GetxController {
  HomeController(
    this._auth,
    this._myUserService,
    this._settings,
    this._upgradeWorker, {
    this.signedUp = false,
    this.link,
    this.context,
  });

  /// Indicator whether the [IntroductionView] should be displayed with
  /// [IntroductionViewStage.signUp] initial stage.
  final bool signedUp;

  /// Maximal percentage of the screen's width which side bar can occupy.
  static const double sideBarMaxWidthPercentage = 0.5;

  /// Minimal width of the side bar.
  static const double sideBarMinWidth = 250;

  /// Current width of the side bar.
  late final RxDouble sideBarWidth;

  /// Controller of the [PageView] tab.
  late PageController pages;

  /// Current [pages] [HomeTab] value.
  late final Rx<HomeTab> page;

  /// Reactive [MyUser.unreadChatsCount] value.
  final RxInt unreadChats = RxInt(0);

  /// [GlobalKey] of a [Chat]s button in the navigation bar.
  final GlobalKey chatsKey = GlobalKey();

  /// [GlobalKey] of a [CustomNavigationBar] displayed.
  ///
  /// Used to position a status changing [Selector] properly.
  final GlobalKey panelKey = GlobalKey();

  /// [ChatDirectLinkSlug] to display [IntroductionView] with.
  final ChatDirectLinkSlug? link;

  /// [BuildContext] of the [HomeView].
  final BuildContext? context;

  /// Balance of [MyUser] to display in [HomeTab.wallet].
  final RxDouble purse = RxDouble(0);

  /// Balance of [MyUser] to display in [HomeTab.partner].
  final RxDouble income = RxDouble(0);

  /// Authentication service to determine auth status.
  final AuthService _auth;

  /// [MyUserService] to listen to the [MyUser] changes.
  final MyUserService _myUserService;

  /// [AbstractSettingsRepository] containing the [ApplicationSettings] used to
  /// determine whether an [IntroductionView] was already shown.
  final AbstractSettingsRepository _settings;

  /// [UpgradeWorker] for displaying the [UpgradeWorker.scheduled].
  final UpgradeWorker _upgradeWorker;

  /// Subscription to the [MyUser] changes.
  late final StreamSubscription _myUserSubscription;

  /// Returns user authentication status.
  Rx<RxStatus> get authStatus => _auth.status;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the width side bar is allowed to occupy.
  double get sideBarAllowedWidth =>
      _settings.applicationSettings.value?.sideBarWidth ?? 350;

  /// Returns the background's [Uint8List].
  Rx<Uint8List?> get background => _settings.background;

  /// Returns the current [ApplicationSettings] value.
  Rx<ApplicationSettings?> get settings => _settings.applicationSettings;

  /// Returns the [List] of the [HomeTab]s to display.
  List<HomeTab> get tabs {
    final List<HomeTab> tabs = HomeTab.values.toList();
    return tabs;
  }

  /// Returns the latest [Release] being scheduled to be displayed.
  Rx<Release?> get scheduled => _upgradeWorker.scheduled;

  /// Returns the [ReleaseDownload] being active, if any.
  Rx<ReleaseDownload?> get activeDownload => _upgradeWorker.activeDownload;

  @override
  void onInit() {
    super.onInit();
    page = Rx<HomeTab>(router.tab);
    pages = PageController(initialPage: page.value.index, keepPage: true);

    unreadChats.value = _myUserService.myUser.value?.unreadChatsCount ?? 0;
    _myUserSubscription = _myUserService.myUser.listen(
      (u) => unreadChats.value = u?.unreadChatsCount ?? unreadChats.value,
    );

    sideBarWidth = RxDouble(
      _settings.applicationSettings.value?.sideBarWidth ?? 350,
    );

    router.addListener(_onRouterChanged);
  }

  @override
  void onReady() {
    super.onReady();
    pages.jumpToPage(router.tab.index);
    refresh();

    if (_settings.applicationSettings.value?.showIntroduction ?? true) {
      if (_myUserService.myUser.value != null) {
        _displayIntroduction(_myUserService.myUser.value!);
      } else {
        Worker? worker;
        worker = ever(_myUserService.myUser, (MyUser? myUser) {
          if (myUser != null && worker != null) {
            _displayIntroduction(myUser);
            worker?.dispose();
            worker = null;
          }
        });
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    router.removeListener(_onRouterChanged);
    _myUserSubscription.cancel();
  }

  /// Returns corrected according to the side bar constraints [width] value.
  double applySideBarWidth(BuildContext context, double width) {
    double maxWidth = context.width * sideBarMaxWidthPercentage;

    if (maxWidth < sideBarMinWidth) {
      maxWidth = sideBarMinWidth;
    }

    return width.clamp(sideBarMinWidth, maxWidth);
  }

  /// Sets the current [sideBarWidth] as the [sideBarAllowedWidth].
  Future<void> setSideBarWidth() =>
      _settings.setSideBarWidth(sideBarWidth.value);

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);

  /// Toggles the [MyUser.muted] status.
  Future<void> toggleMute(bool enabled) async {
    try {
      await _myUserService.toggleMute(enabled ? null : MuteDuration.forever());
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Refreshes the [MyUser] to be up to date.
  Future<void> updateAvatar() async {
    await _myUserService.refresh();
  }

  /// Refreshes the controller on [router] change.
  ///
  /// Required in order for the [BottomNavigatorBar] to rebuild.
  void _onRouterChanged() {
    if (pages.hasClients) {
      if (pages.page?.round() != router.tab.index) {
        pages.jumpToPage(router.tab.index);
      }
      refresh();
    }
  }

  /// Displays an [IntroductionView] if [MyUser.hasPassword] is `false`.
  void _displayIntroduction(MyUser myUser) {
    IntroductionViewStage? stage;

    if (link != null) {
      stage = IntroductionViewStage.link;
    } else if (signedUp) {
      stage = IntroductionViewStage.signUp;
    } else if (!myUser.hasPassword &&
        myUser.emails.confirmed.isEmpty &&
        myUser.phones.confirmed.isEmpty) {
      stage = IntroductionViewStage.oneTime;
    }

    if (stage != null) {
      IntroductionView.show(
        context ?? router.context!,
        initial: stage,
      ).then((_) => _settings.setShowIntroduction(false));
    } else {
      _settings.setShowIntroduction(false);
    }
  }
}
