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

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for alerting about password not being set.
///
/// Intended to be displayed with the [show] method.
class ConfirmLogoutView extends StatelessWidget {
  const ConfirmLogoutView({Key? key, this.hasPassword = false})
      : super(key: key);

  final bool hasPassword;

  /// Displays a [ConfirmLogoutView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    bool hasPassword = false,
  }) {
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
      child: ConfirmLogoutView(hasPassword: hasPassword),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      key: const Key('ConfirmLogoutView'),
      init: ConfirmLogoutController(Get.find()),
      builder: (ConfirmLogoutController c) {
        return Obx(() {
          List<Widget> children = [];

          switch (c.stage.value) {
            case ConfirmLogoutViewStage.password:
              children = [
                ModalPopupHeader(
                  onBack: () => c.stage.value = null,
                  header: Center(
                    child: Text(
                      'btn_set_password'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
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
                const SizedBox(height: 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('RepeatPasswordField'),
                    state: c.repeat,
                    label: 'label_repeat_password'.l10n,
                    obscure: c.obscureRepeat.value,
                    style: thin,
                    onSuffixPressed: c.obscureRepeat.toggle,
                    treatErrorAsStatus: false,
                    trailing: SvgLoader.asset(
                      'assets/icons/visible_${c.obscureRepeat.value ? 'off' : 'on'}.svg',
                      width: 17.07,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: OutlinedRoundedButton(
                    key: const Key('ChangePasswordButton'),
                    title: Text(
                      'btn_proceed'.l10n,
                      style: thin?.copyWith(
                        color:
                            c.password.isEmpty.value || c.repeat.isEmpty.value
                                ? Colors.black
                                : Colors.white,
                      ),
                    ),
                    onPressed:
                        c.password.isEmpty.value || c.repeat.isEmpty.value
                            ? null
                            : c.setPassword,
                    // height: 50,
                    // leading: SvgLoader.asset(
                    //   'assets/icons/save.svg',
                    //   height: 25 * 0.7,
                    // ),
                    color: const Color(0xFF63B4FF),
                  ),
                ),
              ];
              break;

            case ConfirmLogoutViewStage.success:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'btn_set_password'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Text(
                    'label_password_set'.l10n,
                    style: thin?.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      key: const Key('CloseButton'),
                      maxWidth: null,
                      title: Text(
                        'btn_close'.l10n,
                        style: thin?.copyWith(color: Colors.white),
                      ),
                      onPressed: Navigator.of(context).pop,
                      color: const Color(0xFF63B4FF),
                    ),
                  ),
                ),
              ];
              break;

            default:
              if (hasPassword) {
                children = [
                  ModalPopupHeader(
                    header: Center(
                      child: Text(
                        'btn_logout'.l10n,
                        style: thin?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25 - 12),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: thin?.copyWith(
                            color: const Color(0xFF888888),
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Вы действительно хотите выйти из аккаунта '
                                  .l10n,
                            ),
                            TextSpan(
                              style: const TextStyle(color: Colors.black),
                              text: c.myUser.value?.name?.val ??
                                  c.myUser.value?.num.val ??
                                  '',
                            ),
                            TextSpan(text: '?'.l10n),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: OutlinedRoundedButton(
                      maxWidth: null,
                      title: Text(
                        'btn_logout'.l10n,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      color: const Color(0xFF63B4FF),
                    ),
                  ),
                ];
              } else {
                children = [
                  ModalPopupHeader(
                    header: Center(
                      child: Text(
                        'btn_logout'.l10n,
                        style: thin?.copyWith(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25 - 12),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          style: thin?.copyWith(
                            color: const Color(0xFF888888),
                            fontSize: 16,
                          ),
                          children: [
                            TextSpan(
                              text: 'Вы действительно хотите выйти из аккаунта '
                                  .l10n,
                            ),
                            TextSpan(
                              style: const TextStyle(color: Colors.black),
                              text: c.myUser.value?.name?.val ??
                                  c.myUser.value?.num.val ??
                                  '',
                            ),
                            TextSpan(text: '?'.l10n),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: RichText(
                      text: TextSpan(
                        style: thin?.copyWith(color: const Color(0xFF888888)),
                        children: [
                          TextSpan(
                            text:
                                'Пароль не задан. Доступ к аккаунту будет утерян.'
                                    .l10n,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedRoundedButton(
                            key: const Key('SetPasswordButton'),
                            maxWidth: null,
                            title: Text(
                              'btn_set_password'.l10n,
                              style: const TextStyle(color: Colors.white),
                            ),
                            onPressed: () =>
                                c.stage.value = ConfirmLogoutViewStage.password,
                            color: const Color(0xFF63B4FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedRoundedButton(
                            key: const Key('LogoutConfirmedButton'),
                            maxWidth: null,
                            title: Text(
                              'btn_logout'.l10n,
                              style: const TextStyle(),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            color: const Color(0xFFEEEEEE),
                          ),
                        )
                      ],
                    ),
                  ),
                ];
              }

              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: ListView(
              key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
              shrinkWrap: true,
              children: [
                ...children,
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }
}
