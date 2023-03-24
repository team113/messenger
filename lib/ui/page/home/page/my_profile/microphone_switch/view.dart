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
import 'package:messenger/themes.dart';

import '/domain/model/media_settings.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [MediaSettings.audioDevice].
///
/// Intended to be displayed with the [show] method.
class MicrophoneSwitchView extends StatelessWidget {
  const MicrophoneSwitchView({super.key, this.onChanged, this.mic});

  /// Callback, called when the selected microphone device changes.
  final void Function(String)? onChanged;

  /// ID of the initially selected microphone device.
  final String? mic;

  /// Displays a [MicrophoneSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    void Function(String)? onChanged,
    String? mic,
  }) {
    return ModalPopup.show(
      context: context,
      child: MicrophoneSwitchView(onChanged: onChanged, mic: mic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin = Theme.of(context)
        .textTheme
        .bodyLarge
        ?.copyWith(color: Theme.of(context).extension<Style>()!.onBackground);

    return GetBuilder(
      init: MicrophoneSwitchController(Get.find(), mic: mic),
      builder: (MicrophoneSwitchController c) {
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
                    'label_media_microphone'.l10n,
                    style: thin?.copyWith(fontSize: 18),
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
                            final MediaDeviceInfo e = c.devices[i];

                            final bool selected =
                                (c.mic.value == null && i == 0) ||
                                    c.mic.value == e.deviceId();

                            return RectangleButton(
                              selected: selected,
                              onPressed: selected
                                  ? null
                                  : () {
                                      c.mic.value = e.deviceId();
                                      (onChanged ?? c.setAudioDevice)
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
