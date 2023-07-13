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
import '/ui/page/home/page/my_profile/password/controller.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Custom-styled [CopyableTextField] to display copyable [num].
class CopyableNumField extends StatefulWidget {
  const CopyableNumField(this.num, {super.key});

  /// Unique number of an [User].
  final UserNum? num;

  @override
  State<CopyableNumField> createState() => _CopyableNumFieldState();
}

/// State of an [CopyableNumField] maintaining the [_state].
class _CopyableNumFieldState extends State<CopyableNumField> {
  /// State of the [ReactiveTextField].
  late final TextFieldState _state = TextFieldState(
    text: widget.num?.val.replaceAllMapped(
      RegExp(r'.{4}'),
      (match) => '${match.group(0)} ',
    ),
    editable: false,
  );

  @override
  Widget build(BuildContext context) {
    return Paddings.basic(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CopyableTextField(
            key: const Key('NumCopyable'),
            state: _state,
            label: 'label_num'.l10n,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// [ReactiveTextField] with label to display user login.
class ReactiveLoginField extends StatefulWidget {
  const ReactiveLoginField(this.login, {super.key, this.onCreate});

  /// Unique login of an [User].
  final UserLogin? login;

  /// Callback, called when a `UserLogin` is spotted.
  final FutureOr<void> Function(UserLogin login)? onCreate;

  @override
  State<ReactiveLoginField> createState() => _ReactiveLoginFieldState();
}

/// State of an [ReactiveLoginField] maintaining the [_state].
class _ReactiveLoginFieldState extends State<ReactiveLoginField> {
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
          await widget.onCreate?.call(UserLogin(s.text.toLowerCase()));
          s.status.value = RxStatus.success();
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
  void didUpdateWidget(ReactiveLoginField oldWidget) {
    if (!_state.focus.hasFocus &&
        !_state.changed.value &&
        _state.editable.value) {
      _state.unchecked = widget.login?.val;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Paddings.basic(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReactiveTextField(
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
                    child: Transform.scale(
                      scale: 1.15,
                      child:
                          SvgImage.asset('assets/icons/copy.svg', height: 15),
                    ),
                  ),
            label: 'label_login'.l10n,
            hint: widget.login == null
                ? 'label_login_hint'.l10n
                : widget.login?.val,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'label_login_visible'.l10n,
                    style: fonts.labelSmall!.copyWith(
                      color: style.colors.secondary,
                    ),
                  ),
                  TextSpan(
                    text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                    style: fonts.labelSmall!.copyWith(
                      color: style.colors.primary,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await ConfirmDialog.show(
                          context,
                          title: 'label_login'.l10n,
                          additional: [
                            Center(
                              child: Text(
                                'label_login_visibility_hint'.l10n,
                                style: fonts.labelLarge!.copyWith(
                                  color: style.colors.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'label_visible_to'.l10n,
                                style: fonts.headlineMedium,
                              ),
                            ),
                          ],
                          label: 'label_confirm'.l10n,
                          initial: 2,
                          variants: [
                            ConfirmDialogVariant(
                              onProceed: () {},
                              child: Text('label_all'.l10n),
                            ),
                            ConfirmDialogVariant(
                              onProceed: () {},
                              child: Text('label_my_contacts'.l10n),
                            ),
                            ConfirmDialogVariant(
                              onProceed: () {},
                              child: Text('label_nobody'.l10n),
                            ),
                          ],
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom-styled [FieldButton] for changing or setting the user password.
class ProfilePassword extends StatelessWidget {
  const ProfilePassword({super.key, this.hasPassword = false});

  /// Indicator whether user has a password.
  final bool hasPassword;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Paddings.dense(
          FieldButton(
            key: hasPassword
                ? const Key('ChangePassword')
                : const Key('SetPassword'),
            text: hasPassword
                ? 'btn_change_password'.l10n
                : 'btn_set_password'.l10n,
            onPressed: () => ChangePasswordView.show(context),
            style: fonts.titleMedium!.copyWith(
              color: !hasPassword
                  ? style.colors.dangerColor
                  : style.colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
