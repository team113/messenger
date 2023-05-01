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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';

import '../controller.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/dock.dart';
import '../widget/reorderable_fit.dart';
import '../widget/scaler.dart';
import '../widget/tooltip_button.dart';
import '/domain/repository/chat.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/page/home/widget/avatar.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';
import 'desktop.dart';

/// Handle with a drag-and-drop function that allows the user to resize and
/// manipulate user interface elements.
class BuildDragHandle extends StatelessWidget {
  const BuildDragHandle(
    this.height,
    this.width,
    this.alignment,
    this.draggedRenderer, {
    super.key,
    this.onDragUpdate,
    this.onDragEnd,
  });

  /// Alignment of the [SecondaryScaler].
  final Alignment alignment;

  /// Height of the [SecondaryScaler].
  final double height;

  /// Width of the [SecondaryScaler].
  final double width;

  /// [Function] that is responsible for handling the events of dragging
  /// an element on the screen, returning a callback function that will be
  /// called every time the user moves the element.
  final dynamic Function(double, double)? onDragUpdate;

  /// [Function] that is responsible for handling element dragging events
  /// is called only once at the moment when the user finishes dragging
  /// the element.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Link to the item that is being dragged now.
  final Rx<Participant?> draggedRenderer;

  @override
  Widget build(BuildContext context) {
    Widget widget = Container();

    if (alignment == Alignment.centerLeft) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.centerRight) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeLeftRight,
        height: height - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.bottomCenter) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.topCenter) {
      widget = SecondaryScaler(
        cursor: SystemMouseCursors.resizeUpDown,
        width: width - Scaler.size,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.topLeft) {
      widget = SecondaryScaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.topRight) {
      widget = SecondaryScaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.bottomLeft) {
      widget = SecondaryScaler(
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpRightDownLeft,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    } else if (alignment == Alignment.bottomRight) {
      widget = SecondaryScaler(
        // TODO: https://github.com/flutter/flutter/issues/89351
        cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
            ? SystemMouseCursors.resizeRow
            : SystemMouseCursors.resizeUpLeftDownRight,
        width: Scaler.size * 2,
        height: Scaler.size * 2,
        draggedRenderer: draggedRenderer,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
      );
    }

    return Align(alignment: alignment, child: widget);
  }
}

/// [Dock] which contains the [CallController.buttons].
class DockWidget extends StatelessWidget {
  const DockWidget({
    super.key,
    required this.showBottomUi,
    required this.answer,
    required this.computation,
    this.dock,
    this.audioButton,
    this.videoButton,
    this.declineButton,
    this.isOutgoing,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.dockKey,
  });

  /// [Widget] that will be shown at the bottom of the screen.
  final Widget? dock;

  /// [Widget] of the call button with audio.
  final Widget? audioButton;

  /// [Widget] of a call button with a video.
  final Widget? videoButton;

  /// [Widget] of the reject call button.
  final Widget? declineButton;

  /// [Function] that is called when the mouse cursor enters the area
  /// of this [DockWidget].
  final void Function(PointerEnterEvent)? onEnter;

  /// [Function] that is called when the mouse cursor moves in the area
  /// of this [DockWidget].
  final void Function(PointerHoverEvent)? onHover;

  /// [Function] that is called when the mouse cursor leaves the area
  /// of this [DockWidget].
  final void Function(PointerExitEvent)? onExit;

  /// Indicator of whether the call is outgoing.
  final bool? isOutgoing;

  /// Indicator of whether to show the [dock].
  final bool showBottomUi;

  /// Indicator whether the call is incoming.
  final bool answer;

  /// Key for handling [dock] widget states.
  final Key? dockKey;

  /// Function that is called when switching between two widget states occurs.
  final VoidCallback computation;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: const EdgeInsets.only(bottom: 5),
      curve: Curves.ease,
      duration: 200.milliseconds,
      child: AnimatedSwitcher(
        duration: 200.milliseconds,
        child: AnimatedSlider(
          isOpen: showBottomUi,
          duration: 400.milliseconds,
          translate: false,
          listener: () => Function.apply(computation, []),
          child: MouseRegion(
            onEnter: onEnter,
            onHover: onHover,
            onExit: onExit,
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
                key: dockKey,
                borderRadius: BorderRadius.circular(30),
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Material(
                  color: const Color(0x301D6AAE),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 5,
                    ),
                    child: answer
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 11),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: audioButton,
                              ),
                              const SizedBox(width: 24),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: videoButton,
                              ),
                              const SizedBox(width: 24),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: declineButton,
                              ),
                              const SizedBox(width: 11),
                            ],
                          )
                        : dock,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// More panel which contains the [CallController.panel].
class Launchpad extends StatelessWidget {
  const Launchpad({
    super.key,
    required this.enabled,
    required this.test,
    required this.panel,
    required this.displayMore,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.onAccept,
    this.onWillAccept,
    this.children = const <Widget>[],
  });

  /// Indicator of whether [Launchpad] is enabled.
  final bool enabled;

  /// [Function] that is called when the mouse cursor enters the area
  /// of this [Launchpad].
  final void Function(PointerEnterEvent)? onEnter;

  /// [Function] that is called when the mouse cursor moves in the area
  /// of this [Launchpad].
  final void Function(PointerHoverEvent)? onHover;

  /// [Function] that is called when the mouse cursor leaves the area
  /// of this [Launchpad].
  final void Function(PointerExitEvent)? onExit;

  /// Indicator whether at least one element from the [panel] list satisfies
  /// the condition set by the [test] function.
  final bool Function(CallButton?) test;

  /// [CallButton] list, which is a panel of buttons in [Launchpad].
  final RxList<CallButton> panel;

  /// Callback function that is called when accepting a draggable element.
  final void Function(CallButton)? onAccept;

  /// Callback function that is called when the dragged element is above
  /// the widget, but has not yet been released.
  final bool Function(CallButton?)? onWillAccept;

  /// Indicator of whether additional elements should be displayed
  /// in [Launchpad].
  final RxBool displayMore;

  /// [List] of widgets that will be displayed in the [Launchpad].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    /// Builder function for the [DragTarget].
    ///
    /// It is responsible for displaying the visual interface when dragging
    /// elements onto the target.
    Widget launchpadBuilder(
      BuildContext context,
      List<CallButton?> candidate,
      List<dynamic> rejected,
    ) {
      return MouseRegion(
        onEnter: onEnter,
        onHover: onHover,
        onExit: onExit,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: candidate.any(test)
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
                      children: children,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: displayMore.value
            ? DragTarget<CallButton>(
                onAccept: onAccept,
                onWillAccept: onWillAccept,
                builder: launchpadBuilder,
              )
            : Container(),
      ),
    );
  }
}

/// [Container] with a specific alignment on the screen.
///
/// It is used to visualize the possible locations for dropping an item
/// during drag-and-drop operations.
class PossibleContainer extends StatelessWidget {
  const PossibleContainer(
    this.alignment, {
    super.key,
  });

  /// Variable determines the alignment of the [PossibleContainer]
  /// on the screen.
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    if (alignment == null) {
      return Container();
    }

    final double width =
        alignment == Alignment.topCenter || alignment == Alignment.bottomCenter
            ? double.infinity
            : 10;

    final double height =
        alignment == Alignment.topCenter || alignment == Alignment.bottomCenter
            ? 10
            : double.infinity;

    return Align(
      alignment: alignment!,
      child: ConditionalBackdropFilter(
        child: Container(
          height: height,
          width: width,
          color: const Color(0x4D165084),
        ),
      ),
    );
  }
}

/// [Scaffold] widget which combines all stackable content.
class DesktopScaffoldWidget extends StatelessWidget {
  const DesktopScaffoldWidget({
    super.key,
    required this.content,
    required this.ui,
    this.onPanUpdate,
    this.titleBar,
  });

  /// List of [Widget] that make up the stackable content.
  final List<Widget> content;

  /// List of [Widget] that make up the user interface.
  final List<Widget> ui;

  /// [Widget] that represents the title bar.
  ///
  /// It is displayed at the top of the scaffold if [WebUtils.isPopup] is false.
  final Widget? titleBar;

  /// Callback [Function] that handles drag update events.
  final void Function(DragUpdateDetails)? onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!WebUtils.isPopup)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: onPanUpdate,
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
                child: titleBar,
              ),
            ),
          Expanded(child: Stack(children: [...content, ...ui])),
        ],
      ),
    );
  }
}

/// [Widget] that displays the title bar at the top of the screen.
///
/// [TitleBar] contains information such as the recipient or caller's
/// name, avatar, and call state, as well as buttons for full-screen mode
/// and other actions.
class TitleBar extends StatelessWidget {
  const TitleBar({
    super.key,
    required this.constraints,
    required this.chat,
    required this.titleArguments,
    required this.fullscreen,
    this.onDoubleTap,
    this.onTap,
    this.toggleFullscreen,
  });

  /// Callback called when double-tapping on the [TitleBar].
  final VoidCallback? onDoubleTap;

  /// Variable that imposes restrictions on the size of the element.
  final BoxConstraints constraints;

  /// Callback that is called when you touch on the left side
  /// of the [TitleBar].
  final VoidCallback? onTap;

  /// Chat Information.
  final Rx<RxChat?> chat;

  /// Header arguments.
  final Map<String, String> titleArguments;

  /// Callback that is called when you click on the "full-screen" button.
  final VoidCallback? toggleFullscreen;

  /// Indicator indicating whether the application is in full-screen mode.
  final RxBool fullscreen;

  @override
  Widget build(BuildContext context) {
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
            onDoubleTap: onDoubleTap,
          ),

          // Left part of the title bar that displays the recipient or
          // the caller, its avatar and the call's state.
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: constraints,
              child: GestureDetector(
                onTap: onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 10),
                    AvatarWidget.fromRxChat(chat.value, radius: 8),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'label_call_title'.l10nfmt(titleArguments),
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
                    onTap: toggleFullscreen,
                    hint: fullscreen.value
                        ? 'btn_fullscreen_exit'.l10n
                        : 'btn_fullscreen_enter'.l10n,
                    child: SvgImage.asset(
                      'assets/icons/fullscreen_${fullscreen.value ? 'exit' : 'enter'}.svg',
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
  }
}

/// [Widget] that contains a [MouseRegion] and a [Scaler] widget.
///
/// It is used to resize a secondary video window.
class SecondaryScaler extends StatelessWidget {
  const SecondaryScaler({
    super.key,
    required this.draggedRenderer,
    this.cursor = MouseCursor.defer,
    this.onDragUpdate,
    this.onDragEnd,
    this.width,
    this.height,
  });

  /// Interface for mouse cursor definitions
  final MouseCursor cursor;

  /// [Rx] object that contains information about the renderer being dragged.
  final Rx<Participant?> draggedRenderer;

  /// [Function] that gets called when dragging is updated.
  final Function(double, double)? onDragUpdate;

  /// [Function] that gets called when dragging ends.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Width of the [SecondaryScaler].
  final double? width;

  /// Height of the [SecondaryScaler].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: draggedRenderer.value == null ? cursor : MouseCursor.defer,
      child: Scaler(
        key: key,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        width: width ?? Scaler.size,
        height: height ?? Scaler.size,
      ),
    );
  }
}

/// [Widget] which returns a [Scaler] scaling the minimized view.
class MinimizedScaler extends StatelessWidget {
  const MinimizedScaler({
    Key? key,
    this.cursor = MouseCursor.defer,
    this.onDragUpdate,
    this.onDragEnd,
    this.width,
    this.height,
  }) : super(key: key);

  /// Interface for mouse cursor definitions.
  final MouseCursor cursor;

  /// [Function] that gets called when dragging is updated.
  final Function(double, double)? onDragUpdate;

  /// [Function] that gets called when dragging ends.
  final dynamic Function(DragEndDetails)? onDragEnd;

  /// Width of this [MinimizedScaler].
  final double? width;

  /// Height of this [MinimizedScaler].
  final double? height;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: Scaler(
        key: key,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd,
        width: width ?? Scaler.size,
        height: height ?? Scaler.size,
      ),
    );
  }
}

/// [Widget] that serves as a drag target for a list of [Participant].
///
/// It provides a secondary data source for the main widget and allows dragging
/// and dropping of participants between the two widgets.
class SecondaryTarget extends StatelessWidget {
  const SecondaryTarget({
    super.key,
    required this.size,
    required this.secondaryAxis,
    required this.secondary,
    required this.doughDraggedRenderer,
    required this.primaryDrags,
    required this.secondaryAlignment,
    required this.unfocus,
    this.onWillAccept,
  });

  /// [Size] object that represents the size of the widget.
  final Size size;

  /// [Axis] enumeration value that specifies the secondary axis of the widget.
  final Axis secondaryAxis;

  /// [RxList] object that contains a list of Participant objects.
  ///
  /// It represents the secondary data source of the widget.
  final RxList<Participant> secondary;

  /// [Rx] object that contains a Participant object.
  ///
  /// It represents the participant that is currently being dragged.
  final Rx<Participant?> doughDraggedRenderer;

  /// Callback function that called when a drag operation enters the target
  /// [Widget] to determine whether the [Widget] can accept the dragged data.
  final bool Function(DragData?)? onWillAccept;

  /// [RxInt] object that represents the number of primary drag operations
  /// that have been performed.
  final RxInt primaryDrags;

  /// [Rx] object that contains an [Alignment] object.
  ///
  /// It represents the alignment of the secondary widget with respect
  /// to the primary [Widget].
  final Rx<Alignment?> secondaryAlignment;

  /// Callback [Function] that called to remove focus from the
  /// specified [Participant].
  final void Function(Participant) unfocus;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Pre-calculate the [ReorderableFit]'s size.
      double panelSize = max(
        ReorderableFit.calculateSize(
          maxSize: size.shortestSide / 4,
          constraints: Size(size.width, size.height - 45),
          axis: size.width >= size.height ? Axis.horizontal : Axis.vertical,
          length: secondary.length,
        ),
        130,
      );

      return AnimatedSwitcher(
        key: const Key('SecondaryTargetAnimatedSwitcher'),
        duration: 200.milliseconds,
        child: secondary.isEmpty && doughDraggedRenderer.value != null
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
                  child: DragTarget<DragData>(
                    onWillAccept: onWillAccept,
                    onAccept: (DragData d) {
                      if (secondaryAxis == Axis.horizontal) {
                        secondaryAlignment.value = Alignment.centerRight;
                      } else {
                        secondaryAlignment.value = Alignment.topCenter;
                      }
                      unfocus(d.participant);
                    },
                    builder: (context, candidate, rejected) {
                      return IgnorePointer(
                        child: AnimatedSwitcher(
                          key: const Key('SecondaryTargetAnimatedSwitcher'),
                          duration: 200.milliseconds,
                          child: primaryDrags.value >= 1
                              ? Container(
                                  padding: EdgeInsets.only(
                                    left: secondaryAxis == Axis.horizontal
                                        ? 1
                                        : 0,
                                    bottom:
                                        secondaryAxis == Axis.vertical ? 1 : 0,
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
                                          width:
                                              secondaryAxis == Axis.horizontal
                                                  ? min(panelSize, 150 + 44)
                                                  : null,
                                          height:
                                              secondaryAxis == Axis.horizontal
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
                                                    color:
                                                        const Color(0x40000000),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(10),
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
                              : Container(),
                        ),
                      );
                    },
                  ),
                ),
              )
            : Container(),
      );
    });
  }
}
