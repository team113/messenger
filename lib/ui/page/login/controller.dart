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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart'
    show CreateSessionErrorCode, UpdateUserPasswordErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        AddUserEmailException,
        ConnectionException,
        CreateSessionException,
        SignUpException,
        UpdateUserPasswordException,
        ValidateConfirmationCodeException;
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
  signInWithEmail,
  signInWithEmailCode,
  signUp,
  signUpWithPassword,
  signUpWithEmail,
  signUpWithEmailCode,
  signUpOrSignIn,
}

/// [GetxController] of a [LoginView].
class LoginController extends GetxController {
  LoginController(
    this._authService, {
    LoginViewStage initial = LoginViewStage.signUp,
    MyUser? myUser,
    this.onSuccess,
  }) : stage = Rx(initial),
       _myUser = myUser;

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

  /// [TextFieldState] for an [UserNum], [UserLogin] or [UserEmail] text input.
  late final TextFieldState identifier;

  /// [LoginView] stage to go back to.
  LoginViewStage? returnTo;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [newPassword] should be obscured.
  final RxBool obscureNewPassword = RxBool(true);

  /// Indicator whether the [repeatPassword] should be obscured.
  final RxBool obscureRepeatPassword = RxBool(true);

  /// Indicator whether the [emailCode] should be obscured.
  final RxBool obscureCode = RxBool(true);

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

  /// [MyUser], whose data should be prefilled in the fields.
  final MyUser? _myUser;

  /// Current authentication status.
  Rx<RxStatus> get authStatus => _authService.status;

  @override
  void onInit() {
    login = TextFieldState(
      text: _myUser?.num.toString(),
      onChanged: (_) {
        password.error.value = null;
        password.unsubmit();
        repeatPassword.unsubmit();
      },
      onSubmitted: (s) {
        password.focus.requestFocus();
        s.unsubmit();
      },
    );

    password = TextFieldState(
      onFocus: (s) => s.unsubmit(),
      onChanged: (_) {
        password.error.value = null;
        password.unsubmit();
        repeatPassword.error.value = null;
        repeatPassword.unsubmit();
      },
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
        switch (stage.value) {
          case LoginViewStage.signUpWithPassword:
            if (s.text != password.text && password.isValidated) {
              s.error.value = 'err_passwords_mismatch'.l10n;
            }
            break;

          default:
            if (s.text != newPassword.text && newPassword.isValidated) {
              s.error.value = 'err_passwords_mismatch'.l10n;
            }
            break;
        }
      },
      onSubmitted: (s) async {
        switch (stage.value) {
          case LoginViewStage.signUpWithPassword:
            final userLogin = UserLogin.tryParse(login.text);
            final userPassword = UserPassword.tryParse(password.text);

            if (userLogin == null) {
              login.error.value = 'err_incorrect_login_input'.l10n;
              return;
            }

            if (userPassword == null) {
              password.error.value = 'err_password_incorrect'.l10n;
              return;
            }

            try {
              await register(login: userLogin, password: userPassword);
            } on SignUpException catch (e) {
              login.error.value = e.toMessage();
            } catch (e) {
              password.error.value = 'err_data_transfer'.l10n;
              rethrow;
            }
            break;

          default:
            await resetUserPassword();
            break;
        }
      },
    );

    email = TextFieldState(
      onFocus: (s) {
        if (s.text.trim().isNotEmpty) {
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

          final LoginViewStage previous = stage.value;

          stage.value = switch (stage.value) {
            LoginViewStage.signInWithEmail =>
              LoginViewStage.signInWithEmailCode,
            (_) => LoginViewStage.signUpWithEmailCode,
          };

          try {
            await _authService.createConfirmationCode(email: email);
            s.unsubmit();
          } on AddUserEmailException catch (e) {
            s.error.value = e.toMessage();
            _setResendEmailTimer(false);

            stage.value = previous;
          } catch (_) {
            s.resubmitOnError.value = true;
            s.error.value = 'err_data_transfer'.l10n;
            _setResendEmailTimer(false);
            s.unsubmit();

            stage.value = previous;
            rethrow;
          }
        }
      },
    );

    emailCode = TextFieldState(
      onSubmitted: (s) async {
        s.status.value = RxStatus.loading();

        try {
          UserLogin? userLogin;
          UserNum? userNum;
          UserEmail? userEmail;
          UserPhone? userPhone;

          switch (stage.value) {
            case LoginViewStage.signUpWithEmailCode:
              userEmail = UserEmail.tryParse(email.text);
              break;

            default:
              userLogin = UserLogin.tryParse(identifier.text);
              userNum = UserNum.tryParse(identifier.text);
              userEmail = UserEmail.tryParse(identifier.text);
              userPhone = UserPhone.tryParse(identifier.text);
              break;
          }

          await _authService.signIn(
            email: userEmail,
            login: userLogin,
            num: userNum,
            phone: userPhone,
            code: ConfirmationCode(emailCode.text),
          );

          (onSuccess ?? router.home)(signedUp: true);
        } on CreateSessionException catch (e) {
          switch (e.code) {
            case CreateSessionErrorCode.wrongCode:
              s.error.value = e.toMessage();

              ++codeAttempts;
              if (codeAttempts >= 3) {
                codeAttempts = 0;
                _setCodeTimer();
              }
              s.status.value = RxStatus.empty();
              break;

            default:
              s.error.value = 'err_wrong_code'.l10n;
              break;
          }
        } on FormatException catch (_) {
          s.error.value = 'err_wrong_code'.l10n;
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

    identifier = TextFieldState(
      onSubmitted: (s) async {
        final UserLogin? userLogin = UserLogin.tryParse(s.text);
        final UserNum? userNum = UserNum.tryParse(s.text);
        final UserEmail? userEmail = UserEmail.tryParse(s.text);
        final UserPhone? userPhone = UserPhone.tryParse(s.text);

        emailCode.clear();

        final LoginViewStage previous = stage.value;

        stage.value = switch (stage.value) {
          LoginViewStage.signInWithEmail => LoginViewStage.signInWithEmailCode,
          (_) => LoginViewStage.signUpWithEmailCode,
        };

        _setResendEmailTimer();

        try {
          if (userLogin != null ||
              userNum != null ||
              userEmail != null ||
              userPhone != null) {
            await _authService.createConfirmationCode(
              email: userEmail,
              login: userLogin,
              num: userNum,
              phone: userPhone,
            );
          }

          s.unsubmit();
        } on AddUserEmailException catch (e) {
          s.error.value = e.toMessage();
          _setResendEmailTimer(false);

          stage.value = previous;
        } catch (_) {
          s.resubmitOnError.value = true;
          s.error.value = 'err_data_transfer'.l10n;
          _setResendEmailTimer(false);
          s.unsubmit();

          stage.value = previous;
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

    final bool noCredentials =
        userLogin == null &&
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

      final bool authorized = _authService.isAuthorized();

      await _authService.signIn(
        password: userPassword,
        login: userLogin,
        num: userNum,
        email: userEmail,
        phone: userPhone,
        force: authorized,
      );

      if (onSuccess != null) {
        onSuccess?.call();
      } else {
        // TODO: This is a hack that should be removed, as whenever the account
        //       is changed, the [HomeView] and its dependencies must be
        //       rebuilt, which may take some unidentifiable amount of time as
        //       of now.
        if (authorized) {
          router.nowhere();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        router.home();
      }
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
  Future<void> register({UserPassword? password, UserLogin? login}) async {
    try {
      await _authService.register(password: password, login: login);
      (onSuccess ?? router.home)();
    } on SignUpException catch (e) {
      this.login.error.value = e.toMessage();
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
      if (_recoveryLogin != null ||
          _recoveryNum != null ||
          _recoveryEmail != null ||
          _recoveryPhone != null) {
        await _authService.createConfirmationCode(
          login: _recoveryLogin,
          num: _recoveryNum,
          email: _recoveryEmail,
          phone: _recoveryPhone,
          locale: L10n.chosen.value?.toString(),
        );
      }

      stage.value = LoginViewStage.recoveryCode;
      recovery.status.value = RxStatus.success();
      recovery.editable.value = false;
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
      await _authService.validateConfirmationCode(
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
      recoveryCode.error.value = 'err_wrong_code'.l10n;
    } on ArgumentError {
      recoveryCode.error.value = 'err_wrong_code'.l10n;
    } on ValidateConfirmationCodeException catch (e) {
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
    if (newPassword.error.value != null ||
        repeatPassword.error.value != null ||
        recoveryCode.error.value != null) {
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
      await _authService.updateUserPassword(
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
    } on UpdateUserPasswordException catch (e) {
      switch (e.code) {
        case UpdateUserPasswordErrorCode.wrongOldPassword:
          repeatPassword.error.value = 'err_wrong_password'.l10n;
        case UpdateUserPasswordErrorCode.wrongCode:
          recoveryCode.error.value = 'err_wrong_code'.l10n;
        case UpdateUserPasswordErrorCode.confirmationRequired:
          repeatPassword.error.value = 'err_data_transfer'.l10n;
        case UpdateUserPasswordErrorCode.artemisUnknown:
          repeatPassword.error.value = 'err_unknown'.l10n;
      }
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
      switch (stage.value) {
        case LoginViewStage.signInWithEmailCode:
          final UserLogin? userLogin = UserLogin.tryParse(identifier.text);
          final UserNum? userNum = UserNum.tryParse(identifier.text);
          final UserEmail? userEmail = UserEmail.tryParse(identifier.text);
          final UserPhone? userPhone = UserPhone.tryParse(identifier.text);

          if (userLogin != null ||
              userNum != null ||
              userEmail != null ||
              userPhone != null) {
            await _authService.createConfirmationCode(
              email: userEmail,
              login: userLogin,
              num: userNum,
              phone: userPhone,
            );
          }
          break;

        default:
          await _authService.createConfirmationCode(
            email: UserEmail(email.text),
          );
          break;
      }
    } on AddUserEmailException catch (e) {
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
      password.submittable.value = false;
      signInTimeout.value = 30;
      _signInTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        signInTimeout.value--;
        if (signInTimeout.value <= 0) {
          password.submittable.value = true;
          signInTimeout.value = 0;
          _signInTimer?.cancel();
          _signInTimer = null;
        }
      });
    } else {
      password.submittable.value = true;
      signInTimeout.value = 0;
      _signInTimer?.cancel();
      _signInTimer = null;
    }
  }

  /// Starts or stops the [_resendEmailTimer] based on [enabled] value.
  void _setResendEmailTimer([bool enabled = true]) {
    if (enabled) {
      resendEmailTimeout.value = 30;
      _resendEmailTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        resendEmailTimeout.value--;
        if (resendEmailTimeout.value <= 0) {
          resendEmailTimeout.value = 0;
          _resendEmailTimer?.cancel();
          _resendEmailTimer = null;
        }
      });
    } else {
      resendEmailTimeout.value = 0;
      _resendEmailTimer?.cancel();
      _resendEmailTimer = null;
    }
  }

  /// Starts or stops the [_codeTimer] based on [enabled] value.
  void _setCodeTimer([bool enabled = true]) {
    if (enabled) {
      emailCode.submittable.value = false;
      codeTimeout.value = 30;
      _codeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        codeTimeout.value--;
        if (codeTimeout.value <= 0) {
          emailCode.submittable.value = true;
          codeTimeout.value = 0;
          _codeTimer?.cancel();
          _codeTimer = null;
        }
      });
    } else {
      emailCode.submittable.value = true;
      codeTimeout.value = 0;
      _codeTimer?.cancel();
      _codeTimer = null;
    }
  }
}
