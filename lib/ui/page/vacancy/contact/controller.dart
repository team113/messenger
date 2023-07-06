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

import 'package:get/get.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/routes.dart';

import '/domain/service/auth.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

enum VacancyContactScreen {
  register,
  validate,
}

/// Controller of an [AccountsView].
class VacancyContactController extends GetxController {
  VacancyContactController(this._authService);

  /// [MyUser.num]'s copyable [TextFieldState].
  late final TextFieldState login = TextFieldState();
  late final TextFieldState email = TextFieldState(
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
    onSubmitted: (s) => password.focus.requestFocus(),
  );

  /// [TextFieldState] for a password input.
  late final TextFieldState password = TextFieldState(
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
  );

  /// [TextFieldState] for a password input.
  late final TextFieldState newPassword = TextFieldState(
    onChanged: (s) {
      s.error.value = null;
      repeatPassword.error.value = null;

      try {
        UserPassword(s.text);
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_input'.l10n;
      }
    },
    onSubmitted: (s) => repeatPassword.focus.requestFocus(),
  );

  late final TextFieldState repeatPassword = TextFieldState(
    onChanged: (s) {
      s.error.value = null;
      newPassword.error.value = null;
      if (s.text != newPassword.text && newPassword.isValidated) {
        s.error.value = 'err_passwords_mismatch'.l10n;
      }
    },
    onSubmitted: (s) => register(),
  );

  late final TextFieldState emailCode = TextFieldState(
    onChanged: (s) {
      s.error.value = null;
      s.unsubmit();
    },
    onSubmitted: (s) async {
      if (s.text.isEmpty) {
        s.error.value = 'err_wrong_recovery_code'.l10n;
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();
        try {
          // await _myUserService.confirmEmailCode(ConfirmationCode(s.text));
          s.clear();
        } on FormatException {
          s.error.value = 'err_wrong_recovery_code'.l10n;
        } on ConfirmUserEmailException catch (e) {
          s.error.value = e.toMessage();
        } catch (e) {
          s.error.value = 'err_data_transfer'.l10n;
          s.unsubmit();
          rethrow;
        } finally {
          s.editable.value = true;
          s.status.value = RxStatus.empty();
        }
      }
    },
  );

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);
  final RxBool obscureNewPassword = RxBool(true);

  /// Indicator whether the [repeatPassword] should be obscured.
  final RxBool obscureRepeatPassword = RxBool(true);

  final Rx<VacancyContactScreen?> stage = Rx(null);

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Timeout of a [resendEmail].
  final RxInt resendEmailTimeout = RxInt(0);

  final AuthService _authService;

  Future<void> signIn() async {
    await _authService.signIn(
      UserPassword(password.text),
      login: UserLogin(login.text),
    );
    router.home();

    useLink();
  }

  Future<void> register() async {
    // stage.value = VacancyContactScreen.validate;
    await _authService.register();
    useLink();

    router.validateEmail = true;

    while (!Get.isRegistered<MyUserService>()) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final MyUserService myUserService = Get.find();
    await myUserService.addUserEmail(UserEmail(email.text));
    await myUserService.updateUserPassword(
      newPassword: UserPassword(repeatPassword.text),
    );
  }

  void resendEmail() {}

  void useLink() {
    router.validateEmail = true;
    router.useLink(
      '1KMoJjW8wZ',
      // 'nikita',
      welcome: '''Здравствуйте, уважаемый соискатель.

Для более предметного диалога просим Вас выслать резюме.

С уважением,
Роман
HR-менеджер Gapopa
''',
    );
  }
}
