// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart';
import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/auth.dart';
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/web/web_utils.dart';

/// Page to display in an [IntroductionView].
enum IntroductionStage {
  accountCreated,
  accountCreating,
  guestCreated,
  language,
  recovery,
  recoveryCode,
  recoveryPassword,
  signIn,
  signInAs,
  signInWithEmail,
  signInWithEmailCode,
  signInWithPassword,
}

/// Controller of an [IntroductionView].
class IntroductionController extends GetxController with IdentityAware {
  IntroductionController(
    this._authService,
    this._myUserService,
    this._chatService,
  );

  /// Opacity of the displayed [IntroductionView].
  final RxDouble opacity = RxDouble(0.5);

  /// [GlobalKey] of a panel to prevent it from rebuilding.
  final GlobalKey positionedKey = GlobalKey();

  /// [GlobalKey] of the whole overlay to prevent it from rebuilding.
  final GlobalKey stackKey = GlobalKey();

  /// [IntroductionStage] currently displayed.
  final Rx<IntroductionStage?> page = Rx(null);

  /// Timeout of a [signIn] next invoke attempt.
  final RxInt signInTimeout = RxInt(0);

  /// Timeout of a [emailCode] next submit attempt.
  final RxInt codeTimeout = RxInt(0);

  /// Timeout of a [resendEmail] next invoke attempt.
  final RxInt resendEmailTimeout = RxInt(0);

  /// Amount of [signIn] unsuccessful submitting attempts.
  int signInAttempts = 0;

  /// Amount of [emailCode] unsuccessful submitting attempts.
  int codeAttempts = 0;

  /// Previous [IntroductionStage].
  IntroductionStage? previousPage;

  /// Indicator whether [chat] is being fetched, in case [Routes.chatDirectLink]
  /// is the initial route.
  final RxBool fetching = RxBool(false);

  /// [RxChat] of a [Routes.chatDirectLink] initial route.
  final Rx<RxChat?> chat = Rx(null);

  /// [MyUser] to complete sign in information as.
  MyUser? signInAs;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [recoveryPassword] should be obscured.
  final RxBool obscureNewPassword = RxBool(true);

  /// Indicator whether the [repeatPassword] should be obscured.
  final RxBool obscureRepeatPassword = RxBool(true);

  /// Indicator whether the [emailCode] should be obscured.
  final RxBool obscureCode = RxBool(true);

  /// [MyUser.name] field state.
  late final TextFieldState name = TextFieldState(
    text: myUser.value?.name?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserName? name = UserName.tryParse(s.text);

      try {
        await _myUserService.updateUserName(name);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// [TextFieldState] of a login text input.
  late final TextFieldState login = TextFieldState(
    onChanged: (_) {
      login.error.value = null;
      password.error.value = null;
      password.unsubmit();
      repeatPassword.unsubmit();
    },
    onSubmitted: (s) {
      password.focus.requestFocus();
      s.unsubmit();
    },
  );

  /// [TextFieldState] of a password text input.
  late final TextFieldState password = TextFieldState(
    onFocus: (s) => s.unsubmit(),
    onChanged: (_) {
      login.error.value = null;
      password.error.value = null;
      password.unsubmit();
      repeatPassword.error.value = null;
      repeatPassword.unsubmit();
    },
    onSubmitted: (s) async {
      switch (page.value) {
        case IntroductionStage.signInWithPassword:
          await signIn();
          break;

        case IntroductionStage.accountCreating:
          repeatPassword.focus.requestFocus();
          break;

        default:
          // No-op.
          break;
      }
    },
  );

  /// [TextFieldState] of a repeat password text input.
  late final TextFieldState repeatPassword = TextFieldState(
    onFocus: (s) {
      password.error.value = null;

      if (s.text != password.text && password.isValidated) {
        s.error.value = 'err_passwords_mismatch'.l10n;
      }
    },
    onSubmitted: (s) async {
      switch (page.value) {
        case IntroductionStage.accountCreating:
          await createAccount();
          break;

        default:
          // No-op.
          break;
      }
    },
  );

  /// [TextFieldState] for an [UserEmail] text input.
  late final TextFieldState email = TextFieldState(
    onFocus: (s) {},
    onSubmitted: (s) async {
      final UserEmail? email = UserEmail.tryParse(s.text.toLowerCase());
      final UserLogin? login = UserLogin.tryParse(s.text.toLowerCase());
      final UserNum? userNum = UserNum.tryParse(s.text.toLowerCase());

      emailCode.clear();

      final IntroductionStage? previous = page.value;

      page.value = switch (page.value) {
        IntroductionStage.signInWithEmail =>
          IntroductionStage.signInWithEmailCode,
        (_) => IntroductionStage.signIn,
      };

      try {
        _setResendEmailTimer();

        // Simulate like everything's alright despite not sending anything.
        if (login != null || userNum != null || email != null) {
          await _authService.createConfirmationCode(
            email: email,
            login: login,
            num: userNum,
          );
        }

        s.unsubmit();
      } on AddUserEmailException catch (e) {
        s.error.value = e.toMessage();
        _setResendEmailTimer(false);

        page.value = previous;
      } catch (_) {
        s.resubmitOnError.value = true;
        s.error.value = 'err_data_transfer'.l10n;
        _setResendEmailTimer(false);
        s.unsubmit();

        page.value = previous;
        rethrow;
      }
    },
  );

  /// [TextFieldState] of a [ConfirmationCode] for [email].
  late final TextFieldState emailCode = TextFieldState(
    onSubmitted: (s) async {
      s.status.value = RxStatus.loading();
      try {
        final bool authorized = _authService.isAuthorized();

        await _authService.signIn(
          email: UserEmail(email.text),
          code: ConfirmationCode(emailCode.text),
          force: true,
          // removeAfterwards: userId,
        );

        // TODO: This is a hack that should be removed, as whenever the account
        //       is changed, the [HomeView] and its dependencies must be
        //       rebuilt, which may take some unidentifiable amount of time as
        //       of now.
        if (authorized) {
          router.nowhere();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        router.home(signedUp: true);
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

  /// [TextFieldState] of a [UserName] for registered account.
  late final TextFieldState signUpName = TextFieldState(
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }
    },
  );

  /// [TextFieldState] of a [UserLogin] for registered account.
  late final TextFieldState signUpLogin = TextFieldState(
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserLogin(s.text.toLowerCase());
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }
    },
  );

  /// [TextFieldState] of a [UserEmail] for registered account.
  late final TextFieldState signUpEmail = TextFieldState(
    onFocus: (s) {
      if (s.text.trim().isNotEmpty) {
        try {
          UserEmail(s.text);
        } catch (e) {
          s.error.value = 'err_incorrect_email'.l10n;
        }
      }
    },
  );

  /// [TextFieldState] of a recovery text input.
  late final TextFieldState recoveryIdentifier = TextFieldState(
    onSubmitted: (s) => recoverAccess(),
  );

  /// [TextFieldState] of a recovery code text input.
  late final TextFieldState recoveryCode = TextFieldState(
    onSubmitted: (s) => validateCode(),
  );

  /// [TextFieldState] of a new password text input for [resetUserPassword].
  late final TextFieldState recoveryPassword = TextFieldState(
    onChanged: (_) {
      recoveryRepeatPassword.error.value = null;
      recoveryRepeatPassword.unsubmit();
    },
    onSubmitted: (s) {
      recoveryRepeatPassword.focus.requestFocus();
      s.unsubmit();
    },
  );

  /// [TextFieldState] of a repeat password text input for [resetUserPassword].
  late final TextFieldState recoveryRepeatPassword = TextFieldState(
    onChanged: (s) {
      if (s.text != recoveryPassword.text && recoveryPassword.isValidated) {
        s.error.value = 'err_passwords_mismatch'.l10n;
      }
    },
    onSubmitted: (s) => resetUserPassword(),
  );

  /// [AuthService] used for authorization manipulations.
  final AuthService _authService;

  /// [MyUserService] retrieving the current [MyUser].
  final MyUserService _myUserService;

  /// [ChatService] for fetching the [chat], if any.
  final ChatService _chatService;

  /// [Timer] disabling [signIn] invoking for [signInTimeout].
  Timer? _signInTimer;

  /// [Timer] used to disable resend code button [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// [Timer] disabling [emailCode] submitting for [codeTimeout].
  Timer? _codeTimer;

  ChatDirectLinkSlug? _slug;

  /// [Worker] adding and removing this modal to/from [RouterState.obscuring].
  Worker? _opacityWorker;

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

  /// Returns the [UserId] of the currently authenticated account.
  UserId get me => _authService.userId;

  /// Returns the reactive list of known [MyUser]s.
  RxList<MyUser> get profiles => _authService.profiles;

  /// Returns the [Credentials] of the available accounts.
  RxMap<UserId, Rx<Credentials>> get accounts => _authService.accounts;

  /// Returns the current [myUser] logged in, if any.
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the current authentication status.
  Rx<RxStatus> get authStatus => _authService.status;

  @override
  void onInit() {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => WebUtils.deleteLoader(),
    );

    if (router.byLink) {
      final String? slug = router.initial?.uri.path.replaceFirst(
        Routes.chatDirectLink,
        '',
      );

      if (slug != null) {
        _slug = ChatDirectLinkSlug(slug);
        _scheduleChat();
      }
    } else {
      _scheduleSupport();
    }

    final ModalRoute dummyRoute = RawDialogRoute(
      pageBuilder: (_, _, _) => const SizedBox(),
    );

    bool hasRoute = false;
    _opacityWorker = ever(opacity, (d) {
      final bool shouldRoute = d > 0;

      if (hasRoute != shouldRoute) {
        hasRoute = shouldRoute;
        if (hasRoute) {
          router.obscuring.add(dummyRoute);
        } else {
          router.obscuring.remove(dummyRoute);
        }
      }
    });

    opacity.value = _authService.userId.isLocal ? 1 : 0;

    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
    _opacityWorker?.dispose();
  }

  @override
  void onIdentityChanged(UserId me) {
    super.onIdentityChanged(me);

    if (_authService.userId.isLocal) {
      _scheduleSupport();
      opacity.value = 1;
      page.value = null;
    } else {
      switch (page.value) {
        case IntroductionStage.accountCreated ||
            IntroductionStage.accountCreating ||
            IntroductionStage.guestCreated:
          // No-op.
          break;

        default:
          dismiss();
          break;
      }
    }
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
      login.error.value = '';
      password.error.value = 'err_incorrect_login_or_password'.l10n;
      password.unsubmit();
      return;
    }

    try {
      login.status.value = RxStatus.loading();
      password.status.value = RxStatus.loading();

      final bool authorized = _authService.isAuthorized();

      // router.switchedFrom = userId;

      await _authService.signIn(
        password: userPassword,
        login: userLogin,
        num: userNum,
        email: userEmail,
        phone: userPhone,
        force: authorized,
        // removeAfterwards: userId,
      );

      // TODO: This is a hack that should be removed, as whenever the account
      //       is changed, the [HomeView] and its dependencies must be
      //       rebuilt, which may take some unidentifiable amount of time as
      //       of now.
      if (authorized) {
        router.nowhere();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      router.home();
    } on CreateSessionException catch (e) {
      ++signInAttempts;

      if (signInAttempts >= 3) {
        // Wrong password was entered three times. Login is possible in N
        // seconds.
        signInAttempts = 0;
        _setSignInTimer();
      }

      login.error.value = '';
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
  Future<void> register({
    UserLogin? login,
    UserPassword? password,
    UserName? name,
    UserEmail? email,
  }) async {
    try {
      await _authService.register(
        password: password,
        login: login,
        force: true,
      );

      if (name != null) {
        await _myUserService.updateUserName(name);
      }

      if (email != null) {
        await _myUserService.addUserEmail(email);
      }
    } on SignUpException catch (e) {
      this.login.error.value = e.toMessage();
    } on ConnectionException {
      MessagePopup.error('err_data_transfer'.l10n);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  Future<void> createAccount() async {
    final userName = UserName.tryParse(signUpName.text);
    final userLogin = UserLogin.tryParse(signUpLogin.text);
    final userEmail = UserEmail.tryParse(signUpEmail.text);
    final userPassword = UserPassword.tryParse(password.text);
    final passwordRepeat = UserPassword.tryParse(repeatPassword.text);

    if (!signUpName.isEmpty.value && userName == null) {
      signUpName.error.value = 'err_incorrect_input'.l10n;
      page.value = IntroductionStage.accountCreating;
      return;
    }

    if (!signUpLogin.isEmpty.value && userLogin == null) {
      signUpLogin.error.value = 'err_incorrect_login_input'.l10n;
      page.value = IntroductionStage.accountCreating;
      return;
    }

    if (!signUpEmail.isEmpty.value && userEmail == null) {
      signUpEmail.error.value = 'err_incorrect_input'.l10n;
      page.value = IntroductionStage.accountCreating;
      return;
    }

    if (!password.isEmpty.value && userPassword == null) {
      password.error.value = 'err_password_incorrect'.l10n;
      page.value = IntroductionStage.accountCreating;
      return;
    }

    if (!repeatPassword.isEmpty.value && passwordRepeat == null) {
      repeatPassword.error.value = 'err_password_incorrect'.l10n;
      page.value = IntroductionStage.accountCreating;
      return;
    }

    if (userPassword != passwordRepeat) {
      password.error.value = 'err_passwords_mismatch'.l10n;
      repeatPassword.error.value = 'err_passwords_mismatch'.l10n;
      page.value = IntroductionStage.accountCreating;
      return;
    }

    try {
      await register(
        login: userLogin,
        password: userPassword,
        name: userName,
        email: userEmail,
      );
    } on SignUpException catch (e) {
      login.error.value = e.toMessage();
      page.value = IntroductionStage.accountCreating;
    } catch (e) {
      password.error.value = 'err_data_transfer'.l10n;
      page.value = IntroductionStage.accountCreating;
      rethrow;
    }
  }

  /// Deletes the account with the provided [UserId] from the list.
  ///
  /// Also performs logout, when deleting the current account.
  Future<void> deleteAccount(UserId id) async {
    profiles.removeWhere((e) => e.id == id);

    if (id == _authService.userId) {
      _authService.logout();
      router.auth();
      router.tab = HomeTab.chats;
    } else {
      await _authService.removeAccount(id);
    }
  }

  /// Switches to the account with the given [id].
  Future<void> switchTo(UserId id) async {
    // router.switchedFrom = userId;

    try {
      // TODO: This is a hack that should be removed, as whenever the account is
      //       changed, the [HomeView] and its dependencies must be rebuilt,
      //       which may take some unidentifiable amount of time as of now.
      router.nowhere();

      final bool succeeded = await _authService.switchAccount(id);
      if (succeeded) {
        await Future.delayed(500.milliseconds);
        router.tab = HomeTab.chats;
        router.home();
      } else {
        await Future.delayed(500.milliseconds);
        router.home();
        await Future.delayed(500.milliseconds);
        MessagePopup.error('err_account_unavailable'.l10n);
      }
    } catch (e) {
      await Future.delayed(500.milliseconds);
      router.home();
      await Future.delayed(500.milliseconds);
      MessagePopup.error(e);
    }
  }

  /// Resends a [ConfirmationCode] to the specified [email].
  Future<void> resendEmail() async {
    _setResendEmailTimer();

    try {
      await _authService.createConfirmationCode(email: UserEmail(email.text));
    } on AddUserEmailException catch (e) {
      emailCode.error.value = e.toMessage();
    } catch (e) {
      emailCode.resubmitOnError.value = true;
      emailCode.error.value = 'err_data_transfer'.l10n;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Initiates password recovery for the [MyUser] identified by the provided
  /// [recoveryIdentifier] input and stores the parsed value.
  Future<void> recoverAccess() async {
    recoveryIdentifier.editable.value = false;
    recoveryIdentifier.status.value = RxStatus.loading();
    recoveryIdentifier.error.value = null;

    _recoveryLogin = _recoveryNum = _recoveryPhone = _recoveryEmail = null;

    // Parse the [recovery] input.
    try {
      _recoveryNum = UserNum(recoveryIdentifier.text);
    } catch (_) {
      try {
        _recoveryPhone = UserPhone(recoveryIdentifier.text);
      } catch (_) {
        try {
          _recoveryLogin = UserLogin(recoveryIdentifier.text.toLowerCase());
        } catch (_) {
          try {
            _recoveryEmail = UserEmail(recoveryIdentifier.text.toLowerCase());
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

      page.value = IntroductionStage.recoveryCode;
      recoveryIdentifier.status.value = RxStatus.success();
      recoveryIdentifier.editable.value = false;
    } catch (e) {
      recoveryIdentifier.unsubmit();
      recoveryIdentifier.resubmitOnError.value = true;
      recoveryIdentifier.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      recoveryIdentifier.status.value = RxStatus.empty();
      recoveryIdentifier.editable.value = true;
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
      page.value = IntroductionStage.recoveryPassword;
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
    if (recoveryPassword.error.value != null ||
        recoveryRepeatPassword.error.value != null ||
        recoveryCode.error.value != null) {
      return;
    }

    recoveryRepeatPassword.status.value = RxStatus.empty();

    if (recoveryPassword.text.isEmpty) {
      recoveryPassword.error.value = 'err_input_empty'.l10n;
      recoveryPassword.editable.value = true;
      recoveryRepeatPassword.editable.value = true;
      return;
    }

    if (recoveryRepeatPassword.text.isEmpty) {
      recoveryRepeatPassword.error.value = 'err_input_empty'.l10n;
      return;
    }

    if (UserPassword.tryParse(recoveryPassword.text) == null) {
      recoveryPassword.error.value = 'err_incorrect_input'.l10n;
      return;
    }

    if (UserPassword.tryParse(recoveryRepeatPassword.text) == null) {
      recoveryRepeatPassword.error.value = 'err_incorrect_input'.l10n;
      return;
    }

    if (recoveryPassword.text != recoveryRepeatPassword.text) {
      recoveryRepeatPassword.error.value = 'err_passwords_mismatch'.l10n;
      return;
    }

    recoveryPassword.editable.value = false;
    recoveryRepeatPassword.editable.value = false;
    recoveryPassword.status.value = RxStatus.loading();
    recoveryRepeatPassword.status.value = RxStatus.loading();

    try {
      await _authService.updateUserPassword(
        login: _recoveryLogin,
        num: _recoveryNum,
        email: _recoveryEmail,
        phone: _recoveryPhone,
        code: ConfirmationCode(recoveryCode.text.toLowerCase()),
        newPassword: UserPassword(recoveryPassword.text),
      );

      page.value = IntroductionStage.signInWithPassword;
    } on FormatException {
      recoveryRepeatPassword.error.value = 'err_incorrect_input'.l10n;
    } on ArgumentError {
      recoveryRepeatPassword.error.value = 'err_incorrect_input'.l10n;
    } on UpdateUserPasswordException catch (e) {
      switch (e.code) {
        case UpdateUserPasswordErrorCode.wrongOldPassword:
          recoveryRepeatPassword.error.value = 'err_wrong_password'.l10n;
        case UpdateUserPasswordErrorCode.wrongCode:
          recoveryCode.error.value = 'err_wrong_code'.l10n;
        case UpdateUserPasswordErrorCode.confirmationRequired:
          recoveryRepeatPassword.error.value = 'err_data_transfer'.l10n;
        case UpdateUserPasswordErrorCode.artemisUnknown:
          recoveryRepeatPassword.error.value = 'err_unknown'.l10n;
      }
    } catch (e) {
      recoveryRepeatPassword.resubmitOnError.value = true;
      recoveryRepeatPassword.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      recoveryPassword.status.value = RxStatus.empty();
      recoveryRepeatPassword.status.value = RxStatus.empty();
      recoveryPassword.editable.value = true;
      recoveryRepeatPassword.editable.value = true;
    }
  }

  /// Dismisses the [IntroductionView] and resets this controller.
  Future<void> dismiss() async {
    opacity.value = 0;
    name.clear();
    email.clear();
    password.clear();
    login.clear();
    repeatPassword.clear();
    emailCode.clear();
    signUpName.clear();
    signUpLogin.clear();
    signUpEmail.clear();
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

  /// Schedules [router] to go to a [Chat]-support.
  Future<void> _scheduleSupport() async {
    Log.debug('_scheduleSupport()', '$runtimeType');

    if (!me.isLocal) {
      Log.debug('_scheduleSupport() -> `$me` is not local', '$runtimeType');
      return;
    }

    final ChatId chatId = ChatId.local(UserId(Config.supportId));

    chat.value = await _chatService.get(chatId);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Log.debug(
        '_scheduleSupport() -> postFrameCallback -> `${router.route}` vs `${router.initial?.uri.path}`',
        '$runtimeType',
      );

      if (router.route == router.initial?.uri.path) {
        router.tab = HomeTab.chats;
        router.chat(chatId);
      }
    });
  }

  /// Schedules [_chatService] to fetch [_slug] to a [chat], if any.
  Future<void> _scheduleChat() async {
    Log.debug('_scheduleChat() -> $_slug', '$runtimeType');

    if (_slug != null) {
      try {
        fetching.value = true;

        final ChatId chatId = await _chatService.useChatDirectLink(_slug!);
        router.chat(chatId);

        chat.value = await _chatService.get(chatId);
      } on UseChatDirectLinkException catch (e) {
        switch (e.code) {
          case UseChatDirectLinkErrorCode.artemisUnknown:
            Log.error('Unable to `_scheduleChat()` -> $e', '$runtimeType');
            break;

          case UseChatDirectLinkErrorCode.blocked:
            Log.error('Unable to `_scheduleChat()` -> $e', '$runtimeType');
            break;

          case UseChatDirectLinkErrorCode.unknownDirectLink:
            await _scheduleSupport();
            break;
        }
      } catch (e) {
        Log.error('Unable to `_scheduleChat()` -> $e', '$runtimeType');
      } finally {
        fetching.value = false;
      }
    }
  }
}
