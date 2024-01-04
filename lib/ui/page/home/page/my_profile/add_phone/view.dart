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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
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
  const AddPhoneView({super.key, this.phone});

  /// Initial [UserPhone] to confirm.
  final UserPhone? phone;

  /// Displays a [AddPhoneView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {UserPhone? phone}) {
    return ModalPopup.show(context: context, child: AddPhoneView(phone: phone));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AddPhoneController(
        Get.find(),
        initial: phone,
        pop: context.popModal,
      ),
      builder: (AddPhoneController c) {
        return Obx(() {
          final Widget child;

          switch (c.stage.value) {
            case AddPhoneFlowStage.code:
              child = Scrollbar(
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
                      state: c.phoneCode,
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
                              title: Text(
                                c.resendPhoneTimeout.value == 0
                                    ? 'label_resend'.l10n
                                    : 'label_resend_timeout'.l10nfmt(
                                        {'timeout': c.resendPhoneTimeout.value},
                                      ),
                                style: c.resendPhoneTimeout.value == 0
                                    ? style.fonts.normal.regular.onPrimary
                                    : style.fonts.normal.regular.onBackground,
                              ),
                              onPressed: c.resendPhoneTimeout.value == 0
                                  ? c.resendPhone
                                  : null,
                              color: style.colors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedRoundedButton(
                              key: const Key('Proceed'),
                              maxWidth: double.infinity,
                              title: Text(
                                'btn_proceed'.l10n,
                                style: c.phoneCode.isEmpty.value
                                    ? style.fonts.normal.regular.onBackground
                                    : style.fonts.normal.regular.onPrimary,
                              ),
                              onPressed: c.phoneCode.isEmpty.value
                                  ? null
                                  : c.phoneCode.submit,
                              color: style.colors.primary,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              );
              break;

            default:
              child = Scrollbar(
                controller: c.scrollController,
                child: ListView(
                  controller: c.scrollController,
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'label_add_phone_description'.l10n,
                        style: style.fonts.normal.regular.secondary,
                      ),
                    ),
                    const SizedBox(height: 25),
                    ReactiveTextField(
                      key: const Key('Phone'),
                      state: c.phone,
                      label: 'label_phone_number'.l10n,
                      // TODO: Improve hint to account user's region.
                      hint: '+34 123 123 53 53',
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d+ ]')),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Obx(() {
                      return OutlinedRoundedButton(
                        key: const Key('Proceed'),
                        maxWidth: double.infinity,
                        title: Text(
                          'btn_proceed'.l10n,
                          style: c.phone.isEmpty.value
                              ? style.fonts.normal.regular.onBackground
                              : style.fonts.normal.regular.onPrimary,
                        ),
                        onPressed:
                            c.phone.isEmpty.value ? null : c.phone.submit,
                        color: style.colors.primary,
                      );
                    }),
                  ],
                ),
              );
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              key: Key('${c.stage.value}'),
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
            ),
          );
        });
      },
    );
  }
}
