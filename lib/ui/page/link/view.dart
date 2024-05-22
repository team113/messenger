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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/widget/modal_popup.dart';
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
    return GetBuilder(
      init: LinkController(Get.find(), Get.find()),
      builder: (LinkController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_your_direct_link'.l10n),
            Flexible(
              child: ListView(
                padding: ModalPopup.padding(context),
                shrinkWrap: true,
                children: [
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
