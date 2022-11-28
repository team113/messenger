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
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/selector.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/l10n/l10n.dart';
import '/ui/widget/modal_popup.dart';
import 'controller.dart';

class OutputSwitchView extends StatelessWidget {
  const OutputSwitchView(this._call, {super.key});

  final Rx<OngoingCall> _call;

  /// Displays a [LinkDetailsView] wrapped in a [ModalPopup].
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
      child: OutputSwitchView(call),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: OutputSwitchController(_call, Get.find()),
      builder: (OutputSwitchController c) {
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
                    'Output'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 25 - 12),

              Flexible(
                child: Obx(() {
                  return ListView.separated(
                    shrinkWrap: true,
                    padding: ModalPopup.padding(context),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: c.devices.output().length,
                    itemBuilder: (_, i) {
                      return Obx(() {
                        final MediaDeviceInfo e =
                            c.devices.output().toList()[i];

                        final bool selected =
                            (c.output.value == null && i == 0) ||
                                c.output.value == e.deviceId();

                        return SizedBox(
                          // height: 48,
                          child: Material(
                            borderRadius: BorderRadius.circular(10),
                            color: selected
                                ? const Color(0xFFD7ECFF).withOpacity(0.8)
                                : Colors.white.darken(0.05),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => c.setOutputDevice(e.deviceId()),
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
                                              key: Key('0'),
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
              ),
              // const SizedBox(height: 25),

              // const SizedBox(height: 25),
              // Padding(
              //   padding: ModalPopup.padding(context),
              //   child: OutlinedRoundedButton(
              //     key: const Key('Proceed'),
              //     maxWidth: null,
              //     title: Text(
              //       'btn_proceed'.l10n,
              //       style: thin?.copyWith(color: Colors.white),
              //     ),
              //     onPressed: Navigator.of(context).pop,
              //     color: const Color(0xFF63B4FF),
              //   ),
              // ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
