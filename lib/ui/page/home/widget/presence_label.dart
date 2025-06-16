// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>

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

import '/api/backend/schema.graphql.dart';
import '/l10n/l10n.dart';
import '/themes.dart';

/// Widget that displays the presence status.
class PresenceLabel extends StatelessWidget {
  const PresenceLabel({super.key, this.presence});

  /// The presence to display.
  ///
  /// If it is not provided (i.e. null), the status will default to
  /// [Presence.present].
  final Presence? presence;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    final Presence presence = this.presence ?? Presence.present;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: switch (presence) {
              Presence.present => style.colors.acceptAuxiliary,
              Presence.away => style.colors.warning,
              (_) => style.colors.secondary,
            },
          ),
          width: 8,
          height: 8,
        ),
        SizedBox(width: 5),
        Flexible(
          child: Text(switch (presence) {
            Presence.present => 'label_presence_present'.l10n,
            Presence.away => 'label_presence_away'.l10n,
            (_) => '',
          }, textAlign: TextAlign.left),
        ),
      ],
    );
  }
}
