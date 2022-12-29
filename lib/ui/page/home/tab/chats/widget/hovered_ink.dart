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
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// [InkWell] button decorated differently based on the [selected] indicator.
///
/// Used to bypass [InkWell] incorrect behaviour when changing its
/// [InkResponse.hoverColor].
class InkWellWithHover extends StatefulWidget {
  InkWellWithHover({
    super.key,
    this.selected = false,
    this.selectedColor,
    this.selectedHoverColor,
    this.unselectedColor,
    this.unselectedHoverColor,
    this.border,
    this.hoveredBorder,
    this.borderRadius,
    this.onTap,
    this.folded = false,
    RxBool? showSplashColor,
    required this.child,
  }) {
    if (showSplashColor == null) {
      this.showSplashColor = RxBool(true);
    } else {
      this.showSplashColor = showSplashColor;
    }
  }

  /// Indicator whether this [InkWellWithHover] is selected.
  final bool selected;

  /// [Color] of this [InkWellWithHover] when [selected] is `true`.
  final Color? selectedColor;

  late final RxBool? showSplashColor;

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

  /// [BorderRadius] of this [InkWellWithHover].
  final BorderRadius? borderRadius;

  /// Callback, called when this [InkWellWithHover] is pressed.
  final void Function()? onTap;

  /// Indicator whether this [InkWellWithHover] should have its corner folded.
  final bool folded;

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
    final Style style = Theme.of(context).extension<Style>()!;
    return Obx(
      () => ClipPath(
        clipper: widget.folded
            ? _Clipper(widget.borderRadius?.topLeft.y ?? 10)
            : null,
        child: DecoratedBox(
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
            surfaceTintColor:
                widget.showSplashColor?.value == false ? style.cardColor : null,
            child: InkWell(
              splashColor: widget.showSplashColor?.value == false
                  ? style.cardColor
                  : null,
              highlightColor: widget.showSplashColor?.value == false
                  ? style.cardColor
                  : null,
              borderRadius: widget.borderRadius,
              onTap: widget.onTap?.call,
              onHover: (v) => setState(() => hovered = v),
              hoverColor: Colors.transparent,
              child: Stack(
                children: [
                  Center(child: widget.child),
                  if (widget.folded)
                    Container(
                      width: widget.borderRadius?.topLeft.y ?? 10,
                      height: widget.borderRadius?.topLeft.y ?? 10,
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? widget.selectedHoverColor?.darken(0.1)
                            : widget.hoveredBorder!.top.color.darken(0.1),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: const [
                          CustomBoxShadow(
                            color: Color(0xFFC0C0C0),
                            blurStyle: BlurStyle.outer,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [CustomClipper] clipping a top-left corner.
class _Clipper extends CustomClipper<Path> {
  const _Clipper(this.radius);

  /// Radius of the corner being clipped.
  final double radius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, radius)
      ..lineTo(radius, 0);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
