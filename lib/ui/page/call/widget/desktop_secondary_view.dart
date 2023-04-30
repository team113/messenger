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
import 'package:get/get.dart';

import '../../../../domain/model/chat.dart';
import '/themes.dart';
import '/util/platform_utils.dart';
import '../../../widget/svg/svg.dart';
import '../component/desktop.dart';
import '../component/desktop_sub.dart';
import '../controller.dart';
import 'animated_delayed_scale.dart';
import 'conditional_backdrop.dart';
import 'participant.dart';
import 'reorderable_fit.dart';
import 'scaler.dart';

/// [ReorderableFit] of the [CallController.secondary] participants.
class SecondaryView extends StatelessWidget {
  const SecondaryView(
      {super.key,
      required this.secondary,
      required this.secondaryAlignment,
      required this.secondaryLeft,
      required this.secondaryTop,
      required this.secondaryRight,
      required this.secondaryBottom,
      required this.secondaryWidth,
      required this.secondaryHeight,
      required this.size,
      required this.onDragEnded,
      required this.resizeSecondary,
      required this.updateSecondaryAttach,
      required this.draggedRenderer,
      required this.onAdded,
      required this.onWillAccept,
      required this.onLeave,
      required this.onDragStarted,
      required this.onDoughBreak,
      required this.onOffset,
      required this.overlayBuilder,
      required this.itemContraintsSize,
      required this.itemBuilder,
      required this.chatId,
      required this.secondaryKey,
      required this.isAnyDrag,
      required this.onPanStart,
      required this.onPanUpdate,
      required this.onPanEnd,
      required this.secondaryHovered,
      required this.minimized,
      required this.fullscreen,
      required this.primaryDrags,
      required this.secondaryTargets});

  final RxList<Participant> secondary;

  final Rx<Alignment?> secondaryAlignment;

  final RxnDouble secondaryLeft;

  final RxnDouble secondaryTop;

  final RxnDouble secondaryRight;

  final RxnDouble secondaryBottom;

  final RxDouble secondaryWidth;

  final RxDouble secondaryHeight;

  final Size size;

  final void Function(DesktopDragData d) onDragEnded;

  final void Function(
    BuildContext context, {
    ScaleModeY? y,
    ScaleModeX? x,
    double? dx,
    double? dy,
  }) resizeSecondary;

  final void Function() updateSecondaryAttach;

  final Rx<Participant?> draggedRenderer;

  final dynamic Function(DesktopDragData, int)? onAdded;

  final bool Function(DesktopDragData?)? onWillAccept;

  final void Function(DesktopDragData?)? onLeave;

  final dynamic Function(DesktopDragData)? onDragStarted;

  final void Function(DesktopDragData)? onDoughBreak;

  final Offset Function()? onOffset;

  final Widget Function(DesktopDragData)? overlayBuilder;

  final double itemContraintsSize;

  final Widget Function(DesktopDragData) itemBuilder;

  final Rx<ChatId> chatId;

  final GlobalKey<State<StatefulWidget>> secondaryKey;

  final bool isAnyDrag;

  final void Function(DragStartDetails)? onPanStart;

  final void Function(DragUpdateDetails)? onPanUpdate;

  final void Function(DragEndDetails)? onPanEnd;

  final RxBool secondaryHovered;

  final RxBool minimized;

  final RxBool fullscreen;

  final RxInt primaryDrags;

  final RxInt secondaryTargets;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(size: c.size),
          child: Obx(() {
            if (secondary.isEmpty) {
              return Container();
            }

            // [BorderRadius] to decorate the secondary panel with.
            final BorderRadius borderRadius = BorderRadius.circular(10);

            double? left, right;
            double? top, bottom;
            Axis? axis;

            if (secondaryAlignment.value == Alignment.centerRight) {
              top = 0;
              right = 0;
              axis = Axis.horizontal;
            } else if (secondaryAlignment.value == Alignment.centerLeft) {
              top = 0;
              left = 0;
              axis = Axis.horizontal;
            } else if (secondaryAlignment.value == Alignment.topCenter) {
              top = 0;
              left = 0;
              axis = Axis.vertical;
            } else if (secondaryAlignment.value == Alignment.bottomCenter) {
              bottom = 0;
              left = 0;
              axis = Axis.vertical;
            } else {
              left = secondaryLeft.value;
              top = secondaryTop.value;
              right = secondaryRight.value;
              bottom = secondaryBottom.value;

              axis = null;
            }

            double width, height;
            if (axis == Axis.horizontal) {
              width = secondaryWidth.value;
              height = size.height;
            } else if (axis == Axis.vertical) {
              width = size.width;
              height = secondaryHeight.value;
            } else {
              width = secondaryWidth.value;
              height = secondaryHeight.value;
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // Secondary panel shadow.
                Positioned(
                  left: left,
                  right: right,
                  top: top,
                  bottom: bottom,
                  child: IgnorePointer(
                    child: Obx(() {
                      if (secondaryAlignment.value == null) {
                        return Container(
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
                        );
                      }

                      return Container();
                    }),
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
                      child: Obx(() {
                        if (secondaryAlignment.value == null) {
                          return IgnorePointer(
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
                          );
                        }

                        return Container();
                      }),
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
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerLeft,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                x: ScaleModeX.left,
                                dx: dx,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerRight,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                x: ScaleModeX.right,
                                dx: -dx,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomCenter,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                y: ScaleModeY.bottom,
                                dy: -dy,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topCenter,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                y: ScaleModeY.top,
                                dy: dy,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topLeft,
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
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topRight,
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
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomLeft,
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
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == null
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomRight,
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
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                // Secondary panel itself.
                ReorderableFit<DesktopDragData>(
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
                      maxWidth: itemContraintsSize,
                      maxHeight: itemContraintsSize,
                    );
                  },
                  itemBuilder: itemBuilder,
                  children: secondary
                      .map((e) => DesktopDragData(e, chatId.value))
                      .toList(),
                  borderRadius:
                      secondaryAlignment.value == null ? borderRadius : null,
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
                  child: Obx(() {
                    return SizedBox(
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
                              // onPanUpdate: (d) {
                              //   c.updateSecondaryOffset(d.globalPosition);
                              //   c.applySecondaryConstraints();
                              // },
                              onPanUpdate: onPanUpdate,
                              // onPanEnd: (d) {
                              //   c.secondaryDragged.value = false;
                              //   if (c.possibleSecondaryAlignment.value !=
                              //       null) {
                              //     c.secondaryAlignment.value =
                              //         c.possibleSecondaryAlignment.value;
                              //     c.possibleSecondaryAlignment.value = null;
                              //     c.applySecondaryConstraints();
                              //   } else {
                              //     updateSecondaryAttach();
                              //   }
                              // },
                              onPanEnd: onPanEnd,
                              child: AnimatedOpacity(
                                duration: 200.milliseconds,
                                key: const ValueKey('TitleBar'),
                                opacity: secondaryHovered.value ? 1 : 0,
                                child: ClipRRect(
                                  borderRadius: secondaryAlignment.value == null
                                      ? BorderRadius.only(
                                          topLeft: borderRadius.topLeft,
                                          topRight: borderRadius.topRight,
                                        )
                                      : BorderRadius.zero,
                                  child: ConditionalBackdropFilter(
                                    condition: PlatformUtils.isWeb &&
                                        (minimized.isFalse ||
                                            fullscreen.isTrue),
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
                                              style: TextStyle(
                                                  color: Colors.white),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          InkResponse(
                                            onTap:
                                                isAnyDrag ? null : c.focusAll,
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
                    );
                  }),
                ),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.centerRight
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerLeft,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                x: ScaleModeX.left,
                                dx: dx,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.centerLeft
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.centerRight,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                x: ScaleModeX.right,
                                dx: -dx,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.topCenter
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.bottomCenter,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                y: ScaleModeY.top,
                                dy: dy,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                              draggedRenderer: draggedRenderer,
                            )
                          : Container(),
                    )),

                PositionedBoilerplateWidget(
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom,
                    width: width,
                    height: height,
                    child: Obx(
                      () => c.secondaryAlignment.value == Alignment.bottomCenter
                          ? DesktopBuildDragHandle(
                              width,
                              height,
                              alignment: Alignment.topCenter,
                              draggedRenderer: c.draggedRenderer,
                              onDragUpdate: (dx, dy) => resizeSecondary(
                                context,
                                x: ScaleModeX.left,
                                dx: dx,
                              ),
                              onDragEnd: (_) {
                                updateSecondaryAttach();
                              },
                            )
                          : Container(),
                    )),

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
                      child: Obx(() {
                        return AnimatedSwitcher(
                          duration: 200.milliseconds,
                          child: primaryDrags.value != 0 &&
                                  secondaryTargets.value != 0
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
                                        condition: !minimized.value ||
                                            fullscreen.value,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            color: !minimized.value ||
                                                    fullscreen.value
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
                        );
                      }),
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
                    onEnter: (p) => secondaryHovered.value = true,
                    onHover: (p) => secondaryHovered.value = true,
                    onExit: (p) => secondaryHovered.value = false,
                    child: SizedBox(
                      width: width + Scaler.size,
                      height: height + Scaler.size,
                      child: Obx(() {
                        return Stack(
                          children: [
                            IgnorePointer(
                              child: AnimatedContainer(
                                duration: 200.milliseconds,
                                margin: const EdgeInsets.all(Scaler.size / 2),
                                decoration: ShapeDecoration(
                                  shape: secondaryHovered.value ||
                                          primaryDrags.value != 0
                                      ? secondaryAlignment.value == null
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
                                              top: secondaryAlignment.value ==
                                                      Alignment.bottomCenter
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                              left: secondaryAlignment.value ==
                                                      Alignment.centerRight
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                              right: secondaryAlignment.value ==
                                                      Alignment.centerLeft
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                              bottom: secondaryAlignment
                                                          .value ==
                                                      Alignment.topCenter
                                                  ? BorderSide(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      width: 1,
                                                    )
                                                  : BorderSide.none,
                                            )
                                      : secondaryAlignment.value == null
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
                        );
                      }),
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}

class PositionedBoilerplateWidget extends StatelessWidget {
  const PositionedBoilerplateWidget({
    Key? key,
    required this.child,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.width,
    required this.height,
  }) : super(key: key);

  /// The widget contained by this widget
  final Widget child;

  /// The distance between the left edge of the [PositionedBoilerplateWidget]
  /// and the left edge of the parent widget.
  final double? left;

  /// The distance between the right edge of the [PositionedBoilerplateWidget]
  /// and the right edge of the parent widget.
  final double? right;

  /// The distance between the top edge of the [PositionedBoilerplateWidget]
  /// and the top edge of the parent widget.
  final double? top;

  /// The distance between the bottom edge of the [PositionedBoilerplateWidget]
  /// and the bottom edge of the parent widget.
  final double? bottom;

  ///The width of the [PositionedBoilerplateWidget].
  final double width;

  ///The height of the [PositionedBoilerplateWidget].
  final double height;
  @override
  Widget build(BuildContext context) {
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
