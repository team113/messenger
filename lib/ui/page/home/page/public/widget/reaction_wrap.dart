// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:math';

import 'package:flutter/material.dart';

class ReactionWrap extends StatelessWidget {
  const ReactionWrap({
    Key? key,
    required this.width,
    required this.children,
  }) : super(key: key);

  final double width;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = children.length * width;
        final int columns = totalWidth ~/ constraints.maxWidth + 1;
        final int maxItems = (totalWidth / constraints.maxWidth).floor();

        final List<Widget> rows = [];

        for (int i = 0; i < columns; ++i) {
          final int from = i * maxItems;
          final int to = from + min(maxItems, children.length);

          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children.sublist(from, to),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}
