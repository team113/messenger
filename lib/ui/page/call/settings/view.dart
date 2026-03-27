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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/camera_switch/view.dart';
import '/ui/page/home/page/my_profile/microphone_switch/view.dart';
import '/ui/page/home/page/my_profile/output_switch/view.dart';
import '/ui/page/home/page/my_profile/widget/switch_field.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/styled_slider.dart';
import '/ui/widget/svg/svg.dart';
import '/util/media_utils.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'controller.dart';

/// View of the call overlay settings.
class CallSettingsView extends StatelessWidget {
  const CallSettingsView(this._call, {super.key});

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  /// Displays a [CallSettingsView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<OngoingCall> call,
  }) {
    return ModalPopup.show(context: context, child: CallSettingsView(call));
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: CallSettingsController(_call, Get.find(), pop: context.popModal),
      builder: (CallSettingsController c) {
        return Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ModalPopupHeader(text: 'label_media_devices'.l10n),
                SizedBox(height: 12),
                Flexible(
                  child: Scrollbar(
                    controller: c.scrollController,
                    child: ListView(
                      controller: c.scrollController,
                      shrinkWrap: true,
                      padding: ModalPopup.padding(context),
                      children: [
                        Obx(() {
                          final selected =
                              c.devices.audio().firstWhereOrNull(
                                (e) => e.id() == c.mic.value?.id(),
                              ) ??
                              c.devices.audio().firstWhereOrNull(
                                (e) => e.id() == 'default',
                              ) ??
                              c.devices.audio().firstOrNull;

                          return FieldButton(
                            text:
                                selected?.label() ??
                                'label_media_no_device_available'.l10n,
                            style: style.fonts.normal.regular.primary,
                            trailing: Transform.translate(
                              offset: Offset(5, 0),
                              child: SvgIcon(SvgIcons.mediaDevicesMicrophone),
                            ),
                            onPressed: () async {
                              await MicrophoneSwitchView.show(
                                context,
                                onChanged: (device) => c.setAudioDevice(device),
                                mic: c.mic.value?.id(),
                              );

                              if (c.devices.audio().isEmpty) {
                                await c.enumerateDevices();
                              }
                            },
                          );
                        }),

                        // TODO: Remove, when Safari supports output devices without
                        //       tweaking the developer options:
                        //       https://bugs.webkit.org/show_bug.cgi?id=216641
                        if (!WebUtils.isSafari ||
                            c.devices.output().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Obx(() {
                            final selected =
                                c.devices.output().firstWhereOrNull(
                                  (e) => e.id() == c.output.value?.id(),
                                ) ??
                                c.devices.output().firstWhereOrNull(
                                  (e) => e.id() == 'default',
                                ) ??
                                c.devices.output().firstOrNull;

                            return FieldButton(
                              text:
                                  selected?.label() ??
                                  'label_media_no_device_available'.l10n,
                              trailing: Transform.translate(
                                offset: Offset(5, 0),
                                child: SvgIcon(SvgIcons.mediaDevicesSpeaker),
                              ),
                              style: style.fonts.normal.regular.primary,
                              onPressed: () async {
                                await OutputSwitchView.show(
                                  context,
                                  onChanged: (device) =>
                                      c.setOutputDevice(device),
                                  output: c.output.value?.id(),
                                );

                                if (c.devices.output().isEmpty) {
                                  await c.enumerateDevices();
                                }
                              },
                            );
                          }),
                        ],
                        const SizedBox(height: 16),
                        Obx(() {
                          final selected =
                              c.devices.video().firstWhereOrNull(
                                (e) => e.id() == c.camera.value?.id(),
                              ) ??
                              c.devices.video().firstOrNull;

                          return FieldButton(
                            text:
                                selected?.label() ??
                                'label_media_no_device_available'.l10n,
                            trailing: Transform.translate(
                              offset: Offset(5, 0),
                              child: SvgIcon(SvgIcons.mediaDevicesCamera),
                            ),
                            style: style.fonts.normal.regular.primary,
                            onPressed: () async {
                              await CameraSwitchView.show(
                                context,
                                onChanged: (device) => c.setVideoDevice(device),
                                camera: c.camera.value?.id(),
                              );

                              if (c.devices.video().isEmpty) {
                                await c.enumerateDevices();
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 16),

                        // Voice processing is unavailable for mobile platforms.
                        if (!PlatformUtils.isMobile) ...[
                          const SizedBox(height: 20),
                          LineDivider('label_voice_processing'.l10n),
                          const SizedBox(height: 16),
                          Obx(() {
                            return SwitchField(
                              text: 'label_echo_cancellation'.l10n,
                              value: _call.value.echoCancellation ?? false,
                              onChanged: c.setEchoCancellation,
                            );
                          }),
                          const SizedBox(height: 16),
                          Obx(() {
                            return SwitchField(
                              text: 'label_auto_gain_control'.l10n,
                              value: _call.value.autoGainControl ?? false,
                              onChanged: c.setAutoGainControl,
                            );
                          }),

                          // High pass filter and noise suppression level are only available under
                          // desktops.
                          if (PlatformUtils.isWeb) ...[
                            const SizedBox(height: 16),
                            Obx(() {
                              final bool enabled =
                                  _call.value.noiseSuppression ?? true;

                              return SwitchField(
                                text: 'label_noise_suppression'.l10n,
                                value: enabled,
                                onChanged: (e) => c.setNoiseSuppression(
                                  e
                                      ? NoiseSuppressionLevelWithOff.veryHigh
                                      : NoiseSuppressionLevelWithOff.off,
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ] else ...[
                            const SizedBox(height: 16),
                            Obx(() {
                              return SwitchField(
                                text: 'label_high_pass_filter'.l10n,
                                value: _call.value.highPassFilter ?? false,
                                onChanged: c.setHighPassFilter,
                              );
                            }),
                            const SizedBox(height: 20),
                            LineDivider('label_noise_suppression'.l10n),
                            SizedBox(height: 8),
                            Obx(() {
                              NoiseSuppressionLevelWithOff? level =
                                  _call.value.noiseSuppression != true
                                  ? NoiseSuppressionLevelWithOff.off
                                  : NoiseSuppressionLevelWithOff.values
                                        .whereNot(
                                          (e) =>
                                              e ==
                                              NoiseSuppressionLevelWithOff.off,
                                        )
                                        .firstWhereOrNull(
                                          (e) =>
                                              e.toLevel() ==
                                              _call.value.noiseSuppressionLevel,
                                        );
                              level ??= NoiseSuppressionLevelWithOff.off;

                              return StyledSlider(
                                value: level,
                                values: NoiseSuppressionLevelWithOff.values,
                                labelBuilder: (_, value) {
                                  return Text(
                                    textAlign: TextAlign.center,
                                    switch (value) {
                                      NoiseSuppressionLevelWithOff.off =>
                                        'label_noise_suppression_disabled'.l10n,
                                      NoiseSuppressionLevelWithOff.low =>
                                        'label_noise_suppression_low'.l10n,
                                      NoiseSuppressionLevelWithOff.moderate =>
                                        'label_noise_suppression_medium'.l10n,
                                      NoiseSuppressionLevelWithOff.high =>
                                        'label_noise_suppression_high'.l10n,
                                      NoiseSuppressionLevelWithOff.veryHigh =>
                                        'label_noise_suppression_very_high'
                                            .l10n,
                                    },
                                    style:
                                        style.fonts.smaller.regular.secondary,
                                  );
                                },
                                onCompleted: c.setNoiseSuppression,
                              );
                            }),
                          ],
                        ],
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
