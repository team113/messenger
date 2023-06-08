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

import '/domain/model/application_settings.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [ApplicationSettings.timelineEnabled] value.
///
/// Intended to be displayed with the [show] method.
class TimelineSwitchView extends StatelessWidget {
  const TimelineSwitchView({super.key});

  /// Displays a [TimelineSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(context: context, child: const TimelineSwitchView());
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: TimelineSwitchController(Get.find()),
      builder: (TimelineSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_display_timestamps'.l10n,
                    style: style.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: ModalPopup.padding(context),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: 2,
                  itemBuilder: (_, i) {
                    return Obx(() {
                      final bool enabled =
                          (c.settings.value?.timelineEnabled ?? true);

                      return RectangleButton(
                        selected: (i == 0 && enabled) || (i == 1 && !enabled),
                        onPressed: () => c.setTimelineEnabled(i == 0),
                        label: i == 0
                            ? 'label_as_timeline'.l10n
                            : 'label_in_message'.l10n,
                      );
                    });
                  },
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
