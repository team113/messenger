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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible [AddEmailView] flow stage.
enum AddEmailFlowStage { code }

/// Controller of a [AddEmailView].
class AddEmailController extends GetxController {
  AddEmailController(this._myUserService, {this.initial, this.pop});

  /// Callback, called when a [AddEmailView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// Initial [UserEmail] to confirm.
  final UserEmail? initial;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [UserEmail] field state.
  late final TextFieldState email;

  /// [TextFieldState] for the [UserEmail] confirmation code.
  late final TextFieldState emailCode;

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Timeout of a [resendEmail].
  final RxInt resendEmailTimeout = RxInt(0);

  /// [AddEmailFlowStage] currently being displayed.
  final Rx<AddEmailFlowStage?> stage = Rx(null);

  /// [MyUserService] used for confirming an [UserEmail].
  final MyUserService _myUserService;

  /// [Timer] decreasing the [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    email = TextFieldState(
      text: initial?.val,
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        UserEmail? email;
        try {
          email = UserEmail(s.text.toLowerCase());

          if (myUser.value!.emails.confirmed.contains(email) ||
              myUser.value?.emails.unconfirmed == email) {
            s.error.value = 'err_you_already_add_this_email'.l10n;
          }
        } on FormatException {
          s.error.value = 'err_incorrect_email'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.addUserEmail(email!);
            _setResendEmailTimer(true);
            stage.value = AddEmailFlowStage.code;
          } on FormatException {
            s.error.value = 'err_incorrect_email'.l10n;
          } on AddUserEmailException catch (e) {
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

    emailCode = TextFieldState(
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
            await _myUserService.confirmEmailCode(ConfirmationCode(s.text));
            pop?.call();
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

    if (initial != null) {
      stage.value = AddEmailFlowStage.code;
    }

    super.onInit();
  }

  @override
  void onClose() {
    _setResendEmailTimer(false);
    super.onClose();
  }

  /// Resends a [ConfirmationCode] to the specified [email].
  Future<void> resendEmail() async {
    try {
      await _myUserService.resendEmail();
      resent.value = true;
      _setResendEmailTimer(true);
    } on ResendUserEmailConfirmationException catch (e) {
      emailCode.error.value = e.toMessage();
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
