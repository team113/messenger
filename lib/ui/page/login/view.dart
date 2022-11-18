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
import 'package:messenger/ui/widget/widget_button.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for logging in or recovering access on.
///
/// Intended to be displayed with the [show] method.
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  /// Displays a [LoginView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      // desktopConstraints: const BoxConstraints(maxWidth: 400),
      // modalConstraints: const BoxConstraints(maxWidth: 520),
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
      child: const LoginView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    TextTheme theme = Theme.of(context).textTheme;

    return GetBuilder(
      key: const Key('LoginView'),
      init: LoginController(Get.find()),
      builder: (LoginController c) {
        return Obx(() {
          List<Widget> children;

          // Returns a primary styled [OutlinedRoundedButton].
          Widget primaryButton({
            Key? key,
            String? title,
            VoidCallback? onPressed,
          }) {
            return OutlinedRoundedButton(
              key: key,
              maxWidth: null,
              title: Text(
                title ?? '',
                style: TextStyle(
                  color: onPressed == null ? Colors.black : Colors.white,
                ),
              ),
              onPressed: onPressed,
              color: Theme.of(context).colorScheme.secondary,
            );
          }

          // Returns a secondary styled [OutlinedRoundedButton].
          Widget secondaryButton({
            Key? key,
            String? title,
            VoidCallback? onPressed,
          }) {
            return OutlinedRoundedButton(
              key: key,
              maxWidth: null,
              title: Text(
                title ?? '',
                style: const TextStyle(color: Colors.black),
              ),
              onPressed: onPressed,
              color: const Color(0xFFEEEEEE),
            );
          }

          // Returns a [Row] with [a] and [b] placed in the [Expanded] widgets.
          Row spaced(Widget a, Widget b) {
            return Row(
              children: [
                Expanded(child: a),
                const SizedBox(width: 10),
                Expanded(child: b)
              ],
            );
          }

          switch (c.stage.value) {
            case LoginViewStage.recovery:
              children = [
                ModalPopupHeader(
                  onBack: () => c.stage.value = null,
                  header: Center(
                    child: Text(
                      'label_recover_account'.l10n,
                      style: theme.headline3?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                // const SizedBox(height: 57 - 12),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Text(
                    'Укажите Ваш Gapopa ID, логин, E-mail или номер телефона.',
                    style: theme.headline3?.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('RecoveryField'),
                    state: c.recovery,
                    label: 'label_sign_in_input'.l10n,
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: primaryButton(
                    key: const Key('Proceed'),
                    title: 'btn_proceed'.l10n,
                    onPressed:
                        c.recovery.isEmpty.value ? null : c.recovery.submit,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoveryCode:
              children = [
                ModalPopupHeader(
                  onBack: () => c.stage.value = null,
                  header: Center(
                    child: Text(
                      'label_recover_account'.l10n,
                      style: theme.headline3?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Text(
                    'label_recovery_code_sent'.l10n,
                    style: theme.headline3?.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('RecoveryCodeField'),
                    state: c.recoveryCode,
                    label: 'label_recovery_code'.l10n,
                    type: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: primaryButton(
                    key: const Key('Proceed'),
                    title: 'btn_proceed'.l10n,
                    onPressed: c.recoveryCode.isEmpty.value
                        ? null
                        : c.recoveryCode.submit,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoveryPassword:
              children = [
                ModalPopupHeader(
                  onBack: () => c.stage.value = null,
                  header: Center(
                    child: Text(
                      'label_recover_account'.l10n,
                      style: theme.headline3?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Text(
                    'Пожалуйста, введите новый пароль для Вашего аккаунта ниже.'
                        .l10n,
                    style: theme.headline3?.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('PasswordField'),
                    state: c.newPassword,
                    label: 'label_new_password'.l10n,
                    obscure: c.obscureNewPassword.value,
                    onSuffixPressed: c.obscureNewPassword.toggle,
                    treatErrorAsStatus: false,
                    trailing: SvgLoader.asset(
                      'assets/icons/visible_${c.obscureNewPassword.value ? 'off' : 'on'}.svg',
                      width: 17.07,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('RepeatPasswordField'),
                    state: c.repeatPassword,
                    label: 'label_repeat_password'.l10n,
                    obscure: c.obscureRepeatPassword.value,
                    onSuffixPressed: c.obscureRepeatPassword.toggle,
                    treatErrorAsStatus: false,
                    trailing: SvgLoader.asset(
                      'assets/icons/visible_${c.obscureRepeatPassword.value ? 'off' : 'on'}.svg',
                      width: 17.07,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: primaryButton(
                    key: const Key('Proceed'),
                    title: 'btn_proceed'.l10n,
                    onPressed: c.newPassword.isEmpty.value ||
                            c.repeatPassword.isEmpty.value
                        ? null
                        : c.resetUserPassword,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoverySuccess:
              children = [
                ModalPopupHeader(
                  onBack: () => c.stage.value = null,
                  header: Center(
                    child: Text(
                      'label_recover_account'.l10n,
                      style: theme.headline3?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Text(
                    'Пароль к указанному аккаунту успешно изменён. Пожалуйста, войдите с новыми данными для входа.'
                        .l10n,
                    style: theme.headline3?.copyWith(
                      fontSize: 15,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: primaryButton(
                      key: const Key('RecoverySuccessButton'),
                      title: 'btn_proceed'.l10n,
                      onPressed: () => c.stage.value = null,
                    ),
                  ),
                ),
                const SizedBox(height: 13)
              ];
              break;

            default:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'label_entrance'.l10n,
                      style: theme.headline3?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                if (c.recovered.value)
                  Padding(
                    padding: ModalPopup.padding(context)
                        .add(const EdgeInsets.symmetric(horizontal: 8)),
                    child: Text(
                      'Пароль к указанному аккаунту успешно изменён. Пожалуйста, войдите с новыми данными для входа.'
                          .l10n,
                      style: theme.headline3?.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('UsernameField'),
                    state: c.login,
                    label: 'label_sign_in_input'.l10n,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReactiveTextField(
                        key: const ValueKey('PasswordField'),
                        state: c.password,
                        label: 'label_password'.l10n,
                        obscure: c.obscurePassword.value,
                        onSuffixPressed: c.obscurePassword.toggle,
                        treatErrorAsStatus: false,
                        trailing: SvgLoader.asset(
                          'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                          width: 17.07,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
                        child: WidgetButton(
                          onPressed: () {
                            c.recovery.clear();
                            c.recoveryCode.clear();
                            c.newPassword.clear();
                            c.repeatPassword.clear();
                            c.recovery.unchecked = c.login.text;
                            c.recovered.value = false;
                            c.stage.value = LoginViewStage.recovery;
                          },
                          child: Text(
                            'btn_forgot_password'.l10n,
                            style: const TextStyle(color: Color(0xFF00A3FF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: primaryButton(
                    key: const Key('LoginButton'),
                    title: 'btn_login'.l10n,
                    onPressed: c.signIn,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            fadeInCurve: Curves.easeOut,
            fadeOutCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
            child: ListView(
              key: Key('${c.stage.value}'),
              shrinkWrap: true,
              children: [
                // const SizedBox(height: 12),
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
