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

import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

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
    this.folded = false,
    this.outlined = false,
    this.onHover,
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

  /// [BorderRadius] of this [InkWellWithHover].
  final BorderRadius? borderRadius;

  /// Callback, called when this [InkWellWithHover] is pressed.
  final void Function()? onTap;

  /// Indicator whether this [InkWellWithHover] should have its corner folded.
  final bool folded;

  final bool outlined;

  final void Function(bool)? onHover;

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
    final border = OutlineInputBorder(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
    );

    return ClipPath(
      clipper:
          widget.folded ? _Clipper(widget.borderRadius?.topLeft.y ?? 10) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
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
                onHover: (v) {
                  widget.onHover?.call(v);
                  setState(() => hovered = v);
                },
                hoverColor: Colors.transparent,
                child: Stack(
                  children: [
                    Center(child: widget.child),
                    if (widget.folded)
                      Container(
                        width: widget.borderRadius?.topLeft.y ?? 10,
                        height: widget.borderRadius?.topLeft.y ?? 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .extension<Style>()!
                              .cardHoveredBorder
                              .top
                              .color
                              .darken(0.1),
                          // color: const Color(0xFFEE9B01),
                          // color: Colors.yellow,
                          // color: const Color(0xFFFFED00),
                          // color: widget.selected
                          //     ? widget.outlined
                          //         ? Theme.of(context)
                          //             .colorScheme
                          //             .secondary
                          //             .darken(0.1)
                          //         : widget.selectedHoverColor?.darken(0.1)
                          //     : widget.hoveredBorder!.top.color.darken(0.1),
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
          // if (widget.outlined)
          //   Positioned.fill(
          //     child: IgnorePointer(
          //       child: InputDecorator(
          //         decoration: InputDecoration(
          //           label: Text(
          //             '1232321',
          //             style: TextStyle(fontSize: 11),
          //           ),
          //           border: border,
          //           errorBorder: border,
          //           enabledBorder: border,
          //           focusedBorder: border,
          //           disabledBorder: border,
          //           focusedErrorBorder: border,
          //         ),
          //         child: Container(height: double.infinity),
          //       ),
          //     ),
          //   ),
        ],
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

/// [CustomClipper] clipping a top-left corner.
class FoldedClipper extends CustomClipper<Path> {
  const FoldedClipper(this.radius);

  /// Radius of the corner being clipped.
  final double radius;

  @override
  Path getClip(Size size) {
    // final path = Path()
    //   ..lineTo(size.width, 0)
    //   ..lineTo(size.width, size.height - radius)
    //   ..lineTo(size.width - radius, size.height)
    //   ..lineTo(0, size.height)
    //   ..lineTo(0, 0);

    // final path = Path()
    //   ..lineTo(size.width, 0)
    //   ..lineTo(size.width, size.height)
    //   ..lineTo(radius, size.height)
    //   ..lineTo(0, size.height - radius)
    //   ..lineTo(0, 0);

    // final path = Path()
    //   ..lineTo(size.width - radius, 0)
    //   ..lineTo(size.width, radius)
    //   ..lineTo(size.width, size.height)
    //   ..lineTo(0, size.height)
    //   ..lineTo(0, 0);

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
