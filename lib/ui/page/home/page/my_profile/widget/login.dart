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
import 'package:messenger/ui/page/home/page/user/widget/contact_info.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateUserLoginException;
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Custom-styled [ReactiveTextField] displaying editable [UserLogin].
class UserLoginField extends StatefulWidget {
  const UserLoginField(
    this.login, {
    super.key,
    this.onSubmit,
    this.editable = true,
  });

  /// Unique login of an [User].
  final UserLogin? login;

  /// Callback, called when [UserLogin] is submitted.
  final Future<void> Function(UserLogin? login)? onSubmit;
  final bool editable;

  @override
  State<UserLoginField> createState() => _UserLoginFieldState();
}

/// State of a [UserLoginField] maintaining the [_state].
class _UserLoginFieldState extends State<UserLoginField> {
  late bool _editing = widget.login == null;

  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.login?.val,
    approvable: true,
    submitted: false,
    onChanged: (s) async {
      s.error.value = null;

      if (s.text.isEmpty) {
        return;
      }

      try {
        UserLogin(s.text.toLowerCase());
      } on FormatException catch (_) {
        s.error.value = 'err_incorrect_login_input'.l10n;
      }
    },
    onSubmitted: (s) async {
      if (s.error.value == null) {
        s.editable.value = false;

        // if (!widget.editable) {
        s.status.value = RxStatus.loading();
        // }

        try {
          if (s.text.isEmpty) {
            await widget.onSubmit?.call(null);
          } else {
            await widget.onSubmit?.call(UserLogin(s.text.toLowerCase()));
          }

          if (widget.editable) {
            setState(() => _editing = false);
          }

          s.status.value = RxStatus.empty();
        } on UpdateUserLoginException catch (e) {
          s.error.value = e.toMessage();
          s.status.value = RxStatus.empty();
          s.unsubmit();
        } catch (e) {
          s.error.value = 'err_data_transfer'.l10n;
          s.status.value = RxStatus.empty();
          s.unsubmit();
          rethrow;
        } finally {
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
          clearable: widget.login == null,
          onChanged: () => _state.error.value = null,
          onCanceled: widget.login == null
              ? null
              : () {
                  _state.unsubmit();
                  _state.text = widget.login!.val;
                  // _state.submit();
                },
          label: 'label_login'.l10n,
          hint: widget.login == null
              ? 'label_login_hint'.l10n
              : widget.login!.val,
        ),
      );
    } else {
      child = Paddings.basic(
        ContactInfoContents(
          padding: EdgeInsets.zero,
          title: 'label_login'.l10n,
          content: _state.text,
          trailing: WidgetButton(
            onPressed: () => setState(() {
              _editing = true;
              _state.unsubmit();
              _state.changed.value = true;
            }),
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
