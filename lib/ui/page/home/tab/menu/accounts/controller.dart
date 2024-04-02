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

import 'package:get/get.dart' hide Response;

import '/api/backend/extension/credentials.dart';
import '/api/backend/schema.dart'
    show ConfirmUserEmailErrorCode, CreateSessionErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

typedef AccountData = ({Rx<MyUser?> myUser, RxUser user});

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
    this._authService,
    this._userService, {
    AccountsViewStage initial = AccountsViewStage.accounts,
  }) : stage = Rx(initial);

  /// [AccountsViewStage] currently being displayed.
  late final Rx<AccountsViewStage> stage;

  /// [MyUser.num]'s copyable [TextFieldState].
  late final TextFieldState login;

  /// [TextFieldState] for a password input.
  late final TextFieldState password;

  /// [TextFieldState] for an email input.
  late final TextFieldState email;

  /// [TextFieldState] for an email code input.
  late final TextFieldState emailCode;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  Credentials? creds;

  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Reactive map of authenticated [MyUser]s.
  RxMap<UserId, Rx<MyUser?>> get _accounts => _myUserService.myUsers;

  /// Reactive list of [MyUser]s paired with the corresponding [User]s.
  final RxList<AccountData> accounts = RxList();

  /// [MyUserService] ...
  final MyUserService _myUserService;

  /// [AuthService] ...
  final AuthService _authService;

  /// [UserService] ...
  final UserService _userService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  Worker? _myUsersWorker;

  @override
  void onInit() {
    _myUsersWorker ??= ever(_accounts, (_) {
      _populateUsers();
      accounts.refresh();
    });

    login = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        password.unsubmit();
      },
      onSubmitted: (s) {
        password.focus.requestFocus();
        s.unsubmit();
      },
    );

    password = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        if (s.text.isNotEmpty) {
          try {
            UserPassword(s.text);
          } on FormatException {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        if (!password.status.value.isEmpty) {
          return;
        }

        password.status.value = RxStatus.loading();
        login.status.value = RxStatus.loading();

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
        } on CreateSessionException catch (e) {
          switch (e.code) {
            case CreateSessionErrorCode.wrongPassword:
              // TODO: Тут ещё должен быть подсчёт попыток, запуск таймера и т.д.
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

        router.go(Routes.nowhere);
        await Future.delayed(const Duration(milliseconds: 500));
        router.home();
      },
    );

    email = TextFieldState(
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

        final UserEmail? email = UserEmail.tryParse(s.text.toLowerCase());

        if (email == null) {
          s.error.value = 'err_incorrect_email'.l10n;
        } else {
          emailCode.clear();
          stage.value = AccountsViewStage.signUpWithEmailCode;
          try {
            await _authService.signUpWithEmail(email);
            s.unsubmit();
          } on AddUserEmailException catch (e) {
            s.error.value = e.toMessage();
            // _setResendEmailTimer(false);

            stage.value = AccountsViewStage.signUpWithEmail;
          } catch (_) {
            s.error.value = 'err_data_transfer'.l10n;
            // _setResendEmailTimer(false);
            s.unsubmit();

            stage.value = AccountsViewStage.signUpWithEmail;
            rethrow;
          }
        }
      },
    );

    emailCode = TextFieldState(
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

          await switchTo(creds!.userId);
        } on FormatException catch (_) {
          graphQlProvider.token = null;
          s.error.value = 'err_wrong_recovery_code'.l10n;
        } catch (_) {
          graphQlProvider.token = null;
          s.error.value = 'err_data_transfer'.l10n;
          s.unsubmit();
        }
      },
    );

    _populateUsers();

    super.onInit();
  }

  void _populateUsers() async {
    status.value = RxStatus.loading();

    final values = <AccountData>[];

    for (final e in _accounts.entries) {
      final UserId id = e.key;
      final Rx<MyUser?> myUser = e.value;

      if (myUser.value != null) {
        final FutureOr<RxUser?> futureOrUser = _userService.get(id);
        final user =
            futureOrUser is RxUser? ? futureOrUser : await futureOrUser;

        if (user != null) {
          values.add((myUser: myUser, user: user));
        }
      }
    }

    values.sort((a, b) {
      if (_authService.credentials.value?.userId == a.user.id) {
        return -1;
      } else if (_authService.credentials.value?.userId == b.user.id) {
        return 1;
      } else if (a.user.user.value.online && !b.user.user.value.online) {
        return -1;
      } else if (!a.user.user.value.online && b.user.user.value.online) {
        return 1;
      } else if (a.user.user.value.lastSeenAt == null ||
          b.user.user.value.lastSeenAt == null) {
        return -1;
      }

      return -a.user.user.value.lastSeenAt!.compareTo(
        b.user.user.value.lastSeenAt!,
      );
    });

    accounts.value = values;

    status.value = RxStatus.success();
  }

  @override
  void onClose() {
    _myUsersWorker?.dispose();

    super.onClose();
  }

  Future<void> signIn() async {}

  Future<void> delete(UserId id) async {
    await _authService.deleteAccount(id);

    if (id == _authService.userId) {
      final Iterable<AccountData> others =
          accounts.where((e) => e.user.id != id);

      if (others.isEmpty) {
        router.go(await _authService.logout());
      } else {
        await switchTo(others.first.user.id);
      }
    }
  }

  Future<void> switchTo(UserId? id) async {
    router.go(Routes.nowhere);

    try {
      if (id == null) {
        await _authService.register();
      } else {
        await _authService.signInToSavedAccount(id);
      }
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 1000)).then((v) {
        MessagePopup.error(e);
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));

    router.home();
  }
}

extension on AccountsViewStage {
  bool get registering => switch (this) {
        AccountsViewStage.signIn ||
        AccountsViewStage.signInWithPassword =>
          false,
        (_) => true,
      };
}
