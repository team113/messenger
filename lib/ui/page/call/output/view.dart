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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/util/media_utils.dart';
import 'controller.dart';

/// View for changing [DeviceDetails] of the current output device.
class OutputRouteView extends StatelessWidget {
  const OutputRouteView({super.key, this.initial, this.onSelected});

  /// Initial [DeviceDetails] to display as selected.
  final DeviceDetails? initial;

  /// Callback, called when [DeviceDetails] are selected.
  final void Function(DeviceDetails)? onSelected;

  /// Displays a [OutputRouteView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    DeviceDetails? initial,
    void Function(DeviceDetails)? onSelected,
  }) async {
    final style = Theme.of(context).style;

    final route = RawDialogRoute<T?>(
      barrierColor: style.barrierColor,
      barrierDismissible: true,
      pageBuilder: (_, _, _) {
        final Widget body = Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            width: 380,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: style.colors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: OutputRouteView(initial: initial, onSelected: onSelected),
          ),
        );

        return CustomSafeArea(
          child: Material(type: MaterialType.transparency, child: body),
        );
      },
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, Animation<double> animation, _, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
          child: child,
        );
      },
    );

    router.obscuring.add(route);

    try {
      return await Navigator.of(context, rootNavigator: true).push<T?>(route);
    } finally {
      router.obscuring.remove(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: OutputRouteController(initial: initial),
      builder: (OutputRouteController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ModalPopupHeader(text: 'label_media_output'.l10n),
            Flexible(
              child: Obx(() {
                return ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 10),
                  children: c.devices.map((e) {
                    return Obx(() {
                      final bool selected = e.id() == c.selected.value?.id();

                      return ListTile(
                        title: Text(e.label()),
                        leading: switch (e.audioDeviceKind()) {
                          AudioDeviceKind.earSpeaker => Icon(
                            Icons.phone_android_rounded,
                          ),
                          AudioDeviceKind.speakerphone => Icon(
                            Icons.volume_up_rounded,
                          ),
                          AudioDeviceKind.wiredHeadphones => Icon(
                            Icons.headphones,
                          ),
                          AudioDeviceKind.wiredHeadset => Icon(
                            Icons.headphones,
                          ),
                          AudioDeviceKind.usbHeadphones => Icon(
                            Icons.headphones,
                          ),
                          AudioDeviceKind.usbHeadset => Icon(Icons.headphones),
                          AudioDeviceKind.bluetoothHeadphones => Icon(
                            Icons.bluetooth_audio,
                          ),
                          AudioDeviceKind.bluetoothHeadset => Icon(
                            Icons.bluetooth_audio,
                          ),
                          null => Icon(Icons.device_unknown_rounded),
                        },
                        trailing: selected ? Icon(Icons.check) : null,
                        onTap: selected
                            ? null
                            : () {
                                c.selected.value = e;
                                onSelected?.call(e);
                              },
                      );
                    });
                  }).toList(),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
