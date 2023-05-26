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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../copyable.dart';
import '../dense.dart';
import '../padding.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/add_email/controller.dart';
import '/ui/page/home/page/my_profile/add_phone/controller.dart';
import '/ui/page/home/page/my_profile/password/controller.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/ui/page/home/widget/confirm_dialog.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Widget] which returns [MyUser.num] copyable field.
class ProfileNum extends StatelessWidget {
  const ProfileNum(this.myUser, this.num, {super.key});

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  /// [MyUser.num] copyable state.
  final TextFieldState num;

  @override
  Widget build(BuildContext context) {
    return BasicPadding(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CopyableTextField(
            key: const Key('NumCopyable'),
            state: num,
            label: 'label_num'.l10n,
            copy: myUser?.num.val,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

/// [Widget] which returns [MyUser.login] editable field.
class ProfileLogin extends StatelessWidget {
  const ProfileLogin(this.myUser, this.login, {super.key});

  /// [MyUser.login] field state.
  final TextFieldState login;

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return BasicPadding(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReactiveTextField(
            key: const Key('LoginField'),
            state: login,
            onSuffixPressed: login.text.isEmpty
                ? null
                : () {
                    PlatformUtils.copy(text: login.text);
                    MessagePopup.success('label_copied'.l10n);
                  },
            trailing: login.text.isEmpty
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
            hint: myUser?.login == null
                ? 'label_login_hint'.l10n
                : myUser!.login!.val,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal),
                children: [
                  TextSpan(
                    text: 'label_login_visible'.l10n,
                    style: TextStyle(color: style.colors.secondary),
                  ),
                  TextSpan(
                    text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                    style: TextStyle(
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
                                style: TextStyle(
                                  fontSize: 15,
                                  color: style.colors.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'label_visible_to'.l10n,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: style.colors.onBackground,
                                ),
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

/// [Widget] which returns addable list of [MyUser.emails] .
class ProfileEmails extends StatelessWidget {
  const ProfileEmails(this.myUser, this.onTrailingPressed, {super.key});

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  /// Callback, called when the trailing is pressed.
  final void Function()? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final List<Widget> widgets = [];

    for (UserEmail e in myUser?.emails.confirmed ?? []) {
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_email_visible'.l10n,
                      style: TextStyle(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: TextStyle(color: style.colors.primary),
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: style.colors.onBackground,
                                  ),
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

    if (myUser?.emails.unconfirmed != null) {
      widgets.addAll([
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context)
                .inputDecorationTheme
                .copyWith(
                  floatingLabelStyle: TextStyle(color: style.colors.primary),
                ),
          ),
          child: FieldButton(
            key: const Key('UnconfirmedEmail'),
            text: myUser!.emails.unconfirmed!.val,
            hint: 'label_verify_email'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            onPressed: () => AddEmailView.show(
              context,
              email: myUser!.emails.unconfirmed!,
            ),
            onTrailingPressed: onTrailingPressed,
            style: TextStyle(color: style.colors.secondary),
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (myUser?.emails.unconfirmed == null) {
      widgets.add(
        FieldButton(
          key: myUser?.emails.confirmed.isNotEmpty == true
              ? const Key('AddAdditionalEmail')
              : const Key('AddEmail'),
          text: myUser?.emails.confirmed.isNotEmpty == true
              ? 'label_add_additional_email'.l10n
              : 'label_add_email'.l10n,
          onPressed: () => AddEmailView.show(context),
          style: TextStyle(color: style.colors.primary),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Dense(e)).toList(),
    );
  }
}

/// [Widget] which returns addable list of [MyUser.phones].
class ProfilePhones extends StatelessWidget {
  const ProfilePhones(this.myUser, this.onTrailingPressed, {super.key});

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  /// Callback, called when the trailing is pressed.
  final void Function()? onTrailingPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final List<Widget> widgets = [];

    for (UserPhone e in [...myUser?.phones.confirmed ?? []]) {
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                  children: [
                    TextSpan(
                      text: 'label_phone_visible'.l10n,
                      style: TextStyle(
                        color: style.colors.secondary,
                      ),
                    ),
                    TextSpan(
                      text: 'label_nobody'.l10n.toLowerCase() + 'dot'.l10n,
                      style: TextStyle(
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
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: style.colors.onBackground,
                                  ),
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

    if (myUser?.phones.unconfirmed != null) {
      widgets.addAll([
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: Theme.of(context)
                .inputDecorationTheme
                .copyWith(
                  floatingLabelStyle: TextStyle(color: style.colors.primary),
                ),
          ),
          child: FieldButton(
            key: const Key('UnconfirmedPhone'),
            text: myUser!.phones.unconfirmed!.val,
            hint: 'label_verify_number'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            onPressed: () => AddPhoneView.show(
              context,
              phone: myUser!.phones.unconfirmed!,
            ),
            onTrailingPressed: onTrailingPressed,
            style: TextStyle(color: style.colors.secondary),
          ),
        ),
      ]);
      widgets.add(const SizedBox(height: 10));
    }

    if (myUser?.phones.unconfirmed == null) {
      widgets.add(
        FieldButton(
          key: myUser?.phones.confirmed.isNotEmpty == true
              ? const Key('AddAdditionalPhone')
              : const Key('AddPhone'),
          onPressed: () => AddPhoneView.show(context),
          text: myUser?.phones.confirmed.isNotEmpty == true
              ? 'label_add_additional_number'.l10n
              : 'label_add_number'.l10n,
          style: TextStyle(color: style.colors.primary),
        ),
      );
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets.map((e) => Dense(e)).toList(),
    );
  }
}

/// [Widget] which returns the buttons changing or setting the password of
/// the currently authenticated [MyUser].
class ProfilePassword extends StatelessWidget {
  const ProfilePassword(this.myUser, {super.key});

  /// [MyUser] that stores the currently authenticated user.
  final MyUser? myUser;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Dense(
          FieldButton(
            key: myUser?.hasPassword == true
                ? const Key('ChangePassword')
                : const Key('SetPassword'),
            text: myUser?.hasPassword == true
                ? 'btn_change_password'.l10n
                : 'btn_set_password'.l10n,
            onPressed: () => ChangePasswordView.show(context),
            style: TextStyle(
              color: myUser?.hasPassword != true
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
