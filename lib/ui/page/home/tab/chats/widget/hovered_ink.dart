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

  final void Function()? onTap;
  final BorderRadius? borderRadius;
  final Color? selectedHoverColor;
  final Color? unselectedHoverColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Border? hoveredBorder;
  final Border? unhoveredBorder;
  final Widget child;
  final bool isSelected;

  @override
  State<InkWellWithHover> createState() => _InkWellWithHoverState();
}

class _InkWellWithHoverState extends State<InkWellWithHover> {
  bool isHovered = false;
  late bool isSelected;

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: isHovered ? widget.hoveredBorder : widget.unhoveredBorder,
        color: Colors.transparent,
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
          onHover: (b) => setState(() => isHovered = b),
          hoverColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}
