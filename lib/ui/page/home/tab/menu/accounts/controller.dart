// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';

import '/api/backend/schema.dart' show AddUserEmailErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

/// Possible [AccountsView] flow stage.
enum AccountsViewStage {
  accounts,
  add,
  signUp,
  signUpWithEmail,
  signUpWithEmailCode,
  signIn,
  signInWithPassword,
}

/// Controller of an [AccountsView].
class AccountsController extends GetxController {
  AccountsController(
    this._myUserService,
    this._authService, {
    AccountsViewStage initial = AccountsViewStage.accounts,
  }) : stage = Rx(initial);

  /// [AccountsViewStage] currently being displayed.
  late final Rx<AccountsViewStage> stage;

  /// [MyUser.login]'s [TextFieldState].
  late final TextFieldState login;

  /// [TextFieldState] for a password input.
  late final TextFieldState password;

  /// [TextFieldState] for an email input.
  late final TextFieldState email;

  /// [TextFieldState] for an email code input.
  late final TextFieldState emailCode;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [emailCode] should be obscured.
  final RxBool obscureCode = RxBool(true);

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

  /// Known [MyUser] accounts that can be used to [signIn] to.
  final RxList<Rx<MyUser>> accounts = RxList();

  /// [Timer] disabling [emailCode] submitting for [codeTimeout].
  Timer? _codeTimer;

  /// [Timer] disabling [signIn] invoking for [signInTimeout].
  Timer? _signInTimer;

  /// [Timer] used to disable resend code button for [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// [MyUserService] to obtain [accounts] and [me].
  final MyUserService _myUserService;

  /// [AuthService] providing the authentication capabilities.
  final AuthService _authService;

  /// Subscription for [MyUserService.myUsers] changes updating the [accounts]
  /// list.
  StreamSubscription? _profilesSubscription;

  /// Returns [UserId] of currently authenticated [MyUser].
  UserId? get me => _authService.userId;

  /// Returns the current authentication status.
  Rx<RxStatus> get authStatus => _authService.status;

  /// Returns a reactive map of all the active [Credentials] for [accounts].
  ///
  /// Accounts whose [UserId]s are present in this set are available for
  /// switching.
  RxMap<UserId, Rx<Credentials>> get sessions => _authService.accounts;

  /// Returns a reactive map of all the known [MyUser] profiles for [accounts].
  RxObsMap<UserId, Rx<MyUser>> get _profiles => _myUserService.profiles;

  @override
  void onInit() {
    for (var e in _profiles.values) {
      accounts.add(e);
    }
    accounts.sort(_compareAccounts);

    _profilesSubscription = _profiles.changes.listen((e) async {
      switch (e.op) {
        case OperationKind.added:
          accounts.add(e.value!);
          accounts.sort(_compareAccounts);
          break;

        case OperationKind.removed:
          accounts.removeWhere((u) => u.value.id == e.key);
          break;

        case OperationKind.updated:
          accounts.sort(_compareAccounts);
          break;
      }
    });

    login = TextFieldState(
      onFocus: (s) {
        s.error.value = null;
        password.unsubmit();
      },
      onSubmitted: (s) {
        password.focus.requestFocus();
        s.unsubmit();
      },
    );

    password = TextFieldState(
      onFocus: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (_) => signIn(),
    );

    email = TextFieldState(
      onFocus: (s) {
        try {
          if (s.text.trim().isNotEmpty) {
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

        final UserEmail? email = UserEmail.tryParse(s.text.toLowerCase());

        if (email == null) {
          s.error.value = 'err_incorrect_email'.l10n;
        } else {
          emailCode.clear();
          stage.value = AccountsViewStage.signUpWithEmailCode;
          try {
            await _authService.createConfirmationCode(email: email);
            s.unsubmit();
          } on AddUserEmailException catch (e) {
            s.error.value = e.toMessage();
            _setResendEmailTimer(false);

            stage.value = AccountsViewStage.signUpWithEmail;
          } catch (_) {
            s.resubmitOnError.value = true;
            s.error.value = 'err_data_transfer'.l10n;
            _setResendEmailTimer(false);
            s.unsubmit();

            stage.value = AccountsViewStage.signUpWithEmail;
            rethrow;
          }
        }
      },
    );

    emailCode = TextFieldState(
      onSubmitted: (s) async {
        s.status.value = RxStatus.loading();
        try {
          await _authService.signIn(
            email: UserEmail(email.text),
            code: ConfirmationCode(emailCode.text),
            force: true,
          );

          // TODO: This is a hack that should be removed, as whenever the
          //       account is changed, the [HomeView] and its dependencies must
          //       be rebuilt, which may take some unidentifiable amount of time
          //       as of now.
          router.go(Routes.nowhere);
          await Future.delayed(const Duration(milliseconds: 500));
          router.home();
        } on AddUserEmailException catch (e) {
          switch (e.code) {
            case AddUserEmailErrorCode.wrongCode:
              s.error.value = e.toMessage();

              ++codeAttempts;
              if (codeAttempts >= 3) {
                codeAttempts = 0;
                _setCodeTimer();
              }
              s.status.value = RxStatus.empty();
              break;

            default:
              s.error.value = e.toMessage();
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

    super.onInit();
  }

  @override
  void onClose() {
    _profilesSubscription?.cancel();
    super.onClose();
  }

  /// Tries to sign in into a new account and to redirect to the [Routes.home]
  /// page.
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

      await _authService.signIn(
        password: userPassword,
        login: userLogin,
        num: userNum,
        email: userEmail,
        phone: userPhone,
        force: true,
      );

      // TODO: This is a hack that should be removed, as whenever the account is
      //       changed, the [HomeView] and its dependencies must be rebuilt,
      //       which may take some unidentifiable amount of time as of now.
      router.nowhere();
      await Future.delayed(const Duration(milliseconds: 500));
      router.home();
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
      password.error.value = 'err_data_transfer'.l10n;
      password.resubmitOnError.value = true;
    } catch (e) {
      password.unsubmit();
      password.error.value = 'err_data_transfer'.l10n;
      password.resubmitOnError.value = true;
      rethrow;
    } finally {
      login.status.value = RxStatus.empty();
      password.status.value = RxStatus.empty();
    }
  }

  /// Deletes the account with the provided [UserId] from the list.
  ///
  /// Also performs logout, when deleting the current account.
  Future<void> deleteAccount(UserId id) async {
    accounts.removeWhere((e) => e.value.id == id);

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

  /// Creates a new account and switches to it.
  Future<void> register() async {
    router.nowhere();

    try {
      await _authService.register(force: true);

      // TODO: This is a hack that should be removed, as whenever the account is
      //       changed, the [HomeView] and its dependencies must be rebuilt,
      //       which may take some unidentifiable amount of time as of now.
      await Future.delayed(500.milliseconds);

      router.tab = HomeTab.chats;
      router.home();
    } catch (e) {
      await Future.delayed(500.milliseconds);
      router.home();
      await Future.delayed(500.milliseconds);
      MessagePopup.error(e);
    }
  }

  /// Starts or stops the [_signInTimer] based on [enabled] value.
  void _setSignInTimer([bool enabled = true]) {
    if (enabled) {
      signInTimeout.value = 30;
      _signInTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        signInTimeout.value--;
        if (signInTimeout.value <= 0) {
          signInTimeout.value = 0;
          _signInTimer?.cancel();
          _signInTimer = null;
        }
      });
    } else {
      signInTimeout.value = 0;
      _signInTimer?.cancel();
      _signInTimer = null;
    }
  }

  /// Starts or stops the [_codeTimer] based on [enabled] value.
  void _setCodeTimer([bool enabled = true]) {
    if (enabled) {
      codeTimeout.value = 30;
      _codeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        codeTimeout.value--;
        if (codeTimeout.value <= 0) {
          codeTimeout.value = 0;
          _codeTimer?.cancel();
          _codeTimer = null;
        }
      });
    } else {
      codeTimeout.value = 0;
      _codeTimer?.cancel();
      _codeTimer = null;
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

  /// Resends a [ConfirmationCode] to the specified [email].
  Future<void> resendEmail() async {
    _setResendEmailTimer();

    try {
      await _authService.createConfirmationCode(email: UserEmail(email.text));
    } on AddUserEmailException catch (e) {
      emailCode.error.value = e.toMessage();
    } catch (e) {
      emailCode.error.value = 'err_data_transfer'.l10n;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Compares two [MyUser]s based on their last seen times and the online
  /// statuses.
  int _compareAccounts(Rx<MyUser> a, Rx<MyUser> b) {
    if (a.value.id == me) {
      return -1;
    } else if (b.value.id == me) {
      return 1;
    } else if (a.value.online && !b.value.online) {
      return -1;
    } else if (!a.value.online && b.value.online) {
      return 1;
    } else if (a.value.lastSeenAt == null || b.value.lastSeenAt == null) {
      return -1;
    }

    return -a.value.lastSeenAt!.compareTo(b.value.lastSeenAt!);
  }
}
