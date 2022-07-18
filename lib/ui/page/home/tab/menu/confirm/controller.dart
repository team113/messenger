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
import 'package:messenger/l10n/l10n.dart';

import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/provider/gql/exceptions.dart' show UpdateUserPasswordException;
import '/ui/widget/text_field.dart';

class ConfirmLogoutController extends GetxController {
  ConfirmLogoutController(this._myUser, {this.pop});

  final RxBool displayPassword = RxBool(false);
  final RxBool displaySuccess = RxBool(false);
  final Function()? pop;

  final MyUserService _myUser;

  late final TextFieldState password;
  late final TextFieldState repeat;

  final RxBool obscurePassword = RxBool(true);
  final RxBool obscureRepeat = RxBool(true);

  @override
  void onInit() {
    password = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        try {
          if (s.text.isEmpty) {
            throw const FormatException();
          }

          UserPassword(s.text);

          if (repeat.text != password.text && repeat.isValidated) {
            repeat.error.value = 'err_passwords_mismatch'.l10n;
          }
        } on FormatException {
          if (s.text.isEmpty) {
            s.error.value = 'err_password_empty'.l10n;
          } else {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }
      },
    );

    repeat = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        try {
          if (s.text.isEmpty) {
            throw const FormatException();
          }

          UserPassword(s.text);

          if (repeat.text != password.text && password.isValidated) {
            repeat.error.value = 'err_passwords_mismatch'.l10n;
          }
        } on FormatException {
          if (s.text.isEmpty) {
            s.error.value = 'err_repeat_password_empty'.l10n;
          } else {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }
      },
    );

    super.onInit();
  }

  Future<void> setPassword() async {
    if (password.error.value != null ||
        repeat.error.value != null ||
        !password.editable.value ||
        !repeat.editable.value) {
      return;
    }

    if (password.text.isEmpty) {
      password.error.value = 'err_password_empty'.l10n;
      return;
    }

    if (repeat.text.isEmpty) {
      repeat.error.value = 'err_repeat_password_empty'.l10n;
      return;
    }

    password.editable.value = false;
    repeat.editable.value = false;
    password.status.value = RxStatus.loading();
    repeat.status.value = RxStatus.loading();
    try {
      await _myUser.updateUserPassword(newPassword: UserPassword(repeat.text));
      password.status.value = RxStatus.success();
      repeat.status.value = RxStatus.success();
      await Future.delayed(1.seconds);
      displaySuccess.value = true;
    } on UpdateUserPasswordException catch (e) {
      repeat.error.value = e.toMessage();
    } catch (e) {
      repeat.error.value = e.toString();
      rethrow;
    } finally {
      password.status.value = RxStatus.empty();
      repeat.status.value = RxStatus.empty();
      password.editable.value = true;
      repeat.editable.value = true;
    }
  }
}
