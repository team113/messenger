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
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [ApplicationSettings.enablePopups] value.
///
/// Intended to be displayed with the [show] method.
class CallLeaveSwitchView extends StatelessWidget {
  const CallLeaveSwitchView({super.key});

  /// Displays a [CallWindowSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(BuildContext context) {
    return ModalPopup.show(
      context: context,
      child: const CallLeaveSwitchView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: CallLeaveSwitchController(Get.find()),
      builder: (CallLeaveSwitchController c) {
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
                    'label_calls'.l10n,
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
                            (c.settings.value?.leaveWhenAlone ?? false) == true;
                      } else {
                        selected =
                            (c.settings.value?.leaveWhenAlone ?? false) ==
                                false;
                      }

                      return RectangleButton(
                        label: i == 0
                            ? 'label_leave_group_call_when_alone'.l10n
                            : 'label_don_t_leave_group_call_when_alone'.l10n,
                        selected: selected,
                        onPressed: () => c.setLeaveWhenAlone(i == 0),
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
