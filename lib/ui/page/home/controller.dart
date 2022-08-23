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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/store/settings.dart';
import '/ui/page/home/introduction/view.dart';

export 'view.dart';

/// [Routes.home] page controller.
class HomeController extends GetxController {
  HomeController(this._auth, this._myUser, this._settings);

  /// Maximal percentage of the screen's width which side bar can occupy.
  static double sideBarMaxWidthPercentage = 0.6;

  /// Minimal width which side bar can occupy.
  static double sideBarMinWidth = 250;

  /// Width which side bar will occupy.
  Rx<double> sideBarWidth = Rx<double>(350.0);

  /// Controller of the [PageView] tab.
  late PageController pages;

  /// Current [pages] [HomeTab] value.
  late final Rx<HomeTab> page;

  /// Reactive [MyUser.unreadChatsCount] value.
  final Rx<int> unreadChatsCount = Rx<int>(0);

  /// [Timer] for discarding any horizontal movement in a [PageView] when
  /// non-`null`.
  ///
  /// Indicates currently ongoing vertical scroll of a view.
  final Rx<Timer?> verticalScrollTimer = Rx(null);

  /// Authentication service to determine auth status.
  final AuthService _auth;

  /// [MyUserService] to listen to the [MyUser] changes.
  final MyUserService _myUser;

  /// [AbstractSettingsRepository] containing the [ApplicationSettings] used to
  /// determine whether an [IntroductionView] was already shown.
  final AbstractSettingsRepository _settings;

  /// Subscription to the [MyUser] changes.
  late final StreamSubscription _myUserSubscription;

  /// Returns user authentication status.
  Rx<RxStatus> get authStatus => _auth.status;

  @override
  void onInit() {
    super.onInit();
    page = Rx<HomeTab>(router.tab);
    pages = PageController(initialPage: page.value.index, keepPage: true);

    unreadChatsCount.value = _myUser.myUser.value?.unreadChatsCount ?? 0;
    _myUserSubscription = _myUser.myUser.listen((u) =>
        unreadChatsCount.value = u?.unreadChatsCount ?? unreadChatsCount.value);

    sideBarWidth.value =
        _settings.applicationSettings.value?.sideBarWidth ?? sideBarWidth.value;

    router.addListener(_onRouterChanged);
  }

  @override
  void onReady() {
    super.onReady();
    pages.jumpToPage(router.tab.index);
    refresh();

    if (_settings.applicationSettings.value?.showIntroduction ?? true) {
      if (_myUser.myUser.value != null) {
        _displayIntroduction(_myUser.myUser.value!);
      } else {
        Worker? worker;
        worker = ever(
          _myUser.myUser,
          (MyUser? myUser) {
            if (myUser != null && worker != null) {
              _displayIntroduction(myUser);
              worker?.dispose();
              worker = null;
            }
          },
        );
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    router.removeListener(_onRouterChanged);
    _myUserSubscription.cancel();
  }

  /// Returns corrected according to side bar constraints [width] value.
  double applySideBarWidth(double width) {
    double maxWidth =
        router.context!.width * HomeController.sideBarMaxWidthPercentage;

    if (width < HomeController.sideBarMinWidth) {
      return HomeController.sideBarMinWidth;
    }

    if (width > maxWidth) {
      return maxWidth;
    }

    return width;
  }

  /// Saves [sideBarWidth] to [SettingsRepository].
  Future<void> saveSideBarWidth() =>
      _settings.setSideBarWidth(sideBarWidth.value);

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
    if (!myUser.hasPassword) {
      IntroductionView.show(router.context!)
          .then((_) => _settings.setShowIntroduction(false));
    } else {
      _settings.setShowIntroduction(false);
    }
  }
}
