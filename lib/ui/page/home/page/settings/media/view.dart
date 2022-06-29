// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/fluent/extension.dart';
import 'controller.dart';

/// View of the [Routes.settingsMedia] page.
class MediaSettingsView extends StatelessWidget {
  const MediaSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);

    Widget divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 9),
      color: const Color(0x99000000),
      height: 1,
      width: double.infinity,
    );

    Widget row(Widget left, Widget right, [bool useFlexible = false]) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(flex: 9, child: left),
              useFlexible
                  ? Flexible(flex: 31, child: right)
                  : Expanded(flex: 31, child: right),
            ],
          ),
        );

    Widget dropdown({
      required MediaDeviceInfo? value,
      required Iterable<MediaDeviceInfo> devices,
      required ValueChanged<MediaDeviceInfo?> onChanged,
    }) =>
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(18),
          ),
          height: 36,
          child: DropdownButton<MediaDeviceInfo>(
            value: value,
            items: devices
                .map<DropdownMenuItem<MediaDeviceInfo>>(
                  (MediaDeviceInfo e) =>
                      DropdownMenuItem(value: e, child: Text(e.label())),
                )
                .toList(),
            onChanged: onChanged,
            borderRadius: BorderRadius.circular(18),
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black,
              size: 31,
            ),
            disabledHint: Text('label_media_no_device_available'.td()),
            style: context.textTheme.subtitle1?.copyWith(color: Colors.black),
            underline: const SizedBox(),
          ),
        );

    return GetBuilder(
      init: MediaSettingsController(Get.find()),
      builder: (MediaSettingsController c) => Scaffold(
        appBar: AppBar(
          title: Text('label_media_settings'.td()),
          elevation: 0,
        ),
        body: Obx(
          () => ListView(
            children: [
              const SizedBox(height: 25),
              row(
                Text('label_media_camera'.td(), style: font17),
                dropdown(
                  value: c.devices.video().firstWhereOrNull(
                          (e) => e.deviceId() == c.camera.value) ??
                      c.devices.video().firstOrNull,
                  devices: c.devices.video(),
                  onChanged: (d) => c.setVideoDevice(d!.deviceId()),
                ),
              ),
              const SizedBox(height: 25),
              StreamBuilder(
                stream: c.local.changes,
                builder: (context, snapshot) {
                  RtcVideoRenderer? local = c.local.firstWhereOrNull(
                      (e) => e.source == MediaSourceKind.Device);
                  return row(
                    Container(),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 250,
                          width: 370,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: local == null
                              ? const Center(
                                  child: Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                )
                              : webrtc.VideoView(
                                  local.inner,
                                  objectFit: webrtc.VideoViewObjectFit.cover,
                                  mirror: true,
                                ),
                        ),
                      ),
                    ),
                    true,
                  );
                },
              ),
              const SizedBox(height: 25),
              divider,
              const SizedBox(height: 25),
              row(
                Text('label_media_microphone'.td(), style: font17),
                dropdown(
                  value: c.devices.audio().firstWhereOrNull(
                          (e) => e.deviceId() == c.mic.value) ??
                      c.devices.audio().firstOrNull,
                  devices: c.devices.audio(),
                  onChanged: (d) => c.setAudioDevice(d!.deviceId()),
                ),
              ),
              const SizedBox(height: 25),
              divider,
              const SizedBox(height: 25),
              row(
                Text('label_media_output'.td(), style: font17),
                dropdown(
                  value: c.devices.output().firstWhereOrNull(
                          (e) => e.deviceId() == c.output.value) ??
                      c.devices.output().firstOrNull,
                  devices: c.devices.output(),
                  onChanged: (d) => c.setOutputDevice(d!.deviceId()),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
