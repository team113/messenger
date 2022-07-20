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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for logging in or recovering access on the [Routes.auth] page.
///
/// Intended to be displayed with the [show] method.
class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

  /// Displays a [LoginView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context,
      const LoginView(),
      contentMaxWidth: 400,
      layoutMaxWidth: 520,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextTheme theme = Theme.of(context).textTheme;

    return GetBuilder(
      init: LoginController(Get.find()),
      builder: (LoginController c) {
        return Obx(() {
          List<Widget> children;

          Widget _primaryButton({
            Key? key,
            String? title,
            VoidCallback? onPressed,
          }) {
            return OutlinedRoundedButton(
              key: key,
              maxWidth: null,
              title: Text(
                title ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: onPressed,
              color: Theme.of(context).colorScheme.secondary,
            );
          }

          Widget _secondaryButton({
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

          Row _spaced(Widget a, Widget b) {
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
                Center(
                  child: Text(
                    'label_recover_account'.l10n,
                    style: theme.headline3,
                  ),
                ),
                const SizedBox(height: 57),
                ReactiveTextField(
                  key: const Key('RecoveryField'),
                  state: c.recovery,
                  label: 'label_sign_in_input'.l10n,
                ),
                const SizedBox(height: 58),
                _spaced(
                  _secondaryButton(
                    key: const Key('RecoveryBackButton'),
                    title: 'btn_back'.l10n,
                    onPressed: () => c.stage.value = null,
                  ),
                  _primaryButton(
                    key: const Key('RecoveryNextButton'),
                    title: 'btn_next'.l10n,
                    onPressed: c.recovery.submit,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoveryCode:
              children = [
                Center(
                  child: Text(
                    'label_email_confirmation_code_was_send'.l10n,
                    style: theme.headline3,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 57),
                ReactiveTextField(
                  key: const Key('RecoveryCodeField'),
                  state: c.recoveryCode,
                  label: 'label_recovery_code'.l10n,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 58),
                _spaced(
                  _secondaryButton(
                    key: const Key('RecoveryBackButton'),
                    title: 'btn_cancel'.l10n,
                    onPressed: () => c.stage.value = null,
                  ),
                  _primaryButton(
                    key: const Key('RecoveryNextButton'),
                    title: 'btn_next'.l10n,
                    onPressed: c.recoveryCode.submit,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoveryPassword:
              children = [
                Center(
                  child: Text(
                    'label_set_new_password'.l10n,
                    style: theme.headline3,
                  ),
                ),
                const SizedBox(height: 57),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.newPassword,
                  label: 'label_new_password'.l10n,
                  obscure: true,
                ),
                const SizedBox(height: 16),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeatPassword,
                  label: 'label_repeat_password'.l10n,
                  obscure: true,
                ),
                const SizedBox(height: 58),
                _spaced(
                  _secondaryButton(
                    key: const Key('RecoveryBackButton'),
                    title: 'btn_cancel'.l10n,
                    onPressed: () => c.stage.value = null,
                  ),
                  _primaryButton(
                    key: const Key('RecoveryNextButton'),
                    title: 'btn_next'.l10n,
                    onPressed: c.resetUserPassword,
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LoginViewStage.recoverySuccess:
              // TODO: Handle this case.
              children = [];
              break;

            default:
              children = [
                Center(
                  child: Text(
                    'label_entrance'.l10n,
                    style: theme.headline3,
                  ),
                ),
                const SizedBox(height: 57),
                ReactiveTextField(
                  key: const Key('UsernameField'),
                  state: c.login,
                  label: 'label_sign_in_input'.l10n,
                  onChanged: () {},
                ),
                const SizedBox(height: 16),
                ReactiveTextField(
                  key: const ValueKey('PasswordField'),
                  obscure: true,
                  state: c.password,
                  label: 'label_password'.l10n,
                ),
                const SizedBox(height: 52),
                _spaced(
                  _primaryButton(
                    key: const Key('LoginButton'),
                    title: 'btn_login'.l10n,
                    onPressed: c.signIn,
                  ),
                  _secondaryButton(
                    key: const Key('RecoveryButton'),
                    title: 'btn_forgot_password'.l10n,
                    onPressed: () {
                      c.recovery.unchecked = c.login.text;
                      c.recovery.error.value = null;
                      c.stage.value = LoginViewStage.recovery;
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;
          }

          return AnimatedSize(
            duration: 250.milliseconds,
            curve: Curves.easeOut,
            child: AnimatedSwitcher(
              duration: 250.milliseconds,
              child: ListView(
                key: Key('${c.stage.value}'),
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 12),
                  ...children,
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
