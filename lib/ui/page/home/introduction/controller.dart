// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/provider/gql/exceptions.dart' show UpdateUserPasswordException;
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

/// Possible [IntroductionViewStage] flow stage.
enum IntroductionViewStage {
  introduction,
  password,
  success,
}

/// Controller of an [IntroductionView].
class IntroductionController extends GetxController {
  IntroductionController(this._myUser);

  /// [IntroductionViewStage] currently being displayed.
  final Rx<IntroductionViewStage> stage =
      Rx(IntroductionViewStage.introduction);

  /// Uses for password updating.
  final MyUserService _myUser;

  /// Field which contains unique num of [MyUser].
  late final TextFieldState num;

  /// Field for password input.
  late final TextFieldState password;

  /// Field for password repeat input.
  late final TextFieldState repeat;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [obscureRepeat] should be obscured.
  final RxBool obscureRepeat = RxBool(true);

  /// Current [MyUser].
  Rx<MyUser?> get myUser => _myUser.myUser;

  @override
  void onInit() {
    num = TextFieldState(
      text: _myUser.myUser.value!.num.val
          .replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} '),
      editable: false,
    );

    password = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        if (s.text.isEmpty) {
          return;
        }

        try {
          UserPassword(s.text);

          if (repeat.text != password.text && repeat.isValidated) {
            repeat.error.value = 'err_passwords_mismatch'.l10n;
          }
        } on FormatException {
          if (s.text.isEmpty) {
            s.error.value = 'err_password_empty'.l10n;
          } else {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }
      },
    );

    repeat = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        if (s.text.isEmpty) {
          return;
        }

        try {
          if (s.text.isEmpty) {
            throw const FormatException();
          }

          UserPassword(s.text);

          if (repeat.text != password.text && password.isValidated) {
            repeat.error.value = 'err_passwords_mismatch'.l10n;
          }
        } on FormatException {
          if (s.text.isEmpty) {
            s.error.value = 'err_repeat_password_empty'.l10n;
          } else {
            s.error.value = 'err_password_incorrect'.l10n;
          }
        }
      },
    );

    super.onInit();
  }

  /// Validates and updates the [password] of the currently authenticated
  /// [MyUser].
  Future<void> setPassword() async {
    if (password.error.value != null ||
        repeat.error.value != null ||
        !password.editable.value ||
        !repeat.editable.value) {
      return;
    }

    if (password.text.isEmpty) {
      password.error.value = 'err_password_empty'.l10n;
      return;
    }

    if (repeat.text.isEmpty) {
      repeat.error.value = 'err_repeat_password_empty'.l10n;
      return;
    }

    password.editable.value = false;
    repeat.editable.value = false;
    password.status.value = RxStatus.loading();
    repeat.status.value = RxStatus.loading();
    try {
      await _myUser.updateUserPassword(newPassword: UserPassword(repeat.text));
      password.status.value = RxStatus.success();
      repeat.status.value = RxStatus.success();
      await Future.delayed(1.seconds);
      stage.value = IntroductionViewStage.success;
    } on UpdateUserPasswordException catch (e) {
      repeat.error.value = e.toMessage();
    } catch (e) {
      repeat.error.value = e.toString();
      rethrow;
    } finally {
      password.status.value = RxStatus.empty();
      repeat.status.value = RxStatus.empty();
      password.editable.value = true;
      repeat.editable.value = true;
    }
  }
}
