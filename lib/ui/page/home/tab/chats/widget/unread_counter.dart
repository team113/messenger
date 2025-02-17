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
import '/themes.dart';

/// Circle representation of the provided [count] being unread.
class UnreadCounter extends StatelessWidget {
  const UnreadCounter(
    this.count, {
    super.key,
    this.dimmed = false,
    this.inverted = false,
  });

  /// Count to display in this [UnreadCounter].
  final int count;

  /// Indicator whether this [UnreadCounter] should be dimmed, or bright
  /// otherwise.
  final bool dimmed;

  /// Indicator whether this [UnreadCounter] should have its colors
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dimmed
            ? inverted
                ? style.colors.onPrimary
                : style.colors.secondaryHighlightDarkest
            : style.colors.danger,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99${'plus'.l10n}' : '$count',
        style: dimmed && inverted
            ? style.fonts.smaller.bold.secondary
            : style.fonts.smaller.bold.onPrimary,
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
      ),
    );
  }
}
