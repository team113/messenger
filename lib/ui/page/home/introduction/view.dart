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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/num.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:share_plus/share_plus.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
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
  const IntroductionView({
    super.key,
    this.initial = IntroductionViewStage.oneTime,
  });

  /// Initial [IntroductionViewStage] to display.
  final IntroductionViewStage initial;

  /// Displays an [IntroductionView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    IntroductionViewStage initial = IntroductionViewStage.oneTime,
  }) {
    return ModalPopup.show(
      context: context,
      child: IntroductionView(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('IntroductionView'),
      init: IntroductionController(Get.find(), initial: initial),
      builder: (IntroductionController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.stage.value) {
            case IntroductionViewStage.signUp:
              header = ModalPopupHeader(text: 'label_account_created'.l10n);

              children = [
                const SizedBox(height: 25),
                _num(c, context),
                const SizedBox(height: 25),
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

            case IntroductionViewStage.oneTime:
              header = ModalPopupHeader(
                text: 'label_one_time_account_created'.l10n,
              );

              children = [
                const SizedBox(height: 25),
                _num(c, context),
                const SizedBox(height: 25),
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
              key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
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

  /// Builds the [UserNumCopyable].
  Widget _num(IntroductionController c, BuildContext context) {
    return Obx(() {
      return UserNumCopyable(
        c.myUser.value?.num,
        key: const Key('NumCopyable'),
        share: PlatformUtils.isMobile,
      );
    });
  }

  /// Builds the [ChatDirectLink] visual representation field.
  Widget _link(IntroductionController c, BuildContext context) {
    Future<void> copy() async {
      if (PlatformUtils.isMobile) {
        Share.share(c.link.text);
      } else {
        PlatformUtils.copy(text: c.link.text);
        MessagePopup.success('label_copied'.l10n);
      }

      await c.createLink();
    }

    return ReactiveTextField(
      state: c.link,
      onSuffixPressed: copy,
      selectable: c.myUser.value?.chatDirectLink != null,
      trailing: PlatformUtils.isMobile
          ? const SvgIcon(SvgIcons.shareThick)
          : const SvgIcon(SvgIcons.copy),
      label: 'label_your_direct_link'.l10n,
    );
  }
}
