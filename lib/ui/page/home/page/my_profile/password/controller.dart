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

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] of the current [MyUser]'s password.
  late final TextFieldState oldPassword;

  /// [TextFieldState] of the new password.
  late final TextFieldState newPassword;

  /// [TextFieldState] for repeating the new password.
  late final TextFieldState repeatPassword;

  /// Indicator whether the [oldPassword] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [newPassword] should be obscured.
  final RxBool obscureNewPassword = RxBool(true);

  /// Indicator whether the [repeatPassword] should be obscured.
  final RxBool obscureRepeatPassword = RxBool(true);

  /// Indicator whether [MyUser] has a password set.
  late bool hasPassword;

  /// [MyUserService] updating the [MyUser]'s password.
  final MyUserService _myUserService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    oldPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        repeatPassword.unsubmit();

        try {
          UserPassword(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) {
        newPassword.focus.requestFocus();
        s.unsubmit();
      },
    );

    newPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        repeatPassword.error.value = null;
        repeatPassword.unsubmit();

        try {
          UserPassword(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) {
        repeatPassword.focus.requestFocus();
        s.unsubmit();
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
      onSubmitted: (s) => changePassword(),
    );

    hasPassword = myUser.value?.hasPassword ?? false;

    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
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
      if (oldPassword.error.value != null) {
        return;
      }
    }

    if (newPassword.error.value == null && repeatPassword.error.value == null) {
      if (repeatPassword.text != newPassword.text) {
        repeatPassword.error.value = 'err_passwords_mismatch'.l10n;
        return;
      }

      oldPassword.editable.value = false;
      newPassword.editable.value = false;
      repeatPassword.editable.value = false;
      newPassword.status.value = RxStatus.loading();
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
        repeatPassword.error.value = 'err_data_transfer'.l10n;
        rethrow;
      } finally {
        newPassword.status.value = RxStatus.empty();
        repeatPassword.status.value = RxStatus.empty();
        oldPassword.editable.value = true;
        newPassword.editable.value = true;
        repeatPassword.editable.value = true;
      }
    }
  }
}
