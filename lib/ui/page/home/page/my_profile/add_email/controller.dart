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

import '/api/backend/schema.dart' show ConfirmUserEmailErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of a [AddEmailView].
class AddEmailController extends GetxController {
  AddEmailController(
    this._myUserService, {
    this.pop,
    bool timeout = false,
  }) {
    if (timeout) {
      _setResendEmailTimer();
    }
  }

  /// Callback, called when a [AddEmailView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] for the [UserEmail] confirmation code.
  late final TextFieldState code;

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Timeout of a [resendEmail].
  final RxInt resendEmailTimeout = RxInt(0);

  /// [MyUserService] used for confirming an [UserEmail].
  final MyUserService _myUserService;

  /// [Timer] decreasing the [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    code = TextFieldState(
      onFocus: (s) {
        if (s.text.isNotEmpty) {
          try {
            ConfirmationCode(s.text);
          } on FormatException {
            s.error.value = 'err_wrong_recovery_code'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        final code = ConfirmationCode.tryParse(s.text);

        if (code == null) {
          s.error.value = 'err_wrong_recovery_code'.l10n;
        } else {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.confirmEmailCode(code);
            pop?.call();
            s.clear();
          } on ConfirmUserEmailException catch (e) {
            if (e.code == ConfirmUserEmailErrorCode.occupied) {
              s.resubmitOnError.value = true;
            }

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

    super.onInit();
  }

  @override
  void onClose() {
    _setResendEmailTimer(false);
    scrollController.dispose();
    super.onClose();
  }

  /// Resends a [ConfirmationCode] to the unconfirmed email of the authenticated
  /// [MyUser].
  Future<void> resendEmail() async {
    try {
      await _myUserService.resendEmail();
      resent.value = true;
      _setResendEmailTimer(true);
    } on ResendUserEmailConfirmationException catch (e) {
      code.error.value = e.toMessage();
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
