// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/api/backend/schema.dart' show AddUserEmailErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show AddUserEmailException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible stages of a [AddEmailView] to be displayed.
enum AddEmailPage { add, confirm, success }

/// Controller of a [AddEmailView].
class AddEmailController extends GetxController {
  AddEmailController(this._myUserService, {this.email, bool timeout = false})
    : page = Rx(email == null ? AddEmailPage.add : AddEmailPage.confirm) {
    if (timeout) {
      _setResendEmailTimer();
    }
  }

  /// Current [AddEmailPage] displayed.
  final Rx<AddEmailPage> page;

  /// [UserEmail] the [AddEmailView] is about.
  UserEmail? email;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] for inputting the [email].
  late final TextFieldState emailField = TextFieldState(
    onFocus: (s) {
      if (s.text.trim().isNotEmpty) {
        try {
          email = UserEmail(s.text);

          if (myUser.value!.emails.confirmed.contains(email) ||
              myUser.value?.emails.unconfirmed == email) {
            s.error.value = 'err_you_already_add_this_email'.l10n;
          }
        } catch (e) {
          s.error.value = 'err_incorrect_email'.l10n;
        }
      }
    },
    onSubmitted: (s) async {
      if (s.text.trim().isEmpty ||
          (s.error.value != null && s.resubmitOnError.isFalse)) {
        return;
      }

      page.value = AddEmailPage.confirm;

      email = UserEmail(s.text.toLowerCase());

      try {
        await _myUserService.addUserEmail(
          email!,
          locale: L10n.chosen.value?.toString(),
        );

        _setResendEmailTimer();
      } catch (e) {
        page.value = AddEmailPage.add;
        s.unchecked = email?.val;

        if (e is AddUserEmailException) {
          s.error.value = e.toMessage();
          s.resubmitOnError.value = e.code == AddUserEmailErrorCode.busy;
        } else {
          s.error.value = 'err_data_transfer'.l10n;
          s.resubmitOnError.value = true;
        }

        s.unsubmit();
      }
    },
  );

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
        if (s.text.trim().isNotEmpty) {
          try {
            ConfirmationCode(s.text);
          } on FormatException {
            s.error.value = 'err_wrong_code'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        final code = ConfirmationCode.tryParse(s.text);

        if (code == null) {
          s.error.value = 'err_wrong_code'.l10n;
        } else {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.addUserEmail(
              email!,
              confirmation: code,
              locale: L10n.chosen.value?.toString(),
            );
            s.clear();
            page.value = AddEmailPage.success;
          } on AddUserEmailException catch (e) {
            if (e.code == AddUserEmailErrorCode.occupied) {
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
    resent.value = true;
    _setResendEmailTimer(true);

    try {
      await _myUserService.addUserEmail(
        email!,
        locale: L10n.chosen.value?.toString(),
      );
    } on AddUserEmailException catch (e) {
      code.error.value = e.toMessage();
      _setResendEmailTimer(false);
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
