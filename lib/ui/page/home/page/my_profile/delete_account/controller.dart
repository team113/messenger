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
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of a [DeleteAccountView].
class DeleteAccountController extends GetxController {
  DeleteAccountController(this._authService, this._myUserService);

  /// [AuthService] used for logout.
  final AuthService _authService;

  /// [MyUserService] used to get the [MyUser].
  final MyUserService _myUserService;

  /// Returns current [MyUser] value.
  Rx<MyUser?> get myUser => _myUserService.myUser;

  Future<void> deleteAccount() async {
    try {
      router.go(await _authService.logout());
      router.tab = HomeTab.chats;
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }
}
