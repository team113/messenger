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
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';

export 'view.dart';

/// Possible [ChangePasswordView] flow stage.
enum ChangePasswordFlowStage { set, changed }

/// Controller of a [ChangePasswordView].
class ChangePasswordController extends GetxController {
  ChangePasswordController(this._myUserService);

  /// [ChangePasswordFlowStage] currently being displayed.
  final Rx<ChangePasswordFlowStage?> stage = Rx(null);

  /// State of a current [myUser]'s password field.
  late final TextFieldState oldPassword;

  /// State of a new [myUser]'s password field.
  late final TextFieldState newPassword;

  /// State of a repeated new [myUser]'s password field.
  late final TextFieldState repeatPassword;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [newPassword] should be obscured.
  final RxBool obscureNewPassword = RxBool(true);

  /// Indicator whether the [repeatPassword] should be obscured.
  final RxBool obscureRepeatPassword = RxBool(true);

  /// [MyUserService] updating the [MyUser]'s password.
  final MyUserService _myUserService;

  /// Returns current [MyUser] value.
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    oldPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        newPassword.error.value = null;
        repeatPassword.error.value = null;
        try {
          UserPassword(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
    );
    newPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        repeatPassword.error.value = null;
        try {
          UserPassword(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
    );
    repeatPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        newPassword.error.value = null;
        if (s.text != newPassword.text && newPassword.isValidated) {
          s.error.value = 'err_passwords_mismatch'.l10n;
        }
      },
    );

    super.onInit();
  }

  /// Validates and updates current [myUser]'s password with the one specified
  /// in the [newPassword] and [repeatPassword] fields.
  Future<void> changePassword() async {
    if (myUser.value?.hasPassword == true) {
      oldPassword.focus.unfocus();
      oldPassword.submit();
    }

    newPassword.focus.unfocus();
    newPassword.submit();
    repeatPassword.focus.unfocus();
    repeatPassword.submit();

    if (myUser.value?.hasPassword == true) {
      if (!oldPassword.isValidated || oldPassword.text.isEmpty) {
        oldPassword.error.value = 'err_current_password_empty'.l10n;
        return;
      }

      if (oldPassword.error.value != null) {
        return;
      }
    }

    if (newPassword.error.value == null && repeatPassword.error.value == null) {
      if (!newPassword.isValidated || newPassword.text.isEmpty) {
        newPassword.error.value = 'err_new_password_empty'.l10n;
        return;
      }

      if (!repeatPassword.isValidated || repeatPassword.text.isEmpty) {
        repeatPassword.error.value = 'err_repeat_password_empty'.l10n;
        return;
      }

      if (repeatPassword.text != newPassword.text) {
        repeatPassword.error.value = 'err_passwords_mismatch'.l10n;
        return;
      }

      oldPassword.editable.value = false;
      newPassword.editable.value = false;
      repeatPassword.editable.value = false;
      repeatPassword.status.value = RxStatus.loading();
      try {
        final bool hadPassword = myUser.value?.hasPassword ?? false;
        await _myUserService.updateUserPassword(
          oldPassword:
              myUser.value!.hasPassword ? UserPassword(oldPassword.text) : null,
          newPassword: UserPassword(newPassword.text),
        );
        stage.value = hadPassword
            ? ChangePasswordFlowStage.changed
            : ChangePasswordFlowStage.set;
      } on UpdateUserPasswordException catch (e) {
        oldPassword.error.value = e.toMessage();
      } catch (e) {
        repeatPassword.error.value = e.toString();
        rethrow;
      } finally {
        repeatPassword.status.value = RxStatus.empty();
        oldPassword.editable.value = true;
        newPassword.editable.value = true;
        repeatPassword.editable.value = true;
      }
    }
  }
}
