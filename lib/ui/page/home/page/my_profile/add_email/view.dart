// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/widget/primary_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View for adding and confirming an [UserEmail].
///
/// Intended to be displayed with the [show] method.
class AddEmailView extends StatelessWidget {
  const AddEmailView({super.key, required this.email, this.timeout = false});

  /// [UserEmail] to confirm.
  final UserEmail? email;

  /// Indicator whether the resend [Timer] should be started initially.
  final bool timeout;

  /// Displays a [AddEmailView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    UserEmail? email,
    bool timeout = false,
  }) {
    return ModalPopup.show(
      context: context,
      child: AddEmailView(email: email, timeout: timeout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: AddEmailController(Get.find(), email: email, timeout: timeout),
      builder: (AddEmailController c) {
        return Obx(() {
          final Widget header = ModalPopupHeader(text: 'label_add_email'.l10n);

          final List<Widget> children = switch (c.page.value) {
            AddEmailPage.add => [
              const SizedBox(height: 12),
              ReactiveTextField(
                key: Key('EmailField'),
                state: c.emailField,
                label: 'label_email'.l10n,
                hint: 'label_email_example'.l10n,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                style: style.fonts.normal.regular.onBackground,
                treatErrorAsStatus: false,
                spellCheck: false,
              ),
              const SizedBox(height: 25),
              Obx(() {
                return PrimaryButton(
                  key: const Key('Proceed'),
                  onPressed: c.emailField.isEmpty.value
                      ? null
                      : c.emailField.submit,
                  leading: c.emailField.isEmpty.value
                      ? const SvgIcon(SvgIcons.emailGrey)
                      : const SvgIcon(SvgIcons.emailWhite),
                  title: 'btn_add'.l10n,
                );
              }),
            ],

            AddEmailPage.confirm => [
              ?switch (c.email) {
                UserEmail(:final val) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    val,
                    textAlign: TextAlign.center,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
                null => null,
              },
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'label_add_email_confirmation_sent'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
              ),
              const SizedBox(height: 25),
              ReactiveTextField(
                key: const Key('ConfirmationCode'),
                state: c.code,
                label: 'label_one_time_password'.l10n,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hint: 'label_enter_code'.l10n,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                type: TextInputType.number,
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
                            ? c.resendEmail
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
                        onPressed: c.code.isEmpty.value || !enabled
                            ? null
                            : c.code.submit,
                        title: 'btn_confirm'.l10n,
                      ),
                    ),
                  ],
                );
              }),
            ],

            AddEmailPage.success => [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'label_add_email_confirmed'.l10n,
                  textAlign: TextAlign.center,
                  style: style.fonts.small.regular.secondary,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                key: const Key('Proceed'),
                onPressed: context.popModal,
                title: 'btn_ok'.l10n,
              ),
            ],
          };

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: 13),
              Flexible(
                child: Padding(
                  padding: ModalPopup.padding(context),
                  child: Scrollbar(
                    controller: c.scrollController,
                    child: AnimatedSizeAndFade(
                      sizeDuration: const Duration(milliseconds: 250),
                      fadeDuration: const Duration(milliseconds: 250),
                      child: ListView(
                        key: Key(c.page.value.name),
                        controller: c.scrollController,
                        shrinkWrap: true,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        });
      },
    );
  }
}
