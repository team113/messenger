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
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View for updating the [MediaSettings.videoDevice].
///
/// Intended to be displayed with the [show] method.
class CameraSwitchView extends StatelessWidget {
  const CameraSwitchView({
    this.onChanged,
    this.camera,
    super.key,
  });

  /// Callback, called when the selected camera device changes.
  final void Function(String)? onChanged;

  /// ID of the initially selected video device.
  final String? camera;

  /// Displays a [CameraSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    void Function(String)? onChanged,
    String? camera,
  }) {
    return ModalPopup.show(
      context: context,
      child: CameraSwitchView(onChanged: onChanged, camera: camera),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: CameraSwitchController(Get.find(), camera: camera),
      builder: (CameraSwitchController c) {
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
                    'label_camera'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(height: 13),
                    Padding(
                      padding: ModalPopup.padding(context),
                      child: Obx(() {
                        final RtcVideoRenderer? local = c.renderer.value;
                        return Center(
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
                                  ? Center(
                                      child: SvgLoader.asset(
                                        'assets/icons/no_video.svg',
                                        width: 48.54,
                                        height: 42,
                                      ),
                                    )
                                  : webrtc.VideoView(
                                      local.inner,
                                      objectFit:
                                          webrtc.VideoViewObjectFit.cover,
                                      mirror: true,
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 25),
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
                                (c.camera.value == null && i == 0) ||
                                    c.camera.value == e.deviceId();

                            return Material(
                              borderRadius: BorderRadius.circular(10),
                              color: selected
                                  ? style.cardSelectedColor.withOpacity(0.8)
                                  : Colors.white.darken(0.05),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: selected
                                    ? null
                                    : () {
                                        c.camera.value = e.deviceId();
                                        (onChanged ?? c.setVideoDevice)
                                            .call(e.deviceId());
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e.label(),
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
                                                  backgroundColor:
                                                      Theme.of(context)
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
