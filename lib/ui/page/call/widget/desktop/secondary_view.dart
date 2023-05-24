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
import '../participant.dart';
import '../reorderable_fit.dart';
import '../scaler.dart';
import '/domain/model/chat.dart';
import '/themes.dart';
import '/util/platform_utils.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/page/call/component/desktop.dart';
import '/ui/page/call/controller.dart';
import 'drag_drop_handler.dart';
import 'positioned_boilerplate.dart';

/// [ReorderableFit] of the [CallController.secondary] participants.
class SecondaryView extends StatelessWidget {
  const SecondaryView({
    super.key,
    required this.secondary,
    required this.secondaryAlignment,
    required this.secondaryLeft,
    required this.secondaryTop,
    required this.secondaryRight,
    required this.secondaryBottom,
    required this.secondaryWidth,
    required this.secondaryHeight,
    required this.size,
    required this.resizeSecondary,
    required this.updateSecondaryAttach,
    required this.draggedRenderer,
    required this.itemConstraintsSize,
    required this.itemBuilder,
    required this.chatId,
    required this.secondaryKey,
    required this.isAnyDrag,
    required this.secondaryHovered,
    required this.minimized,
    required this.fullscreen,
    required this.primaryDrags,
    required this.secondaryTargets,
    required this.focusAll,
    this.onAdded,
    this.onWillAccept,
    this.onLeave,
    this.onDragStarted,
    this.onDragEnded,
    this.onDoughBreak,
    this.onOffset,
    this.overlayBuilder,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    required this.onEnter,
    required this.onHover,
    required this.onExit,
  });

  /// [GlobalKey] that uniquely identifies the secondary panel.
  final GlobalKey<State<StatefulWidget>> secondaryKey;

  /// [Rx] that holds the chat ID.
  final ChatId chatId;

  /// [RxList] of participants that are displayed in the secondary panel.
  final List<Participant> secondary;

  /// [Rx] that holds the alignment of the secondary panel.
  final Alignment? secondaryAlignment;

  /// [Rx] that holds the left position of the secondary panel.
  final double? secondaryLeft;

  /// [Rx] that holds the top position of the secondary panel.
  final double? secondaryTop;

  /// [Rx] that holds the right position of the secondary panel.
  final double? secondaryRight;

  /// [Rx] that holds the bottom position of the secondary panel.
  final double? secondaryBottom;

  /// [Rx] that holds the width of the secondary panel.
  final double secondaryWidth;

  /// [Rx] that holds the height of the secondary panel.
  final double secondaryHeight;

  /// [Rx] indicator whether the secondary panel is currently being hovered
  /// over.
  final bool secondaryHovered;

  /// [Rx] indicator whether the secondary panel is currently minimized or not.
  final bool minimized;

  /// [Rx] indicator whether the secondary panel is currently in full-screen
  /// mode or not.
  final bool fullscreen;

  /// [Rx] integer that stores the number of drags that have been performed
  /// on the primary panel.
  final int primaryDrags;

  /// [Rx] integer that stores the number of targets that have been set for
  /// the secondary panel.
  final int secondaryTargets;

  /// [Rx] that holds the [Participant] being dragged.
  final Participant? draggedRenderer;

  /// [Size] that holds the size of the widget.
  final Size size;

  /// Maximum width and height that satisfies the constraints.
  final double itemConstraintsSize;

  /// Indicator whether any dragging event has occurred.
  final bool isAnyDrag;

  /// CallBack, called when a drag event is completed.
  final void Function(DragData d)? onDragEnded;

  /// CallBack, called when the secondary panel is resized.
  final void Function(
    BuildContext context, {
    ScaleModeY? y,
    ScaleModeX? x,
    double? dx,
    double? dy,
  }) resizeSecondary;

  /// CallBack, called when the secondary panel is updated.
  final void Function() updateSecondaryAttach;

  /// CallBack, called when a [Participant] is added to the widget.
  final dynamic Function(DragData, int)? onAdded;

  /// CallBack, called to check if a [Participant] can be
  /// added to the widget.
  final bool Function(DragData?)? onWillAccept;

  /// CallBack, called when a [Participant] leaves the widget.
  final void Function(DragData?)? onLeave;

  /// CallBack, called when a drag event is started.
  final dynamic Function(DragData)? onDragStarted;

  /// CallBack, called when a drag event is cancelled.
  final void Function(DragData)? onDoughBreak;

  /// [Function] that returns the [Offset] of the widget.
  final Offset Function()? onOffset;

  /// [Function] that builds the overlay widget for the [ReorderableFit].
  final Widget Function(DragData)? overlayBuilder;

  /// [Function] that builds the item widget for the [ReorderableFit].
  final Widget Function(DragData) itemBuilder;

  /// CallBack, called when a pan event is started.
  final void Function(DragStartDetails)? onPanStart;

  /// CallBack, called when a pan event is updated.
  final void Function(DragUpdateDetails)? onPanUpdate;

  /// CallBack, called when a pan event is ended.
  final void Function(DragEndDetails)? onPanEnd;

  /// Triggered when a mouse pointer has entered this widget.
  final void Function(PointerEnterEvent)? onEnter;

  /// Triggered when a pointer moves into a position within this widget without
  /// buttons pressed.
  final void Function(PointerHoverEvent)? onHover;

  /// Triggered when a mouse pointer has exited this widget when the widget is
  /// still mounted.
  final void Function(PointerExitEvent)? onExit;

  /// Focuses all [Participant]s, which means putting them in theirs
  /// `default` groups.
  final void Function() focusAll;

  @override
  Widget build(BuildContext context) {
    // [BorderRadius] to decorate the secondary panel with.
    final BorderRadius borderRadius = BorderRadius.circular(10);

    double? left, right;
    double? top, bottom;
    Axis? axis;

    if (secondaryAlignment == Alignment.centerRight) {
      top = 0;
      right = 0;
      axis = Axis.horizontal;
    } else if (secondaryAlignment == Alignment.centerLeft) {
      top = 0;
      left = 0;
      axis = Axis.horizontal;
    } else if (secondaryAlignment == Alignment.topCenter) {
      top = 0;
      left = 0;
      axis = Axis.vertical;
    } else if (secondaryAlignment == Alignment.bottomCenter) {
      bottom = 0;
      left = 0;
      axis = Axis.vertical;
    } else {
      left = secondaryLeft;
      top = secondaryTop;
      right = secondaryRight;
      bottom = secondaryBottom;

      axis = null;
    }

    double width, height;
    if (axis == Axis.horizontal) {
      width = secondaryWidth;
      height = size.height;
    } else if (axis == Axis.vertical) {
      width = size.width;
      height = secondaryHeight;
    } else {
      width = secondaryWidth;
      height = secondaryHeight;
    }
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(size: size),
      child: secondary.isEmpty
          ? const SizedBox()
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
                    child: secondaryAlignment == null
                        ? Container(
                            width: width,
                            height: height,
                            decoration: BoxDecoration(
                              boxShadow: const [
                                CustomBoxShadow(
                                  color: Color(0x44000000),
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
                      child: secondaryAlignment == null
                          ? IgnorePointer(
                              child: ClipRRect(
                                borderRadius: borderRadius,
                                child: Stack(
                                  children: [
                                    Container(color: const Color(0xFF0A1724)),
                                    SvgImage.asset(
                                      'assets/images/background_dark.svg',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(color: const Color(0x11FFFFFF)),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(),
                    ),
                  ),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.centerLeft,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            x: ScaleModeX.left,
                            dx: dx,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.centerRight,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            x: ScaleModeX.right,
                            dx: -dx,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.bottomCenter,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.bottom,
                            dy: -dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.topCenter,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.top,
                            dy: dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.topLeft,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.top,
                            x: ScaleModeX.left,
                            dx: dx,
                            dy: dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.topRight,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.top,
                            x: ScaleModeX.right,
                            dx: -dx,
                            dy: dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.bottomLeft,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.bottom,
                            x: ScaleModeX.left,
                            dx: dx,
                            dy: -dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == null
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.bottomRight,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.bottom,
                            x: ScaleModeX.right,
                            dx: -dx,
                            dy: -dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                // Secondary panel itself.
                ReorderableFit<DragData>(
                  key: const Key('SecondaryFitView'),
                  onAdded: onAdded,
                  onWillAccept: onWillAccept,
                  onLeave: onLeave,
                  onDragStarted: onDragStarted,
                  onDoughBreak: onDoughBreak,
                  onDragEnd: onDragEnded,
                  onDragCompleted: onDragEnded,
                  onDraggableCanceled: onDragEnded,
                  axis: axis,
                  width: width,
                  height: height,
                  left: left,
                  top: top,
                  right: right,
                  bottom: bottom,
                  onOffset: onOffset,
                  overlayBuilder: overlayBuilder,
                  decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
                  itemConstraints: (_) {
                    return BoxConstraints(
                      maxWidth: itemConstraintsSize,
                      maxHeight: itemConstraintsSize,
                    );
                  },
                  itemBuilder: itemBuilder,
                  children: secondary.map((e) => DragData(e, chatId)).toList(),
                  borderRadius:
                      secondaryAlignment == null ? borderRadius : null,
                ),

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
                        child: SizedBox(width: width, height: height)),
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
                              opacity: secondaryHovered ? 1 : 0,
                              child: ClipRRect(
                                borderRadius: secondaryAlignment == null
                                    ? BorderRadius.only(
                                        topLeft: borderRadius.topLeft,
                                        topRight: borderRadius.topRight,
                                      )
                                    : BorderRadius.zero,
                                child: ConditionalBackdropFilter(
                                  condition: PlatformUtils.isWeb &&
                                      (!minimized || fullscreen),
                                  child: Container(
                                    color: PlatformUtils.isWeb
                                        ? const Color(0x9D165084)
                                        : const Color(0xE9165084),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 7),
                                        const Expanded(
                                          child: Text(
                                            'Draggable',
                                            style:
                                                TextStyle(color: Colors.white),
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

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == Alignment.centerRight
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.centerLeft,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            x: ScaleModeX.left,
                            dx: dx,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == Alignment.centerLeft
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.centerRight,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            x: ScaleModeX.right,
                            dx: -dx,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == Alignment.topCenter
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.bottomCenter,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            y: ScaleModeY.top,
                            dy: dy,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
                      : const SizedBox(),
                ),

                PositionedBoilerplateWidget(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  width: width,
                  height: height,
                  child: secondaryAlignment == Alignment.bottomCenter
                      ? DragDropHandler(
                          width,
                          height,
                          Alignment.topCenter,
                          draggedRenderer,
                          onDragUpdate: (dx, dy) => resizeSecondary(
                            context,
                            x: ScaleModeX.left,
                            dx: dx,
                          ),
                          onDragEnd: (_) {
                            updateSecondaryAttach();
                          },
                        )
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
                        child: primaryDrags != 0 && secondaryTargets != 0
                            ? Container(
                                color: const Color(0x40000000),
                                child: Center(
                                  child: AnimatedDelayedScale(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    beginScale: 1,
                                    endScale: 1.06,
                                    child: ConditionalBackdropFilter(
                                      condition: !minimized || fullscreen,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          color: !minimized || fullscreen
                                              ? const Color(0x40000000)
                                              : const Color(0x90000000),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 50,
                                            color: Colors.white,
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
                  left: left == null ? null : (left - Scaler.size / 2),
                  right: right == null ? null : (right - Scaler.size / 2),
                  top: top == null ? null : (top - Scaler.size / 2),
                  bottom: bottom == null ? null : (bottom - Scaler.size / 2),
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
                                shape: secondaryHovered || primaryDrags != 0
                                    ? secondaryAlignment == null
                                        ? RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              width: 1,
                                            ),
                                            borderRadius: borderRadius,
                                          )
                                        : Border(
                                            top: secondaryAlignment ==
                                                    Alignment.bottomCenter
                                                ? BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            left: secondaryAlignment ==
                                                    Alignment.centerRight
                                                ? BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            right: secondaryAlignment ==
                                                    Alignment.centerLeft
                                                ? BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                            bottom: secondaryAlignment ==
                                                    Alignment.topCenter
                                                ? BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    width: 1,
                                                  )
                                                : BorderSide.none,
                                          )
                                    : secondaryAlignment == null
                                        ? RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0),
                                              width: 1,
                                            ),
                                            borderRadius: borderRadius,
                                          )
                                        : Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
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
}
