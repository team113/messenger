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

import '../animated_delayed_scale.dart';
import '../conditional_backdrop.dart';
import '../scaler.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// View of an secondary overlay.
class SecondaryView extends StatelessWidget {
  const SecondaryView({
    super.key,
    required this.height,
    required this.width,
    required this.child,
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
    this.onDragCenterLeft,
    this.onDragCenterRight,
    this.onDragBottomCenter,
    this.onDragTopCenter,
    this.onDragTopLeft,
    this.onDragTopRight,
    this.onDragBottomLeft,
    this.onDragBottomRight,
    this.condition = true,
    this.isVisible = true,
    this.showCursor = true,
    this.isDragDropVisible = true,
    this.showDragTarget = true,
    this.isShape = true,
    this.isAnyDrag = true,
    this.opacity = 1,
  });

  /// [GlobalKey] of this [SecondaryView].
  final GlobalKey<State<StatefulWidget>>? secondaryKey;

  /// Actual size of the [SecondaryView].
  final Size? size;

  /// Height of this [SecondaryView].
  final double height;

  /// Width of this [SecondaryView].
  final double width;

  /// Left position of this [SecondaryView].
  final double? left;

  /// Right position of this [SecondaryView].
  final double? right;

  /// Top position of this [SecondaryView].
  final double? top;

  /// Bottom position of this [SecondaryView].
  final double? bottom;

  /// Indicator whether this [SecondaryView] is visible.
  final bool isVisible;

  /// Indicator whether the cursor should be shown.
  final bool showCursor;

  /// Indicator whether the [buildDragHandle] is currently visible.
  final bool isDragDropVisible;

  /// Indicator whether the drag target should be shown.
  final bool showDragTarget;

  /// Indicator whether the widget is a shape.
  final bool isShape;

  /// Indicator whether there are currently drags at the moment.
  final bool isAnyDrag;

  /// Indicator whether [BackdropFilter] should be enabled or not.
  final bool condition;

  /// Alignment of [positionedBoilerplate] and secondary panel border.
  final Alignment? alignment;

  /// Opacity of sliding from top draggable title bar.
  final double opacity;

  /// [Widget] wrapped by this [SecondaryView].
  final Widget child;

  /// Callback, called when the delta drag of the left side of the `x` and
  /// the center side of the `y` is triggered.
  final dynamic Function(double, double)? onDragCenterLeft;

  /// Callback, called when the delta drag of the right side of the `x` and
  /// the center side of the `y` is triggered.
  final dynamic Function(double, double)? onDragCenterRight;

  /// Callback, called when the delta drag of the center side of the `x` and
  /// the bottom side of the `y` is triggered.
  final dynamic Function(double, double)? onDragBottomCenter;

  /// Callback, called when the delta drag of the center side of the `x` and
  /// the top side of the `y` is triggered.
  final dynamic Function(double, double)? onDragTopCenter;

  /// Callback, called when the delta drag of the left side of the `x` and
  /// the top side of the `y` is triggered.
  final dynamic Function(double, double)? onDragTopLeft;

  /// Callback, called when the delta drag of the right side of the `x` and
  /// the top side of the `y` is triggered.
  final dynamic Function(double, double)? onDragTopRight;

  /// Callback, called when the delta drag of the left side of the `x` and
  /// the bottom side of the `y` is triggered.
  final dynamic Function(double, double)? onDragBottomLeft;

  /// Callback, called when the delta drag of the right side of the `x` and
  /// the bottom side of the `y` is triggered.
  final dynamic Function(double, double)? onDragBottomRight;

  /// Callback, called when dragging is ended.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Callback, called when pointer has contacted the screen with a primary
  /// button and has begun to move.
  final void Function(DragStartDetails)? onPanStart;

  /// Callback, called when pointer that is in contact with the screen with
  /// a primary button and moving has moved again.
  final void Function(DragUpdateDetails)? onPanUpdate;

  /// Callback, called when pointer that was previously in contact with the
  /// screen with a primary button and moving is no longer in contact with
  /// the screen and was moving at a specific velocity when it stopped
  /// contacting the screen.
  final void Function(DragEndDetails)? onPanEnd;

  /// Callback, called when a mouse pointer has entered this widget.
  final void Function(PointerEnterEvent)? onEnter;

  /// Callback, called when a pointer moves into a position within this
  /// widget without buttons pressed
  final void Function(PointerHoverEvent)? onHover;

  /// Callback, called when a mouse pointer has exited this widget when the
  /// widget is still mounted.
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
                    child: isDragDropVisible
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
                      child: isDragDropVisible
                          ? IgnorePointer(
                              child: ClipRRect(
                                borderRadius: borderRadius,
                                child: Stack(
                                  children: [
                                    Container(
                                        color:
                                            style.colors.backgroundAuxiliary),
                                    SvgImage.asset(
                                      'assets/images/background_dark.svg',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                        color: style.colors.onPrimaryOpacity7),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.centerLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.centerRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.bottomCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.topCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.topLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.topRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.bottomLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  isDragDropVisible
                      ? buildDragHandle(Alignment.bottomRight, context)
                      : const SizedBox(),
                ),

                child,

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
                                borderRadius: isDragDropVisible
                                    ? BorderRadius.only(
                                        topLeft: borderRadius.topLeft,
                                        topRight: borderRadius.topRight,
                                      )
                                    : BorderRadius.zero,
                                child: ConditionalBackdropFilter(
                                  condition: PlatformUtils.isWeb && (condition),
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
                      child: AnimatedSwitcher(
                        duration: 200.milliseconds,
                        child: showDragTarget
                            ? Container(
                                color: style.colors.onBackgroundOpacity27,
                                child: Center(
                                  child: AnimatedDelayedScale(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    beginScale: 1,
                                    endScale: 1.06,
                                    child: ConditionalBackdropFilter(
                                      condition: condition,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          color: condition
                                              ? style
                                                  .colors.onBackgroundOpacity27
                                              : style
                                                  .colors.onBackgroundOpacity50,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 50,
                                            color: style.colors.onPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
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
                                shape: (isShape && isDragDropVisible)
                                    ? RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: style.colors.secondary,
                                          width: 1,
                                        ),
                                        borderRadius: borderRadius,
                                      )
                                    : (!isShape && isDragDropVisible)
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
        onDrag: onDragCenterLeft,
      );
    } else if (alignment == Alignment.centerRight) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        onDrag: onDragCenterRight,
      );
    } else if (alignment == Alignment.bottomCenter) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        onDrag: onDragBottomCenter,
      );
    } else if (alignment == Alignment.topCenter) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        onDrag: onDragTopCenter,
      );
    } else if (alignment == Alignment.topLeft) {
      widget = scaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onDragTopLeft,
      );
    } else if (alignment == Alignment.topRight) {
      widget = scaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onDragTopRight,
      );
    } else if (alignment == Alignment.bottomLeft) {
      widget = scaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onDragBottomLeft,
      );
    } else if (alignment == Alignment.bottomRight) {
      widget = scaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: onDragBottomRight,
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
