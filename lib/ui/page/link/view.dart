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
import 'package:get/get.dart';

import '/config.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of a [DirectLinkField].
///
/// Intended to be displayed with a [show] method.
class LinkView extends StatelessWidget {
  const LinkView({super.key});

  /// Displays a [LinkView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const LinkView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: LinkController(
        Get.find(),
        Get.find(),
        Get.find(),
        pop: context.popModal,
      ),
      builder: (LinkController c) {
        return Obx(() {
          final Widget header;
          final List<Widget> children;

          switch (c.screen.value) {
            case LinkScreen.link:
              header = ModalPopupHeader(text: 'label_your_direct_link'.l10n);
              children = [
                const SizedBox(height: 16),
                Obx(() {
                  return DirectLinkField(
                    c.myUser.value?.chatDirectLink,
                    onSubmit: (s) async {
                      if (s == null) {
                        await c.deleteChatDirectLink();
                      } else {
                        await c.createChatDirectLink(s);
                      }
                    },
                    background: c.background.value,
                  );
                }),
                // const SizedBox(height: 25),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: 0.5,
                        color: style.colors.onBackgroundOpacity27,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'label_or'.l10n,
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        height: 0.5,
                        color: style.colors.onBackgroundOpacity27,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: WidgetButton(
                    key: const Key('SaveLinkButton'),
                    onPressed: () => c.screen.value = LinkScreen.input,
                    child: Text(
                      'btn_or_input_someones_link'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ];
              break;

            case LinkScreen.input:
              header = ModalPopupHeader(
                text: 'label_direct_chat_link'.l10n,
                onBack: () => c.screen.value = LinkScreen.link,
              );
              children = [
                const SizedBox(height: 25),
                ReactiveTextField(
                  state: c.link,
                  label: 'label_direct_chat_link'.l10n,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hint: '${Config.link}/...',
                ),
                const SizedBox(height: 25),
                Obx(() {
                  final bool enabled = !c.link.isEmpty.value &&
                      c.link.status.value.isEmpty &&
                      (c.link.error.value == null ||
                          c.link.resubmitOnError.value);

                  return PrimaryButton(
                    title: 'btn_proceed'.l10n,
                    onPressed: enabled ? c.openLink : null,
                  );
                }),
                const SizedBox(height: 16),
              ];
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: Column(
              key: Key(c.screen.value.toString()),
              mainAxisSize: MainAxisSize.min,
              children: [
                header,
                Flexible(
                  child: ListView(
                    padding: ModalPopup.padding(context),
                    shrinkWrap: true,
                    children: children,
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
