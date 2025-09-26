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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/auth/account_is_not_accessible/view.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/login/controller.dart';
import '/ui/page/login/view.dart';
import '/ui/page/login/widget/sign_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import 'controller.dart';

/// View for known [MyUser] profiles management.
///
/// Intended to be displayed with the [show] method.
class AccountsView extends StatelessWidget {
  const AccountsView({super.key, this.initial = AccountsViewStage.accounts});

  /// Initial [AccountsViewStage] of this [AccountsView].
  final AccountsViewStage initial;

  /// Displays an [AccountsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    AccountsViewStage initial = AccountsViewStage.accounts,
  }) {
    return ModalPopup.show(
      context: context,
      background: Theme.of(context).style.colors.background,
      child: AccountsView(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('AccountsView'),
      init: AccountsController(Get.find(), Get.find(), initial: initial),
      builder: (AccountsController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;
          final List<Widget> bottom = [];

          switch (c.stage.value) {
            case AccountsViewStage.signInWithPassword:
              header = ModalPopupHeader(
                text: 'label_sign_in_with_password'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.signIn,
              );

              children = [
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('UsernameField'),
                  state: c.login,
                  label: 'label_sign_in_input'.l10n,
                ),
                const SizedBox(height: 16),
                ReactiveTextField(
                  key: const ValueKey('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgIcon(
                    c.obscurePassword.value
                        ? SvgIcons.visibleOff
                        : SvgIcons.visibleOn,
                  ),
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.login.isEmpty.value &&
                      !c.password.isEmpty.value &&
                      c.signInTimeout.value == 0 &&
                      !c.password.status.value.isLoading;

                  return PrimaryButton(
                    key: const Key('LoginButton'),
                    title: c.signInTimeout.value == 0
                        ? 'btn_sign_in'.l10n
                        : 'label_wait_seconds'.l10nfmt({
                            'for': c.signInTimeout.value,
                          }),
                    onPressed: enabled ? c.password.submit : null,
                  );
                }),
                const SizedBox(height: 16),
              ];
              break;

            case AccountsViewStage.signIn:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );

              children = [
                SignButton(
                  key: const Key('PasswordButton'),
                  title: 'btn_password'.l10n,
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signInWithPassword,
                  icon: const SvgIcon(SvgIcons.password),
                  padding: const EdgeInsets.only(left: 1),
                ),
                const SizedBox(height: 25 / 2),
                const SizedBox(height: 16),
              ];
              break;

            case AccountsViewStage.signUpWithEmailCode:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                Center(child: Text(c.email.text)),
                SizedBox(height: 20),
                Text(
                  'label_add_email_confirmation_sent'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('EmailCodeField'),
                  state: c.emailCode,
                  label: 'label_one_time_password'.l10n,
                  type: TextInputType.number,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hint: 'label_enter_code'.l10n,
                  obscure: c.obscureCode.value,
                  onSuffixPressed: c.obscureCode.toggle,
                  trailing: Center(
                    child: SvgIcon(
                      c.obscureCode.value
                          ? SvgIcons.visibleOff
                          : SvgIcons.visibleOn,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled =
                      !c.emailCode.isEmpty.value &&
                      c.codeTimeout.value == 0 &&
                      c.authStatus.value.isEmpty;

                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Resend'),
                          onPressed: enabled ? c.resendEmail : null,
                          title: c.resendEmailTimeout.value == 0
                              ? 'label_resend'.l10n
                              : 'label_resend_timeout'.l10nfmt({
                                  'timeout': c.resendEmailTimeout.value,
                                }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          key: const Key('Proceed'),
                          onPressed: c.emailCode.submit,
                          title: 'btn_sign_up'.l10n,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
              ];
              break;

            case AccountsViewStage.signUpWithEmail:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () {
                  c.stage.value = AccountsViewStage.signUp;
                  c.email.unsubmit();
                },
              );
              children = [
                ReactiveTextField(
                  state: c.email,
                  label: 'label_email'.l10n,
                  hint: 'label_email_example'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  style: style.fonts.normal.regular.onBackground,
                  treatErrorAsStatus: false,
                ),
                const SizedBox(height: 25),
                Center(
                  child: Obx(() {
                    final bool enabled = !c.email.isEmpty.value;

                    return PrimaryButton(
                      onPressed: enabled ? c.email.submit : null,
                      title: 'btn_send_one_time_code'.l10n,
                      leading: SvgIcon(
                        enabled ? SvgIcons.emailWhite : SvgIcons.emailGrey,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case AccountsViewStage.signUp:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                SignButton(
                  title: 'btn_email'.l10n,
                  icon: const SvgIcon(SvgIcons.email),
                  onPressed: () =>
                      c.stage.value = AccountsViewStage.signUpWithEmail,
                ),
                const SizedBox(height: 25 / 2),
                const SizedBox(height: 16),
              ];
              break;

            case AccountsViewStage.add:
              header = ModalPopupHeader(
                text: 'label_add_account'.l10n,
                onBack: initial == AccountsViewStage.accounts
                    ? () => c.stage.value = AccountsViewStage.accounts
                    : null,
              );

              children = [
                Center(
                  child: Obx(() {
                    final bool enabled = c.authStatus.value.isSuccess;

                    return OutlinedRoundedButton(
                      key: const Key('StartButton'),
                      maxWidth: 290,
                      height: 46,
                      leading: Transform.translate(
                        offset: const Offset(4, 0),
                        child: const SvgIcon(SvgIcons.guest),
                      ),
                      onPressed: enabled
                          ? () {
                              Navigator.of(context).pop();
                              c.register();
                            }
                          : () {},
                      child: Text('btn_guest'.l10n),
                    );
                  }),
                ),
                const SizedBox(height: 15),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('SignUpButton'),
                    maxWidth: 290,
                    height: 46,
                    leading: Transform.translate(
                      offset: const Offset(3, 0),
                      child: const SvgIcon(SvgIcons.register),
                    ),
                    onPressed: () => c.stage.value = AccountsViewStage.signUp,
                    child: Text('btn_sign_up'.l10n),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('SignInButton'),
                    maxWidth: 290,
                    height: 46,
                    leading: Transform.translate(
                      offset: const Offset(4, 0),
                      child: const SvgIcon(SvgIcons.enter),
                    ),
                    onPressed: () => c.stage.value = AccountsViewStage.signIn,
                    child: Text('btn_sign_in'.l10n),
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case AccountsViewStage.accounts:
              header = ModalPopupHeader(text: 'label_accounts'.l10n);
              children = [];

              for (final e in c.accounts) {
                children.add(
                  Obx(() {
                    final MyUser myUser = e.value;
                    final bool expired = !c.sessions.containsKey(myUser.id);
                    final bool active = c.me == myUser.id;

                    return ContactTile(
                      key: Key('Account_${e.value.id}'),
                      myUser: myUser,

                      // TODO: Prompt to sign in to the non-[authorized].
                      onTap: active
                          ? null
                          : () async {
                              if (expired) {
                                final hasPasswordOrEmail =
                                    myUser.hasPassword ||
                                    myUser.emails.confirmed.isNotEmpty ||
                                    myUser.phones.confirmed.isNotEmpty;

                                if (hasPasswordOrEmail) {
                                  await LoginView.show(
                                    context,
                                    initial: LoginViewStage.signIn,
                                    myUser: myUser,
                                  );
                                } else {
                                  await AccountIsNotAccessibleView.show(
                                    context,
                                    myUser,
                                  );
                                }
                              } else {
                                Navigator.of(context).pop();
                                await c.switchTo(myUser.id);
                              }
                            },

                      // TODO: Remove, when [MyUser]s will receive their
                      //       updates in real-time.
                      avatarBuilder: (_) => AvatarWidget.fromMyUser(
                        myUser,
                        radius: AvatarRadius.large,
                        badge: active,
                      ),

                      trailing: [
                        AnimatedButton(
                          key: const Key('RemoveAccount'),
                          decorator: (child) => Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                            child: child,
                          ),
                          onPressed: () async {
                            final bool hasPassword = myUser.hasPassword;
                            final bool canRecover =
                                myUser.emails.confirmed.isNotEmpty ||
                                myUser.phones.confirmed.isNotEmpty;

                            final bool? result = await MessagePopup.alert(
                              'btn_remove_account'.l10n,
                              additional: [
                                Center(
                                  child: Text(
                                    '${myUser.name ?? myUser.num}',
                                    style:
                                        style.fonts.normal.regular.onBackground,
                                  ),
                                ),

                                if (!hasPassword || !canRecover)
                                  const SizedBox(height: 16),

                                if (!hasPassword)
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          style.fonts.small.regular.secondary,
                                      children: [
                                        TextSpan(
                                          text: 'label_password_not_set1'.l10n,
                                          style: style
                                              .fonts
                                              .small
                                              .regular
                                              .onBackground,
                                        ),
                                        TextSpan(
                                          text: 'label_password_not_set2'.l10n,
                                        ),
                                      ],
                                    ),
                                  ),

                                if (!hasPassword && !canRecover)
                                  const SizedBox(height: 16),

                                if (!canRecover) ...[
                                  RichText(
                                    text: TextSpan(
                                      style:
                                          style.fonts.small.regular.secondary,
                                      children: [
                                        TextSpan(
                                          text: 'label_email_or_phone_not_set1'
                                              .l10n,
                                        ),
                                        TextSpan(
                                          text: 'label_email_or_phone_not_set2'
                                              .l10n,
                                          style: style
                                              .fonts
                                              .small
                                              .regular
                                              .onBackground,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                              button: (context) => MessagePopup.deleteButton(
                                context,
                                label: 'btn_remove_account'.l10n,
                                icon: SvgIcons.removeFromCallWhite,
                              ),
                            );

                            if (result == true) {
                              await c.deleteAccount(myUser.id);
                            }
                          },
                          child: active
                              ? const SvgIcon(SvgIcons.logoutWhite)
                              : const SvgIcon(SvgIcons.logout),
                        ),
                      ],
                      selected: active,
                      subtitle: [
                        const SizedBox(height: 5),
                        if (active)
                          Text(
                            'label_active_account'.l10n,
                            style: style.fonts.small.regular.onPrimary,
                          )
                        else if (expired)
                          Text(
                            'label_sign_in_required'.l10n,
                            style: style.fonts.small.regular.danger,
                          )
                        else
                          Text(
                            'label_signed_in'.l10n,
                            style: style.fonts.small.regular.secondary,
                          ),

                        // TODO: Uncomment, when [MyUser]s will receive their
                        //       updates in real-time.
                        // else
                        //   Text(
                        //     myUser.getStatus() ?? '',
                        //     style: style.fonts.small.regular.secondary,
                        //   )
                      ],
                    );
                  }),
                );
              }

              children.add(const SizedBox(height: 10));

              bottom.addAll([
                Padding(
                  padding: ModalPopup.padding(context),
                  child: PrimaryButton(
                    key: const Key('AddAccountButton'),
                    onPressed: () => c.stage.value = AccountsViewStage.add,
                    title: 'btn_add_account'.l10n,
                  ),
                ),
                const SizedBox(height: 16),
              ]);
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              key: Key('${c.stage.value.name.capitalized}Stage'),
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                const SizedBox(height: 13),
                Flexible(
                  child: ListView(
                    padding: ModalPopup.padding(context),
                    shrinkWrap: true,
                    children: children,
                  ),
                ),
                ...bottom,
              ],
            ),
          );
        });
      },
    );
  }
}

// TODO: Uncomment, when [MyUser]s will receive their updates in real-time.
/// Extension adding [MyUser] related wrappers and helpers.
// extension _MyUserViewExt on MyUser {
//   /// Returns a text represented status of this [MyUser] based on its
//   /// [MyUser.presence] and [MyUser.online] fields.
//   String? getStatus() {
//     switch (presence) {
//       case Presence.present:
//         if (online) {
//           return 'label_online'.l10n;
//         } else if (lastSeenAt != null) {
//           return lastSeenAt?.val.toDifferenceAgo();
//         } else {
//           return 'label_offline'.l10n;
//         }

//       case Presence.away:
//         if (online) {
//           return 'label_away'.l10n;
//         } else if (lastSeenAt != null) {
//           return lastSeenAt?.val.toDifferenceAgo();
//         } else {
//           return 'label_offline'.l10n;
//         }

//       case Presence.artemisUnknown:
//         return null;
//     }
//   }
// }
