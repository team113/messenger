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
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [ApplicationSettings.enablePopups] value.
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
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: CallWindowSwitchController(Get.find()),
      builder: (CallWindowSwitchController c) {
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
                    'label_timeline_displaying'.l10n,
                    style: thin?.copyWith(fontSize: 18),
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
                      final bool selected;
                      if (i == 0) {
                        selected =
                            (c.settings.value?.timelineEnabled ?? true) == true;
                      } else {
                        selected =
                            (c.settings.value?.timelineEnabled ?? true) ==
                                false;
                      }

                      return Material(
                        borderRadius: BorderRadius.circular(10),
                        color: selected
                            ? style.cardSelectedColor.withOpacity(0.8)
                            : Colors.white.darken(0.05),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => c.setTimelineEnabled(i == 0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    i == 0
                                        ? 'label_compact_timeline'.l10n
                                        : 'label_detailed_timeline'.l10n,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
                                        ? CircleAvatar(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                            radius: 12,
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          )
                                        : const SizedBox(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
