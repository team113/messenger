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
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/media_settings.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [MediaSettings.outputDevice].
///
/// Intended to be displayed with the [show] method.
class OutputSwitchView extends StatelessWidget {
  const OutputSwitchView({super.key, this.onChanged, this.output});

  /// Callback, called when the selected output device changes.
  final void Function(String)? onChanged;

  /// ID of the initially selected audio output device.
  final String? output;

  /// Displays a [OutputSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    void Function(String)? onChanged,
    String? output,
  }) {
    return ModalPopup.show(
      context: context,
      child: OutputSwitchView(onChanged: onChanged, output: output),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              ModalPopupHeader(
                header: Center(
                  child: Text(
                    'label_media_output'.l10n,
                    style: context.textTheme.displaySmall,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 13),
                    Obx(() {
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: ModalPopup.padding(context),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: c.devices.length,
                        itemBuilder: (_, i) {
                          return Obx(() {
                            final MediaDeviceDetails e = c.devices[i];

                            final bool selected =
                                (c.output.value == null && i == 0) ||
                                    c.output.value == e.deviceId();

                            return RectangleButton(
                              selected: selected,
                              onPressed: selected
                                  ? null
                                  : () {
                                      c.output.value = e.deviceId();
                                      (onChanged ?? c.setOutputDevice)
                                          .call(e.deviceId());
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
