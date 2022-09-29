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

import 'package:get/get.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/tab/menu/confirm/view.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/web/web_utils.dart';

class MoreController extends GetxController {
  MoreController(this._authService, this._callService, this._myUserService);

  final AuthService _authService;
  final CallService _callService;
  final MyUserService _myUserService;

  /// Determines whether the [logout] action may be invoked or not.
  ///
  /// Shows a confirmation popup if there's any ongoing calls.
  Future<bool> confirmLogout() async {
    if (_callService.calls.isNotEmpty || WebUtils.containsCalls()) {
      if (await MessagePopup.alert('alert_are_you_sure_want_to_log_out'.l10n) !=
          true) {
        return false;
      }
    }

    // TODO: [MyUserService.myUser] might still be `null` here.
    if (_myUserService.myUser.value?.hasPassword != true) {
      if (await ConfirmLogoutView.show(router.context!) != true) {
        return false;
      }
    }

    return true;
  }

  /// Logs out the current session and go to the [Routes.auth] page.
  Future<String> logout() => _authService.logout();
}
