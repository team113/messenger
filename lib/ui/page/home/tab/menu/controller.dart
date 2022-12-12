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

import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/web/web_utils.dart';
import 'confirm/view.dart';

export 'view.dart';

/// Controller of the `HomeTab.menu` tab.
class MenuTabController extends GetxController {
  MenuTabController(this._auth, this._myUserService, this._callService);

  /// Authorization service.
  final AuthService _auth;

  /// Service managing [MyUser].
  final MyUserService _myUserService;

  /// [CallService], used to determine whether a confirm logout alert should be
  /// shown or not.
  final CallService _callService;

  /// Current [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

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
  Future<String> logout() => _auth.logout();
}
