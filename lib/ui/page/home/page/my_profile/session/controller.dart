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

import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import 'view.dart';

export 'view.dart';

/// Controller of a [DeleteSessionView].
class DeleteSessionController extends GetxController {
  DeleteSessionController(
    this._session,
    this._myUserService,
    this._authService, {
    this.pop,
  });

  /// [TextFieldState] of the [MyUser]'s password.
  late final TextFieldState password;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether [MyUser] has a password set.
  late bool hasPassword;

  /// Callback, called when an [DeleteSessionView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// [Session] to delete.
  final Session _session;

  /// [MyUserService] updating the [MyUser]'s password.
  final MyUserService _myUserService;

  /// [MyUserService] updating the [MyUser]'s password.
  final AuthService _authService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    password = TextFieldState(
      onChanged: (s) {
        password.error.value = null;

        if (s.text.isNotEmpty) {
          try {
            UserPassword(s.text);
          } on FormatException {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }
      },
      onSubmitted: (s) {
        s.unsubmit();
      },
    );

    hasPassword = myUser.value?.hasPassword ?? false;

    super.onInit();
  }

  /// Validates and updates current [myUser]'s password with the one specified
  /// in the [newPassword] and [repeatPassword] fields.
  Future<void> deleteSession() async {
    if (password.error.value == null) {
      password.editable.value = false;
      password.status.value = RxStatus.loading();

      try {
        await _authService.deleteSession(
          id: _session.id,
          password: UserPassword(password.text),
        );
        pop?.call();
      } on DeleteSessionException catch (e) {
        password.error.value = e.toMessage();
      } catch (e) {
        password.error.value = 'err_data_transfer'.l10n;
        rethrow;
      } finally {
        password.status.value = RxStatus.empty();
        password.editable.value = true;
      }
    }
  }
}
