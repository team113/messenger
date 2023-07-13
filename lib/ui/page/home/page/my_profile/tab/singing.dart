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
import '/ui/page/home/page/my_profile/add_email/controller.dart';
import '/ui/page/home/page/my_profile/add_phone/controller.dart';
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
            copy: widget.num?.val,
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

/// [Column] with addable list of user emails.
class EmailsColumn extends StatelessWidget {
  const EmailsColumn({
    super.key,
    this.text,
    this.confirmedEmails,
    this.onPressed,
    this.onTrailingPressed,
    this.hasUnconfirmed = false,
  });

  /// [List] of the user's currently verified email addresses.
  final List? confirmedEmails;

  /// Text of [FieldButton] with unverified email.
  final String? text;

  /// Indicator whether there is an unverified email.
  final bool hasUnconfirmed;

  /// Callback, called when [FieldButton] with unverified email is pressed.
  final void Function()? onPressed;

  /// Callback, called when the trailing is pressed.
  final void Function()? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    final List<Widget> widgets = [];

    for (UserEmail e in confirmedEmails ?? []) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldButton(
              key: const Key('ConfirmedEmail'),
              text: e.val,
              hint: 'label_email'.l10n,
              onPressed: () {
                PlatformUtils.copy(text: e.val);
                MessagePopup.success('label_copied'.l10n);
              },
              onTrailingPressed: onTrailingPressed,
              trailing: Transform.translate(
                key: const Key('DeleteEmail'),
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: RichText(
                text: TextSpan(
                  style: fonts.labelSmall,
                  children: [
                    TextSpan(
                      text: 'label_email_visible'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.primary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'label_email'.l10n,
                            additional: [
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
      widgets.add(const SizedBox(height: 10));
    }

    if (hasUnconfirmed) {
      widgets.addAll([
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme:
                Theme.of(context).inputDecorationTheme.copyWith(
                      floatingLabelStyle: fonts.bodyMedium!.copyWith(
                        color: style.colors.primary,
                      ),
                    ),
          ),
          child: FieldButton(
            key: const Key('UnconfirmedEmail'),
            text: text,
            hint: 'label_verify_email'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            onPressed: onPressed,
            onTrailingPressed: onTrailingPressed,
            style: fonts.titleMedium!.copyWith(color: style.colors.secondary),
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (!hasUnconfirmed) {
      widgets.add(
        FieldButton(
          key: confirmedEmails?.isNotEmpty == true
              ? const Key('AddAdditionalEmail')
              : const Key('AddEmail'),
          text: confirmedEmails?.isNotEmpty == true
              ? 'label_add_additional_email'.l10n
              : 'label_add_email'.l10n,
          onPressed: () => AddEmailView.show(context),
          style: fonts.titleMedium!.copyWith(color: style.colors.primary),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
    );
  }
}

/// [Column] with addable list of user phones.
class PhonesColumn extends StatelessWidget {
  const PhonesColumn({
    super.key,
    this.confirmedPhones,
    this.text,
    this.onPressed,
    this.onTrailingPressed,
    this.hasUnconfirmed = false,
  });

  /// [List] of the user's currently verified phone numbers.
  final List? confirmedPhones;

  /// Text of [FieldButton] with unverified phone.
  final String? text;

  /// Indicator whether there is an unverified phone.
  final bool hasUnconfirmed;

  /// Callback, called when [FieldButton] with unverified phone is pressed.
  final void Function()? onPressed;

  /// Callback, called when the trailing is pressed.
  final void Function()? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    final List<Widget> widgets = [];

    for (UserPhone e in confirmedPhones ?? []) {
      widgets.add(
        Column(
          key: const Key('ConfirmedPhone'),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldButton(
              text: e.val,
              hint: 'label_phone_number'.l10n,
              trailing: Transform.translate(
                key: const Key('DeletePhone'),
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              onPressed: () {
                PlatformUtils.copy(text: e.val);
                MessagePopup.success('label_copied'.l10n);
              },
              onTrailingPressed: onTrailingPressed,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: RichText(
                text: TextSpan(
                  style: fonts.labelSmall,
                  children: [
                    TextSpan(
                      text: 'label_phone_visible'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: fonts.bodySmall!.copyWith(
                        color: style.colors.primary,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          await ConfirmDialog.show(
                            context,
                            title: 'label_phone'.l10n,
                            additional: [
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
      widgets.add(const SizedBox(height: 10));
    }

    if (hasUnconfirmed) {
      widgets.addAll([
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme:
                Theme.of(context).inputDecorationTheme.copyWith(
                      floatingLabelStyle: fonts.bodyMedium!.copyWith(
                        color: style.colors.primary,
                      ),
                    ),
          ),
          child: FieldButton(
            key: const Key('UnconfirmedPhone'),
            text: text,
            hint: 'label_verify_number'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            onPressed: onPressed,
            onTrailingPressed: onTrailingPressed,
            style: fonts.titleMedium!.copyWith(color: style.colors.secondary),
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (!hasUnconfirmed) {
      widgets.add(
        FieldButton(
          key: confirmedPhones?.isNotEmpty == true
              ? const Key('AddAdditionalPhone')
              : const Key('AddPhone'),
          onPressed: () => AddPhoneView.show(context),
          text: confirmedPhones?.isNotEmpty == true
              ? 'label_add_additional_number'.l10n
              : 'label_add_number'.l10n,
          style: fonts.titleMedium?.copyWith(color: style.colors.primary),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Paddings.dense(e)).toList(),
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
