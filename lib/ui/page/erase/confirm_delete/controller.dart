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

import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show DeleteMyUserException;
import '/ui/widget/text_field.dart';

/// [ConfirmDeleteView] controller.
class ConfirmDeleteController extends GetxController {
  ConfirmDeleteController(this._myUserService, this._authService);

  /// [TextFieldState] of the [ConfirmationCode] input.
  late final TextFieldState code = TextFieldState(
    onChanged: (_) {
      code.error.value = null;
      password.error.value = null;
    },
  );

  /// [TextFieldState] of the [UserPassword] input.
  late final TextFieldState password = TextFieldState(
    onChanged: (_) {
      code.error.value = null;
      password.error.value = null;
    },
  );

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Timeout of a [sendConfirmationCode] next invoke attempt.
  final RxInt resendEmailTimeout = RxInt(0);

  /// [AuthService] to [sendConfirmationCode].
  final AuthService _authService;

  /// [MyUserService] maintaining the [MyUser].
  final MyUserService _myUserService;

  /// [Timer] used to disable resend code button [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    if (myUser.value?.emails.confirmed.isNotEmpty == true) {
      sendConfirmationCode();
    }

    super.onInit();
  }

  /// Sends a [ConfirmationCode] to confirm the [deleteAccount].
  Future<void> sendConfirmationCode() async {
    _setResendEmailTimer();

    try {
      await _authService.createConfirmationCode();
    } catch (e) {
      code.resubmitOnError.value = true;
      code.error.value = 'err_data_transfer'.l10n;
      _setResendEmailTimer(false);
      rethrow;
    }
  }

  /// Deletes the currently authenticated [MyUser] account.
  Future<void> deleteAccount() async {
    code.error.value = null;
    password.error.value = null;

    try {
      await _myUserService.deleteMyUser(
        confirmation: code.text.isNotEmpty ? ConfirmationCode(code.text) : null,
        password: password.text.isNotEmpty ? UserPassword(password.text) : null,
      );
    } on DeleteMyUserException catch (e) {
      code.error.value = e.toMessage();
      password.error.value = e.toMessage();
    } on FormatException {
      code.error.value = 'err_wrong_code'.l10n;
      password.error.value = 'err_wrong_code'.l10n;
    } catch (e) {
      code.error.value = 'err_data_transfer'.l10n;
      password.error.value = 'err_data_transfer'.l10n;
      rethrow;
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
}
