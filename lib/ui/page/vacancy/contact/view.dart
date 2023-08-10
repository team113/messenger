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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/animated_size_and_fade.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// ...
///
/// Intended to be displayed with the [show] method.
class VacancyContactView extends StatelessWidget {
  const VacancyContactView({super.key, this.onSuccess});

  final void Function()? onSuccess;

  /// Displays an [AccountsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context,
      {void Function()? onSuccess}) {
    return ModalPopup.show(
      context: context,
      child: VacancyContactView(onSuccess: onSuccess),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('AccountsView'),
      init: VacancyContactController(Get.find()),
      builder: (VacancyContactController c) {
        return Obx(() {
          List<Widget> children;

          switch (c.stage.value) {
            case VacancyContactScreen.validate:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text('Register'.l10n,
                        style: style.fonts.headlineMedium),
                  ),
                  onBack: () => c.stage.value = null,
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Obx(() {
                      return Text(
                        c.resent.value
                            ? 'label_add_email_confirmation_sent_again'.l10n
                            : 'label_add_email_confirmation_sent'.l10n,
                        style: style.fonts.bodyMedium!.copyWith(
                          color: style.colors.secondary,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    state: c.emailCode,
                    label: 'label_confirmation_code'.l10n,
                    style: style.fonts.bodyMedium,
                    treatErrorAsStatus: false,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Obx(() {
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
                                      {'timeout': c.resendEmailTimeout.value},
                                    ),
                              style: style.fonts.bodyMedium!.copyWith(
                                color: c.resendEmailTimeout.value == 0
                                    ? style.colors.onPrimary
                                    : style.colors.onBackground,
                              ),
                            ),
                            onPressed: c.resendEmailTimeout.value == 0
                                ? c.resendEmail
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
                              style: style.fonts.bodyMedium!.copyWith(
                                color: c.emailCode.isEmpty.value
                                    ? style.colors.onBackground
                                    : style.colors.onPrimary,
                              ),
                            ),
                            onPressed: c.emailCode.isEmpty.value
                                ? null
                                : c.emailCode.submit,
                            color: style.colors.primary,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                // const SizedBox(height: 18),
                // Padding(
                //   padding: ModalPopup.padding(context),
                //   child: Center(
                //     child: Obx(() {
                //       final bool enabled = !c.emailCode.isEmpty.value;

                //       return OutlinedRoundedButton(
                //         title: Text(
                //           'Proceed'.l10n,
                //           style: style.fonts.titleLarge!.copyWith(
                //             color: enabled
                //                 ? style.colors.onPrimary
                //                 : style.fonts.titleLarge!.color,
                //           ),
                //         ),
                //         onPressed: enabled ? c.emailCode.submit : null,
                //         color: style.colors.primary,
                //         maxWidth: double.infinity,
                //       );
                //     }),
                //   ),
                // ),
              ];
              break;

            case VacancyContactScreen.register:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text('Register'.l10n,
                        style: style.fonts.headlineMedium),
                  ),
                  onBack: () => c.stage.value = null,
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    state: c.email,
                    label: 'label_email'.l10n,
                    style: style.fonts.bodyMedium,
                    treatErrorAsStatus: false,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    state: c.newPassword,
                    label: 'label_password'.l10n,
                    obscure: c.obscureNewPassword.value,
                    style: style.fonts.bodyMedium,
                    onSuffixPressed: c.obscureNewPassword.toggle,
                    treatErrorAsStatus: false,
                    trailing: SvgImage.asset(
                      'assets/icons/visible_${c.obscureNewPassword.value ? 'off' : 'on'}.svg',
                      width: 17.07,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    state: c.repeatPassword,
                    label: 'label_repeat_password'.l10n,
                    obscure: c.obscureRepeatPassword.value,
                    style: style.fonts.bodyMedium,
                    onSuffixPressed: c.obscureRepeatPassword.toggle,
                    treatErrorAsStatus: false,
                    trailing: SvgImage.asset(
                      'assets/icons/visible_${c.obscureRepeatPassword.value ? 'off' : 'on'}.svg',
                      width: 17.07,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: Obx(() {
                      final bool enabled = !c.email.isEmpty.value &&
                          c.email.error.value == null &&
                          !c.newPassword.isEmpty.value &&
                          c.newPassword.error.value == null &&
                          !c.repeatPassword.isEmpty.value &&
                          c.repeatPassword.error.value == null;

                      return OutlinedRoundedButton(
                        title: Text(
                          'Proceed'.l10n,
                          style: style.fonts.titleLarge!.copyWith(
                            color: enabled
                                ? style.colors.onPrimary
                                : style.fonts.titleLarge!.color,
                          ),
                        ),
                        onPressed: enabled ? c.repeatPassword.submit : null,
                        color: style.colors.primary,
                        maxWidth: double.infinity,
                      );
                    }),
                  ),
                ),
              ];
              break;

            default:
              children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text('Contact us'.l10n,
                        style: style.fonts.headlineMedium),
                  ),
                ),
                const SizedBox(height: 25 - 12),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: ReactiveTextField(
                    key: const Key('LoginField'),
                    state: c.login,
                    label: 'label_login'.l10n,
                    style: style.fonts.bodyMedium,
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
                    style: style.fonts.bodyMedium,
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
                      title: Text(
                        'Login'.l10n,
                        style: style.fonts.titleLarge!.copyWith(
                          color:
                              c.login.isEmpty.value || c.password.isEmpty.value
                                  ? style.fonts.titleLarge!.color
                                  : style.colors.onPrimary,
                        ),
                      ),
                      onPressed:
                          c.login.isEmpty.value || c.password.isEmpty.value
                              ? null
                              : () async {
                                  await c.signIn();
                                  Navigator.of(context).pop(true);
                                },
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                    ),
                  ),
                ),
                const SizedBox(height: 25 / 2),
                Row(
                  children: [
                    const SizedBox(width: 32),
                    Expanded(
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: style.colors.secondaryHighlight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('OR', style: style.fonts.headlineSmall),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: style.colors.secondaryHighlight,
                      ),
                    ),
                    const SizedBox(width: 32),
                  ],
                ),
                const SizedBox(height: 25 / 2),
                Padding(
                  padding: ModalPopup.padding(context),
                  child: Center(
                    child: OutlinedRoundedButton(
                      title: Text(
                        'Create account'.l10n,
                        style: style.fonts.titleLarge!.copyWith(
                          color: style.colors.onPrimary,
                        ),
                      ),
                      onPressed: () {
                        c.stage.value = VacancyContactScreen.register;
                      },
                      color: style.colors.primary,
                      maxWidth: double.infinity,
                    ),
                  ),
                ),
              ];
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: ListView(
              key: Key('${c.stage.value}'),
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [...children, const SizedBox(height: 12)],
            ),
          );
        });
      },
    );
  }
}
