// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateUserPasswordException;
import '/routes.dart';
import '/ui/widget/text_field.dart';

/// Possible [ConfirmLogoutView] flow stage.
enum ConfirmLogoutViewStage { password, success }

/// Controller of a [ConfirmLogoutView].
class ConfirmLogoutController extends GetxController {
  ConfirmLogoutController(this._myUserService, this._authService);

  /// [ConfirmLogoutViewStage] currently being displayed.
  final Rx<ConfirmLogoutViewStage?> stage = Rx(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Field for password input.
  late final TextFieldState password;

  /// Field for password repeat input.
  late final TextFieldState repeat;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [repeat]ed password should be obscured.
  final RxBool obscureRepeat = RxBool(true);

  /// Indicator whether the currently authenticated [MyUser] has a password.
  late final RxBool hasPassword;

  /// Indicator whether the current [MyUser] profile should be kept in the
  /// [AuthService.profiles] or completely erased otherwise.
  final RxBool keep = RxBool(true);

  /// [MyUserService] setting the password.
  final MyUserService _myUserService;

  /// [AuthService] used to [logout].
  final AuthService _authService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Indicator whether the account of [myUser] can be recovered.
  bool get canRecover =>
      myUser.value?.emails.confirmed.isNotEmpty == true ||
      myUser.value?.phones.confirmed.isNotEmpty == true;

  @override
  void onInit() {
    hasPassword = RxBool(myUser.value?.hasPassword ?? false);

    password = TextFieldState(
      onChanged: (_) => repeat.error.value = null,
      onFocus: (s) {
        if (s.text.isNotEmpty) {
          try {
            UserPassword(s.text);
          } on FormatException {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }

        if (s.error.value == null &&
            repeat.text.isNotEmpty &&
            password.text.isNotEmpty &&
            password.text != repeat.text) {
          repeat.error.value = 'err_passwords_mismatch'.l10n;
        }
      },
      onSubmitted: (s) {
        repeat.focus.requestFocus();
        s.unsubmit();
      },
    );

    repeat = TextFieldState(
      onFocus: (s) {
        if (s.text.isNotEmpty) {
          try {
            UserPassword(s.text);
          } on FormatException {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }

        if (s.error.value == null &&
            repeat.text.isNotEmpty &&
            password.text.isNotEmpty &&
            password.text != repeat.text) {
          repeat.error.value = 'err_passwords_mismatch'.l10n;
        }
      },
      onSubmitted: (s) => setPassword(),
    );

    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Validates and sets the [password] of the currently authenticated [MyUser].
  Future<void> setPassword() async {
    if (password.error.value != null ||
        repeat.error.value != null ||
        !password.editable.value ||
        !repeat.editable.value) {
      return;
    }

    if (password.text.isEmpty) {
      password.error.value = 'err_input_empty'.l10n;
      return;
    }

    if (repeat.text.isEmpty) {
      repeat.error.value = 'err_input_empty'.l10n;
      return;
    }

    password.editable.value = false;
    repeat.editable.value = false;
    password.status.value = RxStatus.loading();
    repeat.status.value = RxStatus.loading();
    try {
      await _myUserService.updateUserPassword(
        newPassword: UserPassword(repeat.text),
      );
      password.status.value = RxStatus.success();
      repeat.status.value = RxStatus.success();
      await Future.delayed(1.seconds);
      stage.value = ConfirmLogoutViewStage.success;
    } on UpdateUserPasswordException catch (e) {
      repeat.error.value = e.toMessage();
    } catch (e) {
      repeat.resubmitOnError.value = true;
      repeat.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      password.status.value = RxStatus.empty();
      repeat.status.value = RxStatus.empty();
      password.editable.value = true;
      repeat.editable.value = true;
    }
  }

  /// Logs out the current session and go to the [Routes.auth] page.
  void logout() {
    // Don't allow user to keep his profile, when no recovery methods are
    // available or any password set, as they won't be able to sign in.
    _authService.logout(canRecover || hasPassword.value ? keep.value : false);

    router.auth();
    router.tab = HomeTab.chats;
  }
}
