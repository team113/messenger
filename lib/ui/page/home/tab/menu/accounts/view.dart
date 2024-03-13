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
import 'package:messenger/domain/model/account.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/message_popup.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
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
      init: AccountsController(Get.find(), Get.find()),
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
                      !c.login.isEmpty.value && !c.password.isEmpty.value;

                  return PrimaryButton(
                    key: const Key('LoginButton'),
                    title: 'btn_sign_in'.l10n,
                    onPressed: enabled ? c.password.submit : null,
                  );
                }),
              ];
              break;

            case AccountsViewStage.signUp:
              header = ModalPopupHeader(
                text: 'label_sign_up'.l10n,
                onBack: () => c.stage.value = AccountsViewStage.add,
              );
              children = [
                const SizedBox(height: 50 - 12 - 13),
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
                        c.switchTo(null);
                      },
                      child: Text('btn_guest'.l10n),
                    ),
                  ),
                ),
              ];
              break;

            case AccountsViewStage.accounts:
              header = ModalPopupHeader(text: 'Your accounts'.l10n);

              final Account? active = c.accounts
                  .firstWhereOrNull((e) => c.myUser.value?.id == e.myUser.id);

              final List<Account> accounts =
                  c.accounts.where((e) => e != active).toList();
              accounts.sort(
                (a, b) => '${a.myUser.name ?? a.myUser.num}'
                    .compareTo('${b.myUser.name ?? b.myUser.num}'),
              );

              if (active != null) {
                accounts.insert(0, active);
              }

              children = [
                for (var e in accounts)
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: ContactTile(
                      myUser: e.myUser,
                      onTap: () {
                        Navigator.of(context).pop();

                        if (c.myUser.value?.id != e.myUser.id) {
                          c.switchTo(e);
                        }
                      },
                      trailing: [
                        if (c.myUser.value?.id == e.myUser.id)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
                            child: Text(
                              'Active',
                              style: style.fonts.normal.regular.secondary,
                            ),
                          )
                        else
                          AnimatedButton(
                            decorator: (child) => Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                              child: child,
                            ),
                            onPressed: () async {
                              final result = await MessagePopup.alert(
                                'btn_logout'.l10n,
                                description: [
                                  TextSpan(
                                    style: style.fonts.medium.regular.secondary,
                                    children: [
                                      TextSpan(
                                        text:
                                            'alert_are_you_sure_want_to_log_out1'
                                                .l10n,
                                      ),
                                      TextSpan(
                                        style: style
                                            .fonts.medium.regular.onBackground,
                                        text: e.myUser.name?.val ??
                                            e.myUser.num.toString(),
                                      ),
                                      TextSpan(
                                        text:
                                            'alert_are_you_sure_want_to_log_out2'
                                                .l10n,
                                      ),
                                      if (!e.myUser.hasPassword) ...[
                                        const TextSpan(text: '\n\n'),
                                        TextSpan(
                                          text:
                                              'Пароль не задан. Доступ к аккаунту может быть утерян безвозвратно.'
                                                  .l10n,
                                        ),
                                      ],
                                      if (e
                                          .myUser.emails.confirmed.isEmpty) ...[
                                        const TextSpan(text: '\n\n'),
                                        TextSpan(
                                          text:
                                              'E-mail или номер телефона не задан. Восстановление доступа к аккаунту невозможно.'
                                                  .l10n,
                                        ),
                                      ],
                                    ],
                                  )
                                ],
                              );

                              if (result == true) {
                                c.delete(e);
                              }
                            },
                            child: const SvgIcon(SvgIcons.logout),
                          ),
                      ],
                      subtitle: [
                        const SizedBox(height: 5),
                        if (c.myUser.value?.id == e.myUser.id)
                          Text(
                            'Online',
                            style: style.fonts.small.regular.secondary,
                          )
                        else
                          Text(
                            'Offline',
                            style: style.fonts.small.regular.secondary,
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
                      const SizedBox(height: 16),
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
