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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View for adding and confirming an [UserEmail].
///
/// Intended to be displayed with the [show] method.
class AddEmailView extends StatelessWidget {
  const AddEmailView({Key? key, this.email}) : super(key: key);

  /// [UserEmail] to confirm.
  final UserEmail? email;

  /// Displays a [AddEmailView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context, {UserEmail? email}) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: AddEmailView(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: AddEmailController(
        Get.find(),
        initial: email,
        pop: Navigator.of(context).pop,
      ),
      builder: (AddEmailController c) {
        return Obx(() {
          final List<Widget> children;

          switch (c.stage.value) {
            case AddEmailFlowStage.code:
              children = [
                Flexible(
                  child: Padding(
                    padding: ModalPopup.padding(context),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Obx(() {
                            return Text(
                              c.resent.value
                                  ? 'label_add_email_confirmation_sent_again'
                                      .l10n
                                  : 'label_add_email_confirmation_sent'.l10n,
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: const Color(0xFF888888),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 25),
                        ReactiveTextField(
                          key: const Key('ConfirmationCode'),
                          state: c.emailCode,
                          label: 'label_confirmation_code'.l10n,
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
                                    c.resendEmailTimeout.value == 0
                                        ? 'label_resend'.l10n
                                        : 'label_resend_timeout'.l10nfmt(
                                            {
                                              'timeout':
                                                  c.resendEmailTimeout.value,
                                            },
                                          ),
                                    style: thin?.copyWith(
                                      color: c.resendEmailTimeout.value == 0
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  onPressed: c.resendEmailTimeout.value == 0
                                      ? c.resendEmail
                                      : null,
                                  color: const Color(0xFF63B4FF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedRoundedButton(
                                  key: const Key('Proceed'),
                                  maxWidth: double.infinity,
                                  title: Text(
                                    'btn_proceed'.l10n,
                                    style: thin?.copyWith(
                                      color: c.emailCode.isEmpty.value
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                  onPressed: c.emailCode.isEmpty.value
                                      ? null
                                      : c.emailCode.submit,
                                  color: const Color(0xFF63B4FF),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ];
              break;

            default:
              children = [
                Flexible(
                  child: Padding(
                    padding: ModalPopup.padding(context),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'label_add_email_description'.l10n,
                            style: thin?.copyWith(
                              fontSize: 15,
                              color: const Color(0xFF888888),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        ReactiveTextField(
                          key: const Key('Email'),
                          state: c.email,
                          label: 'label_email'.l10n,
                          hint: 'label_email_example'.l10n,
                        ),
                        const SizedBox(height: 25),
                        Obx(() {
                          return OutlinedRoundedButton(
                            key: const Key('Proceed'),
                            maxWidth: double.infinity,
                            title: Text(
                              'btn_proceed'.l10n,
                              style: thin?.copyWith(
                                color: c.email.isEmpty.value
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            onPressed:
                                c.email.isEmpty.value ? null : c.email.submit,
                            color: const Color(0xFF63B4FF),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'label_add_email'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                ...children,
                const SizedBox(height: 16),
              ],
            ),
          );
        });
      },
    );
  }
}
