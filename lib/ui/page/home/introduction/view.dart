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
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('IntroductionView'),
      init: IntroductionController(Get.find()),
      builder: (IntroductionController c) {
        return Obx(() {
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.password:
              children = [
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'btn_set_password'.l10n,
                    style: style.fonts.headlineMedium,
                  ),
                ),
                const SizedBox(height: 18),
                ReactiveTextField(
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
                const SizedBox(height: 12),
                ReactiveTextField(
                  key: const Key('RepeatPasswordField'),
                  state: c.repeat,
                  label: 'label_repeat_password'.l10n,
                  obscure: c.obscureRepeat.value,
                  style: style.fonts.bodyMedium,
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
                    style: c.password.isEmpty.value || c.repeat.isEmpty.value
                        ? style.fonts.bodyMedium
                        : style.fonts.bodyMediumOnPrimary,
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
                  style: style.fonts.bodyMediumSecondary,
                ),
                const SizedBox(height: 25),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('CloseButton'),
                    maxWidth: double.infinity,
                    title: Text(
                      'btn_close'.l10n,
                      style: style.fonts.bodyMediumOnPrimary,
                    ),
                    onPressed: Navigator.of(context).pop,
                    color: style.colors.primary,
                  ),
                ),
              ];
              break;

            default:
              children = [
                Text(
                  'label_introduction_description'.l10n,
                  style: style.fonts.bodyMedium,
                ),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('SetPasswordButton'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_set_password'.l10n,
                    style: style.fonts.bodyMediumOnPrimary,
                  ),
                  onPressed: () =>
                      c.stage.value = IntroductionViewStage.password,
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
                    text: 'label_account_created'.l10n,
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
                            style: style.fonts.bodyMedium,
                          )
                        : CopyableTextField(
                            key: const Key('NumCopyable'),
                            state: c.num,
                            label: 'label_num'.l10n,
                            style: style.fonts.headlineMedium,
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
