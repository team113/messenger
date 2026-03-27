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

import '/l10n/l10n.dart';
import '/themes.dart';

/// [Container] displaying the provided [count] as an unread messages label.
class UnreadLabel extends StatelessWidget {
  const UnreadLabel(this.count, {super.key});

  /// Count to display in this [UnreadLabel].
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: style.systemMessageBorder,
        color: style.systemMessageColor,
      ),
      child: Center(
        child: Text(
          'label_unread_messages'.l10nfmt({'quantity': count}),
          style: style.systemMessageStyle,
        ),
      ),
    );
  }
}
