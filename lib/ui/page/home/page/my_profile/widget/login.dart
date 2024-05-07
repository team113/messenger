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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateUserLoginException;
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';

/// Custom-styled [ReactiveTextField] displaying editable [UserLogin].
class UserLoginField extends StatefulWidget {
  const UserLoginField(this.login, {super.key, this.onSubmit});

  /// Unique login of an [User].
  final UserLogin? login;

  /// Callback, called when [UserLogin] is submitted.
  final Future<void> Function(UserLogin? login)? onSubmit;

  @override
  State<UserLoginField> createState() => _UserLoginFieldState();
}

/// State of a [UserLoginField] maintaining the [_state] and [_editing].
class _UserLoginFieldState extends State<UserLoginField> {
  /// Indicates whether this [UserLoginField] is in editing mode.
  late bool _editing = widget.login == null;

  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.login?.val,
    onFocus: (s) async {
      if (s.text.isNotEmpty) {
        try {
          UserLogin(s.text.toLowerCase());
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_login_input'.l10n;
        }
      }

      if (s.error.value == null || s.resubmitOnError.isTrue) {
        s.editable.value = false;
        s.status.value = RxStatus.loading();

        try {
          await widget.onSubmit?.call(UserLogin.tryParse(s.text.toLowerCase()));

          if (mounted) {
            setState(() => _editing = false);
          }
        } on UpdateUserLoginException catch (e) {
          s.error.value = e.toMessage();
        } catch (e) {
          s.resubmitOnError.value = true;
          s.error.value = 'err_data_transfer'.l10n;
          s.unsubmit();
          s.changed.value = true;
          rethrow;
        } finally {
          s.status.value = RxStatus.empty();
          s.editable.value = true;
        }
      }
    },
  );

  @override
  void didUpdateWidget(UserLoginField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value &&
        _state.error.value == null) {
      _state.unchecked = widget.login?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;

    if (_editing) {
      child = Padding(
        key: const Key('1'),
        padding: const EdgeInsets.only(top: 8.0),
        child: ReactiveTextField(
          key: const Key('LoginField'),
          state: _state,
          onChanged: () => _state.error.value = null,
          onCanceled: widget.login == null
              ? null
              : () {
                  _state.unchecked = widget.login?.val;
                  if (mounted) {
                    setState(() => _editing = false);
                  }
                },
          label: 'label_login'.l10n,
          prefixText: '@',
          hint: widget.login == null
              ? 'label_login_hint'.l10n
              : widget.login!.val,
        ),
      );
    } else {
      child = Paddings.basic(
        InfoTile(
          title: 'label_login'.l10n,
          content: '@${_state.text}',
          trailing: AnimatedButton(
            onPressed: () => setState(() => _editing = true),
            child: const SvgIcon(SvgIcons.editField),
          ),
        ),
      );
    }

    return AnimatedSizeAndFade(
      fadeDuration: const Duration(milliseconds: 200),
      sizeDuration: const Duration(milliseconds: 200),
      child: child,
    );
  }
}
