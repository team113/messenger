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

import '../controller.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';

/// [PlayerNotification] visual representation.
class PlayerNotificationWidget extends StatelessWidget {
  const PlayerNotificationWidget(this.notification, {super.key, this.onClose});

  /// [PlayerNotification] this [PlayerNotificationWidget] displays.
  final PlayerNotification notification;

  /// Callback, called when the close button is pressed.
  final Function()? onClose;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    PlayerNotification notification = this.notification;
    final String title;

    switch (notification.kind) {
      case PlayerNotificationKind.error:
        notification as ErrorNotification;
        title = notification.message;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: style.colors.transparent,
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                padding: const EdgeInsets.fromLTRB(8, 16, 12, 12),
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
