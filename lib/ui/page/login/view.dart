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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View for logging in or recovering access on.
///
/// Intended to be displayed with the [show] method.
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  /// Displays a [LoginView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const LoginView());
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme theme = Theme.of(context).textTheme;

    return GetBuilder(
      key: const Key('LoginView'),
      init: LoginController(Get.find()),
      builder: (LoginController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case LoginViewStage.recovery:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = null,
                header: Center(
                  child: Text(
                    'label_recover_account'.l10n,
                    style: theme.displaySmall?.copyWith(fontSize: 18),
                  ),
                ),
              );

              children = [
                const SizedBox(height: 12),
                Text(
                  'label_recover_account_description'.l10n,
                  style: theme.displaySmall?.copyWith(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryField'),
                  state: c.recovery,
                  label: 'label_sign_in_input'.l10n,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed:
                      c.recovery.isEmpty.value ? null : c.recovery.submit,
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoveryCode:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = null,
                header: Center(
                  child: Text(
                    'label_recover_account'.l10n,
                    style: theme.displaySmall?.copyWith(fontSize: 18),
                  ),
                ),
              );

              children = [
                Text(
                  'label_recovery_code_sent'.l10n,
                  style: theme.displaySmall?.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('RecoveryCodeField'),
                  state: c.recoveryCode,
                  label: 'label_recovery_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed: c.recoveryCode.isEmpty.value
                      ? null
                      : c.recoveryCode.submit,
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoveryPassword:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = null,
                header: Center(
                  child: Text(
                    'label_recover_account'.l10n,
                    style: theme.displaySmall?.copyWith(fontSize: 18),
                  ),
                ),
              );

              children = [
                Text(
                  'label_recovery_enter_new_password'.l10n,
                  style: theme.displaySmall?.copyWith(
                    fontSize: 15,
                    color: const Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.newPassword,
                  label: 'label_new_password'.l10n,
                  obscure: c.obscureNewPassword.value,
                  onSuffixPressed: c.obscureNewPassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscureNewPassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 16),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_repeat_password'.l10n,
                  obscure: c.obscureRepeatPassword.value,
                  onSuffixPressed: c.obscureRepeatPassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscureRepeatPassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('Proceed'),
                  title: 'btn_proceed'.l10n,
                  onPressed: c.newPassword.isEmpty.value ||
                          c.repeatPassword.isEmpty.value
                      ? null
                      : c.resetUserPassword,
                ),
                const SizedBox(height: 16),
              ];
              break;

            default:
              header = ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_entrance'.l10n,
                    style: theme.displaySmall?.copyWith(fontSize: 18),
                  ),
                ),
              );

              children = [
                if (c.recovered.value)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                    child: Text(
                      'label_password_changed'.l10n,
                      style: theme.displaySmall?.copyWith(
                        fontSize: 15,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('UsernameField'),
                  state: c.login,
                  label: 'label_sign_in_input'.l10n,
                ),
                const SizedBox(height: 16),
                Column(
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
                      trailing: SvgImage.asset(
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
                const SizedBox(height: 25),
                PrimaryButton(
                  key: const Key('LoginButton'),
                  title: 'btn_login'.l10n,
                  onPressed: c.signIn,
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
            child: Scrollbar(
              controller: c.scrollController,
              child: ListView(
                controller: c.scrollController,
                key: Key('${c.stage.value}'),
                shrinkWrap: true,
                children: [
                  header,
                  const SizedBox(height: 12),
                  ...children.map((e) =>
                      Padding(padding: ModalPopup.padding(context), child: e)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

/// [Widget] which returns a primary styled [OutlinedRoundedButton].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, this.title, this.onPressed});

  /// Text to display.
  final String? title;

  /// Callback, called when this button is tapped or activated other way.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedRoundedButton(
      maxWidth: double.infinity,
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
}
