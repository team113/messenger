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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:medea_jason/medea_jason.dart';

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// Styled popup window showing the [notification].
class CallNotificationView extends StatelessWidget {
  const CallNotificationView(
      {super.key, required this.notification, this.onClose});

  /// [CallNotification] this [CallNotificationView] displaying.
  final CallNotification notification;

  /// Callback, called when the close button is pressed.
  final Function()? onClose;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    CallNotification notification = this.notification;
    String title = '';

    if (notification is DeviceChangedNotification) {
      if (notification.device.kind() == MediaDeviceKind.AudioInput) {
        title = 'label_microphone_changed'
            .l10nfmt({'microphone': notification.device.label()});
      } else if (notification.device.kind() == MediaDeviceKind.AudioOutput) {
        title = 'label_speaker_changed'
            .l10nfmt({'speaker': notification.device.label()});
      }
    } else if (notification is ErrorNotification) {
      title = notification.message;
    } else if (notification is ConnectionLostNotification) {
      title = 'label_connection_lost'.l10n;
    } else if (notification is ConnectionRestoredNotification) {
      title = 'label_connection_restored'.l10n;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          CustomBoxShadow(
            color: style.colors.onBackgroundOpacity20,
            blurRadius: 8,
            blurStyle: BlurStyle.outer,
          )
        ],
      ),
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
      child: ConditionalBackdropFilter(
        borderRadius: BorderRadius.circular(30),
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x301D6AAE),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                  child: Text(
                    title,
                    style: fonts.bodyMedium?.copyWith(
                      color: style.colors.onPrimary,
                    ),
                  ),
                ),
              ),
              WidgetButton(
                onPressed: onClose,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                  child: SvgImage.asset(
                    'assets/icons/close.svg',
                    width: 10,
                    height: 10,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
