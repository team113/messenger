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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show RemoveUserEmailException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible stages of a [DeleteEmailView] to be displayed.
enum DeleteEmailPage { delete, success }

/// Controller of a [DeleteEmailView].
class DeleteEmailController extends GetxController {
  DeleteEmailController(
    this._myUserService,
    this._authService, {
    required this.email,
  });

  /// [UserEmail] the [DeleteEmailView] is about.
  final UserEmail email;

  /// Current [DeleteEmailPage] displayed.
  final Rx<DeleteEmailPage> page = Rx(DeleteEmailPage.delete);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] of the [UserPassword] input.
  late final TextFieldState passwordOrCode = TextFieldState(
    onChanged: (s) => s.error.value = null,
    onSubmitted: (s) async {
      final password = UserPassword.tryParse(s.text);

      if (password == null) {
        s.error.value = 'err_wrong_password'.l10n;
      } else {
        s.editable.value = false;
        s.status.value = RxStatus.loading();
        try {
          final code = ConfirmationCode.tryParse(s.text);

          // If text in the field is not even parsed as [ConfirmationCode], then
          // it is certainly a [UserPassword].
          if (code == null) {
            await _myUserService.removeUserEmail(email, password: password);
          } else {
            // Otherwise first try the parsed [ConfirmationCode].
            try {
              await _myUserService.removeUserEmail(email, confirmation: code);
            } on RemoveUserEmailException catch (e) {
              switch (e.code) {
                // If wrong, then perhaps it may be a password instead?
                case RemoveUserEmailErrorCode.wrongCode:
                  await _myUserService.removeUserEmail(
                    email,
                    password: password,
                  );
                  break;

                default:
                  rethrow;
              }
            }
          }
          s.clear();
          page.value = DeleteEmailPage.success;
        } on RemoveUserEmailException catch (e) {
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

  /// Indicator whether the [passwordOrCode] should be obscured.
  final RxBool obscurePasswordOrCode = RxBool(true);

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
    sendConfirmationCode();
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
      _setResendEmailTimer(true);

      await _authService.createConfirmationCode(
        email: email,
        locale: L10n.chosen.value?.toString(),
      );
      resent.value = true;
    } catch (e) {
      _setResendEmailTimer(false);
      MessagePopup.error(e);
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
