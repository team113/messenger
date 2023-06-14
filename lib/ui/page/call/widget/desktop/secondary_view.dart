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

import '../../controller.dart';
import '../animated_delayed_scale.dart';
import '../conditional_backdrop.dart';
import '../scaler.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

class SecondaryView extends StatelessWidget {
  const SecondaryView({
    super.key,
    required this.height,
    required this.width,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.child,
    required this.condition,
    required this.secondaryKey,
    required this.data,
    required this.test1,
    required this.test2,
    required this.test3,
    required this.test4,
    required this.test5,
    required this.alignment,
    required this.isAnyDrag,
    required this.opacity,
    required this.resizeSecondary,
    required this.focusAll,
    required this.onDragEnd,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
  });

  ///
  final GlobalKey<State<StatefulWidget>> secondaryKey;

  ///
  final MediaQueryData data;

  ///
  final bool test1;

  ///
  final bool test2;

  ///
  final bool test3;

  ///
  final bool test4;

  ///
  final bool test5;

  ///
  final Alignment? alignment;

  ///
  final bool isAnyDrag;

  ///
  final bool condition;

  ///
  final double opacity;

  ///
  final Widget child;

  ///
  final void Function(
    BuildContext context, {
    ScaleModeY? y,
    ScaleModeX? x,
    double? dx,
    double? dy,
  }) resizeSecondary;

  ///
  final void Function()? focusAll;

  ///
  final dynamic Function(DragEndDetails)? onDragEnd;

  ///
  final void Function(DragStartDetails)? onPanStart;

  ///
  final void Function(DragUpdateDetails)? onPanUpdate;

  ///
  final void Function(DragEndDetails)? onPanEnd;

  ///
  final void Function(PointerEnterEvent)? onEnter;

  ///
  final void Function(PointerHoverEvent)? onHover;

  ///
  final void Function(PointerExitEvent)? onExit;

  ///
  final double height;

  ///
  final double width;

  ///
  final double? left;

  ///
  final double? right;

  ///
  final double? top;

  ///
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    // [BorderRadius] to decorate the secondary panel with.
    final BorderRadius borderRadius = BorderRadius.circular(10);

    return MediaQuery(
      data: data,
      child: test1
          ? Container()
          : Stack(
              fit: StackFit.expand,
              children: [
                // Secondary panel shadow.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: test3
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
                      child: test3
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
                          : Container(),
                    ),
                  ),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.centerLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.centerRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.bottomCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.topCenter, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.topLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.topRight, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.bottomLeft, context)
                      : const SizedBox(),
                ),

                positionedBoilerplate(
                  test3
                      ? buildDragHandle(Alignment.bottomRight, context)
                      : const SizedBox(),
                ),

                // Secondary panel itself.

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
                                borderRadius: test3
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
                                            style: TextStyle(
                                              color: style.colors.onPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        InkResponse(
                                          onTap: isAnyDrag ? null : focusAll,
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
                        child: test4
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
                                shape: test5
                                    ? test3
                                        ? RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: style.colors.secondary,
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
                                          )
                                    : test3
                                        ? RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: style.colors.secondary
                                                  .withOpacity(0),
                                              width: 1,
                                            ),
                                            borderRadius: borderRadius,
                                          )
                                        : Border.all(
                                            color: style.colors.secondary
                                                .withOpacity(0),
                                            width: 1,
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
            ),
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
        cursor: test2 ? cursor : MouseCursor.defer,
        child: Scaler(
          key: key,
          onDragUpdate: onDrag,
          onDragEnd: onDragEnd,
          width: width ?? Scaler.size,
          height: height ?? Scaler.size,
        ),
      );
    }

    Widget widget = Container();

    if (alignment == Alignment.centerLeft) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          x: ScaleModeX.left,
          dx: dx,
        ),
      );
    } else if (alignment == Alignment.centerRight) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          x: ScaleModeX.right,
          dx: -dx,
        ),
      );
    } else if (alignment == Alignment.bottomCenter) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          y: ScaleModeY.bottom,
          dy: -dy,
        ),
      );
    } else if (alignment == Alignment.topCenter) {
      widget = scaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          y: ScaleModeY.top,
          dy: dy,
        ),
      );
    } else if (alignment == Alignment.topLeft) {
      widget = scaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          y: ScaleModeY.top,
          x: ScaleModeX.left,
          dx: dx,
          dy: dy,
        ),
      );
    } else if (alignment == Alignment.topRight) {
      widget = scaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          y: ScaleModeY.top,
          x: ScaleModeX.right,
          dx: -dx,
          dy: dy,
        ),
      );
    } else if (alignment == Alignment.bottomLeft) {
      widget = scaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          y: ScaleModeY.bottom,
          x: ScaleModeX.left,
          dx: dx,
          dy: -dy,
        ),
      );
    } else if (alignment == Alignment.bottomRight) {
      widget = scaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        onDrag: (dx, dy) => resizeSecondary(
          context,
          y: ScaleModeY.bottom,
          x: ScaleModeX.right,
          dx: -dx,
          dy: -dy,
        ),
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
