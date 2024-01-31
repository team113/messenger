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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/text_field.dart';

/// Custom-styled [ReactiveTextField] displaying editable [status].
class UserTextStatusField extends StatefulWidget {
  const UserTextStatusField(this.status, {super.key, this.onSubmit});

  /// Status of an [User].
  final UserTextStatus? status;

  /// Callback, called when the [UserTextStatus] is submitted.
  final Future<void> Function(UserTextStatus? status)? onSubmit;

  @override
  State<UserTextStatusField> createState() => _UserTextStatusFieldState();
}

/// State of a [UserTextStatusField] maintaining the [_state].
class _UserTextStatusFieldState extends State<UserTextStatusField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.status?.val ?? '',
    onChanged: (s) {
      s.error.value = null;

      try {
        if (s.text.isNotEmpty) {
          UserTextStatus(s.text);
        }
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_input'.l10n;
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();

        try {
          widget.onSubmit?.call(
            s.text.isNotEmpty ? UserTextStatus(s.text) : null,
          );
          s.status.value = RxStatus.empty();
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

  @override
  void didUpdateWidget(UserTextStatusField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.status?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField(
      key: const Key('StatusField'),
      state: _state,
      label: 'label_about'.l10n,
      filled: true,
      maxLines: null,
      formatters: [LengthLimitingTextInputFormatter(4096)],
    );
  }
}
