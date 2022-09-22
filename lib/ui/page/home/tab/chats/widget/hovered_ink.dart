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

/// Widget creates styles on hover.
class InkWellWithHover extends StatefulWidget {
  const InkWellWithHover({
    Key? key,
    this.borderRadius,
    this.selectedHoverColor,
    this.unselectedHoverColor,
    this.hoveredBorder,
    this.unhoveredBorder,
    this.isSelected = false,
    this.onTap,
    this.selectedColor,
    this.unselectedColor,
    required this.child,
  }) : super(key: key);

  /// [BorderRadius] to paint behind the [child].
  final BorderRadius? borderRadius;

  /// [Color] on selected hover.
  final Color? selectedHoverColor;

  /// [Color] on unselected hover.
  final Color? unselectedHoverColor;

  /// [Border] on hovered.
  final Border? hoveredBorder;

  /// [Border] on unhovered.
  final Border? unhoveredBorder;

  /// Indicator whether select on [child].
  final bool isSelected;

  /// Callback on tap.
  final void Function()? onTap;

  /// Initial [Color] for selected chat.
  final Color? selectedColor;

  /// Initial [Color] for unselected chat.
  final Color? unselectedColor;

  /// [Widget] for hovering.
  final Widget child;

  @override
  State<InkWellWithHover> createState() => _InkWellWithHoverState();
}

/// State of an [InkWellWithHover] maintaining the [isHovered] and [isSelected] indicator.
class _InkWellWithHoverState extends State<InkWellWithHover> {
  /// Indicates whether chat is hovered.
  bool isHovered = false;

  /// Indicates whether chat is selected.
  late bool isSelected = widget.isSelected;

  @override
  void initState() {
    isSelected = widget.isSelected;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant InkWellWithHover oldWidget) {
    isSelected = widget.isSelected;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: isHovered ? widget.hoveredBorder : widget.unhoveredBorder,
      ),
      child: Material(
        type: MaterialType.card,
        borderRadius: widget.borderRadius,
        color: isHovered
            ? isSelected
                ? widget.selectedHoverColor
                : widget.unselectedHoverColor
            : isSelected
                ? widget.selectedColor
                : widget.unselectedColor,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: () {
            setState(() {
              isSelected = true;
            });
            widget.onTap?.call();
          },
          onHover: (bool isHover) => setState(() => isHovered = isHover),
          child: widget.child,
        ),
      ),
    );
  }
}
