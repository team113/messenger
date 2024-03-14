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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/account.dart';
import 'package:messenger/util/message_popup.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/my_user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
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

  RxList<Account> get accounts => _authService.accounts;

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

  /// Logs out the current session and go to the [Routes.auth] page.
  Future<void> logout() async {
    if (accounts.length <= 1) {
      router.go(await _authService.logout());
      router.tab = HomeTab.chats;
    } else {
      final active =
          accounts.firstWhereOrNull((e) => e.myUser.id == myUser.value?.id);
      if (active != null) {
        await _authService.deleteAccount(active);
      }

      final List<Account> allowed = accounts.where((e) => e != active).toList()
        ..sort();

      final Account? next = allowed.firstOrNull;
      if (next != null) {
        router.go(Routes.nowhere);

        try {
          await _authService.signInWith(next.credentials);
        } catch (e) {
          Future.delayed(const Duration(milliseconds: 1000)).then((v) {
            MessagePopup.error(e);
          });
        }

        await Future.delayed(const Duration(milliseconds: 500));

        router.home();
      }
    }
  }

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);
}
