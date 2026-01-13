// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
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
          final List<Widget> children = [
            const SizedBox(height: 12),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'alert_account_will_be_deleted1'.l10n),
                    TextSpan(
                      text: '${c.myUser.value?.name ?? c.myUser.value?.num}',
                      style: style.fonts.small.regular.onBackground,
                    ),
                    TextSpan(text: 'alert_account_will_be_deleted2'.l10n),
                  ],
                ),
                style: style.fonts.small.regular.secondary,
              ),
            ),
            const SizedBox(height: 8),
          ];

          final bool hasEmail =
              c.myUser.value?.emails.confirmed.isNotEmpty == true;
          final bool hasPassword = c.myUser.value?.hasPassword == true;

          if (hasEmail) {
            children.addAll([
              const SizedBox(height: 12),
              Text(
                hasPassword
                    ? 'label_enter_password_or_one_time_code'.l10n
                    : 'label_enter_one_time_code'.l10n,
                style: style.fonts.small.regular.secondary,
              ),

              const SizedBox(height: 24),
              ReactiveTextField.password(
                state: c.code,
                label: hasPassword
                    ? 'label_password_or_one_time_code'.l10n
                    : 'label_one_time_password'.l10n,
                hint: hasPassword
                    ? 'label_enter_password_or_code'.l10n
                    : 'label_enter_code'.l10n,
                obscured: c.obscurePassword,
              ),
              const SizedBox(height: 25),
              Obx(() {
                final bool enabled = c.code.status.value.isEmpty;

                return Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        key: const Key('Resend'),
                        onPressed: c.resendEmailTimeout.value == 0 && enabled
                            ? c.sendConfirmationCode
                            : null,
                        title: c.resendEmailTimeout.value == 0
                            ? 'label_resend'.l10n
                            : 'label_resend_timeout'.l10nfmt({
                                'timeout': c.resendEmailTimeout.value,
                              }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        key: const Key('Proceed'),
                        danger: true,
                        onPressed: c.deleteAccount,
                        title: 'btn_confirm'.l10n,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
            ]);
          } else if (hasPassword) {
            children.addAll([
              const SizedBox(height: 18),
              ReactiveTextField.password(
                key: const Key('PasswordField'),
                state: c.password,
                treatErrorAsStatus: false,
                obscured: c.obscurePassword,
                hint: 'label_enter_password'.l10n,
                label: 'label_password'.l10n,
              ),
              const SizedBox(height: 25),
              Obx(() {
                final bool enabled =
                    !c.password.isEmpty.value && c.password.error.value == null;

                return PrimaryButton(
                  danger: true,
                  key: const Key('Proceed'),
                  onPressed: enabled
                      ? () async {
                          await c.deleteAccount();

                          if (context.mounted) {
                            context.popModal();
                          }
                        }
                      : null,
                  title: 'btn_confirm'.l10n,
                );
              }),
              const SizedBox(height: 16),
            ]);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(text: 'label_delete_account'.l10n),
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
