// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/themes.dart';

/// [TableRow] displaying the provided [label] and [child].
class CenteredRow {
  const CenteredRow(this.label, this.child);

  /// Label to display as a leading [TableRow].
  final Widget label;

  /// Child to display as a trailing [TableRow].
  final Widget child;

  /// Builds a stylized [TableRow] with [label] and [child].
  TableRow _build(BuildContext context) {
    final style = Theme.of(context).style;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
          child: DefaultTextStyle(
            style: style.fonts.small.regular.secondary,
            textAlign: TextAlign.right,
            child: label,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: DefaultTextStyle(
              style: style.fonts.small.regular.secondaryBackgroundLight,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// [Table] displayed with [CenteredRow]s placing their children at
/// [FlexColumnWidth].
class CenteredTable extends StatelessWidget {
  const CenteredTable({super.key, this.children = const []});

  /// [CenteredRow]s to display.
  final List<CenteredRow> children;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: children.map((e) => e._build(context)).toList(),
    );
  }
}
