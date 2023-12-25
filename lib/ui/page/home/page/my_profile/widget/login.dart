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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateUserLoginException;
import '/themes.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Custom-styled [ReactiveTextField] displaying editable [UserLogin].
class UserLoginField extends StatefulWidget {
  const UserLoginField(this.login, {super.key, this.onSubmit});

  /// Unique login of an [User].
  final UserLogin? login;

  /// Callback, called when [UserLogin] is submitted.
  final Future<void> Function(UserLogin login)? onSubmit;

  @override
  State<UserLoginField> createState() => _UserLoginFieldState();
}

/// State of a [UserLoginField] maintaining the [_state].
class _UserLoginFieldState extends State<UserLoginField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.login?.val,
    approvable: true,
    onChanged: (s) async {
      s.error.value = null;

      if (s.text.isEmpty) {
        s.unchecked = widget.login?.val ?? '';
        s.status.value = RxStatus.empty();
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
        s.status.value = RxStatus.loading();
        try {
          await widget.onSubmit?.call(UserLogin(s.text.toLowerCase()));
          s.status.value = RxStatus.empty();
        } on UpdateUserLoginException catch (e) {
          s.error.value = e.toMessage();
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
  void didUpdateWidget(UserLoginField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.login?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      key: const Key('LoginField'),
      state: _state,
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
      label: 'label_login'.l10n,
      hint: widget.login == null ? 'label_login_hint'.l10n : widget.login!.val,
      clearable: false,
      subtitle: true
          ? null
          : RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'label_login_visible'.l10n,
                    style: style.fonts.small.regular.secondary,
                  ),
                  TextSpan(
                    text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                    style: style.fonts.small.regular.primary,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await ConfirmDialog.show(
                          context,
                          title: 'label_login'.l10n,
                          additional: [
                            Center(
                              child: Text(
                                'label_login_visibility_hint'.l10n,
                                style: style.fonts.normal.regular.secondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'label_visible_to'.l10n,
                                style: style.fonts.big.regular.onBackground,
                              ),
                            ),
                          ],
                          label: 'label_confirm'.l10n,
                          initial: 2,
                          variants: [
                            ConfirmDialogVariant(
                              onProceed: () {},
                              label: 'label_all'.l10n,
                            ),
                            ConfirmDialogVariant(
                              onProceed: () {},
                              label: 'label_my_contacts'.l10n,
                            ),
                            ConfirmDialogVariant(
                              onProceed: () {},
                              label: 'label_nobody'.l10n,
                            ),
                          ],
                        );
                      },
                  ),
                ],
              ),
            ),
    );
  }
}
