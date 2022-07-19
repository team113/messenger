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

export 'view.dart';

/// [Routes.home] page controller.
class HomeController extends GetxController {
  HomeController(this._auth, this._myUser);

  /// Maximum screen's width in pixels until side bar will be expanding.
  static double maxSideBarExpandWidth = 860;

  /// Percentage of the screen's width which side bar will occupy.
  static double sideBarWidthPercentage = 0.4;

  /// Controller of the [PageView] tab.
  late PageController pages;

  /// Current [pages] [HomeTab] value.
  late final Rx<HomeTab> page;

  /// Reactive [MyUser.unreadChatsCount] value.
  final Rx<int> unreadChatsCount = Rx<int>(0);

  /// Authentication service to determine auth status.
  final AuthService _auth;

  /// [MyUserService] to listen to the [MyUser] changes.
  final MyUserService _myUser;

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

    router.addListener(_onRouterChanged);
  }

  @override
  void onReady() {
    super.onReady();
    pages.jumpToPage(router.tab.index);
    refresh();
  }

  @override
  void onClose() {
    super.onClose();
    router.removeListener(_onRouterChanged);
    _myUserSubscription.cancel();
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
}
