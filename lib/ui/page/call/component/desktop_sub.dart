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

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';

import '/domain/model/ongoing_call.dart';
import '/routes.dart';
import '/themes.dart';
import '../../../widget/svg/svg.dart';
import '../../home/widget/animated_slider.dart';
import '../../home/widget/avatar.dart';
import '../controller.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/dock.dart';
import '../widget/reorderable_fit.dart';
import '../widget/scaler.dart';
import '../widget/tooltip_button.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';
import 'desktop.dart';

class DesktopBuildDragHandle extends StatelessWidget {
  const DesktopBuildDragHandle(
    this.height,
    this.width, {
    super.key,
    required this.alignment,
  });

  /// Alignment of the [SecondaryScalerWidget].
  final Alignment alignment;

  /// Height of the [SecondaryScalerWidget].
  final double height;

  /// Width of the [SecondaryScalerWidget].
  final double width;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        Widget widget = Container();

        if (alignment == Alignment.centerLeft) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeLeftRight,
            height: height - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              x: ScaleModeX.left,
              dx: dx,
            ),
          );
        } else if (alignment == Alignment.centerRight) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeLeftRight,
            height: height - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              x: ScaleModeX.right,
              dx: -dx,
            ),
          );
        } else if (alignment == Alignment.bottomCenter) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeUpDown,
            width: width - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              dy: -dy,
            ),
          );
        } else if (alignment == Alignment.topCenter) {
          widget = SecondaryScalerWidget(
            cursor: SystemMouseCursors.resizeUpDown,
            width: width - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.top,
              dy: dy,
            ),
          );
        } else if (alignment == Alignment.topLeft) {
          widget = SecondaryScalerWidget(
            // TODO: https://github.com/flutter/flutter/issues/89351
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpLeftDownRight,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.top,
              x: ScaleModeX.left,
              dx: dx,
              dy: dy,
            ),
          );
        } else if (alignment == Alignment.topRight) {
          widget = SecondaryScalerWidget(
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpRightDownLeft,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.top,
              x: ScaleModeX.right,
              dx: -dx,
              dy: dy,
            ),
          );
        } else if (alignment == Alignment.bottomLeft) {
          widget = SecondaryScalerWidget(
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpRightDownLeft,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              x: ScaleModeX.left,
              dx: dx,
              dy: -dy,
            ),
          );
        } else if (alignment == Alignment.bottomRight) {
          widget = SecondaryScalerWidget(
            // TODO: https://github.com/flutter/flutter/issues/89351
            cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                ? SystemMouseCursors.resizeRow
                : SystemMouseCursors.resizeUpLeftDownRight,
            width: Scaler.size * 2,
            height: Scaler.size * 2,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              x: ScaleModeX.right,
              dx: -dx,
              dy: -dy,
            ),
          );
        }

        return Align(alignment: alignment, child: widget);
      },
    );
  }
}

/// Builds the [Dock] containing the [CallController.buttons].
class DockWidget extends StatelessWidget {
  const DockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        final bool isOutgoing =
            (c.outgoing || c.state.value == OngoingCallState.local) &&
                !c.started;

        bool showBottomUi = (c.showUi.isTrue ||
            c.draggedButton.value != null ||
            c.state.value != OngoingCallState.active ||
            (c.state.value == OngoingCallState.active &&
                c.locals.isEmpty &&
                c.remotes.isEmpty &&
                c.focused.isEmpty &&
                c.paneled.isEmpty));

        return AnimatedPadding(
          key: const Key('DockedAnimatedPadding'),
          padding: const EdgeInsets.only(bottom: 5),
          curve: Curves.ease,
          duration: 200.milliseconds,
          child: AnimatedSwitcher(
            key: const Key('DockedAnimatedSwitcher'),
            duration: 200.milliseconds,
            child: AnimatedSlider(
              key: const Key('DockedPanelPadding'),
              isOpen: showBottomUi,
              duration: 400.milliseconds,
              translate: false,
              listener: () =>
                  Future.delayed(Duration.zero, c.relocateSecondary),
              child: MouseRegion(
                onEnter: (d) => c.keepUi(true),
                onHover: (d) => c.keepUi(true),
                onExit: c.showUi.value && !c.displayMore.value
                    ? (d) => c.keepUi(false)
                    : (d) => c.keepUi(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      CustomBoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        blurStyle: BlurStyle.outer,
                      )
                    ],
                  ),
                  margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                  child: ConditionalBackdropFilter(
                    key: c.dockKey,
                    borderRadius: BorderRadius.circular(30),
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x301D6AAE),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: 5,
                      ),
                      child: Obx(() {
                        final bool answer =
                            (c.state.value != OngoingCallState.joining &&
                                c.state.value != OngoingCallState.active &&
                                !isOutgoing);

                        if (answer) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 11),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: AcceptAudioButton(
                                  c,
                                  highlight: !c.withVideo,
                                ).build(),
                              ),
                              const SizedBox(width: 24),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: AcceptVideoButton(
                                  c,
                                  highlight: c.withVideo,
                                ).build(),
                              ),
                              const SizedBox(width: 24),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: DeclineButton(c).build(),
                              ),
                              const SizedBox(width: 11),
                            ],
                          );
                        } else {
                          return Dock<CallButton>(
                            items: c.buttons,
                            itemWidth: CallController.buttonSize,
                            itemBuilder: (e) => e.build(
                              hinted: c.draggedButton.value == null,
                            ),
                            onReorder: (buttons) {
                              c.buttons.clear();
                              c.buttons.addAll(buttons);
                              c.relocateSecondary();
                            },
                            onDragStarted: (b) {
                              c.showDragAndDropButtonsHint = false;
                              c.draggedButton.value = b;
                            },
                            onDragEnded: (_) => c.draggedButton.value = null,
                            onLeave: (_) => c.displayMore.value = true,
                            onWillAccept: (d) => d?.c == c,
                          );
                        }
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      });
    });
  }
}

/// Builds the more panel containing the [CallController.panel].
class LaunchpadWidget extends StatelessWidget {
  const LaunchpadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Obx(() {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: c.displayMore.value
                ? DragTarget<CallButton>(
                    onAccept: (CallButton data) {
                      c.buttons.remove(data);
                      c.draggedButton.value = null;
                    },
                    onWillAccept: (CallButton? a) =>
                        a?.c == c && a?.isRemovable == true,
                    builder: (context, candidateData, rejectedData) =>
                        LaunchpadBuilder(
                      candidate: candidateData,
                      rejected: rejectedData,
                    ),
                  )
                : Container(),
          );
        }),
      );
    });
  }
}

/// Displays a call panel with buttons.
class LaunchpadBuilder extends StatelessWidget {
  const LaunchpadBuilder({
    Key? key,
    required this.candidate,
    required this.rejected,
  }) : super(key: key);

  /// [candidate] of [DragTarget] builder.
  final List<CallButton?> candidate;

  /// [rejected] of [DragTarget] builder.
  final List<dynamic> rejected;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        bool enabled = c.displayMore.isTrue &&
            c.primaryDrags.value == 0 &&
            c.secondaryDrags.value == 0;

        return MouseRegion(
          onEnter: enabled ? (d) => c.keepUi(true) : null,
          onHover: enabled ? (d) => c.keepUi(true) : null,
          onExit: enabled ? (d) => c.keepUi() : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                CustomBoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  blurStyle: BlurStyle.outer,
                )
              ],
            ),
            margin: const EdgeInsets.all(2),
            child: ConditionalBackdropFilter(
              borderRadius: BorderRadius.circular(30),
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Obx(() {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: candidate.any((e) => e?.c == c)
                        ? const Color(0xE0165084)
                        : const Color(0x9D165084),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 35),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 21,
                          children: c.panel.map((e) {
                            return SizedBox(
                              width: 100,
                              height: 100,
                              child: Column(
                                children: [
                                  DelayedDraggable(
                                    feedback: Transform.translate(
                                      offset: const Offset(
                                        CallController.buttonSize / 2 * -1,
                                        CallController.buttonSize / 2 * -1,
                                      ),
                                      child: SizedBox(
                                        height: CallController.buttonSize,
                                        width: CallController.buttonSize,
                                        child: e.build(),
                                      ),
                                    ),
                                    data: e,
                                    onDragStarted: () {
                                      c.showDragAndDropButtonsHint = false;
                                      c.draggedButton.value = e;
                                    },
                                    onDragCompleted: () =>
                                        c.draggedButton.value = null,
                                    onDragEnd: (_) =>
                                        c.draggedButton.value = null,
                                    onDraggableCanceled: (_, __) =>
                                        c.draggedButton.value = null,
                                    maxSimultaneousDrags:
                                        e.isRemovable ? null : 0,
                                    dragAnchorStrategy:
                                        pointerDragAnchorStrategy,
                                    child: e.build(hinted: false),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    e.hint,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      });
    });
  }
}

/// [_SecondaryView] possible alignment.
class PossibleContainerWidget extends StatelessWidget {
  const PossibleContainerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        Alignment? alignment = c.possibleSecondaryAlignment.value;
        if (alignment == null) {
          return Container();
        }

        double width = 10;
        double height = 10;

        if (alignment == Alignment.topCenter ||
            alignment == Alignment.bottomCenter) {
          width = double.infinity;
        } else {
          height = double.infinity;
        }

        return Align(
          alignment: alignment,
          child: ConditionalBackdropFilter(
            child: Container(
              height: height,
              width: width,
              color: const Color(0x4D165084),
            ),
          ),
        );
      });
    });
  }
}

/// Combines all the stackable content into [Scaffold].
class DesktopScaffoldWidget extends StatelessWidget {
  const DesktopScaffoldWidget({
    super.key,
    required this.content,
    required this.ui,
  });

  /// Stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface
  final List<Widget> ui;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!WebUtils.isPopup)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (d) {
                  c.left.value = c.left.value + d.delta.dx;
                  c.top.value = c.top.value + d.delta.dy;
                  c.applyConstraints(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      CustomBoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        blurStyle: BlurStyle.outer,
                      )
                    ],
                  ),
                  child: const TitleBarWidget(),
                ),
              ),
            Expanded(child: Stack(children: [...content, ...ui])),
          ],
        ),
      );
    });
  }
}

/// Title bar of the call containing information about the call and control
/// buttons.
class TitleBarWidget extends StatelessWidget {
  const TitleBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        return Obx(() {
          return Container(
            key: const ValueKey('TitleBar'),
            color: const Color(0xFF162636),
            height: CallController.titleHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Handles double tap to toggle fullscreen.
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: c.toggleFullscreen,
                ),

                // Left part of the title bar that displays the recipient or
                // the caller, its avatar and the call's state.
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.size.width - 60),
                    child: InkWell(
                      onTap: WebUtils.isPopup
                          ? null
                          : () {
                              router.chat(c.chatId.value);
                              if (c.fullscreen.value) {
                                c.toggleFullscreen();
                              }
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          AvatarWidget.fromRxChat(c.chat.value, radius: 8),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'label_call_title'.l10nfmt(c.titleArguments),
                              style: context.textTheme.bodyLarge?.copyWith(
                                fontSize: 13,
                                color: const Color(0xFFFFFFFF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Right part of the title bar that displays buttons.
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TooltipButton(
                          onTap: c.toggleFullscreen,
                          hint: c.fullscreen.value
                              ? 'btn_fullscreen_exit'.l10n
                              : 'btn_fullscreen_enter'.l10n,
                          child: SvgImage.asset(
                            'assets/icons/fullscreen_${c.fullscreen.value ? 'exit' : 'enter'}.svg',
                            width: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

/// Returns a [Scaler] scaling the secondary view.
class SecondaryScalerWidget extends StatelessWidget {
  const SecondaryScalerWidget({
    super.key,
    this.cursor = MouseCursor.defer,
    this.onDrag,
    this.width,
    this.height,
  });

  /// Interface for mouse cursor definitions
  final MouseCursor cursor;

  /// Calculates the corresponding values according to the enabled dragging.
  final Function(double, double)? onDrag;

  /// Width of the [SecondaryScalerWidget].
  final double? width;

  /// Height of the [SecondaryScalerWidget].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        return MouseRegion(
          cursor: c.draggedRenderer.value == null ? cursor : MouseCursor.defer,
          child: Scaler(
            key: key,
            onDragUpdate: onDrag,
            onDragEnd: (_) {
              c.updateSecondaryAttach();
            },
            width: width ?? Scaler.size,
            height: height ?? Scaler.size,
          ),
        );
      });
    });
  }
}

/// Returns a [Scaler] scaling the minimized view.
class MinimizedScalerWidget extends StatelessWidget {
  const MinimizedScalerWidget({
    Key? key,
    required this.onDrag,
    this.cursor = MouseCursor.defer,
    this.width,
    this.height,
  }) : super(key: key);

  /// Interface for mouse cursor definitions.
  final MouseCursor cursor;

  /// Calculates the corresponding values according to the enabled dragging.
  final Function(double, double) onDrag;

  /// Width of this [MinimizedScalerWidget].
  final double? width;

  /// Height of this [MinimizedScalerWidget].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return MouseRegion(
        cursor: cursor,
        child: Scaler(
          key: key,
          onDragUpdate: onDrag,
          onDragEnd: (_) {
            c.updateSecondaryAttach();
          },
          width: width ?? Scaler.size,
          height: height ?? Scaler.size,
        ),
      );
    });
  }
}

/// [DragTarget] of an empty [_secondaryView].
class SecondaryTargetWidget extends StatelessWidget {
  const SecondaryTargetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        Axis secondaryAxis =
            c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical;

        // Pre-calculate the [ReorderableFit]'s size.
        double panelSize = max(
          ReorderableFit.calculateSize(
            maxSize: c.size.shortestSide / 4,
            constraints: Size(c.size.width, c.size.height - 45),
            axis:
                c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical,
            length: c.secondary.length,
          ),
          130,
        );

        return AnimatedSwitcher(
          key: const Key('SecondaryTargetAnimatedSwitcher'),
          duration: 200.milliseconds,
          child: c.secondary.isEmpty && c.doughDraggedRenderer.value != null
              ? Align(
                  alignment: secondaryAxis == Axis.horizontal
                      ? Alignment.centerRight
                      : Alignment.topCenter,
                  child: SizedBox(
                    width: secondaryAxis == Axis.horizontal
                        ? panelSize / 1.6
                        : double.infinity,
                    height: secondaryAxis == Axis.horizontal
                        ? double.infinity
                        : panelSize / 1.6,
                    child: DragTarget<DesktopDragData>(
                      onWillAccept: (d) => d?.chatId == c.chatId.value,
                      onAccept: (DesktopDragData d) {
                        if (secondaryAxis == Axis.horizontal) {
                          c.secondaryAlignment.value = Alignment.centerRight;
                        } else {
                          c.secondaryAlignment.value = Alignment.topCenter;
                        }
                        c.unfocus(d.participant);
                      },
                      builder: (context, candidate, rejected) {
                        return Obx(() {
                          return IgnorePointer(
                            child: AnimatedSwitcher(
                              key: const Key('SecondaryTargetAnimatedSwitcher'),
                              duration: 200.milliseconds,
                              child: c.primaryDrags.value >= 1
                                  ? Container(
                                      padding: EdgeInsets.only(
                                        left: secondaryAxis == Axis.horizontal
                                            ? 1
                                            : 0,
                                        bottom: secondaryAxis == Axis.vertical
                                            ? 1
                                            : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          left: secondaryAxis == Axis.horizontal
                                              ? const BorderSide(
                                                  color: Color(0xFF888888),
                                                  width: 1,
                                                )
                                              : BorderSide.none,
                                          bottom: secondaryAxis == Axis.vertical
                                              ? const BorderSide(
                                                  color: Color(0xFF888888),
                                                  width: 1,
                                                )
                                              : BorderSide.none,
                                        ),
                                        boxShadow: const [
                                          CustomBoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 8,
                                            blurStyle: BlurStyle.outer,
                                          )
                                        ],
                                      ),
                                      child: ConditionalBackdropFilter(
                                        child: AnimatedContainer(
                                          duration: 300.milliseconds,
                                          color: candidate.isNotEmpty
                                              ? const Color(0x10FFFFFF)
                                              : const Color(0x00FFFFFF),
                                          child: Center(
                                            child: SizedBox(
                                              width: secondaryAxis ==
                                                      Axis.horizontal
                                                  ? min(panelSize, 150 + 44)
                                                  : null,
                                              height: secondaryAxis ==
                                                      Axis.horizontal
                                                  ? null
                                                  : min(panelSize, 150 + 44),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  AnimatedScale(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    curve: Curves.ease,
                                                    scale: candidate.isNotEmpty
                                                        ? 1.06
                                                        : 1,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0x40000000),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(10),
                                                        child: Icon(
                                                          Icons.add_rounded,
                                                          size: 35,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(key: UniqueKey()),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                )
              : Container(),
        );
      });
    });
  }
}
