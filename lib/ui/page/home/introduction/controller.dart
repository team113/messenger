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
import 'package:messenger/routes.dart';
import 'package:messenger/util/message_popup.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/provider/gql/exceptions.dart'
    show
        ConfirmUserEmailException,
        ResendUserEmailConfirmationException,
        UpdateUserPasswordException;
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

/// Possible [IntroductionViewStage] flow stage.
enum IntroductionViewStage {
  password,
  success,
  validate,
}

/// Controller of an [IntroductionView].
class IntroductionController extends GetxController {
  IntroductionController(this._myUserService);

  /// [IntroductionViewStage] currently being displayed.
  final Rx<IntroductionViewStage?> stage = Rx(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [MyUser.num]'s copyable [TextFieldState].
  late final TextFieldState num;

  /// [TextFieldState] for a password input.
  late final TextFieldState password;

  /// [TextFieldState] for a repeated password input.
  late final TextFieldState repeat;

  /// Indicator whether the [password] should be obscured.
  final RxBool obscurePassword = RxBool(true);

  /// Indicator whether the [repeat]ed password should be obscured.
  final RxBool obscureRepeat = RxBool(true);

  /// Indicator whether [UserEmail] confirmation code has been resent.
  final RxBool resent = RxBool(false);

  /// Timeout of a [resendEmail].
  final RxInt resendEmailTimeout = RxInt(0);

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
          await _myUserService.confirmEmailCode(ConfirmationCode(s.text));
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

  /// [MyUserService] setting the password.
  final MyUserService _myUserService;

  /// [Timer] decreasing the [resendEmailTimeout].
  Timer? _resendEmailTimer;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    num = TextFieldState(
      text: _myUserService.myUser.value!.num.val
          .replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)} '),
      editable: false,
    );

    password = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        if (s.text.isNotEmpty) {
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
        }
      },
      onSubmitted: (_) => repeat.focus.requestFocus(),
    );

    repeat = TextFieldState(
      onChanged: (s) {
        password.error.value = null;
        repeat.error.value = null;

        if (s.text.isNotEmpty) {
          try {
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
        }
      },
      onSubmitted: (_) => setPassword(),
    );

    if (router.validateEmail) {
      stage.value = IntroductionViewStage.validate;
      _setResendEmailTimer();
    }

    super.onInit();
  }

  @override
  void onClose() {
    router.validateEmail = false;
    _setResendEmailTimer(false);
    super.onClose();
  }

  /// Validates and sets the [password] of the currently authenticated [MyUser].
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
    try {
      await _myUserService.updateUserPassword(
          newPassword: UserPassword(repeat.text));
      stage.value = IntroductionViewStage.success;
    } on UpdateUserPasswordException catch (e) {
      repeat.error.value = e.toMessage();
    } catch (e) {
      repeat.error.value = 'err_data_transfer'.l10n;
      rethrow;
    } finally {
      password.editable.value = true;
      repeat.editable.value = true;
    }
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
