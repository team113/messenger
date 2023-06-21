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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/call/widget/desktop/drop_box.dart';

import '../conditional_backdrop.dart';
import '../scaler.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// View of an secondary overlay.
class SecondaryOverlay extends StatelessWidget {
  const SecondaryOverlay({
    super.key,
    this.child,
    this.size,
    this.secondaryKey,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.alignment,
    this.onTap,
    this.onDragEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onScaleCenterLeft,
    this.onScaleCenterRight,
    this.onScaleBottomCenter,
    this.onScaleTopCenter,
    this.onScaleTopLeft,
    this.onScaleTopRight,
    this.onScaleBottomLeft,
    this.onScaleBottomRight,
    this.condition = true,
    this.isVisible = true,
    this.showCursor = true,
    this.isAligned = true,
    this.showDragTarget = true,
    this.isHover = true,
    this.isAnyDrag = true,
    this.opacity = 1,
    this.height = 50,
    this.width = 50,
  });

  /// [GlobalKey] of this [SecondaryOverlay].
  final GlobalKey<State<StatefulWidget>>? secondaryKey;

  /// Actual size of the [MediaQuery] data.
  final Size? size;

  /// Height of this [SecondaryOverlay].
  final double height;

  /// Width of this [SecondaryOverlay].
  final double width;

  /// Left position of this [SecondaryOverlay].
  final double? left;

  /// Right position of this [SecondaryOverlay].
  final double? right;

  /// Top position of this [SecondaryOverlay].
  final double? top;

  /// Bottom position of this [SecondaryOverlay].
  final double? bottom;

  /// Indicator whether this [SecondaryOverlay] is visible.
  final bool isVisible;

  /// Indicator whether the cursor should be shown.
  final bool showCursor;

  /// Indicator whether the [alignment] should be used.
  final bool isAligned;

  /// Indicator whether the drag target should be shown.
  final bool showDragTarget;

  /// Indicator whether secondary panel is hovered.
  final bool isHover;

  /// Indicator whether there are currently drags at the moment.
  final bool isAnyDrag;

  /// Indicator whether [BackdropFilter] should be enabled or not.
  final bool condition;

  /// Alignment of border and background of secondary panel.
  final Alignment? alignment;

  /// Opacity of sliding from top draggable title bar.
  final double opacity;

  /// [Widget] wrapped by this [SecondaryOverlay].
  final Widget? child;

  /// Callback, called when the delta drag of the left side of the `x` and
  /// the center side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleCenterLeft;

  /// Callback, called when the delta drag of the right side of the `x` and
  /// the center side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleCenterRight;

  /// Callback, called when the delta drag of the center side of the `x` and
  /// the bottom side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleBottomCenter;

  /// Callback, called when the delta drag of the center side of the `x` and
  /// the top side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleTopCenter;

  /// Callback, called when the delta drag of the left side of the `x` and
  /// the top side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleTopLeft;

  /// Callback, called when the delta drag of the right side of the `x` and
  /// the top side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleTopRight;

  /// Callback, called when the delta drag of the left side of the `x` and
  /// the bottom side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleBottomLeft;

  /// Callback, called when the delta drag of the right side of the `x` and
  /// the bottom side of the `y` is triggered.
  final dynamic Function(double, double)? onScaleBottomRight;

  /// Callback, called when dragging is ended.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Callback, called when a pan operation starts.
  final void Function(DragStartDetails)? onPanStart;

  /// Callback, called when a pan operation updates.
  final void Function(DragUpdateDetails)? onPanUpdate;

  /// Callback, called when a pan operation ends.
  final void Function(DragEndDetails)? onPanEnd;

  /// Callback, called when the mouse cursor enters the area of this
  /// [SecondaryOverlay].
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when the mouse cursor moves in the area of this
  /// [SecondaryOverlay].
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when the mouse cursor leaves the area of this
  /// [SecondaryOverlay].
  final void Function(PointerExitEvent)? onExit;

  /// Callback, called when the user taps the [InkResponse].
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    // [BorderRadius] to decorate the secondary panel with.
    final BorderRadius borderRadius = BorderRadius.circular(10);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(size: size),
      child: isVisible
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Secondary panel shadow.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: isAligned
                        ? Container(
                            width: width,
                            height: height,
                            decoration: BoxDecoration(
                              boxShadow: [
                                CustomBoxShadow(
                                  color: style.colors.onBackgroundOpacity27,
                                  blurRadius: 9,
                                  blurStyle: BlurStyle.outer,
                                )
                              ],
                              borderRadius: borderRadius,
                            ),
                          )
                        : const SizedBox(),
                  ),
                ),

                // Secondary panel background.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: isAligned
                          ? IgnorePointer(
                              child: ClipRRect(
                                borderRadius: borderRadius,
                                child: Stack(
                                  children: [
                                    Container(
                                      color: style.colors.backgroundAuxiliary,
                                    ),
                                    SvgImage.asset(
                                      'assets/images/background_dark.svg',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      color: style.colors.onPrimaryOpacity7,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.centerLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.centerRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.bottomCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.topCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.topLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.topRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.bottomLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isAligned
                      ? buildDragHandle(Alignment.bottomRight, context)
                      : const SizedBox(),
                ),

                if (child != null) child!,

                // Discards the pointer when hovered over videos.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: MouseRegion(
                    opaque: false,
                    cursor: SystemMouseCursors.basic,
                    child: IgnorePointer(
                      child: SizedBox(width: width, height: height),
                    ),
                  ),
                ),

                // Sliding from top draggable title bar.
                Positioned(
                  key: secondaryKey,
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: 30,
                        child: MouseRegion(
                          cursor: isAnyDrag
                              ? MouseCursor.defer
                              : SystemMouseCursors.grab,
                          child: GestureDetector(
                            onPanStart: onPanStart,
                            onPanUpdate: onPanUpdate,
                            onPanEnd: onPanEnd,
                            child: AnimatedOpacity(
                              duration: 200.milliseconds,
                              key: const ValueKey('TitleBar'),
                              opacity: opacity,
                              child: ClipRRect(
                                borderRadius: isAligned
                                    ? BorderRadius.only(
                                        topLeft: borderRadius.topLeft,
                                        topRight: borderRadius.topRight,
                                      )
                                    : BorderRadius.zero,
                                child: ConditionalBackdropFilter(
                                  condition: PlatformUtils.isWeb && condition,
                                  child: Container(
                                    color: PlatformUtils.isWeb
                                        ? style.colors.onSecondaryOpacity60
                                        : style.colors.onSecondaryOpacity88,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 7),
                                        Expanded(
                                          child: Text(
                                            'Draggable',
                                            style: fonts.labelMedium!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        InkResponse(
                                          onTap: isAnyDrag ? null : onTap,
                                          child: SvgImage.asset(
                                            'assets/icons/close.svg',
                                            height: 10.25,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                positionedBoilerplate(
                  alignment == Alignment.centerRight
                      ? buildDragHandle(Alignment.centerLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  alignment == Alignment.centerLeft
                      ? buildDragHandle(Alignment.centerRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  alignment == Alignment.topCenter
                      ? buildDragHandle(Alignment.bottomCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  alignment == Alignment.bottomCenter
                      ? buildDragHandle(Alignment.topCenter, context)
                      : const SizedBox(),
                ),

                // Secondary panel drag target indicator.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: DropBox(
                        isVisible: showDragTarget,
                        condition: condition,
                      ),
                    ),
                  ),
                ),

                // Secondary panel border.
                Positioned(
                  left: left == null ? null : (left! - Scaler.size / 2),
                  right: right == null ? null : (right! - Scaler.size / 2),
                  top: top == null ? null : (top! - Scaler.size / 2),
                  bottom: bottom == null ? null : (bottom! - Scaler.size / 2),
                  child: MouseRegion(
                    opaque: false,
                    onEnter: onEnter,
                    onHover: onHover,
                    onExit: onExit,
                    child: SizedBox(
                      width: width + Scaler.size,
                      height: height + Scaler.size,
                      child: Stack(
                        children: [
                          IgnorePointer(
                            child: AnimatedContainer(
                              duration: 200.milliseconds,
                              margin: const EdgeInsets.all(Scaler.size / 2),
                              decoration: ShapeDecoration(
                                shape: (isHover && isAligned)
                                    ? RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: style.colors.secondary,
                                          width: 1,
                                        ),
                                        borderRadius: borderRadius,
                                      )
                                    : (!isHover && isAligned)
                                        ? RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: style.colors.secondary
                                                  .withOpacity(0),
                                              width: 1,
                                            ),
                                            borderRadius: borderRadius,
                                          )
                                        : Border(
                                            top: alignment ==
                                                    Alignment.bottomCenter
                                                ? BorderSide(
                                                    color:
                                                        style.colors.secondary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            left: alignment ==
                                                    Alignment.centerRight
                                                ? BorderSide(
                                                    color:
                                                        style.colors.secondary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            right: alignment ==
                                                    Alignment.centerLeft
                                                ? BorderSide(
                                                    color:
                                                        style.colors.secondary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            bottom: alignment ==
                                                    Alignment.topCenter
                                                ? BorderSide(
                                                    color:
                                                        style.colors.secondary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox(),
    );
  }

  // Returns widget that can be dragged and resized.
  Widget buildDragHandle(Alignment alignment, BuildContext context) {
    // Returns a [Scaler] scaling the secondary view.
    Widget scaler({
      Key? key,
      MouseCursor cursor = MouseCursor.defer,
      Function(double, double)? onDrag,
      double? width,
      double? height,
    }) {
      return MouseRegion(
        cursor: showCursor ? cursor : MouseCursor.defer,
        child: Scaler(
          key: key,
          onDragUpdate: onDrag,
          onDragEnd: onDragEnd,
          width: width ?? Scaler.size,
          height: height ?? Scaler.size,
        ),
      );
    }

    Widget widget = const SizedBox();

    if (alignment == Alignment.centerLeft) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        onDrag: onScaleCenterLeft,
      );
    } else if (alignment == Alignment.centerRight) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        onDrag: onScaleCenterRight,
      );
    } else if (alignment == Alignment.bottomCenter) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        onDrag: onScaleBottomCenter,
      );
    } else if (alignment == Alignment.topCenter) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        onDrag: onScaleTopCenter,
      );
    } else if (alignment == Alignment.topLeft) {
      widget = scaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onScaleTopLeft,
      );
    } else if (alignment == Alignment.topRight) {
      widget = scaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onScaleTopRight,
      );
    } else if (alignment == Alignment.bottomLeft) {
      widget = scaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onScaleBottomLeft,
      );
    } else if (alignment == Alignment.bottomRight) {
      widget = scaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onScaleBottomRight,
      );
    }

    return Align(alignment: alignment, child: widget);
  }

  Widget positionedBoilerplate(Widget child) {
    return Positioned(
      left: left == null ? null : (left! - Scaler.size / 2),
      right: right == null ? null : (right! - Scaler.size / 2),
      top: top == null ? null : (top! - Scaler.size / 2),
      bottom: bottom == null ? null : (bottom! - Scaler.size / 2),
      child: SizedBox(
        width: width + Scaler.size,
        height: height + Scaler.size,
        child: child,
      ),
    );
  }
}
