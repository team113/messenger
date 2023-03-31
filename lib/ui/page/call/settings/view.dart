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

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/call_window_switch/view.dart';
import '/ui/page/home/page/my_profile/camera_switch/view.dart';
import '/ui/page/home/page/my_profile/microphone_switch/view.dart';
import '/ui/page/home/page/my_profile/output_switch/view.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
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
    final Style style = Theme.of(context).extension<Style>()!;

    Widget header(
      String text, {
      EdgeInsets padding = const EdgeInsets.fromLTRB(0, 0, 0, 12),
    }) {
      return Padding(
        padding: padding,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              text,
              style: style.systemMessageStyle
                  .copyWith(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return GetBuilder(
      init: CallSettingsController(
        _call,
        Get.find(),
        onPop: Navigator.of(context).pop,
      ),
      builder: (CallSettingsController c) {
        return Stack(
          children: [
            Scrollbar(
              controller: c.scrollController,
              child: ListView(
                controller: c.scrollController,
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 12),
                  header('label_media'.l10n),
                  _dense(
                    context,
                    WidgetButton(
                      onPressed: () async {
                        await CameraSwitchView.show(
                          context,
                          onChanged: (device) => c.setVideoDevice(device),
                          camera: c.camera.value,
                        );

                        if (c.devices.video().isEmpty) {
                          await c.enumerateDevices();
                        }
                      },
                      child: IgnorePointer(
                        child: Obx(() {
                          return ReactiveTextField(
                            label: 'label_media_camera'.l10n,
                            state: TextFieldState(
                              text: (c.devices.video().firstWhereOrNull((e) =>
                                              e.deviceId() == c.camera.value) ??
                                          c.devices.video().firstOrNull)
                                      ?.label() ??
                                  'label_media_no_device_available'.l10n,
                              editable: false,
                            ),
                            style: context.textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dense(
                    context,
                    WidgetButton(
                      onPressed: () async {
                        await MicrophoneSwitchView.show(
                          context,
                          onChanged: (device) => c.setAudioDevice(device),
                          mic: c.mic.value,
                        );

                        if (c.devices.audio().isEmpty) {
                          await c.enumerateDevices();
                        }
                      },
                      child: IgnorePointer(
                        child: Obx(() {
                          return ReactiveTextField(
                            label: 'label_media_microphone'.l10n,
                            state: TextFieldState(
                              text: (c.devices.audio().firstWhereOrNull((e) =>
                                              e.deviceId() == c.mic.value) ??
                                          c.devices.audio().firstOrNull)
                                      ?.label() ??
                                  'label_media_no_device_available'.l10n,
                              editable: false,
                            ),
                            style: context.textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dense(
                    context,
                    WidgetButton(
                      onPressed: () async {
                        await OutputSwitchView.show(
                          context,
                          onChanged: (device) => c.setOutputDevice(device),
                          output: c.output.value,
                        );

                        if (c.devices.output().isEmpty) {
                          await c.enumerateDevices();
                        }
                      },
                      child: IgnorePointer(
                        child: Obx(() {
                          return ReactiveTextField(
                            label: 'label_media_output'.l10n,
                            state: TextFieldState(
                              text: (c.devices.output().firstWhereOrNull((e) =>
                                              e.deviceId() == c.output.value) ??
                                          c.devices.output().firstOrNull)
                                      ?.label() ??
                                  'label_media_no_device_available'.l10n,
                              editable: false,
                            ),
                            style: context.textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  header('label_calls'.l10n),
                  _dense(
                    context,
                    WidgetButton(
                      onPressed: () => CallWindowSwitchView.show(context),
                      child: IgnorePointer(
                        child: ReactiveTextField(
                          state: TextFieldState(
                            text: (c.settings.value?.enablePopups ?? true)
                                ? 'label_open_calls_in_window'.l10n
                                : 'label_open_calls_in_app'.l10n,
                          ),
                          maxLines: null,
                          style: context.textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const ModalPopupHeader(),
          ],
        );
      },
    );
  }

  /// Dense [Padding] wrapper.
  Widget _dense(BuildContext context, Widget child) => Padding(
        padding: ModalPopup.padding(context)
            .add(const EdgeInsets.fromLTRB(8, 4, 8, 4)),
        child: child,
      );
}
