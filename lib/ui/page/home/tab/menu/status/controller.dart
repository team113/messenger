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

import '/api/backend/schema.dart' show Presence;
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

/// Controller of a [StatusView].
class StatusController extends GetxController {
  StatusController(this._myUserService);

  /// Selected [Presence].
  final Rx<Presence?> presence = Rx(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [MyUser.status]'s field state.
  late final TextFieldState status;

  /// Service responsible for [MyUser] management.
  final MyUserService _myUserService;

  /// [Timer] to set a `RxStatus.empty` status of the [status] field.
  Timer? _statusTimer;

  /// Worker invoking [setPresence] on the [presence] changes.
  Worker? _worker;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    presence.value = myUser.value?.presence;

    _worker = debounce(
      presence,
      (Presence? presence) {
        if (myUser.value?.presence != presence && presence != null) {
          setPresence(presence);
        }
      },
      time: 350.milliseconds,
    );

    status = TextFieldState(
      text: myUser.value?.status?.val ?? '',
      approvable: true,
      onChanged: (s) {
        s.error.value = null;

        try {
          if (s.text.isNotEmpty) {
            UserTextStatus(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        try {
          if (s.text.isNotEmpty) {
            UserTextStatus(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          _statusTimer?.cancel();
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            await _myUserService.updateUserStatus(
              s.text.isNotEmpty ? UserTextStatus(s.text) : null,
            );
            s.status.value = RxStatus.success();
            _statusTimer = Timer(
              const Duration(milliseconds: 1500),
              () => s.status.value = RxStatus.empty(),
            );
          } catch (e) {
            s.error.value = 'err_data_transfer'.l10n;
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );

    super.onInit();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  /// Sets the [MyUser.presence] to the provided value.
  Future<void> setPresence(Presence presence) =>
      _myUserService.updateUserPresence(presence);
}
