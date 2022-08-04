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

/// View for alerting about password existence and password setting.
///
/// Intended to be displayed with the [show] method.
class ConfirmLogoutView extends StatelessWidget {
  const ConfirmLogoutView({Key? key}) : super(key: key);

  /// Displays a [ConfirmLogoutView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) =>
      ModalPopup.show(context: context, child: const ConfirmLogoutView());

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ConfirmLogoutController(Get.find()),
      builder: (ConfirmLogoutController c) {
        return Obx(() {
          List<Widget> children = [];

          switch (c.stage.value) {
            case ConfirmLogoutViewStage.alert:
              children = [
                Center(
                  child: Text(
                    'label_password_not_set'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          style: thin,
                          text: 'label_account_access_will_be_lost'.l10n,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('ConfirmLogoutSetPasswordButton'),
                        maxWidth: null,
                        title: Text(
                          'btn_set_password'.l10n,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () =>
                            c.stage.value = ConfirmLogoutViewStage.password,
                        color: const Color(0xFF63B4FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedRoundedButton(
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
              ];
              break;
            case ConfirmLogoutViewStage.password:
              children = [
                Center(
                  child: Text(
                    'btn_set_password'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 18),
                ReactiveTextField(
                  key: const Key('ConfirmLogoutPasswordField'),
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
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('ConfirmLogoutRepeatPasswordField'),
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
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('ConfirmLogoutSavePasswordButton'),
                  title: Text(
                    'btn_save'.l10n,
                    style: thin?.copyWith(color: Colors.white),
                  ),
                  onPressed: c.setPassword,
                  height: 50,
                  leading: SvgLoader.asset(
                    'assets/icons/save.svg',
                    height: 25 * 0.7,
                  ),
                  color: const Color(0xFF63B4FF),
                ),
              ];
              break;
            case ConfirmLogoutViewStage.success:
              children = [
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'label_password_set_successfully'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('ConfirmLogoutCloseButton'),
                    title: Text('btn_close'.l10n),
                    onPressed: Navigator.of(context).pop,
                    color: const Color(0xFFEEEEEE),
                  ),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: ListView(
              key: Key('ConfirmLogoutView_${c.stage.value.name}'),
              shrinkWrap: true,
              children: [
                const SizedBox(height: 12),
                ...children,
                const SizedBox(height: 25),
              ],
            ),
          );
        });
      },
    );
  }
}
