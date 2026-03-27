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
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [CallNotification] visual representation.
class CallNotificationWidget extends StatelessWidget {
  const CallNotificationWidget(this.notification, {super.key, this.onClose});

  /// [CallNotification] this [CallNotificationWidget] displays.
  final CallNotification notification;

  /// Callback, called when the close button is pressed.
  final Function()? onClose;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    CallNotification notification = this.notification;
    final String title;

    switch (notification.kind) {
      case CallNotificationKind.cameraPermissionDenied:
        notification as CameraPermissionDeniedNotification;
        title = 'err_camera_permission_denied'.l10n;
        break;

      case CallNotificationKind.microphonePermissionDenied:
        notification as MicrophonePermissionDeniedNotification;
        title = 'err_microphone_permission_denied'.l10n;
        break;

      case CallNotificationKind.connectionLost:
        notification as ConnectionLostNotification;
        title = 'label_connection_lost'.l10n;
        break;

      case CallNotificationKind.connectionRestored:
        notification as ConnectionRestoredNotification;
        title = 'label_connection_restored'.l10n;
        break;

      case CallNotificationKind.deviceChanged:
        notification as DeviceChangedNotification;
        switch (notification.device.kind()) {
          case MediaDeviceKind.audioInput:
            title = 'label_microphone_changed'.l10nfmt({
              'microphone': notification.device.label(),
            });
            break;

          case MediaDeviceKind.audioOutput:
            title = 'label_speaker_changed'.l10nfmt({
              'speaker': notification.device.label(),
            });
            break;

          case MediaDeviceKind.videoInput:
            title = 'err_unknown'.l10n;
            break;
        }
        break;

      case CallNotificationKind.error:
        notification as ErrorNotification;
        title = notification.message;
        break;

      case CallNotificationKind.microphoneDeviceFailed:
        notification as MicrophoneDeviceFailedNotification;
        title = 'err_microphone_permission_denied'.l10n;
        break;

      case CallNotificationKind.cameraDeviceFailed:
        notification as CameraDeviceFailedNotification;
        title = 'err_camera_permission_denied'.l10n;
        break;

      case CallNotificationKind.screenDeviceFailed:
        notification as ScreenDeviceFailedNotification;
        title = 'err_screen_permission_denied'.l10n;
        break;

      case CallNotificationKind.mediaFailed:
        notification as MediaFailedNotification;
        title = 'err_media_devices_are_null'.l10n;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: style.colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          CustomBoxShadow(
            color: style.colors.onBackgroundOpacity20,
            blurRadius: 8,
            blurStyle: BlurStyle.outer.workaround,
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: Container(
        decoration: BoxDecoration(
          color: style.colors.primaryAuxiliaryOpacity90,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Text(title, style: style.fonts.normal.regular.onPrimary),
              ),
            ),
            WidgetButton(
              onPressed: onClose,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                child: const SvgIcon(SvgIcons.closeSmall),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
