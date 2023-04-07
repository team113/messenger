// ignore_for_file: public_member_api_docs, sort_constructors_first
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

import 'dart:math';

import 'package:flutter/material.dart';

/// Widget placing its [children] evenly on a screen.
class FitView extends StatelessWidget {
  const FitView({
    super.key,
    required this.children,
    this.dividerColor,
    this.dividerSize = 1,
  });

  /// Children widgets needed to be placed evenly on a screen.
  final List<Widget> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  /// Returns the count of [Column]s this [FitView] uses given the provided
  /// [constraints] and [length].
  static int calculate({
    required BoxConstraints constraints,
    required int length,
  }) {
    // Number of columns.
    int mColumns = 0;

    // Minimal diagonal of a square.
    double min = double.infinity;

    // To find the [mColumns], iterate through every possible number of
    // columns and pick the arrangement with [min]imal diagonal.
    for (int columns = 1; columns <= length; ++columns) {
      int rows = (length / columns).ceil();

      // Current diagonal of a single square.
      double diagonal = (pow(constraints.maxWidth / columns, 2) +
              pow(constraints.maxHeight / rows, 2))
          .toDouble();

      // If there's any [children] left outside, then their diagonal will
      // always be bigger, so we need to recalculate.
      int outside = length % columns;
      if (outside != 0) {
        // Diagonal of an outside [children] is calculated with some
        // coefficient to force the algorithm to pick non-standard
        // arrangement.
        double coef = 1;

        // Coefficient is hard-coded for some cases in order to [FitView] to
        // look better.
        if (length == 3) {
          coef = constraints.maxWidth > constraints.maxHeight ? 0.5 : 0.87;
        } else if (length == 5) {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef = 0.8;
          } else {
            coef = outside == 1 ? 0.8 : 1.5;
          }
        } else if (length == 10) {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef = outside == 2 ? 0.65 : 0.8;
          } else {
            coef = 0.8;
          }
        } else if (length == 9) {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef = 0.9;
          } else {
            coef = 0.5;
          }
        } else if (length == 8) {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef = outside == 2 ? 0.59 : 0.8;
          } else {
            coef = 0.8;
          }
        } else if (length == 7) {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef =
                constraints.maxWidth / constraints.maxHeight >= 3 ? 0.7 : 0.4;
          } else {
            coef = 0.4;
          }
        } else if (length == 6) {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef =
                (constraints.maxWidth / constraints.maxHeight > 3) ? 0.57 : 0.7;
          } else {
            coef = 0.7;
          }
        } else {
          if (constraints.maxWidth > constraints.maxHeight) {
            coef = outside == 2 ? 0.59 : 0.77;
          } else {
            coef = 0.6;
          }
        }

        diagonal = (pow(constraints.maxWidth / outside * coef, 2) +
                pow(constraints.maxHeight / rows, 2))
            .toDouble();
      }

      // Tweak of a standard arrangement.
      else if (length == 4) {
        mColumns =
            constraints.maxWidth / constraints.maxHeight < 0.56 ? 1 : mColumns;
      }

      if (diagonal < min && min - diagonal > 1) {
        mColumns = columns;
        min = diagonal;
      }
    }

    return mColumns;
  }

  /// Returns a [Rect] of an element at the provided [index] in a [FitView]
  /// with the specified [length] and [constraints].
  static Rect sizeOf({
    required int index,
    required int length,
    required BoxConstraints constraints,
  }) {
    final columns = calculate(constraints: constraints, length: length);
    final rows = (length / columns).ceil();
    final outside = length % columns;

    for (int rowIndex = 0; rowIndex < rows; rowIndex++) {
      for (int columnIndex = 0; columnIndex < columns; columnIndex++) {
        final cellIndex = rowIndex * columns + columnIndex;

        if (cellIndex == index) {
          int inThisRow = columns;

          if (rows != 1 && columns != 1 && rowIndex == rows - 1) {
            inThisRow = outside;
          }

          final double width = constraints.maxWidth / inThisRow;
          final double height = constraints.maxHeight / rows;

          return Rect.fromLTWH(
            columnIndex * width,
            rowIndex * height,
            width,
            height,
          );
        }
      }
    }

    return Rect.zero;
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Container();
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Number of columns.
      int mColumns =
          calculate(constraints: constraints, length: children.length);

      return Column(
          children: RowsWidget(
        dividerSize: dividerSize,
        mColumns: mColumns,
        children: children,
      ) as List<Widget>);
    });
  }
}

class ColumnWidget extends StatelessWidget {
  /// Children widgets needed to be placed evenly on a screen.
  final List<Widget> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  final int rowIndex;

  final int mColumns;

  const ColumnWidget(
    Key? key, {
    required this.children,
    required this.dividerColor,
    required this.dividerSize,
    required this.rowIndex,
    required this.mColumns,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final List<Widget> column = [];

    for (int columnIndex = 0; columnIndex < mColumns; columnIndex++) {
      final cellIndex = rowIndex * mColumns + columnIndex;
      if (cellIndex <= children.length - 1) {
        column.add(Expanded(child: children[cellIndex]));
        if (dividerColor != null &&
            columnIndex < mColumns - 1 &&
            cellIndex < children.length - 1) {
          column.add(IgnorePointer(
            child: Container(
              width: dividerSize,
              height: double.infinity,
              color: dividerColor,
            ),
          ));
        }
      }
    }

    return Column(children: column);
  }
}

class RowsWidget extends StatelessWidget {
  /// Children widgets needed to be placed evenly on a screen.
  final List<Widget> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  final int mColumns;
  const RowsWidget({
    Key? key,
    required this.children,
    this.dividerColor,
    required this.dividerSize,
    required this.mColumns,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];

    final rowCount = (children.length / mColumns).ceil();

    for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      final column = ColumnWidget(
        key,
        dividerColor: dividerColor,
        dividerSize: dividerSize,
        rowIndex: rowIndex,
        mColumns: mColumns,
        children: children,
      );
      rows.add(Expanded(child: Row(children: [column])));
      if (dividerColor != null && rowIndex < rowCount - 1) {
        rows.add(IgnorePointer(
          child: Container(
            height: dividerSize,
            width: double.infinity,
            color: dividerColor,
          ),
        ));
      }
    }

    return Column(children: rows);
  }
}
