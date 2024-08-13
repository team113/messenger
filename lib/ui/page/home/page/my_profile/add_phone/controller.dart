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

import '/api/backend/schema.dart' show AddUserPhoneErrorCode;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show AddUserPhoneException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible [AddPhoneView] flow stage.
enum AddPhoneFlowStage { code }

/// Controller of a [AddPhoneView].
class AddPhoneController extends GetxController {
  AddPhoneController(
    this._myUserService, {
    this.pop,
    required this.phone,
    bool timeout = false,
  }) {
    if (timeout) {
      _setResendPhoneTimer();
    }
  }

  /// [UserPhone] the [AddPhoneView] is about.
  final UserPhone phone;

  /// Callback, called when a [AddPhoneView] this controller is bound to should
  /// be popped from the [Navigator].
  final void Function()? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [TextFieldState] for the [UserPhone] confirmation code.
  late final TextFieldState code;

  /// Indicator whether [UserPhone] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Timeout of a [resendPhone].
  final RxInt resendPhoneTimeout = RxInt(0);

  /// [MyUserService] used for confirming an [UserPhone].
  final MyUserService _myUserService;

  /// [Timer] decreasing the [resendPhoneTimeout].
  Timer? _resendPhoneTimer;

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
            s.error.value = 'err_incorrect_input'.l10n;
          }
        }
      },
      onSubmitted: (s) async {
        final ConfirmationCode? code = ConfirmationCode.tryParse(s.text);

        if (code == null) {
          s.error.value = 'err_wrong_recovery_code'.l10n;
        } else {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.addUserPhone(
              phone,
              confirmation: code,
              locale: L10n.chosen.value?.toString(),
            );
            pop?.call();
            s.clear();
          } on AddUserPhoneException catch (e) {
            if (e.code == AddUserPhoneErrorCode.occupied) {
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
    _setResendPhoneTimer(false);
    scrollController.dispose();
    super.onClose();
  }

  /// Resends a [ConfirmationCode] to the unconfirmed phone of the authenticated
  /// [MyUser].
  Future<void> resendPhone() async {
    try {
      await _myUserService.addUserPhone(
        phone,
        locale: L10n.chosen.value?.toString(),
      );
      resent.value = true;
      _setResendPhoneTimer(true);
    } on AddUserPhoneException catch (e) {
      code.error.value = e.toMessage();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Starts or stops the [_resendPhoneTimer] based on [enabled] value.
  void _setResendPhoneTimer([bool enabled = true]) {
    if (enabled) {
      resendPhoneTimeout.value = 30;
      _resendPhoneTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          resendPhoneTimeout.value--;
          if (resendPhoneTimeout.value <= 0) {
            resendPhoneTimeout.value = 0;
            _resendPhoneTimer?.cancel();
            _resendPhoneTimer = null;
          }
        },
      );
    } else {
      resendPhoneTimeout.value = 0;
      _resendPhoneTimer?.cancel();
      _resendPhoneTimer = null;
    }
  }
}
