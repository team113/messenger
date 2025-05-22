// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View of the [MyUser] deletion confirmation.
class ConfirmDeleteView extends StatelessWidget {
  const ConfirmDeleteView({super.key});

  /// Displays a [ConfirmDeleteView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const ConfirmDeleteView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('ConfirmAccountDeletion'),
      init: ConfirmDeleteController(Get.find(), Get.find()),
      builder: (ConfirmDeleteController c) {
        return Obx(() {
          final List<Widget> children = [];

          if (c.myUser.value?.emails.confirmed.isNotEmpty == true) {
            children.addAll([
              const SizedBox(height: 12),
              Text(
                'label_add_email_confirmation_sent_to'.l10nfmt({
                  'email': '${c.myUser.value?.emails.confirmed.firstOrNull}',
                }),
                style: style.fonts.normal.regular.onBackground,
              ),
              const SizedBox(height: 16),
              Obx(() {
                return Text(
                  c.resendEmailTimeout.value == 0
                      ? 'label_did_not_receive_code'.l10n
                      : 'label_code_sent_again'.l10n,
                  style: style.fonts.normal.regular.onBackground,
                );
              }),
              Obx(() {
                final bool enabled = c.resendEmailTimeout.value == 0;

                return WidgetButton(
                  onPressed: enabled ? c.sendConfirmationCode : null,
                  child: Text(
                    enabled
                        ? 'btn_resend_code'.l10n
                        : 'label_wait_seconds'.l10nfmt({
                            'for': c.resendEmailTimeout.value,
                          }),
                    style: enabled
                        ? style.fonts.normal.regular.primary
                        : style.fonts.normal.regular.onBackground,
                  ),
                );
              }),
              const SizedBox(height: 16),
              ReactiveTextField(
                state: c.code,
                hint: 'label_confirmation_code'.l10n,
              ),
              const SizedBox(height: 25),
              PrimaryButton(
                key: const Key('Proceed'),
                onPressed: c.deleteAccount,
                title: 'btn_proceed'.l10n,
              ),
              const SizedBox(height: 16),
            ]);
          } else if (c.myUser.value?.hasPassword == true) {
            children.addAll([
              const SizedBox(height: 12),
              Text(
                'label_enter_password_below'.l10n,
                style: style.fonts.normal.regular.secondary,
              ),
              const SizedBox(height: 12),
              Obx(() {
                return ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.password,
                  obscure: c.obscurePassword.value,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgIcon(
                    c.obscurePassword.value
                        ? SvgIcons.visibleOff
                        : SvgIcons.visibleOn,
                  ),
                  hint: 'label_password'.l10n,
                );
              }),
              const SizedBox(height: 25),
              Obx(() {
                final bool enabled =
                    !c.password.isEmpty.value && c.password.error.value == null;

                return PrimaryButton(
                  key: const Key('Proceed'),
                  onPressed: enabled ? c.deleteAccount : null,
                  title: 'btn_proceed'.l10n,
                );
              }),
              const SizedBox(height: 16),
            ]);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(text: 'label_confirm_account_deletion'.l10n),
              Flexible(
                child: ListView(
                  padding: ModalPopup.padding(context),
                  shrinkWrap: true,
                  children: children,
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
