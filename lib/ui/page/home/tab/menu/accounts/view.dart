// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';

import '/l10n/l10n.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/sharable.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// ...
///
/// Intended to be displayed with the [show] method.
class AccountsView extends StatelessWidget {
  const AccountsView({Key? key}) : super(key: key);

  /// Displays an [AccountsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      // color: const Color.fromARGB(255, 233, 235, 237),
      child: const AccountsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      key: const Key('AccountsView'),
      init: AccountsController(Get.find()),
      builder: (AccountsController c) {
        return Obx(() {
          List<Widget> children;

          switch (c.stage.value) {
            case AccountsViewStage.login:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'Login'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 50 - 12),
                ReactiveTextField(
                  key: const Key('LoginField'),
                  state: c.login,
                  label: 'label_login'.l10n,
                  style: thin,
                  treatErrorAsStatus: false,
                ),
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  style: thin,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgLoader.asset(
                    'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 50),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('BackButton'),
                        maxWidth: double.infinity,
                        title: Text('btn_back'.l10n, style: thin),
                        onPressed: () => c.stage.value = AccountsViewStage.add,
                        color: const Color(0xFFEEEEEE),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('LoginButton'),
                        maxWidth: double.infinity,
                        title: Text(
                          'Login'.l10n,
                          style: thin?.copyWith(color: Colors.white),
                        ),
                        onPressed: () {},
                        color: const Color(0xFF63B4FF),
                      ),
                    ),
                  ],
                ),
              ];
              break;

            case AccountsViewStage.add:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'Add account'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                  onBack: () => c.stage.value = null,
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('LoginField'),
                    state: c.login,
                    label: 'label_login'.l10n,
                    style: thin,
                    treatErrorAsStatus: false,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('PasswordField'),
                    state: c.password,
                    label: 'label_password'.l10n,
                    obscure: c.obscurePassword.value,
                    style: thin,
                    onSuffixPressed: c.obscurePassword.toggle,
                    treatErrorAsStatus: false,
                    trailing: SvgLoader.asset(
                      'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                      width: 17.07,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      title: Text('Login'.l10n),
                      onPressed: () {},
                      color: const Color(0xFFEEEEEE),
                      maxWidth: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: Text(
                    'OR'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      title: Text(
                        'Create account'.l10n,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: Navigator.of(context).pop,
                      color: const Color(0xFF63B4FF),
                      maxWidth: double.infinity,
                    ),
                  ),
                ),
              ];
              break;

            default:
              final Style style = Theme.of(context).extension<Style>()!;
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'Your accounts'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ContactTile(
                    myUser: c.myUser.value,
                    darken: 0.05,
                    // border: style.cardBorder,
                    selected: true,
                    trailing: const [
                      Text(
                        'Active',
                        style: TextStyle(color: Color(0xFF63B4FF)),
                      ),
                    ],
                    subtitle: const [
                      SizedBox(height: 5),
                      Text(
                        'Online',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ContactTile(
                    myUser: c.myUser.value,
                    darken: 0.05,
                    // border: style.cardBorder,
                    selected: false,
                    onTap: () {},
                    // trailing: const [
                    //   Text('Active', style: TextStyle(color: Color(0xFF63B4FF))),
                    // ],
                    subtitle: const [
                      SizedBox(height: 5),
                      Text(
                        'Last seen 10 days ago',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: OutlinedRoundedButton(
                    maxWidth: double.infinity,
                    title: Text(
                      'Add account'.l10n,
                      style: thin?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => c.stage.value = AccountsViewStage.add,
                    color: const Color(0xFF63B4FF),
                    // color: Colors.white.darken(0.05),
                  ),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: ListView(
              key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                const SizedBox(height: 0),
                ...children,
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }
}
