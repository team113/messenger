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

import '../dense.dart';
import '/domain/model/application_settings.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/timeline_switch/controller.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';

/// [Widget] which returns the contents of a [ProfileTab.chats] section.
class ProfileChats extends StatelessWidget {
  const ProfileChats(this.settings, {super.key});

  /// [ApplicationSettings] that returns the current settings.
  final ApplicationSettings? settings;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dense(
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 21.0),
              child: Text(
                'label_display_timestamps'.l10n,
                style: style.systemMessageStyle.copyWith(
                  color: style.colors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Dense(
          FieldButton(
            text: (settings?.timelineEnabled ?? true)
                ? 'label_as_timeline'.l10n
                : 'label_in_message'.l10n,
            maxLines: null,
            onPressed: () => TimelineSwitchView.show(context),
            style: TextStyle(color: style.colors.primary),
          ),
        ),
      ],
    );
  }
}
