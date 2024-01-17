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

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http_parser/http_parser.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/ui/widget/phone_field.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/mime.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '/api/backend/schema.dart'
    show
        ConfirmUserEmailErrorCode,
        ConfirmUserPhoneErrorCode,
        CreateSessionErrorCode;
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
  signUpOrSignIn,
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
    this._authService, {
    LoginViewStage initial = LoginViewStage.signUp,
    this.onSuccess,
  }) : stage = Rx(initial);

  /// Callback, called when this [LoginController] successfully signs into an
  /// account.
  ///
  /// If not specified, the [RouteLinks.home] redirect is invoked.
  final void Function()? onSuccess;

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

  final RxList<Barcode> barcodes = RxList();
  final GlobalKey scannerKey = GlobalKey();

  LoginViewStage? backStage;

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
      print(s.error.value);

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

        await _authService.authorizeWith(creds!);

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

  Credentials? creds;

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
            await _authService.authorizeWith(creds!);
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

  int signInAttempts = 0;
  final RxInt signInTimeout = RxInt(0);
  Timer? _signInTimer;

  int codeAttempts = 0;
  final RxInt codeTimeout = RxInt(0);
  Timer? _codeTimer;

  /// Indicator whether [UserEmail] confirmation code has been resent.
  /// Authentication service providing the authentication capabilities.
  final AuthService _authService;

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
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) => password.focus.requestFocus(),
    );

    password = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
      },
      onSubmitted: (s) => signIn(),
      revalidateOnUnfocus: true,
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

        if (s.text != newPassword.text && newPassword.isValidated) {
          s.error.value = 'err_passwords_mismatch'.l10n;
        }
      },
      onSubmitted: (s) => stage.value == LoginViewStage.signUp
          ? register()
          : resetUserPassword(),
    );

    super.onInit();
  }

  @override
  void onClose() {
    _setSignInTimer(false);
    _setResendEmailTimer(false);
    _setCodeTimer(false);
    super.onClose();
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
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
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
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    if (userLogin == null && num == null && email == null && phone == null) {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    try {
      login.status.value = RxStatus.loading();
      password.status.value = RxStatus.loading();

      print('!!!!! Here1: ${_authService.credentials.value}');

      await _authService.signIn(
        UserPassword(password.text),
        login: userLogin,
        num: num,
        email: email,
        phone: phone,
      );

      print('!!!!! Here2: ${_authService.credentials.value}');

      // _redirect();
    } on FormatException {
      password.error.value = 'err_incorrect_login_or_password'.l10n;
    } on CreateSessionException catch (e) {
      switch (e.code) {
        case CreateSessionErrorCode.wrongPassword:
          ++signInAttempts;

          if (signInAttempts >= 3) {
            // Трижды указан/введён неверный пароль. Вход возможен через Н секунд.
            signInAttempts = 0;
            _setSignInTimer();
          }

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
      repeatPassword.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      repeatPassword.status.value = RxStatus.empty();
      newPassword.editable.value = true;
      repeatPassword.editable.value = true;
    }
  }

  /// Registers and redirects to the [Routes.home] page.
  Future<void> oneTime() async {
    try {
      await _authService.register();
      _redirect();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  Future<void> register() async {
    await _authService.register();
    router.validateEmail = true;
    _redirect();

    while (!Get.isRegistered<MyUserService>()) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final MyUserService myUserService = Get.find();
    await myUserService.addUserEmail(UserEmail(email.text));
    await myUserService.updateUserPassword(
      newPassword: UserPassword(repeatPassword.text),
    );
  }

  Future<void> signInWithoutPassword() async {
    stage.value = LoginViewStage.noPasswordCode;
    recoveryCode.clear();
  }

  Future<void> signInWithCode(String code) async {}

  bool isEmailOrPhone(String text) {
    try {
      UserEmail(text);
      return true;
    } catch (_) {
      try {
        UserPhone(text);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  LoginViewStage fallbackStage = LoginViewStage.signUp;

  Future<void> continueWithGoogle() async {
    fallbackStage = stage.value;
    oAuthProvider = OAuthProvider.google;
    stage.value = LoginViewStage.oauth;

    if (kDebugMode) {
      try {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');

        final auth = FirebaseAuth.instanceFor(app: router.firebase!);

        if (PlatformUtils.isWeb) {
          credential = await auth.signInWithPopup(googleProvider);
        } else {
          credential = await auth.signInWithProvider(googleProvider);
        }

        await registerWithCredentials(credential!);
      } catch (_) {
        stage.value = fallbackStage;
      }

      return;
    }

    try {
      final googleUser =
          await GoogleSignIn(clientId: Config.googleClientId).signIn();

      final googleAuth = await googleUser?.authentication;

      if (googleAuth != null) {
        final creds = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final auth = FirebaseAuth.instanceFor(app: router.firebase!);

        credential = await auth.signInWithCredential(creds);

        await registerWithCredentials(credential!);
      }
    } catch (_) {
      stage.value = fallbackStage;
    }
  }

  UserCredential? credential;
  OAuthProvider? oAuthProvider;

  Future<void> continueWithApple() async {
    fallbackStage = stage.value;
    oAuthProvider = OAuthProvider.apple;
    stage.value = LoginViewStage.oauth;

    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');

      final auth = FirebaseAuth.instanceFor(app: router.firebase!);

      if (PlatformUtils.isWeb) {
        credential = await auth.signInWithPopup(appleProvider);
      } else {
        credential = await auth.signInWithProvider(appleProvider);
      }

      await registerWithCredentials(credential!);
    } catch (_) {
      stage.value = fallbackStage;
    }
  }

  Future<void> continueWithGitHub() async {
    fallbackStage = stage.value;
    oAuthProvider = OAuthProvider.github;
    stage.value = LoginViewStage.oauth;

    try {
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('email');

      final auth = FirebaseAuth.instanceFor(app: router.firebase!);

      if (PlatformUtils.isWeb) {
        credential = await auth.signInWithPopup(githubProvider);
      } else {
        credential = await auth.signInWithProvider(githubProvider);
      }

      await registerWithCredentials(credential!);
    } catch (_) {
      stage.value = fallbackStage;
    }
  }

  Future<void> registerWithCredentials(
    UserCredential credential, [
    bool ignore = false,
  ]) async {
    print(
      '[OAuth] Registering with the provided `UserCredential`:\n\n$credential\n\n',
    );

    if (!ignore) {
      if (fallbackStage == LoginViewStage.signUp &&
          credential.additionalUserInfo?.isNewUser == false) {
        stage.value = LoginViewStage.oauthOccupied;
        return;
      } else if (fallbackStage == LoginViewStage.signIn &&
          (credential.additionalUserInfo?.isNewUser == true || true)) {
        stage.value = LoginViewStage.oauthNoUser;
        return;
      }
    }

    await _authService.register();
    router.directLink = false;
    router.validateEmail = false;
    router.noIntroduction = false;
    router.signUp = true;
    _redirect();

    while (!Get.isRegistered<MyUserService>()) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final MyUserService myUserService = Get.find();

    if (credential.user?.displayName != null) {
      try {
        await myUserService
            .updateUserName(UserName(credential.user!.displayName!));
      } catch (e) {
        print('[OAuth] Unable to `updateUserName`: ${e.toString()}');
      }
    }

    if (credential.user?.email != null) {
      try {
        await myUserService.addUserEmail(UserEmail(credential.user!.email!));
      } catch (e) {
        print('[OAuth] Unable to `addUserEmail`: ${e.toString()}');
      }
    }

    if (credential.user?.phoneNumber != null) {
      try {
        await myUserService
            .addUserPhone(UserPhone(credential.user!.phoneNumber!));
      } catch (e) {
        print('[OAuth] Unable to `addUserPhone`: ${e.toString()}');
      }
    }

    if (credential.user?.photoURL != null) {
      try {
        final Response data = await (await PlatformUtils.dio).get(
          credential.user!.photoURL!,
          options: Options(responseType: ResponseType.bytes),
        );

        if (data.data != null && data.statusCode == 200) {
          var type = MimeResolver.lookup(
            '${DateTime.now()}.jpg',
            headerBytes: data.data,
          );

          final file = NativeFile(
            name: '${DateTime.now()}.jpg',
            size: (data.data as Uint8List).length,
            bytes: data.data,
            mime: type != null ? MediaType.parse(type) : null,
          );

          await myUserService.updateAvatar(file);
          await myUserService.updateCallCover(file);
        }
      } catch (e) {
        print('[OAuth] Unable to `updateAvatar`: ${e.toString()}');
      }
    }
  }

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

  /// Timeout of a [resendEmail].
  final RxInt resendEmailTimeout = RxInt(0);

  /// [Timer] decreasing the [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

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

  Future<void> registerOccupied() async {
    final GraphQlProvider graphQlProvider = Get.find();

    graphQlProvider.token = creds!.session.token;

    if (stage.value == LoginViewStage.signInWithEmailOccupied) {
      // await graphQlProvider.confirmEmailCode(ConfirmationCode(emailCode.text));
    } else if (stage.value == LoginViewStage.signInWithPhoneOccupied) {}

    await _authService.authorizeWith(creds!);

    router.noIntroduction = false;
    router.signUp = true;
    _redirect();
  }

  void _redirect() {
    (onSuccess ?? router.home).call();
  }
}

enum OAuthProvider {
  apple,
  google,
  github,
}
