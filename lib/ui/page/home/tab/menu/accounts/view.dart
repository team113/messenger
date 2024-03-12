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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// ...
///
/// Intended to be displayed with the [show] method.
class AccountsView extends StatelessWidget {
  const AccountsView({
    super.key,
    this.initial = AccountsViewStage.accounts,
  });

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
      init: AccountsController(Get.find()),
      builder: (AccountsController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case AccountsViewStage.signIn:
              header = ModalPopupHeader(
                text: 'label_sign_in'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                const SizedBox(height: 50 - 12 - 13),
                // ReactiveTextField(
                //   key: const Key('LoginField'),
                //   state: c.login,
                //   label: 'label_login'.l10n,
                //   treatErrorAsStatus: false,
                // ),
                // const SizedBox(height: 12),
                // ReactiveTextField(
                //   key: const Key('PasswordField'),
                //   state: c.password,
                //   label: 'label_password'.l10n,
                //   obscure: c.obscurePassword.value,
                //   onSuffixPressed: c.obscurePassword.toggle,
                //   treatErrorAsStatus: false,
                //   trailing: SvgIcon(
                //     c.obscurePassword.value
                //         ? SvgIcons.visibleOff
                //         : SvgIcons.visibleOn,
                //   ),
                // ),
                // const SizedBox(height: 50),
                // Row(
                //   children: [
                //     Expanded(
                //       child: OutlinedRoundedButton(
                //         key: const Key('BackButton'),
                //         maxWidth: double.infinity,
                //         onPressed: () => c.stage.value = AccountsViewStage.add,
                //         color: const Color(0xFFEEEEEE),
                //         child: Text('btn_back'.l10n),
                //       ),
                //     ),
                //     const SizedBox(width: 10),
                //     Expanded(
                //       child: OutlinedRoundedButton(
                //         key: const Key('LoginButton'),
                //         maxWidth: double.infinity,
                //         onPressed: () {},
                //         color: const Color(0xFF63B4FF),
                //         child: Text('Login'.l10n),
                //       ),
                //     ),
                //   ],
                // ),
              ];
              break;

            case AccountsViewStage.signUp:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                const SizedBox(height: 50 - 12 - 13),
                // ReactiveTextField(
                //   key: const Key('LoginField'),
                //   state: c.login,
                //   label: 'label_login'.l10n,
                //   treatErrorAsStatus: false,
                // ),
                // const SizedBox(height: 12),
                // ReactiveTextField(
                //   key: const Key('PasswordField'),
                //   state: c.password,
                //   label: 'label_password'.l10n,
                //   obscure: c.obscurePassword.value,
                //   onSuffixPressed: c.obscurePassword.toggle,
                //   treatErrorAsStatus: false,
                //   trailing: SvgIcon(
                //     c.obscurePassword.value
                //         ? SvgIcons.visibleOff
                //         : SvgIcons.visibleOn,
                //   ),
                // ),
                // const SizedBox(height: 50),
                // Row(
                //   children: [
                //     Expanded(
                //       child: OutlinedRoundedButton(
                //         key: const Key('BackButton'),
                //         maxWidth: double.infinity,
                //         onPressed: () => c.stage.value = AccountsViewStage.add,
                //         color: const Color(0xFFEEEEEE),
                //         child: Text('btn_back'.l10n),
                //       ),
                //     ),
                //     const SizedBox(width: 10),
                //     Expanded(
                //       child: OutlinedRoundedButton(
                //         key: const Key('LoginButton'),
                //         maxWidth: double.infinity,
                //         onPressed: () {},
                //         color: const Color(0xFF63B4FF),
                //         child: Text('Login'.l10n),
                //       ),
                //     ),
                //   ],
                // ),
              ];
              break;

            case AccountsViewStage.add:
              header = ModalPopupHeader(
                text: 'Add account'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.accounts,
              );

              children = [
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
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
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
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
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      key: const Key('StartButton'),
                      maxWidth: 290,
                      height: 46,
                      leading: Transform.translate(
                        offset: const Offset(4, 0),
                        child: const SvgIcon(SvgIcons.guest),
                      ),
                      onPressed: () {
                        router.accounts.value++;
                        Navigator.of(context).pop();
                      },
                      child: Text('btn_guest'.l10n),
                    ),
                  ),
                ),
                // Padding(
                //   padding: ModalPopup.padding(context),
                //   child: ReactiveTextField(
                //     key: const Key('LoginField'),
                //     state: c.login,
                //     label: 'label_login'.l10n,
                //     treatErrorAsStatus: false,
                //   ),
                // ),
                // const SizedBox(height: 12),
                // Padding(
                //   padding: ModalPopup.padding(context),
                //   child: ReactiveTextField(
                //     key: const Key('PasswordField'),
                //     state: c.password,
                //     label: 'label_password'.l10n,
                //     obscure: c.obscurePassword.value,
                //     onSuffixPressed: c.obscurePassword.toggle,
                //     treatErrorAsStatus: false,
                //     trailing: SvgIcon(
                //       c.obscurePassword.value
                //           ? SvgIcons.visibleOff
                //           : SvgIcons.visibleOn,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 18),
                // Padding(
                //   padding: ModalPopup.padding(context),
                //   child: Center(
                //     child: OutlinedRoundedButton(
                //       onPressed: () {
                //         Navigator.of(context).pop();
                //         router.accounts.value++;
                //       },
                //       color: const Color(0xFFEEEEEE),
                //       maxWidth: double.infinity,
                //       child: Text('Login'.l10n),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 25),
                // Center(
                //   child: Text('OR'.l10n),
                // ),
                // const SizedBox(height: 25),
                // Padding(
                //   padding: ModalPopup.padding(context),
                //   child: Center(
                //     child: OutlinedRoundedButton(
                //       onPressed: () {
                //         Navigator.of(context).pop();
                //         router.accounts.value++;
                //       },
                //       color: const Color(0xFF63B4FF),
                //       maxWidth: double.infinity,
                //       child: Text(
                //         'Create account'.l10n,
                //         style: const TextStyle(color: Colors.white),
                //       ),
                //     ),
                //   ),
                // ),
              ];
              break;

            case AccountsViewStage.accounts:
              header = ModalPopupHeader(text: 'Your accounts'.l10n);

              children = [
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ContactTile(
                    myUser: c.myUser.value,
                    onTap: Navigator.of(context).pop,
                    trailing: [
                      Text(
                        'Active',
                        style: style.fonts.normal.regular.secondary,
                      ),
                    ],
                    subtitle: [
                      const SizedBox(height: 5),
                      Text(
                        'Online',
                        style: style.fonts.small.regular.secondary,
                      ),
                    ],
                  ),
                ),
                for (int i = 0; i < router.accounts.value; ++i)
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: ContactTile(
                      myUser: c.myUser.value,
                      selected: false,
                      onTap: Navigator.of(context).pop,
                      subtitle: [
                        const SizedBox(height: 5),
                        Text(
                          '10 days ago',
                          style: style.fonts.small.regular.secondary,
                        ),
                      ],
                      trailing: [
                        AnimatedButton(
                          decorator: (child) => Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                            child: child,
                          ),
                          onPressed: () {
                            // TODO: Add confirm modal.
                            router.accounts.value--;
                          },
                          child: const SvgIcon(SvgIcons.delete19),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: PrimaryButton(
                    onPressed: () => c.stage.value = AccountsViewStage.add,
                    title: 'Add account'.l10n,
                  ),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
              children: [
                header,
                const SizedBox(height: 13),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    children: [
                      ...children,
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
