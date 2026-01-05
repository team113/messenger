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

import '/config.dart';
import '/ui/widget/svg/svg.dart';
import '/themes.dart';

/// Rectangular alert widget displaying the provided [Announcement].
class AnnouncementWidget extends StatelessWidget {
  const AnnouncementWidget(this.announcement, {super.key});

  /// [Announcement] to display.
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final String? body = announcement.body;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: style.colors.warningSecondary),
        color: style.colors.warningBackground,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                const SvgIcon(SvgIcons.attention),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: style.fonts.medium.regular.onBackground,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 2),
                const SvgIcon(SvgIcons.attention),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  body,
                  style: style.fonts.small.regular.onBackground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
