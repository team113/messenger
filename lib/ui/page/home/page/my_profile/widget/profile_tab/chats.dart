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
import '/ui/page/home/page/my_profile/timeline_switch/controller.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';

/// Title with [FieldButton] that toggles the display of chat timestamps
/// between a timeline format and an in-message format.
class ProfileChats extends StatelessWidget {
  const ProfileChats({super.key, this.isTimeline});

  /// Indicator whether timestamp labels should be displayed as a timeline.
  final bool? isTimeline;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Paddings.dense(
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 21.0),
              child: Text(
                'label_display_timestamps'.l10n,
                style: fonts.titleMedium!.copyWith(
                  color: style.colors.secondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Paddings.dense(
          FieldButton(
            text: isTimeline ?? true
                ? 'label_as_timeline'.l10n
                : 'label_in_message'.l10n,
            maxLines: null,
            onPressed: () => TimelineSwitchView.show(context),
            style: fonts.titleMedium!.copyWith(color: style.colors.primary),
          ),
        ),
      ],
    );
  }
}
