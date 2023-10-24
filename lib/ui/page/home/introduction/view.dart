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
import 'package:get/get.dart';
import 'package:messenger/config.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/direct_link.dart';
import 'package:messenger/ui/page/work/widget/share_icon_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:share_plus/share_plus.dart';

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
  const IntroductionView({super.key});

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
          List<Widget> numId() {
            return [
              const SizedBox(height: 25),
              if (PlatformUtils.isMobile)
                SharableTextField(
                  key: const Key('NumCopyable'),
                  text: c.num.text,
                  label: 'label_num'.l10n,
                  share: 'Gapopa ID: ${c.myUser.value?.num}',
                  style: style.fonts.big.regular.onBackground,
                )
              else
                CopyableTextField(
                  key: const Key('NumCopyable'),
                  state: c.num,
                  label: 'label_num'.l10n,
                  style: style.fonts.big.regular.onBackground,
                ),
              const SizedBox(height: 25),
            ];
          }

          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.signUp:
              header = ModalPopupHeader(text: 'label_account_created'.l10n);

              children = [
                const SizedBox(height: 25),
                if (PlatformUtils.isMobile)
                  SharableTextField(
                    text: c.num.text,
                    label: 'label_num'.l10n,
                    share: 'Gapopa ID: ${c.myUser.value?.num}',
                    style: style.fonts.big.regular.onBackground,
                  )
                else
                  CopyableTextField(
                    state: c.num,
                    label: 'label_num'.l10n,
                    style: style.fonts.big.regular.onBackground,
                  ),
                const SizedBox(height: 25),
                // _emails(c, context),
                // _phones(c, context),
                _link(c, context),
                const SizedBox(height: 25),
                OutlinedRoundedButton(
                  key: const Key('OkButton'),
                  maxWidth: double.infinity,
                  title: Text(
                    'btn_ok'.l10n,
                    style: style.fonts.normal.regular.onPrimary,
                  ),
                  onPressed: Navigator.of(context).pop,
                  color: style.colors.primary,
                ),
              ];
              break;

            case IntroductionViewStage.password:
              header = ModalPopupHeader(
                onBack: () => c.stage.value = null,
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                ...numId(),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'btn_set_password'.l10n,
                    style: style.fonts.big.regular.onBackground,
                  ),
                ),
                const SizedBox(height: 18),
                ReactiveTextField(
                  key: const Key('PasswordField'),
                  state: c.password,
                  label: 'label_password'.l10n,
                  obscure: c.obscurePassword.value,
                  style: style.fonts.big.regular.onBackground,
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
                  style: style.fonts.normal.regular.onBackground,
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
                        ? style.fonts.normal.regular.onBackground
                        : style.fonts.normal.regular.onPrimary,
                  ),
                  onPressed: c.password.isEmpty.value || c.repeat.isEmpty.value
                      ? null
                      : c.setPassword,
                  color: style.colors.primary,
                ),
              ];
              break;

            case IntroductionViewStage.success:
              header = ModalPopupHeader(
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                ...numId(),
                Text(
                  'label_password_set'.l10n,
                  style: style.fonts.medium.regular.secondary,
                ),
                const SizedBox(height: 25),
                Center(
                  child: OutlinedRoundedButton(
                    key: const Key('CloseButton'),
                    maxWidth: double.infinity,
                    title: Text(
                      'btn_close'.l10n,
                      style: style.fonts.normal.regular.onPrimary,
                    ),
                    onPressed: Navigator.of(context).pop,
                    color: style.colors.primary,
                  ),
                ),
              ];
              break;

            default:
              header = ModalPopupHeader(
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                ...numId(),
                _link(c, context),
                const SizedBox(height: 25),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'label_introduction_description1'.l10n,
                        style: style.fonts.medium.regular.onBackground,
                      ),
                      TextSpan(
                        text: 'label_introduction_description2'.l10n,
                        style: style.fonts.medium.regular.primary,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pop();
                            router.me();
                          },
                      ),
                      TextSpan(
                        text: 'label_introduction_description3'.l10n,
                        style: style.fonts.medium.regular.onBackground,
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
                    style: style.fonts.normal.regular.onPrimary,
                  ),
                  onPressed: Navigator.of(context).pop,
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
                  header,
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

  Widget _link(IntroductionController c, BuildContext context) {
    final style = Theme.of(context).style;

    return ReactiveTextField(
      state: c.link,
      onSuffixPressed: () {
        // TODO: Create link and copy/share it.
      },
      onCopied: (_, __) {
        // TODO: Create link and copy/share it.
      },
      trailing: PlatformUtils.isMobile
          ? const SvgImage.asset(
              'assets/icons/share_thick.svg',
              width: 17.54,
              height: 18.36,
            )
          : const SvgImage.asset('assets/icons/copy.svg', height: 17.25),
      label: 'label_your_direct_link'.l10n,
    );

    return ReactiveTextField(
      key: const Key('LinkField'),
      state: TextFieldState(
        text:
            '${Config.origin.replaceFirst('https://', '').replaceFirst('http://', '')}${Routes.chatDirectLink}/${c.link.text}',
        editable: false,
      ),
      style: style.fonts.normal.regular.onBackground,
      onSuffixPressed: () async {
        await c.copyLink(
          onSuccess: () async {
            final link =
                '${Config.origin}${Routes.chatDirectLink}/${c.link.text}';

            if (PlatformUtils.isMobile) {
              await Share.share(link);
            } else {
              PlatformUtils.copy(text: link);
              MessagePopup.success('label_copied'.l10n);
            }
          },
        );
      },
      // trailing: const ShareIconButton(''),
      trailing: PlatformUtils.isMobile
          ? const SvgImage.asset(
              'assets/icons/share_thick.svg',
              width: 17.54,
              height: 18.36,
            )
          : const SvgImage.asset('assets/icons/copy.svg', height: 17.25),

      label: 'label_your_direct_link'.l10n,
    );
  }
}
