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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show DeleteUserEmailException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of a [DeleteEmailView].
class DeleteEmailController extends GetxController {
  DeleteEmailController(
    this._myUserService,
    this._authService, {
    required this.email,
    this.pop,
  });

  /// [UserEmail] the [DeleteEmailView] is about.
  final UserEmail email;

  /// Callback, called when a [DeleteEmailView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] of the [UserPassword] input.
  late final TextFieldState password = TextFieldState(
    onChanged: (s) => s.error.value = null,
    onSubmitted: (s) async {
      final password = UserPassword.tryParse(s.text);

      if (password == null) {
        s.error.value = 'err_wrong_password'.l10n;
      } else {
        s.editable.value = false;
        s.status.value = RxStatus.loading();
        try {
          await _myUserService.deleteUserEmail(email, password: password);
          pop?.call();
          s.clear();
        } on DeleteUserEmailException catch (e) {
          s.error.value = e.toMessage();
        } catch (e) {
          s.resubmitOnError.value = true;
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

  /// [TextFieldState] of the [UserPassword] input.
  late final TextFieldState code = TextFieldState(
    onChanged: (s) => s.error.value = null,
    onSubmitted: (s) async {
      final code = ConfirmationCode.tryParse(s.text);

      if (code == null) {
        s.error.value = 'err_wrong_recovery_code'.l10n;
      } else {
        s.editable.value = false;
        s.status.value = RxStatus.loading();
        try {
          await _myUserService.deleteUserEmail(email, confirmation: code);
          pop?.call();
          s.clear();
        } on DeleteUserEmailException catch (e) {
          s.error.value = e.toMessage();
        } catch (e) {
          s.resubmitOnError.value = true;
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

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Timeout of a [sendConfirmationCode].
  final RxInt resendEmailTimeout = RxInt(0);

  /// [MyUserService] used for confirming an [UserEmail].
  final MyUserService _myUserService;

  /// [AuthService] for sending a [ConfirmationCode].
  final AuthService _authService;

  /// [Timer] decreasing the [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    if (myUser.value?.hasPassword == false) {
      sendConfirmationCode();
    }

    super.onInit();
  }

  @override
  void onClose() {
    _setResendEmailTimer(false);
    scrollController.dispose();
    super.onClose();
  }

  /// Sends a [ConfirmationCode] to the [email].
  Future<void> sendConfirmationCode() async {
    try {
      await _authService.createConfirmationCode(
        email: email,
        locale: L10n.chosen.value?.toString(),
      );
      resent.value = true;
      _setResendEmailTimer(true);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
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
}
