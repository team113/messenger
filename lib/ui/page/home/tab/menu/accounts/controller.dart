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

import 'package:get/get.dart';
import 'package:messenger/domain/model/account.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/util/message_popup.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

/// Possible [AccountsView] flow stage.
enum AccountsViewStage {
  accounts,
  add,
  signIn,
  signUp,
}

/// Controller of an [AccountsView].
class AccountsController extends GetxController {
  AccountsController(
    this._myUser,
    this._authService, {
    AccountsViewStage initial = AccountsViewStage.accounts,
  }) : stage = Rx(initial);

  /// [AccountsViewStage] currently being displayed.
  late final Rx<AccountsViewStage> stage;

  /// [MyUser.num]'s copyable [TextFieldState].
  late final TextFieldState login;

  /// [TextFieldState] for a password input.
  late final TextFieldState password;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// [MyUserService] setting the password.
  final MyUserService _myUser;

  final AuthService _authService;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUser.myUser;

  List<Account> get accounts => _authService.accounts;

  @override
  void onInit() {
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

    super.onInit();
  }

  Future<void> delete(Account account) async {
    await _authService.deleteAccount(account);
  }

  Future<void> switchTo(Account? account) async {
    router.go(Routes.nowhere);

    try {
      if (account == null) {
        await _authService.register();
      } else {
        await _authService.authorizeWith(account.credentials);
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
