// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/application_settings.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [ApplicationSettings.enablePopups] value.
///
/// Intended to be displayed with the [show] method.
class CallWindowSwitchView extends StatelessWidget {
  const CallWindowSwitchView({super.key});

  /// Displays a [CallWindowSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      child: const CallWindowSwitchView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: CallWindowSwitchController(Get.find()),
      builder: (CallWindowSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModalPopupHeader(text: 'label_show_call_window'.l10n),
              const SizedBox(height: 13),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  children: [
                    Obx(() {
                      final bool value =
                          (c.settings.value?.enablePopups ?? true);

                      final asset = switch (value) {
                        true => 'calls_in_window',
                        false => 'calls_in_app',
                      };

                      return SafeAnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        child: Image.asset(
                          'assets/images/$asset.png',
                          key: Key(asset),
                          width: 320,
                          height: 200,
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Obx(() {
                      return RectangleButton(
                        label: 'label_open_calls_in_window'.l10n,
                        selected:
                            (c.settings.value?.enablePopups ?? true) == true,
                        onPressed: () => c.setPopupsEnabled(true),
                      );
                    }),
                    const SizedBox(height: 8),
                    Obx(() {
                      return RectangleButton(
                        label: 'label_open_calls_in_app'.l10n,
                        selected:
                            (c.settings.value?.enablePopups ?? true) == false,
                        onPressed: () => c.setPopupsEnabled(false),
                      );
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
