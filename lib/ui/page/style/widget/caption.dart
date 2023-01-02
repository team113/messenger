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
import 'package:get/get.dart';

/// Underlined caption text with padding.
class Caption extends StatelessWidget {
  const Caption(
    this.caption, {
    Key? key,
    this.color,
  }) : super(key: key);

  /// Message to display.
  final String caption;

  /// Color of the message.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 60, 0, 10),
        child: SelectableText(
          caption,
          style: context.theme.textTheme.bodyText1?.copyWith(
            color: color,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

/// Adds the ability to get HEX value of the color.
extension HexColor on Color {
  /// Returns a HEX string value of this color.
  String toHex() => '#'
      '${alpha.toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${red.toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${green.toRadixString(16).toUpperCase().padLeft(2, '0')}'
      '${blue.toRadixString(16).toUpperCase().padLeft(2, '0')}';
}
