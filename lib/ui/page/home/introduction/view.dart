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

import '/l10n/l10n.dart';
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
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: IntroductionController(Get.find()),
      builder: (IntroductionController c) {
        return Obx(() {
          List<Widget> children;

          if (c.displaySuccess.value) {
            children = [
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'label_password_set_successfully'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: OutlinedRoundedButton(
                  title: Text('btn_close'.l10n),
                  onPressed: Navigator.of(context).pop,
                  color: const Color(0xFFEEEEEE),
                ),
              ),
            ];
          } else if (c.displayPassword.value) {
            children = [
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'btn_set_password'.l10n,
                  style: thin?.copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 18),
              ReactiveTextField(
                state: c.password,
                label: 'label_password'.l10n,
                obscure: c.obscurePassword.value,
                style: thin,
                onSuffixPressed: c.obscurePassword.toggle,
                treatErrorAsStatus: false,
                trailing: SvgLoader.asset(
                  'assets/icons/visible_${c.obscurePassword.value ? 'off' : 'on'}.svg',
                  width: 17.07,
                ),
              ),
              const SizedBox(height: 12),
              ReactiveTextField(
                state: c.repeat,
                label: 'label_repeat_password'.l10n,
                obscure: c.obscureRepeat.value,
                style: thin,
                onSuffixPressed: c.obscureRepeat.toggle,
                treatErrorAsStatus: false,
                trailing: SvgLoader.asset(
                  'assets/icons/visible_${c.obscureRepeat.value ? 'off' : 'on'}.svg',
                  width: 17.07,
                ),
              ),
              const SizedBox(height: 25),
              OutlinedRoundedButton(
                title: Text(
                  'btn_save'.l10n,
                  style: thin?.copyWith(color: Colors.white),
                ),
                onPressed: c.setPassword,
                height: 50,
                leading: SvgLoader.asset(
                  'assets/icons/save.svg',
                  height: 25 * 0.7,
                ),
                color: const Color(0xFF63B4FF),
              ),
            ];
          } else {
            children = [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      style: thin,
                      text: 'label_password_not_set_description'.l10n,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedRoundedButton(
                      key: const Key('IntroductionSetPasswordButton'),
                      maxWidth: null,
                      title: Text(
                        'btn_set_password'.l10n,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        c.displayPassword.value = true;
                      },
                      color: const Color(0xFF63B4FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedRoundedButton(
                      key: const Key('IntroductionCloseButton'),
                      maxWidth: null,
                      title: Text(
                        'btn_close'.l10n,
                        style: const TextStyle(),
                      ),
                      onPressed: Navigator.of(context).pop,
                      color: const Color(0xFFEEEEEE),
                    ),
                  )
                ],
              ),
            ];
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 150),
            sizeDuration: const Duration(milliseconds: 200),
            child: ListView(
              key: Key('${c.displayPassword.value}${c.displaySuccess.value}'),
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'label_account_created'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 25),
                if (PlatformUtils.isMobile)
                  SharableTextField(
                    key: const Key('NumCopyable'),
                    text: c.num.text,
                    label: 'label_num'.l10n,
                    copy: 'Gapopa ID: ${c.myUser.value?.num.val}',
                    trailing:
                        SvgLoader.asset('assets/icons/share.svg', width: 18),
                    style: thin,
                  )
                else
                  CopyableTextField(
                    key: const Key('NumCopyable'),
                    state: c.num,
                    label: 'label_num'.l10n,
                    copy: c.myUser.value?.num.val,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                const SizedBox(height: 25),
                ...children,
                const SizedBox(height: 25 + 12),
              ],
            ),
          );
        });
      },
    );
  }
}
