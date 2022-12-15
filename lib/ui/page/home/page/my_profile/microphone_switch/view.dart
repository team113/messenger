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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

/// View for updating the [MediaSettings.audioDevice] value.
///
/// Intended to be displayed with the [show] method.
class MicrophoneSwitchView extends StatelessWidget {
  const MicrophoneSwitchView(this._call, {super.key});

  /// Local [OngoingCall] for enumerating and displaying local media.
  final Rx<OngoingCall> _call;

  /// Displays a [MicrophoneSwitchView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<OngoingCall> call,
  }) {
    return ModalPopup.show(
      context: context,
      desktopConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      modalConstraints: const BoxConstraints(maxWidth: 380),
      mobilePadding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      mobileConstraints: const BoxConstraints(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
      ),
      child: MicrophoneSwitchView(call),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: MicrophoneSwitchController(_call, Get.find()),
      builder: (MicrophoneSwitchController c) {
        return AnimatedSizeAndFade(
          fadeDuration: const Duration(milliseconds: 250),
          sizeDuration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16 - 12),
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
                    const SizedBox(height: 25 - 12),
                    Obx(() {
                      return ListView.separated(
                        shrinkWrap: true,
                        padding: ModalPopup.padding(context),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: c.devices.audio().length,
                        itemBuilder: (_, i) {
                          return Obx(() {
                            final MediaDeviceInfo e =
                                c.devices.audio().toList()[i];

                            final bool selected =
                                (c.mic.value == null && i == 0) ||
                                    c.mic.value == e.deviceId();

                            return SizedBox(
                              child: Material(
                                borderRadius: BorderRadius.circular(10),
                                color: selected
                                    ? const Color(0xFFD7ECFF).withOpacity(0.8)
                                    : Colors.white.darken(0.05),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => c.setAudioDevice(e.deviceId()),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e.label(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        AnimatedSwitcher(
                                          duration: 200.milliseconds,
                                          child: selected
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Color(0xFF63B4FF),
                                                    radius: 12,
                                                    child: Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                  ),
                                                )
                                              : const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                ),
                                        ),
                                      ],
                                    ),
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
