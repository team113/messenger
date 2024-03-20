// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for adding and confirming an [UserPhone].
///
/// Intended to be displayed with the [show] method.
class AddPhoneView extends StatelessWidget {
  const AddPhoneView({super.key, this.timeout = false});

  /// Indicator whether the resend [Timer] should be started initially.
  final bool timeout;

  /// Displays a [AddPhoneView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    bool timeout = false,
  }) {
    return ModalPopup.show(
      context: context,
      child: AddPhoneView(timeout: timeout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AddPhoneController(
        Get.find(),
        timeout: timeout,
        pop: context.popModal,
      ),
      builder: (AddPhoneController c) {
        final Widget child = Scrollbar(
          controller: c.scrollController,
          child: ListView(
            controller: c.scrollController,
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Obx(() {
                  return Text(
                    c.resent.value
                        ? 'label_add_phone_confirmation_sent_again'.l10n
                        : 'label_add_phone_confirmation_sent'.l10n,
                    style: style.fonts.normal.regular.secondary,
                  );
                }),
              ),
              const SizedBox(height: 25),
              ReactiveTextField(
                key: const Key('ConfirmationCode'),
                state: c.code,
                label: 'label_confirmation_code'.l10n,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 25),
              Obx(() {
                return Row(
                  children: [
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('Resend'),
                        maxWidth: double.infinity,
                        onPressed: c.resendPhoneTimeout.value == 0
                            ? c.resendPhone
                            : null,
                        color: style.colors.primary,
                        child: Text(
                          c.resendPhoneTimeout.value == 0
                              ? 'label_resend'.l10n
                              : 'label_resend_timeout'.l10nfmt(
                                  {'timeout': c.resendPhoneTimeout.value},
                                ),
                          style: c.resendPhoneTimeout.value == 0
                              ? style.fonts.normal.regular.onPrimary
                              : style.fonts.normal.regular.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('Proceed'),
                        maxWidth: double.infinity,
                        onPressed: c.code.isEmpty.value ? null : c.code.submit,
                        color: style.colors.primary,
                        child: Text(
                          'btn_proceed'.l10n,
                          style: c.code.isEmpty.value
                              ? style.fonts.normal.regular.onBackground
                              : style.fonts.normal.regular.onPrimary,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            ModalPopupHeader(text: 'label_add_phone'.l10n),
            const SizedBox(height: 13),
            Flexible(
              child: Padding(
                padding: ModalPopup.padding(context),
                child: child,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
