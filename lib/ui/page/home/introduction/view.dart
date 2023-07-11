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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/routes.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/sharable.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// Introduction displaying important information alongside with an ability to
/// set a password.
///
/// Intended to be displayed with the [show] method.
class IntroductionView extends StatelessWidget {
  const IntroductionView({Key? key}) : super(key: key);

  /// Displays an [IntroductionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const IntroductionView());
  }

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return GetBuilder(
      key: const Key('IntroductionView'),
      init: IntroductionController(Get.find()),
      builder: (IntroductionController c) {
        return Obx(() {
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.validate:
              children = [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Obx(() {
                    return Text(
                      c.resent.value
                          ? 'label_add_email_confirmation_sent_again'.l10n
                          : 'label_add_email_confirmation_sent'.l10n,
                      style: fonts.bodyMedium!.copyWith(
                        color: style.colors.secondary,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 25),
                ReactiveTextField(
                  state: c.emailCode,
                  label: 'label_confirmation_code'.l10n,
                  style: fonts.bodyMedium,
                  treatErrorAsStatus: false,
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
                            c.resendEmailTimeout.value == 0
                                ? 'label_resend'.l10n
                                : 'label_resend_timeout'.l10nfmt(
                                    {'timeout': c.resendEmailTimeout.value},
                                  ),
                            style: fonts.bodyMedium!.copyWith(
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
                            style: fonts.bodyMedium!.copyWith(
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
              ];

            case IntroductionViewStage.password:
              children = [
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'btn_set_password'.l10n,
                    style: fonts.headlineMedium,
                  ),
                ),
                const SizedBox(height: 18),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  style: fonts.bodyMedium,
                  onSuffixPressed: c.obscurePassword.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeat,
                  label: 'label_repeat_password'.l10n,
                  obscure: c.obscureRepeat.value,
                  style: fonts.bodyMedium,
                  onSuffixPressed: c.obscureRepeat.toggle,
                  treatErrorAsStatus: false,
                  trailing: SvgImage.asset(
                    'assets/icons/visible_${c.obscureRepeat.value ? 'off' : 'on'}.svg',
                    width: 17.07,
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('ChangePasswordButton'),
                  title: Text(
                    'btn_proceed'.l10n,
                    style: fonts.bodyMedium!.copyWith(
                      color: c.password.isEmpty.value || c.repeat.isEmpty.value
                          ? style.colors.onBackground
                          : style.colors.onPrimary,
                    ),
                  ),
                  onPressed: c.password.isEmpty.value || c.repeat.isEmpty.value
                      ? null
                      : c.setPassword,
                  color: style.colors.primary,
                ),
              ];
              break;

            case IntroductionViewStage.success:
              children = [
                Text(
                  'label_password_set'.l10n,
                  style: fonts.bodyMedium!.copyWith(
                    color: style.colors.secondary,
                  ),
                ),
                const SizedBox(height: 25),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('CloseButton'),
                    maxWidth: double.infinity,
                    title: Text(
                      'btn_close'.l10n,
                      style: fonts.bodyMedium!.copyWith(
                        color: style.colors.onPrimary,
                      ),
                    ),
                    onPressed: Navigator.of(context).pop,
                    color: style.colors.primary,
                  ),
                ),
              ];
              break;

            default:
              children = [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'label_introduction_description1'.l10n,
                        style: fonts.bodyMedium,
                      ),
                      TextSpan(
                        text: 'label_introduction_description2'.l10n,
                        style: fonts.bodyMedium
                            ?.copyWith(color: style.colors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                            router.me();
                          },
                      ),
                      TextSpan(
                        text: 'label_introduction_description3'.l10n,
                        style: fonts.bodyMedium,
                      ),
                      TextSpan(
                        text: 'label_introduction_description4'.l10n,
                        style: fonts.bodyMedium
                            ?.copyWith(color: style.colors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                            router.me();
                          },
                      ),
                      TextSpan(
                        text: 'label_introduction_description5'.l10n,
                        style: fonts.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('SetPasswordButton'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_ok'.l10n,
                    style: fonts.bodyMedium!.copyWith(
                      color: style.colors.onPrimary,
                    ),
                  ),
                  onPressed: Navigator.of(context).pop,
                  // onPressed: () =>
                  //     c.stage.value = IntroductionViewStage.password,
                  color: style.colors.primary,
                ),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Scrollbar(
              key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
              controller: c.scrollController,
              child: ListView(
                controller: c.scrollController,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                children: [
                  ModalPopupHeader(
                    onBack: c.stage.value == IntroductionViewStage.password
                        ? () => c.stage.value = null
                        : null,
                    header: Center(
                      child: Text(
                        'label_one_time_account_created'.l10n,
                        style: fonts.headlineMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Padding(
                    padding: ModalPopup.padding(context),
                    child: PlatformUtils.isMobile
                        ? SharableTextField(
                            key: const Key('NumCopyable'),
                            text: c.num.text,
                            label: 'label_num'.l10n,
                            share: 'Gapopa ID: ${c.myUser.value?.num.val}',
                            trailing: SvgImage.asset(
                              'assets/icons/share.svg',
                              width: 18,
                            ),
                            style: fonts.bodyMedium,
                          )
                        : CopyableTextField(
                            key: const Key('NumCopyable'),
                            state: c.num,
                            label: 'label_num'.l10n,
                            copy: c.myUser.value?.num.val,
                            style: fonts.headlineMedium,
                          ),
                  ),
                  const SizedBox(height: 25),
                  ...children.map((e) =>
                      Padding(padding: ModalPopup.padding(context), child: e)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
