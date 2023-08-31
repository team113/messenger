// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import '../../../api/backend/schema.graphql.dart';
import '../../../domain/model/session.dart';
import '../../../provider/gql/graphql.dart';
import '../../widget/phone_field.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        AddUserEmailException,
        AddUserPhoneException,
        ConfirmUserEmailException,
        ConfirmUserPhoneException,
        ConnectionException,
        CreateSessionException,
        ResendUserEmailConfirmationException,
        ResendUserPhoneConfirmationException,
        ResetUserPasswordException,
        ValidateUserPasswordRecoveryCodeException;
import '/routes.dart';
import '/ui/widget/text_field.dart';

/// Possible [LoginView] flow stage.
enum LoginViewStage {
  oauth,
  oauthOccupied,
  oauthNoUser,
  recovery,
  recoveryCode,
  recoveryPassword,
  signIn,
  signInWithCode,
  signInWithPassword,
  signInWithEmail,
  signInWithEmailCode,
  signInWithEmailOccupied,
  signInWithPhone,
  signInWithPhoneCode,
  signInWithPhoneOccupied,
  signInWithQrScan,
  signInWithQrShow,
  signUp,
  signUpWithEmail,
  signUpWithEmailCode,
  signUpWithEmailOccupied,
  signUpWithPhone,
  signUpWithPhoneCode,
  signUpWithPhoneOccupied,
  noPassword,
  noPasswordCode,
  choice,
}

extension on LoginViewStage {
  bool get registering => switch (this) {
        LoginViewStage.signIn ||
        LoginViewStage.signInWithPassword ||
        LoginViewStage.signInWithEmail ||
        LoginViewStage.signInWithEmailCode ||
        LoginViewStage.signInWithEmailOccupied ||
        LoginViewStage.signInWithPhone ||
        LoginViewStage.signInWithPhoneCode ||
        LoginViewStage.signInWithPhoneOccupied ||
        LoginViewStage.signInWithQrScan ||
        LoginViewStage.signInWithQrShow =>
          false,
        (_) => true,
      };
}

/// [GetxController] of a [LoginView].
class LoginController extends GetxController {
  LoginController(
    this._auth, {
    LoginViewStage stage = LoginViewStage.signUp,
    this.onAuth,
  }) : stage = Rx(stage);

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

  final void Function()? onAuth;
  LoginViewStage? backStage;

  int signInAttempts = 0;
  final RxInt signInTimeout = RxInt(0);
  Timer? _signInTimer;

  int codeAttempts = 0;
  final RxInt codeTimeout = RxInt(0);
  Timer? _codeTimer;

  Credentials? creds;

  late final TextFieldState email = TextFieldState(
    revalidateOnUnfocus: true,
    onChanged: (s) {
      try {
        if (s.text.isNotEmpty) {
          UserEmail(s.text.toLowerCase());
        }

        s.error.value = null;
      } on FormatException {
        s.error.value = 'err_incorrect_email'.l10n;
      }
    },
    onSubmitted: (s) async {
      if (s.error.value != null) {
        return;
      }

      stage.value = stage.value.registering
          ? LoginViewStage.signUpWithEmailCode
          : LoginViewStage.signInWithEmailCode;

      final GraphQlProvider graphQlProvider = Get.find();

      try {
        final response = await graphQlProvider.signUp();

        creds = Credentials(
          Session(
            response.createUser.session.token,
            response.createUser.session.expireAt,
          ),
          RememberedSession(
            response.createUser.remembered!.token,
            response.createUser.remembered!.expireAt,
          ),
          response.createUser.user.id,
        );

        graphQlProvider.token = creds!.session.token;
        await graphQlProvider.addUserEmail(UserEmail(email.text));
        graphQlProvider.token = null;

        s.unsubmit();
      } on AddUserEmailException catch (e) {
        graphQlProvider.token = null;
        s.error.value = e.toMessage();
        _setResendEmailTimer(false);

        stage.value = stage.value.registering
            ? LoginViewStage.signUpWithEmail
            : LoginViewStage.signInWithEmail;
      } catch (e) {
        graphQlProvider.token = null;
        s.error.value = 'err_data_transfer'.l10n;
        _setResendEmailTimer(false);
        s.unsubmit();

        stage.value = stage.value.registering
            ? LoginViewStage.signUpWithEmail
            : LoginViewStage.signInWithEmail;

        rethrow;
      }
    },
  );
  late final TextFieldState emailCode = TextFieldState(
    revalidateOnUnfocus: true,
    onSubmitted: (s) async {
      final GraphQlProvider graphQlProvider = Get.find();

      try {
        if (!stage.value.registering && s.text == '2222') {
          throw const ConfirmUserEmailException(
            ConfirmUserEmailErrorCode.occupied,
          );
        }

        graphQlProvider.token = creds!.session.token;
        await graphQlProvider.confirmEmailCode(ConfirmationCode(s.text));

        await _auth.authorizeWith(creds!);

        router.noIntroduction = false;
        router.signUp = true;
        _redirect();
      } on ConfirmUserEmailException catch (e) {
        switch (e.code) {
          case ConfirmUserEmailErrorCode.occupied:
            stage.value = stage.value.registering
                ? LoginViewStage.signUpWithEmailOccupied
                : LoginViewStage.signInWithEmailOccupied;
            break;

          case ConfirmUserEmailErrorCode.wrongCode:
            graphQlProvider.token = null;
            s.error.value = e.toMessage();

            ++codeAttempts;
            if (codeAttempts >= 3) {
              codeAttempts = 0;
              _setCodeTimer();
            }
            break;

          default:
            s.error.value = 'err_wrong_recovery_code'.l10n;
            break;
        }
      } on FormatException catch (_) {
        graphQlProvider.token = null;
        s.error.value = 'err_wrong_recovery_code'.l10n;

        ++codeAttempts;
        if (codeAttempts >= 3) {
          codeAttempts = 0;
          _setCodeTimer();
        }
      } catch (_) {
        graphQlProvider.token = null;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
      }
    },
  );
  late final PhoneFieldState phone = PhoneFieldState(
    revalidateOnUnfocus: true,
    onChanged: (s) {
      try {
        if (!s.isEmpty.value) {
          UserPhone(s.phone!.international);

          if (!s.phone!.isValid()) {
            throw const FormatException('Does not match validation RegExp');
          }
        }

        s.error.value = null;
      } on FormatException {
        s.error.value = 'err_incorrect_phone'.l10n;
      }
    },
    onSubmitted: (s) async {
      if (s.error.value != null) {
        return;
      }

      stage.value = stage.value.registering
          ? LoginViewStage.signUpWithPhoneCode
          : LoginViewStage.signInWithPhoneCode;

      final GraphQlProvider graphQlProvider = Get.find();

      try {
        final response = await graphQlProvider.signUp();

        creds = Credentials(
          Session(
            response.createUser.session.token,
            response.createUser.session.expireAt,
          ),
          RememberedSession(
            response.createUser.remembered!.token,
            response.createUser.remembered!.expireAt,
          ),
          response.createUser.user.id,
        );

        graphQlProvider.token = creds!.session.token;
        await graphQlProvider.addUserPhone(
          UserPhone(phone.controller2.value!.international.toLowerCase()),
        );
        graphQlProvider.token = null;

        s.unsubmit();
      } on AddUserPhoneException catch (e) {
        graphQlProvider.token = null;
        s.error.value = e.toMessage();
        stage.value = stage.value.registering
            ? LoginViewStage.signUpWithPhone
            : LoginViewStage.signInWithPhone;
      } catch (_) {
        graphQlProvider.token = null;
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
        stage.value = stage.value.registering
            ? LoginViewStage.signUpWithPhone
            : LoginViewStage.signInWithPhone;
      }

      stage.value = stage.value.registering
          ? LoginViewStage.signUpWithPhoneCode
          : LoginViewStage.signInWithPhoneCode;
    },
  );

  late final TextFieldState phoneCode = TextFieldState(
    revalidateOnUnfocus: true,
    onSubmitted: (s) async {
      try {
        if (ConfirmationCode(s.text).val == '1111') {
          if (stage.value.registering) {
            await _auth.authorizeWith(creds!);
            router.noIntroduction = false;
            router.signUp = true;
            _redirect();
          }
        } else if (ConfirmationCode(s.text).val == '2222') {
          throw const ConfirmUserPhoneException(
            ConfirmUserPhoneErrorCode.occupied,
          );
        } else {
          throw const ConfirmUserPhoneException(
            ConfirmUserPhoneErrorCode.wrongCode,
          );
        }
      } on ConfirmUserPhoneException catch (e) {
        switch (e.code) {
          case ConfirmUserPhoneErrorCode.occupied:
            stage.value = stage.value.registering
                ? LoginViewStage.signUpWithPhoneOccupied
                : LoginViewStage.signInWithPhoneOccupied;
            break;

          case ConfirmUserPhoneErrorCode.wrongCode:
            s.error.value = e.toMessage();

            ++codeAttempts;
            if (codeAttempts >= 3) {
              codeAttempts = 0;
              _setCodeTimer();
            }
            break;

          default:
            s.error.value = 'err_wrong_recovery_code'.l10n;
            break;
        }
      } on FormatException catch (_) {
        s.error.value = 'err_wrong_recovery_code'.l10n;

        ++codeAttempts;
        if (codeAttempts >= 3) {
          codeAttempts = 0;
          _setCodeTimer();
        }
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
        s.unsubmit();
      }
    },
  );

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
      onSubmitted: (s) => password.focus.requestFocus(),
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

  /// Signs in and redirects to the [Routes.home] page.
  ///
  /// Username is [login]'s text and the password is [password]'s text.
  Future<void> signIn() async {
    UserLogin? userLogin;
    UserNum? num;
    UserEmail? email;
    UserPhone? phone;

    login.error.value = null;
    password.error.value = null;

    if (login.text.isEmpty) {
      login.error.value = 'err_account_not_found'.l10n;
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
      password.error.value = 'err_password_empty'.l10n;
      return;
    }

    if (userLogin == null && num == null && email == null && phone == null) {
      login.error.value = 'err_account_not_found'.l10n;
      return;
    }

    try {
      login.status.value = RxStatus.loading();
      password.status.value = RxStatus.loading();
      await _auth.signIn(
        UserPassword(password.text),
        login: userLogin,
        num: num,
        email: email,
        phone: phone,
      );

      router.home();
    } on FormatException {
      password.error.value = 'err_incorrect_password'.l10n;
    } on CreateSessionException catch (e) {
      switch (e.code) {
        case CreateSessionErrorCode.wrongPassword:
          password.error.value = e.toMessage();
          break;

        case CreateSessionErrorCode.artemisUnknown:
          password.error.value = 'err_data_transfer'.l10n;
          rethrow;
      }
    } on ConnectionException {
      password.unsubmit();
      password.error.value = 'err_data_transfer'.l10n;
    } catch (e) {
      password.unsubmit();
      password.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      login.status.value = RxStatus.empty();
      password.status.value = RxStatus.empty();
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

      stage.value = LoginViewStage.recoveryCode;
      recovery.status.value = RxStatus.success();
      recovery.editable.value = false;
    } on FormatException {
      recovery.error.value = 'err_account_not_found'.l10n;
    } on ArgumentError {
      recovery.error.value = 'err_account_not_found'.l10n;
    } catch (e) {
      recovery.unsubmit();
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
      await _auth.validateUserPasswordRecoveryCode(
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

    try {
      UserPassword(newPassword.text);
    } catch (e) {
      newPassword.error.value = 'err_incorrect_input'.l10n;
      return;
    }

    try {
      UserPassword(repeatPassword.text);
    } catch (e) {
      repeatPassword.error.value = 'err_incorrect_input'.l10n;
      return;
    }

    if (newPassword.text != repeatPassword.text) {
      repeatPassword.error.value = 'err_passwords_mismatch'.l10n;
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

      recovered.value = true;
      stage.value = LoginViewStage.signIn;
    } on FormatException {
      repeatPassword.error.value = 'err_incorrect_input'.l10n;
    } on ArgumentError {
      repeatPassword.error.value = 'err_incorrect_input'.l10n;
    } on ResetUserPasswordException catch (e) {
      repeatPassword.error.value = e.toMessage();
    } catch (e) {
      repeatPassword.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      repeatPassword.status.value = RxStatus.empty();
      newPassword.editable.value = true;
      repeatPassword.editable.value = true;
    }
  }

  /// Timeout of a [resendEmail].
  final RxInt resendEmailTimeout = RxInt(0);

  /// [Timer] decreasing the [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Starts or stops the [_resendEmailTimer] based on [enabled] value.
  void _setSignInTimer([bool enabled = true]) {
    if (enabled) {
      signInTimeout.value = 30;
      _signInTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          signInTimeout.value--;
          if (signInTimeout.value <= 0) {
            signInTimeout.value = 0;
            _signInTimer?.cancel();
            _signInTimer = null;
          }
        },
      );
    } else {
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

  void _setCodeTimer([bool enabled = true]) {
    if (enabled) {
      codeTimeout.value = 30;
      _codeTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          codeTimeout.value--;
          if (codeTimeout.value <= 0) {
            codeTimeout.value = 0;
            _codeTimer?.cancel();
            _codeTimer = null;
          }
        },
      );
    } else {
      codeTimeout.value = 0;
      _codeTimer?.cancel();
      _codeTimer = null;
    }
  }

  /// Resends a [ConfirmationCode] to the specified [email].
  Future<void> resendEmail() async {
    resent.value = true;
    _setResendEmailTimer();

    try {
      final GraphQlProvider graphQlProvider = Get.find();

      if (stage.value.registering) {
        graphQlProvider.token = creds!.session.token;
        await graphQlProvider.resendEmail();
        graphQlProvider.token = null;
      }
    } on ResendUserEmailConfirmationException catch (e) {
      emailCode.error.value = e.toMessage();
    } catch (e) {
      emailCode.error.value = 'err_data_transfer'.l10n;
      resent.value = false;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Timeout of a [resendPhone].
  final RxInt resendPhoneTimeout = RxInt(0);

  /// [Timer] decreasing the [resendPhoneTimeout].
  Timer? _resendPhoneTimer;

  /// Starts or stops the [_resendPhoneTimer] based on [enabled] value.
  void _setResendPhoneTimer([bool enabled = true]) {
    if (enabled) {
      resendPhoneTimeout.value = 30;
      _resendPhoneTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          resendPhoneTimeout.value--;
          if (resendPhoneTimeout.value <= 0) {
            resendPhoneTimeout.value = 0;
            _resendPhoneTimer?.cancel();
            _resendPhoneTimer = null;
          }
        },
      );
    } else {
      resendPhoneTimeout.value = 0;
      _resendPhoneTimer?.cancel();
      _resendPhoneTimer = null;
    }
  }

  Future<void> resendPhone() async {
    resent.value = true;
    _setResendPhoneTimer();

    try {
      final GraphQlProvider graphQlProvider = Get.find();

      if (stage.value.registering) {
        graphQlProvider.token = creds!.session.token;
        await graphQlProvider.resendPhone();
        graphQlProvider.token = null;
      }
    } on ResendUserPhoneConfirmationException catch (e) {
      phoneCode.error.value = e.toMessage();
    } catch (e) {
      phoneCode.error.value = 'err_data_transfer'.l10n;
      resent.value = false;
      _setResendPhoneTimer(false);
      rethrow;
    }
  }

  void _redirect() {
    (onAuth ?? router.home).call();
  }
}
