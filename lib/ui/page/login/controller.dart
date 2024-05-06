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

import '/api/backend/schema.dart' show ConfirmUserEmailErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        AddUserEmailException,
        ConfirmUserEmailException,
        ConnectionException,
        CreateSessionException,
        ResendUserEmailConfirmationException,
        ResetUserPasswordException,
        ValidateUserPasswordRecoveryCodeException;
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

/// Possible [LoginView] flow stage.
enum LoginViewStage {
  recovery,
  recoveryCode,
  recoveryPassword,
  signIn,
  signInWithPassword,
  signUp,
  signUpWithEmail,
  signUpWithEmailCode,
  signUpOrSignIn,
}

/// [GetxController] of a [LoginView].
class LoginController extends GetxController {
  LoginController(
    this._authService, {
    LoginViewStage initial = LoginViewStage.signUp,
    this.onSuccess,
  }) : stage = Rx(initial);

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

  /// [TextFieldState] for an [UserEmail] text input.
  late final TextFieldState email;

  /// [TextFieldState] for [ConfirmationCode] for [UserEmail] input.
  late final TextFieldState emailCode;

  /// [LoginView] stage to go back to.
  LoginViewStage? returnTo;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [newPassword] should be obscured.
  final RxBool obscureNewPassword = RxBool(true);

  /// Indicator whether the [repeatPassword] should be obscured.
  final RxBool obscureRepeatPassword = RxBool(true);

  /// Indicator whether the password has been reset.
  final RxBool recovered = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [LoginViewStage] currently being displayed.
  final Rx<LoginViewStage> stage;

  /// Callback, called when this [LoginController] successfully signs into an
  /// account.
  ///
  /// If not specified, the [RouteLinks.home] redirect is invoked.
  final void Function({bool? signedUp})? onSuccess;

  /// Amount of [signIn] unsuccessful submitting attempts.
  int signInAttempts = 0;

  /// Amount of [emailCode] unsuccessful submitting attempts.
  int codeAttempts = 0;

  /// Timeout of a [signIn] next invoke attempt.
  final RxInt signInTimeout = RxInt(0);

  /// Timeout of a [emailCode] next submit attempt.
  final RxInt codeTimeout = RxInt(0);

  /// Timeout of a [resendEmail] next invoke attempt.
  final RxInt resendEmailTimeout = RxInt(0);

  /// Authentication service providing the authentication capabilities.
  final AuthService _authService;

  /// [Timer] disabling [emailCode] submitting for [codeTimeout].
  Timer? _codeTimer;

  /// [Timer] disabling [signIn] invoking for [signInTimeout].
  Timer? _signInTimer;

  /// [Timer] used to disable resend code button [resendEmailTimeout].
  Timer? _resendEmailTimer;

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
  Rx<RxStatus> get authStatus => _authService.status;

  @override
  void onInit() {
    login = TextFieldState(
      onChanged: (_) {
        password.error.value = null;
        password.unsubmit();
      },
      onSubmitted: (s) {
        password.focus.requestFocus();
        s.unsubmit();
      },
    );

    password = TextFieldState(
      onFocus: (s) => s.unsubmit(),
      onSubmitted: (s) => signIn(),
    );

    recovery = TextFieldState(onSubmitted: (s) => recoverAccess());

    recoveryCode = TextFieldState(onSubmitted: (s) => validateCode());

    newPassword = TextFieldState(
      onChanged: (_) {
        repeatPassword.error.value = null;
        repeatPassword.unsubmit();
      },
      onSubmitted: (s) {
        repeatPassword.focus.requestFocus();
        s.unsubmit();
      },
    );

    repeatPassword = TextFieldState(
      onFocus: (s) {
        if (s.text != newPassword.text && newPassword.isValidated) {
          s.error.value = 'err_passwords_mismatch'.l10n;
        }
      },
      onSubmitted: (s) => resetUserPassword(),
    );

    email = TextFieldState(
      onFocus: (s) {
        if (s.text.isNotEmpty) {
          try {
            UserEmail(s.text.toLowerCase());
          } on FormatException {
            s.error.value = 'err_incorrect_email'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        final UserEmail? email = UserEmail.tryParse(s.text.toLowerCase());

        if (email == null) {
          s.error.value = 'err_incorrect_email'.l10n;
        } else {
          emailCode.clear();
          stage.value = LoginViewStage.signUpWithEmailCode;
          try {
            await _authService.signUpWithEmail(email);
            s.unsubmit();
          } on AddUserEmailException catch (e) {
            s.error.value = e.toMessage();
            _setResendEmailTimer(false);

            stage.value = LoginViewStage.signUpWithEmail;
          } catch (_) {
            s.resubmitOnError.value = true;
            s.error.value = 'err_data_transfer'.l10n;
            _setResendEmailTimer(false);
            s.unsubmit();

            stage.value = LoginViewStage.signUpWithEmail;
            rethrow;
          }
        }
      },
    );

    emailCode = TextFieldState(
      onSubmitted: (s) async {
        s.status.value = RxStatus.loading();
        try {
          await _authService
              .confirmSignUpEmail(ConfirmationCode(emailCode.text));

          (onSuccess ?? router.home)(signedUp: true);
        } on ConfirmUserEmailException catch (e) {
          switch (e.code) {
            case ConfirmUserEmailErrorCode.wrongCode:
              s.error.value = e.toMessage();

              ++codeAttempts;
              if (codeAttempts >= 3) {
                codeAttempts = 0;
                _setCodeTimer();
              }
              s.status.value = RxStatus.empty();
              break;

            default:
              s.error.value = 'err_wrong_recovery_code'.l10n;
              break;
          }
        } on FormatException catch (_) {
          s.error.value = 'err_wrong_recovery_code'.l10n;
          s.status.value = RxStatus.empty();
          ++codeAttempts;
          if (codeAttempts >= 3) {
            codeAttempts = 0;
            _setCodeTimer();
          }
        } catch (_) {
          s.resubmitOnError.value = true;
          s.error.value = 'err_data_transfer'.l10n;
          s.status.value = RxStatus.empty();
          s.unsubmit();
          rethrow;
        }
      },
    );

    super.onInit();
  }

  @override
  void onClose() {
    _setSignInTimer(false);
    _setResendEmailTimer(false);
    _setCodeTimer(false);
    scrollController.dispose();
    super.onClose();
  }

  /// Signs in and redirects to the [Routes.home] page.
  ///
  /// Username is [login]'s text and the password is [password]'s text.
  Future<void> signIn() async {
    final String input = login.text.toLowerCase();

    final UserLogin? userLogin = UserLogin.tryParse(input);
    final UserNum? userNum = UserNum.tryParse(input);
    final UserEmail? userEmail = UserEmail.tryParse(input);
    final UserPhone? userPhone = UserPhone.tryParse(input);
    final UserPassword? userPassword = UserPassword.tryParse(password.text);

    login.error.value = null;
    password.error.value = null;

    final bool noCredentials = userLogin == null &&
        userNum == null &&
        userEmail == null &&
        userPhone == null;

    if (noCredentials || userPassword == null) {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    try {
      login.status.value = RxStatus.loading();
      password.status.value = RxStatus.loading();
      await _authService.signIn(
        userPassword,
        login: userLogin,
        num: userNum,
        email: userEmail,
        phone: userPhone,
      );

      (onSuccess ?? router.home)();
    } on CreateSessionException catch (e) {
      ++signInAttempts;

      if (signInAttempts >= 3) {
        // Wrong password was entered three times. Login is possible in N
        // seconds.
        signInAttempts = 0;
        _setSignInTimer();
      }

      password.error.value = e.toMessage();
    } on ConnectionException {
      password.unsubmit();
      password.resubmitOnError.value = true;
      password.error.value = 'err_data_transfer'.l10n;
    } catch (e) {
      password.unsubmit();
      password.resubmitOnError.value = true;
      password.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      login.status.value = RxStatus.empty();
      password.status.value = RxStatus.empty();
    }
  }

  /// Creates a new one-time account right away.
  Future<void> register() async {
    try {
      await _authService.register();
      (onSuccess ?? router.home)();
    } on ConnectionException {
      MessagePopup.error('err_data_transfer'.l10n);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Initiates password recovery for the [MyUser] identified by the provided
  /// [recovery] input and stores the parsed value.
  Future<void> recoverAccess() async {
    recovery.editable.value = false;
    recovery.status.value = RxStatus.loading();
    recovery.error.value = null;

    _recoveryLogin = _recoveryNum = _recoveryPhone = _recoveryEmail = null;

    if (recovery.text.isEmpty) {
      recovery.status.value = RxStatus.empty();
      recovery.editable.value = true;
      recovery.error.value = 'err_account_not_found'.l10n;
      return;
    }

    // Parse the [recovery] input.
    try {
      _recoveryNum = UserNum(recovery.text);
    } catch (_) {
      try {
        _recoveryPhone = UserPhone(recovery.text);
      } catch (_) {
        try {
          _recoveryLogin = UserLogin(recovery.text.toLowerCase());
        } catch (_) {
          try {
            _recoveryEmail = UserEmail(recovery.text.toLowerCase());
          } catch (_) {
            // No-op.
          }
        }
      }
    }

    try {
      await _authService.recoverUserPassword(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
      );

      stage.value = LoginViewStage.recoveryCode;
      recovery.status.value = RxStatus.success();
      recovery.editable.value = false;
    } on FormatException {
      recovery.error.value = 'err_account_not_found'.l10n;
    } on ArgumentError {
      recovery.error.value = 'err_account_not_found'.l10n;
    } catch (e) {
      recovery.unsubmit();
      recovery.resubmitOnError.value = true;
      recovery.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      recovery.status.value = RxStatus.empty();
      recovery.editable.value = true;
    }
  }

  /// Validates the provided password recovery [ConfirmationCode] for the
  /// [MyUser] identified by the provided in [recoverAccess] identity.
  Future<void> validateCode() async {
    recoveryCode.editable.value = false;
    recoveryCode.status.value = RxStatus.loading();
    recoveryCode.error.value = null;

    if (recoveryCode.text.isEmpty) {
      recoveryCode.editable.value = true;
      recoveryCode.status.value = RxStatus.empty();
      recoveryCode.error.value = 'err_input_empty'.l10n;
      return;
    }

    try {
      await _authService.validateUserPasswordRecoveryCode(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
        code: ConfirmationCode(recoveryCode.text.toLowerCase()),
      );

      recoveryCode.editable.value = false;
      recoveryCode.status.value = RxStatus.success();
      stage.value = LoginViewStage.recoveryPassword;
    } on FormatException {
      recoveryCode.error.value = 'err_wrong_recovery_code'.l10n;
    } on ArgumentError {
      recoveryCode.error.value = 'err_wrong_recovery_code'.l10n;
    } on ValidateUserPasswordRecoveryCodeException catch (e) {
      recoveryCode.error.value = e.toMessage();
    } catch (e) {
      recoveryCode.unsubmit();
      recoveryCode.resubmitOnError.value = true;
      recoveryCode.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      recoveryCode.editable.value = true;
      recoveryCode.status.value = RxStatus.empty();
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
      newPassword.error.value = 'err_input_empty'.l10n;
      newPassword.editable.value = true;
      repeatPassword.editable.value = true;
      return;
    }

    if (repeatPassword.text.isEmpty) {
      repeatPassword.error.value = 'err_input_empty'.l10n;
      return;
    }

    if (UserPassword.tryParse(newPassword.text) == null) {
      newPassword.error.value = 'err_incorrect_input'.l10n;
      return;
    }

    if (UserPassword.tryParse(repeatPassword.text) == null) {
      repeatPassword.error.value = 'err_incorrect_input'.l10n;
      return;
    }

    if (newPassword.text != repeatPassword.text) {
      repeatPassword.error.value = 'err_passwords_mismatch'.l10n;
      return;
    }

    newPassword.editable.value = false;
    repeatPassword.editable.value = false;
    newPassword.status.value = RxStatus.loading();
    repeatPassword.status.value = RxStatus.loading();

    try {
      await _authService.resetUserPassword(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
        code: ConfirmationCode(recoveryCode.text.toLowerCase()),
        newPassword: UserPassword(newPassword.text),
      );

      recovered.value = true;
      stage.value = LoginViewStage.signIn;
    } on FormatException {
      repeatPassword.error.value = 'err_incorrect_input'.l10n;
    } on ArgumentError {
      repeatPassword.error.value = 'err_incorrect_input'.l10n;
    } on ResetUserPasswordException catch (e) {
      repeatPassword.error.value = e.toMessage();
    } catch (e) {
      repeatPassword.resubmitOnError.value = true;
      repeatPassword.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      newPassword.status.value = RxStatus.empty();
      repeatPassword.status.value = RxStatus.empty();
      newPassword.editable.value = true;
      repeatPassword.editable.value = true;
    }
  }

  /// Resends a [ConfirmationCode] to the specified [email].
  Future<void> resendEmail() async {
    _setResendEmailTimer();

    try {
      await _authService.resendSignUpEmail();
    } on ResendUserEmailConfirmationException catch (e) {
      emailCode.error.value = e.toMessage();
    } catch (e) {
      emailCode.resubmitOnError.value = true;
      emailCode.error.value = 'err_data_transfer'.l10n;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Starts or stops the [_signInTimer] based on [enabled] value.
  void _setSignInTimer([bool enabled = true]) {
    if (enabled) {
      password.submitable.value = false;
      signInTimeout.value = 30;
      _signInTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          signInTimeout.value--;
          if (signInTimeout.value <= 0) {
            password.submitable.value = true;
            signInTimeout.value = 0;
            _signInTimer?.cancel();
            _signInTimer = null;
          }
        },
      );
    } else {
      password.submitable.value = true;
      signInTimeout.value = 0;
      _signInTimer?.cancel();
      _signInTimer = null;
    }
  }

  /// Starts or stops the [_resendEmailTimer] based on [enabled] value.
  void _setResendEmailTimer([bool enabled = true]) {
    if (enabled) {
      resendEmailTimeout.value = 30;
      _resendEmailTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          resendEmailTimeout.value--;
          if (resendEmailTimeout.value <= 0) {
            resendEmailTimeout.value = 0;
            _resendEmailTimer?.cancel();
            _resendEmailTimer = null;
          }
        },
      );
    } else {
      resendEmailTimeout.value = 0;
      _resendEmailTimer?.cancel();
      _resendEmailTimer = null;
    }
  }

  /// Starts or stops the [_codeTimer] based on [enabled] value.
  void _setCodeTimer([bool enabled = true]) {
    if (enabled) {
      emailCode.submitable.value = false;
      codeTimeout.value = 30;
      _codeTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          codeTimeout.value--;
          if (codeTimeout.value <= 0) {
            emailCode.submitable.value = true;
            codeTimeout.value = 0;
            _codeTimer?.cancel();
            _codeTimer = null;
          }
        },
      );
    } else {
      emailCode.submitable.value = true;
      codeTimeout.value = 0;
      _codeTimer?.cancel();
      _codeTimer = null;
    }
  }
}
