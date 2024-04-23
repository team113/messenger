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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/util/message_popup.dart';
import 'confirm/view.dart';

export 'view.dart';

/// Controller of the [HomeTab.menu] tab.
class MenuTabController extends GetxController {
  MenuTabController(this._authService, this._myUserService);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [GlobalKey] of an [AvatarWidget] in the tab title.
  final GlobalKey profileKey = GlobalKey();

  /// [AuthService] used in a [logout].
  final AuthService _authService;

  /// Service managing [MyUser].
  final MyUserService _myUserService;

  /// Current [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns currently authenticated [MyUser]s.
  RxMap<UserId, Rx<MyUser?>> get accounts => _myUserService.myUsers;

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Determines whether the [logout] action may be invoked or not.
  ///
  /// Shows a confirmation popup if there's any ongoing calls.
  Future<bool> confirmLogout() async {
    // TODO: [MyUserService.myUser] might still be `null` here.
    if (await ConfirmLogoutView.show(router.context!) != true) {
      return false;
    }

    return true;
  }

  /// Logs out the current session and switches to the next account or goes to
  /// [Routes.auth] page, if none.
  Future<void> logout() async {
    router.go(Routes.nowhere);

    final String toLogin = await _authService.logout();

    if (accounts.length < 2) {
      router.go(toLogin);
    } else {
      final UserId? me = _authService.userId ?? myUser.value?.id;
      final UserId? next = accounts.keys.firstWhereOrNull(
        (id) => id != me,
      );

      try {
        if (next != null) {
          await _authService.signInToSavedAccount(next);
        } else {
          await _authService.register();
        }
      } catch (e) {
        await Future.delayed(1.seconds);
        MessagePopup.error(e);
      }

      await Future.delayed(500.milliseconds);
      router.home();
    }
  }

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);
}
