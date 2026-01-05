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

import '/domain/model/media_settings.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import '/util/media_utils.dart';
import 'controller.dart';

/// View for updating the [MediaSettings.outputDevice].
///
/// Intended to be displayed with the [show] method.
class OutputSwitchView extends StatelessWidget {
  const OutputSwitchView({super.key, this.onChanged, this.output});

  /// Callback, called when the selected output device changes.
  final void Function(DeviceDetails)? onChanged;

  /// ID of the initially selected audio output device.
  final String? output;

  /// Displays a [OutputSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    void Function(DeviceDetails)? onChanged,
    String? output,
  }) {
    return ModalPopup.show(
      context: context,
      child: OutputSwitchView(onChanged: onChanged, output: output),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: OutputSwitchController(Get.find(), output: output),
      builder: (OutputSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              ModalPopupHeader(text: 'label_media_output'.l10n),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 13),
                    Obx(() {
                      if (c.error.value == null) {
                        return const SizedBox();
                      }

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: Text(
                          c.error.value!,
                          style: style.fonts.normal.regular.danger,
                        ),
                      );
                    }),
                    Obx(() {
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: ModalPopup.padding(context),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemCount: c.devices.length,
                        itemBuilder: (_, i) {
                          return Obx(() {
                            final DeviceDetails e = c.devices[i];

                            final bool selected =
                                (c.selected.value == null && i == 0) ||
                                c.selected.value?.id() == e.id();

                            return RectangleButton(
                              selected: selected,
                              onPressed: selected
                                  ? null
                                  : () {
                                      c.selected.value = e;
                                      (onChanged ?? c.setOutputDevice).call(e);
                                    },
                              label: e.label(),
                            );
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
