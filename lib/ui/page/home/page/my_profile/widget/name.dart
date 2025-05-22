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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Custom-styled [ReactiveTextField] displaying editable [name].
class UserNameField extends StatefulWidget {
  const UserNameField(this.name, {super.key, this.onSubmit});

  /// Name of an [User].
  final UserName? name;

  /// Callback, called when [UserName] is submitted.
  final FutureOr<void> Function(UserName? name)? onSubmit;

  @override
  State<UserNameField> createState() => _UserNameFieldState();
}

/// State of a [UserNameField] maintaining the [_state].
class _UserNameFieldState extends State<UserNameField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.name?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.isNotEmpty) {
        try {
          UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();

        try {
          await widget.onSubmit?.call(UserName.tryParse(s.text));
        } catch (e) {
          s.resubmitOnError.value = true;
          s.error.value = 'err_data_transfer'.l10n;
          rethrow;
        } finally {
          s.status.value = RxStatus.empty();
          s.editable.value = true;
        }
      }
    },
  );

  @override
  void didUpdateWidget(UserNameField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.name?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField(
      key: const Key('NameField'),
      state: _state,
      label: 'label_name'.l10n,
      hint: 'label_name_hint'.l10n,
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      onSuffixPressed: _state.text.isEmpty
          ? null
          : () {
              PlatformUtils.copy(text: _state.text);
              MessagePopup.success('label_copied'.l10n);
            },
      trailing: _state.text.isEmpty
          ? null
          : Transform.translate(
              offset: const Offset(0, -1),
              child: const SvgIcon(SvgIcons.copy),
            ),
    );
  }
}
