// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/api/backend/schema.dart' show UserPresence;
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [MyUser.presence] value.
///
/// Intended to be displayed with the [show] method.
class PresenceSwitchView extends StatelessWidget {
  const PresenceSwitchView({super.key});

  /// Displays a [PresenceSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const PresenceSwitchView());
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: PresenceSwitchController(Get.find()),
      builder: (PresenceSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(text: 'label_your_status'.l10n),
              const SizedBox(height: 13),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  children: [
                    ...[UserPresence.present, UserPresence.away].map((e) {
                      return Obx(() {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
                          child: RectangleButton(
                            selected: c.myUser.value?.presence == e,
                            onPressed: () => c.setPresence(e),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: style.colors.onPrimary,
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: switch (e) {
                                        UserPresence.present =>
                                          style.colors.acceptAuxiliary,
                                        UserPresence.away =>
                                          style.colors.warning,
                                        (_) => style.colors.secondary,
                                      },
                                    ),
                                    width: 8,
                                    height: 8,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(switch (e) {
                                  UserPresence.present =>
                                    'label_presence_present'.l10n,
                                  UserPresence.away =>
                                    'label_presence_away'.l10n,
                                  (_) => '',
                                }),
                              ],
                            ),
                          ),
                        );
                      });
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
