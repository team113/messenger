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
import 'package:messenger/routes.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// ...
///
/// Intended to be displayed with the [show] method.
class FreelanceView extends StatelessWidget {
  const FreelanceView({Key? key}) : super(key: key);

  /// Displays an [FreelanceView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const FreelanceView());
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      key: const Key('AccountsView'),
      init: FreelanceController(),
      builder: (FreelanceController c) {
        return Obx(() {
          final List<Widget> children = [
            ModalPopupHeader(
              header: Center(
                child: Text(
                  'Start earning'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
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
                trailing: SvgImage.asset(
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    router.accounts.value++;
                  },
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    router.accounts.value++;
                  },
                  color: const Color(0xFF63B4FF),
                  maxWidth: double.infinity,
                ),
              ),
            ),
          ];

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: ListView(
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
