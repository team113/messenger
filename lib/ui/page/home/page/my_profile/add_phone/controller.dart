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

import 'dart:async';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger/api/backend/schema.dart'
    show ConfirmUserEmailErrorCode, ConfirmUserPhoneErrorCode;
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/service/my_user.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

enum AddPhoneFlowStage {
  code,
}

/// Controller of a [ChatForwardView].
class AddPhoneController extends GetxController {
  AddPhoneController(this._myUserService, {this.initial, this.pop});

  final void Function()? pop;
  final UserPhone? initial;

  late final TextFieldState phone;
  late final TextFieldState phoneCode;

  final RxBool resent = RxBool(false);

  /// Timeout of a [resendPhone] action.
  final RxInt resendPhoneTimeout = RxInt(0);

  final Rx<AddPhoneFlowStage?> stage = Rx(null);

  final MyUserService _myUserService;

  /// [Timer] to decrease [resendPhoneTimeout].
  Timer? _resendPhoneTimer;

  /// Returns current [MyUser] value.
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    phone = TextFieldState(
      text: initial?.val,
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        UserPhone? phone;
        try {
          phone = UserPhone(s.text);

          if (myUser.value!.phones.confirmed.contains(phone) ||
              myUser.value?.phones.unconfirmed == phone) {
            s.error.value = 'err_you_already_add_this_phone'.l10n;
          }
        } on FormatException {
          s.error.value = 'err_incorrect_phone'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _myUserService.addUserPhone(phone!);
            _setResendPhoneTimer(true);
            stage.value = AddPhoneFlowStage.code;
          } on FormatException {
            s.error.value = 'err_incorrect_phone'.l10n;
          } on AddUserPhoneException catch (e) {
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

    phoneCode = TextFieldState(
      onChanged: (s) {
        s.error.value = null;
        s.unsubmit();
      },
      onSubmitted: (s) async {
        if (s.text.isEmpty) {
          s.error.value = 'err_input_empty'.l10n;
        }

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            // await _myUserService.confirmEmailCode(ConfirmationCode(s.text));
            if (s.text == '1111') {
              await Future.delayed(const Duration(seconds: 1));
            } else {
              throw const ConfirmUserPhoneException(
                ConfirmUserPhoneErrorCode.wrongCode,
              );
            }
            pop?.call();
            s.clear();
          } on FormatException {
            s.error.value = 'err_wrong_recovery_code'.l10n;
          } on ConfirmUserPhoneException catch (e) {
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
      stage.value = AddPhoneFlowStage.code;
    }

    super.onInit();
  }

  @override
  void onClose() {
    _setResendPhoneTimer(false);
    super.onClose();
  }

  /// Resend [ConfirmationCode] to [UserEmail] specified in the [email] field to
  /// [MyUser.emails].
  Future<void> resendPhone() async {
    try {
      await _myUserService.resendPhone();
      resent.value = true;
      _setResendPhoneTimer(true);
    } on ResendUserPhoneConfirmationException catch (e) {
      phoneCode.error.value = e.toMessage();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Starts or stops [resendEmailTimer] based on [enabled] value.
  void _setResendPhoneTimer([bool enabled = true]) {
    if (enabled) {
      resendPhoneTimeout.value = 30;
      _resendPhoneTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
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
