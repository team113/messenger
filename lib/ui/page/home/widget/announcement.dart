// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import '/ui/widget/svg/svg.dart';
import '/themes.dart';

/// Rectangular alert widget display the provided [text].
class AnnouncementWidget extends StatelessWidget {
  const AnnouncementWidget(this.text, {super.key});

  /// Text to display.
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: const Color(0xFFEEAE03)),
        color: const Color(0x30EEAE03),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SvgIcon(SvgIcons.attention),
              Expanded(
                child: Text(
                  'label_critical_update'.l10n,
                  style: style.fonts.medium.regular.onBackground,
                  textAlign: TextAlign.center,
                ),
              ),
              SvgIcon(SvgIcons.attention),
            ],
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(text, style: style.fonts.small.regular.onBackground),
          ),
        ],
      ),
    );
  }
}
