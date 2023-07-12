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

import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/text_field.dart';

/// Label with [Switch.adaptive] that toggles the user's notification
/// settings.
class NotificationSwitch extends StatelessWidget {
  const NotificationSwitch({
    super.key,
    this.isMuted = false,
    this.onChanged,
  });

  /// Indicator whether the notifications are muted or not.
  final bool isMuted;

  /// Callback, called when the user toggles the switch `on` or `off`.
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Paddings.dense(
      Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            child: ReactiveTextField(
              state: TextFieldState(
                text: (isMuted ? 'label_enabled' : 'label_disabled').l10n,
                editable: false,
              ),
              style: fonts.bodyMedium!.copyWith(color: style.colors.secondary),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Transform.scale(
                scale: 0.7,
                transformHitTests: false,
                child: Theme(
                  data: ThemeData(platform: TargetPlatform.macOS),
                  child: Switch.adaptive(
                    activeColor: style.colors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: isMuted,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
