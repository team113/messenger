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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../dense.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/my_profile/camera_switch/controller.dart';
import '/ui/page/home/page/my_profile/microphone_switch/controller.dart';
import '/ui/page/home/page/my_profile/output_switch/controller.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/util/media_utils.dart';

/// [Widget] which returns the contents of a [ProfileTab.media] section.
class ProfileMedia extends StatelessWidget {
  const ProfileMedia(
    this.devices,
    this.media, {
    super.key,
  });

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<MediaDeviceDetails> devices;

  /// Reactive [MediaSettings] that returns the current media settings value.
  final Rx<MediaSettings?> media;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dense(
          Obx(() {
            return FieldButton(
              text: (devices.video().firstWhereOrNull((e) =>
                              e.deviceId() == media.value?.videoDevice) ??
                          devices.video().firstOrNull)
                      ?.label() ??
                  'label_media_no_device_available'.l10n,
              hint: 'label_media_camera'.l10n,
              onPressed: () async {
                await CameraSwitchView.show(
                  context,
                  camera: media.value?.videoDevice,
                );

                if (devices.video().isEmpty) {
                  devices.value = await MediaUtils.enumerateDevices();
                }
              },
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            );
          }),
        ),
        const SizedBox(height: 16),
        Dense(
          Obx(() {
            return FieldButton(
              text: (devices.audio().firstWhereOrNull((e) =>
                              e.deviceId() == media.value?.audioDevice) ??
                          devices.audio().firstOrNull)
                      ?.label() ??
                  'label_media_no_device_available'.l10n,
              hint: 'label_media_microphone'.l10n,
              onPressed: () async {
                await MicrophoneSwitchView.show(
                  context,
                  mic: media.value?.audioDevice,
                );

                if (devices.audio().isEmpty) {
                  devices.value = await MediaUtils.enumerateDevices();
                }
              },
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            );
          }),
        ),
        const SizedBox(height: 16),
        Dense(
          Obx(() {
            return FieldButton(
              text: (devices.output().firstWhereOrNull((e) =>
                              e.deviceId() == media.value?.outputDevice) ??
                          devices.output().firstOrNull)
                      ?.label() ??
                  'label_media_no_device_available'.l10n,
              hint: 'label_media_output'.l10n,
              onPressed: () async {
                await OutputSwitchView.show(
                  context,
                  output: media.value?.outputDevice,
                );

                if (devices.output().isEmpty) {
                  devices.value = await MediaUtils.enumerateDevices();
                }
              },
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            );
          }),
        ),
      ],
    );
  }
}
