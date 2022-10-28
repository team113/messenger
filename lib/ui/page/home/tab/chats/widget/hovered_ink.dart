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

import 'package:flutter/material.dart';

/// [InkWell] button decorated differently based on the [selected] indicator.
///
/// Used to bypass [InkWell] incorrect behaviour when changing its
/// [InkResponse.hoverColor].
class InkWellWithHover extends StatefulWidget {
  const InkWellWithHover({
    Key? key,
    this.selected = false,
    this.selectedColor,
    this.selectedHoverColor,
    this.unselectedColor,
    this.unselectedHoverColor,
    this.border,
    this.hoveredBorder,
    this.borderRadius,
    this.onTap,
    required this.child,
  }) : super(key: key);

  /// Indicator whether this [InkWellWithHover] is selected.
  final bool selected;

  /// [Color] of this [InkWellWithHover] when [selected] is `true`.
  final Color? selectedColor;

  /// Hovered [Color] of this [InkWellWithHover] when [selected] is `true`.
  final Color? selectedHoverColor;

  /// [Color] of this [InkWellWithHover] when [selected] is `false`.
  final Color? unselectedColor;

  /// Hovered [Color] of this [InkWellWithHover] when [selected] is `false`.
  final Color? unselectedHoverColor;

  /// [Border] of this [InkWellWithHover].
  final Border? border;

  /// Hovered [Border] of this [InkWellWithHover].
  final Border? hoveredBorder;

  /// [BorderRadius] to paint behind the [child].
  final BorderRadius? borderRadius;

  /// Callback, called when this [InkWellWithHover] is pressed.
  final void Function()? onTap;

  /// [Widget] wrapped by this [InkWellWithHover].
  final Widget child;

  @override
  State<InkWellWithHover> createState() => _InkWellWithHoverState();
}

/// State of an [InkWellWithHover] maintaining the [hovered] indicator.
class _InkWellWithHoverState extends State<InkWellWithHover> {
  /// Indicator whether [InkWellWithHover.child] is hovered.
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: hovered ? widget.hoveredBorder : widget.border,
      ),
      child: Material(
        type: MaterialType.card,
        borderRadius: widget.borderRadius,
        color: hovered
            ? widget.selected
                ? widget.selectedHoverColor
                : widget.unselectedHoverColor
            : widget.selected
                ? widget.selectedColor
                : widget.unselectedColor,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap?.call,
          onHover: (v) => setState(() => hovered = v),
          hoverColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
