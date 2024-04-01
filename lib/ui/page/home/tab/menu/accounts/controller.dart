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
import '/api/backend/schema.dart' show ConfirmUserEmailErrorCode;
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

  // /// ...
  // final Map<UserId, StreamSubscription> _userSubscriptions = {};

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  Worker? _myUsersWorker;

  @override
  void onInit() {
    _myUsersWorker ??= ever(_accounts, (_) {
      _populateUsers();
      accounts.refresh();
    });

    login = TextFieldState(onSubmitted: (s) {
      password.focus.requestFocus();
    });

    password = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        if (s.text.isNotEmpty) {
          try {
            UserPassword(s.text);
          } on FormatException {
            if (s.text.isEmpty) {
              s.error.value = 'err_password_empty'.l10n;
            } else {
              s.error.value = 'err_password_incorrect'.l10n;
            }
          }
        }
      },
      onSubmitted: (s) async {
        if (!password.status.value.isEmpty) {
          return;
        }

        password.status.value = RxStatus.loading();
        await _authService.signIn(
          UserPassword(password.text),
          login: UserLogin(login.text),
        );
        password.status.value = RxStatus.empty();

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

        stage.value = AccountsViewStage.signUpWithEmailCode;

        final GraphQlProvider graphQlProvider = Get.find();

        try {
          final response = await graphQlProvider.signUp();
          creds = response.toModel();
          graphQlProvider.token = creds!.session.token;
          await graphQlProvider.addUserEmail(UserEmail(email.text));
          graphQlProvider.token = null;

          s.unsubmit();
        } on AddUserEmailException catch (e) {
          graphQlProvider.token = null;
          s.error.value = e.toMessage();

          stage.value = AccountsViewStage.signUpWithEmailCode;
        } catch (e) {
          graphQlProvider.token = null;
          s.error.value = 'err_data_transfer'.l10n;
          s.unsubmit();

          stage.value = AccountsViewStage.signUpWithEmailCode;

          rethrow;
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

      print(myUser);

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
    // for (var e in _userSubscriptions.values) {
    //   e.cancel();
    // }
    // _userSubscriptions.clear();
    _myUsersWorker?.dispose();

    super.onClose();
  }

  Future<void> delete(UserId id) async {
    // accounts.removeWhere((e) => e.user.id == id);
    // accounts.refresh();

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

  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

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
