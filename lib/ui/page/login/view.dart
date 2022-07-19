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

          if (c.showNewPasswordSection.value) {
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
              loginPopupButtons(
                mainButtonKey: const Key('RecoveryNextTile'),
                secondaryButtonKey: const Key('RecoveryBackTile'),
                mainButtonTitle: 'btn_next'.l10n,
                onMainButtonPressed: c.resetUserPassword,
                secondaryButtonTitle: 'btn_back'.l10n,
                onSecondaryButtonPressed: () {
                  c.clearAccessFields();
                  c.showCodeSection.toggle();
                  c.showNewPasswordSection.toggle();
                },
              ),
              const SizedBox(height: 16),
            ];
          } else if (c.showCodeSection.value) {
            children = [
              Center(
                child: Text(
                  '${'label_email_confirmation_code_was_send'.l10n}'
                  '${'dot'.l10n} ${'label_enter_it_bellow'.l10n}',
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
              loginPopupButtons(
                mainButtonKey: const Key('RecoveryNextTile'),
                secondaryButtonKey: const Key('RecoveryBackTile'),
                mainButtonTitle: 'btn_next'.l10n,
                onMainButtonPressed: c.recoveryCode.submit,
                secondaryButtonTitle: 'btn_back'.l10n,
                onSecondaryButtonPressed: () {
                  c.clearAccessFields();
                  c.showCodeSection.toggle();
                },
              ),
              const SizedBox(height: 16),
            ];
          } else if (c.displayAccess.value) {
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
              loginPopupButtons(
                mainButtonKey: const Key('RecoveryNextTile'),
                secondaryButtonKey: const Key('RecoveryBackTile'),
                mainButtonTitle: 'btn_next'.l10n,
                onMainButtonPressed: c.recovery.submit,
                secondaryButtonTitle: 'btn_back'.l10n,
                onSecondaryButtonPressed: c.displayAccess.toggle,
              ),
              const SizedBox(height: 16),
            ];
          } else {
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
              loginPopupButtons(
                mainButtonKey: const Key('LoginNextTile'),
                secondaryButtonKey: const Key('AccessRecoveryTile'),
                isRightMainButton: false,
                mainButtonTitle: 'btn_login'.l10n,
                secondaryButtonTitle: 'btn_forgot_password'.l10n,
                onMainButtonPressed: c.signIn,
                onSecondaryButtonPressed: () {
                  c.recovery.unchecked = c.login.text;
                  c.recovery.error.value = null;
                  c.displayAccess.toggle();
                },
              ),
              const SizedBox(height: 16),
            ];
          }

          return AnimatedSize(
            duration: 250.milliseconds,
            curve: Curves.easeOut,
            child: AnimatedSwitcher(
              duration: 250.milliseconds,
              child: ListView(
                key: Key('${c.displayAccess.value}'),
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

/// Returns [Row] widget with two popup buttons.
Widget loginPopupButtons({
  bool isRightMainButton = true,
  String mainButtonTitle = '',
  String secondaryButtonTitle = '',
  VoidCallback? onMainButtonPressed,
  VoidCallback? onSecondaryButtonPressed,
  Color mainButtonColor = const Color(0xFF63B4FF),
  Color secondaryButtonColor = const Color(0xFFEEEEEE),
  Color mainButtonTextColor = Colors.white,
  Key? mainButtonKey,
  Key? secondaryButtonKey,
}) {
  var elements = [
    Expanded(
      child: OutlinedRoundedButton(
        key: secondaryButtonKey,
        maxWidth: null,
        title: Text(secondaryButtonTitle),
        onPressed: onSecondaryButtonPressed,
        color: secondaryButtonColor,
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: OutlinedRoundedButton(
        key: mainButtonKey,
        maxWidth: null,
        title: Text(
          mainButtonTitle,
          style: TextStyle(color: mainButtonTextColor),
        ),
        onPressed: onMainButtonPressed,
        color: const Color(0xFF63B4FF),
      ),
    ),
  ];

  return Row(
    children: isRightMainButton ? elements : elements.reversed.toList(),
  );
}
