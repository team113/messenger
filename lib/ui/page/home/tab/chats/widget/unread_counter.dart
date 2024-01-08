// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/ui/widget/svg/svgs.dart';

import '/themes.dart';

/// Circle representation of the provided [count] being unread.
class UnreadCounter extends StatelessWidget {
  const UnreadCounter(
    this.text, {
    super.key,
    this.icon,
    this.dimmed = false,
    this.inverted = false,
    this.color,
  });

  /// Count to display in this [UnreadCounter].
  final String? text;

  final SvgData? icon;
  final Color? color;

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
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dimmed
            ? inverted
                ? style.colors.onPrimary
                : color ?? style.colors.secondaryHighlightDarkest
            : style.colors.danger,
      ),
      alignment: Alignment.center,
      child: icon == null
          ? Text(
              text ?? '',
              style: dimmed && inverted
                  ? style.fonts.smaller.regular.secondary
                  : style.fonts.smaller.regular.onPrimary,
              maxLines: 1,
              overflow: TextOverflow.clip,
              textAlign: TextAlign.center,
            )
          : SvgIcon(icon!, height: 13),
    );
  }
}
