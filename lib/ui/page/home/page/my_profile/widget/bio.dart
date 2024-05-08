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
class UserBioField extends StatefulWidget {
  const UserBioField(this.bio, {super.key, this.onSubmit});

  /// [UserBio] of an [User].
  final UserBio? bio;

  /// Callback, called when the [UserBio] is submitted.
  final Future<void> Function(UserBio? status)? onSubmit;

  @override
  State<UserBioField> createState() => _UserBioFieldState();
}

/// State of a [UserBioField] maintaining the [_state].
class _UserBioFieldState extends State<UserBioField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.bio?.val ?? '',
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.isNotEmpty) {
        try {
          if (s.text.isNotEmpty) {
            UserBio(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      }

      if (s.error.value == null) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();

        try {
          await widget.onSubmit?.call(UserBio.tryParse(s.text));
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
  void didUpdateWidget(UserBioField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.bio?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return ReactiveTextField(
      key: const Key('BioField'),
      state: _state,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      label: 'label_description'.l10n,
      hint: 'label_about'.l10n,
      filled: true,
      maxLines: null,
      formatters: [LengthLimitingTextInputFormatter(4096)],
    );
  }
}
