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

import '/api/backend/schema.dart' show CreateSessionErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/provider/gql/exceptions.dart'
    show
        CreateSessionException,
        RecoverUserPasswordException,
        ResetUserPasswordException,
        ValidateUserPasswordRecoveryCodeException;
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of the [Routes.login] page.
class LoginController extends GetxController {
  LoginController(this._auth);

  /// [TextFieldState] of a login text input.
  late final TextFieldState login;

  /// [TextFieldState] of a password text input.
  late final TextFieldState password;

  /// [TextFieldState] of a recovery text input.
  late final TextFieldState recovery;

  /// [TextFieldState] of a recovery code text input.
  late final TextFieldState recoveryCode;

  /// [TextFieldState] of a new password text input.
  late final TextFieldState newPassword;

  /// [TextFieldState] of a repeat password text input.
  late final TextFieldState repeatPassword;

  /// Indicator whether the password field should be shown.
  RxBool showPwdSection = RxBool(false);

  /// Indicator whether the recovery code field should be shown.
  RxBool showCodeSection = RxBool(false);

  /// Indicator whether the new password field should be shown.
  RxBool showNewPasswordSection = RxBool(false);

  /// Authentication service providing the authentication capabilities.
  final AuthService _auth;

  /// [UserNum] that was provided in [recoverAccess] used to [validateCode] and
  /// [resetUserPassword].
  UserNum? _recoveryNum;

  /// [UserEmail] that was provided in [recoverAccess] used to [validateCode]
  /// and [resetUserPassword].
  UserEmail? _recoveryEmail;

  /// [UserPhone] that was provided in [recoverAccess] used to [validateCode]
  /// and [resetUserPassword].
  UserPhone? _recoveryPhone;

  /// [UserLogin] that was provided in [recoverAccess] used to [validateCode]
  /// and [resetUserPassword].
  UserLogin? _recoveryLogin;

  /// Current authentication status.
  Rx<RxStatus> get authStatus => _auth.status;

  @override
  void onInit() {
    login = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) => check(),
    );

    password = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) => signIn(),
    );

    recovery = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) => recoverAccess(),
    );

    recoveryCode = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) => validateCode(),
    );

    newPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        repeatPassword.error.value = null;
      },
      onSubmitted: (s) => repeatPassword.focus.requestFocus(),
    );
    repeatPassword = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        newPassword.error.value = null;
      },
      onSubmitted: (s) => resetUserPassword(),
    );

    super.onInit();
  }

  /// Checks if an [User] with [login]'s text exists.
  Future<void> check() async {
    password.error.value = null;

    UserLogin? userLogin;
    UserNum? num;
    UserEmail? email;
    UserPhone? phone;

    if (login.text.isEmpty) {
      login.error.value = 'err_input_empty'.tr;
      return;
    }

    try {
      userLogin = UserLogin(login.text.toLowerCase());
    } catch (e) {
      // No-op.
    }

    try {
      num = UserNum(login.text);
    } catch (e) {
      // No-op.
    }

    try {
      email = UserEmail(login.text.toLowerCase());
    } catch (e) {
      // No-op.
    }

    try {
      phone = UserPhone(login.text);
    } catch (e) {
      // No-op.
    }

    try {
      if (userLogin == null && num == null && email == null && phone == null) {
        throw const FormatException();
      }
      bool exists = await _auth.checkUserIdentifiable(
        login: userLogin,
        num: num,
        email: email,
        phone: phone,
      );

      if (!exists) {
        login.error.value = 'err_account_not_found'.tr;
      }
      showPwdSection.value = exists;
      if (showPwdSection.value) {
        password.focus.requestFocus();
      }
    } on FormatException {
      login.error.value = 'err_account_not_found'.tr;
    } catch (e) {
      login.unsubmit();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Signs in and redirects to the [Routes.home] page.
  ///
  /// Username is [login]'s text and the password is [password]'s text.
  Future<void> signIn() async {
    UserLogin? userLogin;
    UserNum? num;
    UserEmail? email;
    UserPhone? phone;

    if (login.text.isEmpty) {
      login.error.value = 'err_input_empty'.tr;
      return;
    }

    try {
      userLogin = UserLogin(login.text.toLowerCase());
    } catch (e) {
      // No-op.
    }

    try {
      num = UserNum(login.text);
    } catch (e) {
      // No-op.
    }

    try {
      email = UserEmail(login.text.toLowerCase());
    } catch (e) {
      // No-op.
    }

    try {
      phone = UserPhone(login.text);
    } catch (e) {
      // No-op.
    }

    if (password.text.isEmpty) {
      password.error.value = 'err_input_empty'.tr;
      return;
    }

    try {
      if (userLogin == null && num == null && email == null && phone == null) {
        throw const FormatException();
      }
      await _auth.signIn(
        UserPassword(password.text),
        login: userLogin,
        num: num,
        email: email,
        phone: phone,
      );

      router.home();
    } on FormatException {
      password.error.value = 'err_incorrect_password'.tr;
    } on CreateSessionException catch (e) {
      switch (e.code) {
        case CreateSessionErrorCode.unknownUser:
          login.error.value = e.toMessage();
          break;
        case CreateSessionErrorCode.wrongPassword:
          password.error.value = e.toMessage();
          break;
        case CreateSessionErrorCode.artemisUnknown:
          rethrow;
      }
    } catch (e) {
      password.unsubmit();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Initiates password recovery for the [MyUser] identified by the provided
  /// [recovery] input and stores the parsed value.
  Future<void> recoverAccess() async {
    bool success = false;

    recovery.editable.value = false;
    recovery.status.value = RxStatus.loading();
    recovery.error.value = null;
    showCodeSection.value = false;

    _recoveryLogin = _recoveryNum = _recoveryPhone = _recoveryEmail = null;

    if (recovery.text.isEmpty) {
      recovery.status.value = RxStatus.empty();
      recovery.editable.value = true;
      recovery.error.value = 'err_input_empty'.tr;
      return;
    }

    // Parse the [recovery] input.
    try {
      _recoveryNum = UserNum(recovery.text);
    } catch (e) {
      try {
        _recoveryPhone = UserPhone(recovery.text);
      } catch (e) {
        try {
          _recoveryLogin = UserLogin(recovery.text.toLowerCase());
        } catch (e) {
          try {
            _recoveryEmail = UserEmail(recovery.text);
          } catch (e) {
            // No-op.
          }
        }
      }
    }

    try {
      await _auth.recoverUserPassword(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
      );
      success = true;
    } on FormatException {
      recovery.error.value = 'err_incorrect_input'.tr;
    } on ArgumentError {
      recovery.error.value = 'err_incorrect_input'.tr;
    } on RecoverUserPasswordException catch (e) {
      recovery.error.value = e.toMessage();
    } catch (e) {
      recovery.unsubmit();
      MessagePopup.error(e);
      rethrow;
    } finally {
      if (success) {
        recovery.status.value = RxStatus.success();
        recovery.editable.value = false;
        showCodeSection.value = true;
        recoveryCode.focus.requestFocus();
      } else {
        recovery.status.value = RxStatus.empty();
        recovery.editable.value = true;
      }
    }
  }

  /// Validates the provided password recovery [ConfirmationCode] for the
  /// [MyUser] identified by the provided in [recoverAccess] identity.
  Future<void> validateCode() async {
    bool success = false;

    recoveryCode.editable.value = false;
    recoveryCode.status.value = RxStatus.loading();
    recoveryCode.error.value = null;

    if (recoveryCode.text.isEmpty) {
      recoveryCode.editable.value = true;
      recoveryCode.status.value = RxStatus.empty();
      recoveryCode.error.value = 'err_input_empty'.tr;
      return;
    }

    try {
      await _auth.validateUserPasswordRecoveryCode(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
        code: ConfirmationCode(recoveryCode.text.toLowerCase()),
      );
      success = true;
    } on FormatException {
      recoveryCode.error.value = 'err_incorrect_input'.tr;
    } on ArgumentError {
      recoveryCode.error.value = 'err_incorrect_input'.tr;
    } on ValidateUserPasswordRecoveryCodeException catch (e) {
      recoveryCode.error.value = e.toMessage();
    } catch (e) {
      recoveryCode.unsubmit();
      MessagePopup.error(e);
      rethrow;
    } finally {
      if (success) {
        recoveryCode.editable.value = false;
        recoveryCode.status.value = RxStatus.success();
        showNewPasswordSection.value = true;
        newPassword.focus.requestFocus();
      } else {
        recoveryCode.editable.value = true;
        recoveryCode.status.value = RxStatus.empty();
      }
    }
  }

  /// Resets password for the [MyUser] identified by the provided in
  /// [recoverAccess] identity and [ConfirmationCode].
  Future<void> resetUserPassword() async {
    if (newPassword.error.value != null || repeatPassword.error.value != null) {
      return;
    }

    repeatPassword.status.value = RxStatus.empty();

    if (newPassword.text.isEmpty) {
      newPassword.error.value = 'err_input_empty'.tr;
      newPassword.editable.value = true;
      repeatPassword.editable.value = true;
      return;
    }

    if (repeatPassword.text.isEmpty) {
      repeatPassword.error.value = 'err_input_empty'.tr;
      return;
    }

    try {
      UserPassword(newPassword.text);
    } catch (e) {
      newPassword.error.value = 'err_incorrect_input'.tr;
      return;
    }

    try {
      UserPassword(repeatPassword.text);
    } catch (e) {
      repeatPassword.error.value = 'err_incorrect_input'.tr;
      return;
    }

    if (newPassword.text != repeatPassword.text) {
      repeatPassword.error.value = 'err_passwords_mismatch'.tr;
      return;
    }

    newPassword.editable.value = false;
    repeatPassword.editable.value = false;
    repeatPassword.status.value = RxStatus.loading();

    try {
      await _auth.resetUserPassword(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
        code: ConfirmationCode(recoveryCode.text.toLowerCase()),
        newPassword: UserPassword(newPassword.text),
      );

      MessagePopup.success('label_password_was_changed'.tr);

      recovery.clear();
      recoveryCode.clear();
      newPassword.clear();
      repeatPassword.clear();

      showCodeSection.value = false;
      showNewPasswordSection.value = false;

      recovery.status.value = RxStatus.empty();
      recoveryCode.status.value = RxStatus.empty();

      recovery.editable.value = true;
      recoveryCode.editable.value = true;
    } on FormatException {
      repeatPassword.error.value = 'err_incorrect_input'.tr;
    } on ArgumentError {
      repeatPassword.error.value = 'err_incorrect_input'.tr;
    } on ResetUserPasswordException catch (e) {
      repeatPassword.error.value = e.toMessage();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      repeatPassword.status.value = RxStatus.empty();
      newPassword.editable.value = true;
      repeatPassword.editable.value = true;
    }
  }
}
