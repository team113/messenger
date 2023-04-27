// ignore_for_file: public_member_api_docs, sort_constructors_first
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

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '../widget/call_cover.dart';
import '../widget/call_title_common.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/desktop_primary_view.dart';
import '../widget/desktop_secondary_view.dart';
import '../widget/dock.dart';
import '../widget/hint.dart';
import '../widget/scaler.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';
import 'desktop_sub.dart';

/// Returns a desktop design of a [CallView].
class DesktopCall extends StatelessWidget {
  const DesktopCall(this.call, {super.key});

  /// Current [OngoingCall].
  final Rx<OngoingCall> call;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: CallController(
          call,
          Get.find(),
          Get.find(),
          Get.find(),
          Get.find(),
        ),
        builder: (CallController c) {
          return LayoutBuilder(
            builder: (context, constraints) {
              // Call stackable content.
              List<Widget> content = [
                SvgImage.asset(
                  'assets/images/background_dark.svg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ];

              content.addAll([
                // Call's primary view.
                Column(
                  children: [
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: c.secondary.isNotEmpty &&
                                  c.secondaryAlignment.value ==
                                      Alignment.topCenter
                              ? c.secondaryHeight.value
                              : 0,
                        )),
                    Expanded(
                      child: Row(
                        children: [
                          Obx(() => SizedBox(
                                height: double.infinity,
                                width: c.secondary.isNotEmpty &&
                                        c.secondaryAlignment.value ==
                                            Alignment.centerLeft
                                    ? c.secondaryWidth.value
                                    : 0,
                              )),
                          Expanded(
                            child: Stack(
                              children: [
                                Obx(() {
                                  final bool isOutgoing = (c.outgoing ||
                                          c.state.value ==
                                              OngoingCallState.local) &&
                                      !c.started;

                                  final bool isIncoming = c.state.value !=
                                          OngoingCallState.active &&
                                      c.state.value !=
                                          OngoingCallState.joining &&
                                      !isOutgoing;

                                  final bool isDialog =
                                      c.chat.value?.chat.value.isDialog == true;

                                  final Widget child;

                                  if (!isIncoming) {
                                    child = const PrimaryView();
                                  } else {
                                    if (isDialog) {
                                      final User? user = c
                                              .chat.value?.members.values
                                              .firstWhereOrNull(
                                                (e) => e.id != c.me.id.userId,
                                              )
                                              ?.user
                                              .value ??
                                          c.chat.value?.chat.value.members
                                              .firstWhereOrNull(
                                                (e) =>
                                                    e.user.id != c.me.id.userId,
                                              )
                                              ?.user;

                                      child = CallCoverWidget(
                                        c.chat.value?.callCover,
                                        user: user,
                                      );
                                    } else {
                                      if (c.chat.value?.avatar.value != null) {
                                        final Avatar avatar =
                                            c.chat.value!.avatar.value!;
                                        child = CallCoverWidget(
                                          UserCallCover(
                                            full: avatar.full,
                                            original: avatar.original,
                                            square: avatar.full,
                                            vertical: avatar.full,
                                          ),
                                        );
                                      } else {
                                        child = const SizedBox();
                                      }
                                    }
                                  }

                                  return AnimatedSwitcher(
                                    duration: 400.milliseconds,
                                    child: child,
                                  );
                                }),
                                Obx(() => MouseRegion(
                                      opaque: false,
                                      cursor: c.isCursorHidden.value
                                          ? SystemMouseCursors.none
                                          : SystemMouseCursors.basic,
                                    )),
                              ],
                            ),
                          ),
                          Obx(() => SizedBox(
                                height: double.infinity,
                                width: c.secondary.isNotEmpty &&
                                        c.secondaryAlignment.value ==
                                            Alignment.centerRight
                                    ? c.secondaryWidth.value
                                    : 0,
                              )),
                        ],
                      ),
                    ),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          height: c.secondary.isNotEmpty &&
                                  c.secondaryAlignment.value ==
                                      Alignment.bottomCenter
                              ? c.secondaryHeight.value
                              : 0,
                        )),
                  ],
                ),

                // Dim the primary view in a non-active call.
                Obx(() {
                  final Widget child;

                  if (c.state.value == OngoingCallState.active) {
                    child = const SizedBox();
                  } else {
                    child = IgnorePointer(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: const Color(0x70000000),
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                      duration: 200.milliseconds, child: child);
                }),

                const PossibleContainerWidget(),

                // Makes UI appear on click.
                Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (d) {
                    c.downPosition = d.localPosition;
                    c.downButtons = d.buttons;
                  },
                  onPointerUp: (d) {
                    if (c.downButtons & kPrimaryButton != 0 &&
                        (d.localPosition.distanceSquared -
                                    c.downPosition.distanceSquared)
                                .abs() <=
                            1500) {
                      if (c.primaryDrags.value == 0 &&
                          c.secondaryDrags.value == 0) {
                        if (c.state.value == OngoingCallState.active) {
                          if (!c.showUi.value) {
                            c.keepUi();
                          } else {
                            c.keepUi(false);
                          }
                        }
                      }
                    }
                  },
                ),

                // Empty drop zone if [secondary] is empty.
                const SecondaryTargetWidget(),
              ]);

              /// Indicator that the current call is outgoing
              /// and also has not been started.
              final bool isOutgoing =
                  (c.outgoing || c.state.value == OngoingCallState.local) &&
                      !c.started;

              /// Indicator of whether the bottom menu should be displayed.
              final bool showBottomUi = (c.showUi.isTrue ||
                  c.draggedButton.value != null ||
                  c.state.value != OngoingCallState.active ||
                  (c.state.value == OngoingCallState.active &&
                      c.locals.isEmpty &&
                      c.remotes.isEmpty &&
                      c.focused.isEmpty &&
                      c.paneled.isEmpty));

              /// Indicator that determines whether it is possible
              /// to answer the current call.
              final bool answer = (c.state.value != OngoingCallState.joining &&
                  c.state.value != OngoingCallState.active &&
                  !isOutgoing);

              /// Indicator that the [LaunchpadWidget] can interact with the user.
              final bool enabled = c.displayMore.isTrue &&
                  c.primaryDrags.value == 0 &&
                  c.secondaryDrags.value == 0;

              // Footer part of the call with buttons.
              List<Widget> footer = [
                // Animated bottom buttons.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Obx(
                          () => Column(
                            mainAxisSize: MainAxisSize.min,
                            verticalDirection: VerticalDirection.up,
                            children: [
                              DockWidget(
                                dock: Dock<CallButton>(
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
                                  onDragEnded: (_) =>
                                      c.draggedButton.value = null,
                                  onLeave: (_) => c.displayMore.value = true,
                                  onWillAccept: (d) => d?.c == c,
                                ),
                                audioButton: AcceptAudioButton(
                                  c,
                                  highlight: !c.withVideo,
                                ).build(),
                                videoButton: AcceptVideoButton(
                                  c,
                                  highlight: c.withVideo,
                                ).build(),
                                declineButton: DeclineButton(c).build(),
                                onEnter: (d) => c.keepUi(true),
                                onHover: (d) => c.keepUi(true),
                                onExit: c.showUi.value && !c.displayMore.value
                                    ? (d) => c.keepUi(false)
                                    : (d) => c.keepUi(),
                                isOutgoing: isOutgoing,
                                showBottomUi: showBottomUi,
                                answer: answer,
                                dockKey: c.dockKey,
                                computation: c.relocateSecondary,
                              ),
                              LaunchpadWidget(
                                displayMore: c.displayMore,
                                onEnter: enabled ? (d) => c.keepUi(true) : null,
                                onHover: enabled ? (d) => c.keepUi(true) : null,
                                onExit: enabled ? (d) => c.keepUi() : null,
                                enabled: enabled,
                                onAccept: (CallButton data) {
                                  c.buttons.remove(data);
                                  c.draggedButton.value = null;
                                },
                                onWillAccept: (CallButton? a) =>
                                    a?.c == c && a?.isRemovable == true,
                                test: (e) => e?.c == c,
                                panel: c.panel,
                                children: c.panel.map((e) {
                                  return SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Column(
                                      children: [
                                        DelayedDraggable(
                                          feedback: Transform.translate(
                                            offset: const Offset(
                                              CallController.buttonSize /
                                                  2 *
                                                  -1,
                                              CallController.buttonSize /
                                                  2 *
                                                  -1,
                                            ),
                                            child: SizedBox(
                                              height: CallController.buttonSize,
                                              width: CallController.buttonSize,
                                              child: e.build(),
                                            ),
                                          ),
                                          data: e,
                                          onDragStarted: () {
                                            c.showDragAndDropButtonsHint =
                                                false;
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Display the more hint, if not dismissed.
                Obx(() {
                  return AnimatedSwitcher(
                    duration: 150.milliseconds,
                    child: c.showDragAndDropButtonsHint && c.displayMore.value
                        ? Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedDelayedSwitcher(
                                  delay: const Duration(milliseconds: 500),
                                  duration: const Duration(milliseconds: 200),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 290,
                                      padding: EdgeInsets.only(
                                          top: 10 +
                                              (WebUtils.isPopup
                                                  ? 0
                                                  : CallController
                                                      .titleHeight)),
                                      child: HintWidget(
                                        text: 'label_hint_drag_n_drop_buttons'
                                            .l10n,
                                        onTap: () => c
                                            .showDragAndDropButtonsHint = false,
                                      ),
                                    ),
                                  ),
                                ),
                                const Flexible(child: SizedBox(height: 420)),
                              ],
                            ),
                          )
                        : Container(),
                  );
                }),
              ];

              List<Widget> ui = [
                IgnorePointer(
                  child: Obx(() {
                    bool preferTitle = c.state.value != OngoingCallState.active;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: preferTitle &&
                              c.primary
                                  .where((e) =>
                                      e.video.value?.renderer.value != null)
                                  .isNotEmpty
                          ? Container(color: const Color(0x55000000))
                          : null,
                    );
                  }),
                ),

                Obx(() {
                  bool preferTitle = c.state.value != OngoingCallState.active;
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: c.toggleFullscreen,
                    onPanUpdate: preferTitle
                        ? (d) {
                            c.left.value = c.left.value + d.delta.dx;
                            c.top.value = c.top.value + d.delta.dy;
                            c.applyConstraints(context);
                          }
                        : null,
                  );
                }),

                // Sliding from the top title bar.
                Obx(() {
                  final bool isOutgoing =
                      (c.outgoing || c.state.value == OngoingCallState.local) &&
                          !c.started;

                  final bool preferTitle =
                      c.state.value != OngoingCallState.active && !isOutgoing;

                  return AnimatedSwitcher(
                    key: const Key('AnimatedSwitcherCallTitle'),
                    duration: const Duration(milliseconds: 200),
                    child: preferTitle
                        ? Align(
                            key: const Key('CallTitlePadding'),
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: c.size.height * 0.05,
                              ),
                              child: const CallTitleCommon(),
                            ),
                          )
                        : Container(key: UniqueKey()),
                  );
                }),

                // Sliding from the top info header.
                if (WebUtils.isPopup)
                  Obx(() {
                    if (!c.fullscreen.value) {
                      return const SizedBox();
                    }

                    return Align(
                      alignment: Alignment.topCenter,
                      child: AnimatedSlider(
                        duration: 400.milliseconds,
                        translate: false,
                        beginOffset: const Offset(0, -1),
                        endOffset: const Offset(0, 0),
                        isOpen: c.state.value == OngoingCallState.active &&
                            c.showHeader.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              CustomBoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                blurStyle: BlurStyle.outer,
                              )
                            ],
                          ),
                          margin: const EdgeInsets.fromLTRB(10, 5, 10, 2),
                          child: ConditionalBackdropFilter(
                            borderRadius: BorderRadius.circular(30),
                            filter: ImageFilter.blur(
                              sigmaX: 15,
                              sigmaY: 15,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x301D6AAE),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 10,
                              ),
                              child: Text(
                                'label_call_title'.l10nfmt(c.titleArguments),
                                style: context.textTheme.bodyLarge?.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFFFFFFFF),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                // Bottom [MouseRegion] that toggles UI on hover.
                Obx(() {
                  final bool enabled =
                      c.primaryDrags.value == 0 && c.secondaryDrags.value == 0;
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: MouseRegion(
                        opaque: false,
                        onEnter: enabled ? (d) => c.keepUi(true) : null,
                        onHover: enabled ? (d) => c.keepUi(true) : null,
                        onExit: c.showUi.value && enabled
                            ? (d) {
                                if (c.displayMore.isTrue) {
                                  c.keepUi();
                                } else {
                                  c.keepUi(false);
                                }
                              }
                            : null,
                      ),
                    ),
                  );
                }),

                // Top [MouseRegion] that toggles info header on hover.
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: MouseRegion(
                      opaque: false,
                      onEnter: (_) => c.showHeader.value = true,
                      onHover: (_) => c.showHeader.value = true,
                      onExit: (_) => c.showHeader.value = false,
                    ),
                  ),
                ),

                // Secondary panel itself.
                Obx(() {
                  final bool isIncoming = c.state.value !=
                          OngoingCallState.active &&
                      c.state.value != OngoingCallState.joining &&
                      !(c.outgoing || c.state.value == OngoingCallState.local);

                  if (isIncoming) {
                    return const SizedBox();
                  }

                  return LayoutBuilder(builder: (_, constraints) {
                    // Scale the secondary panel after this frame is displayed, as
                    // otherwise it invokes re-drawing twice in a frame, resulting in an
                    // error.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      c.scaleSecondary(constraints);
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => c.relocateSecondary());
                    });

                    return const SecondaryView();
                  });
                }),

                // Show a hint if any renderer is draggable.
                Obx(() {
                  final bool hideSecondary =
                      c.size.width < 500 && c.size.height < 500;
                  final bool mayDragVideo = !hideSecondary &&
                      (c.focused.length > 1 ||
                          (c.focused.isEmpty &&
                              c.primary.length + c.secondary.length > 1));

                  return AnimatedSwitcher(
                    duration: 150.milliseconds,
                    child: c.showDragAndDropVideosHint && mayDragVideo
                        ? Padding(
                            padding: EdgeInsets.only(
                              top: c.secondary.isNotEmpty &&
                                      c.secondaryAlignment.value ==
                                          Alignment.topCenter
                                  ? 10 + c.secondaryHeight.value
                                  : 10,
                              right: c.secondary.isNotEmpty &&
                                      c.secondaryAlignment.value ==
                                          Alignment.centerRight
                                  ? 10 + c.secondaryWidth.value
                                  : 10,
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: SizedBox(
                                width: 320,
                                child: HintWidget(
                                  text: 'label_hint_drag_n_drop_video'.l10n,
                                  onTap: () =>
                                      c.showDragAndDropVideosHint = false,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  );
                }),

                // If there's any error to show, display it.
                Obx(() {
                  return AnimatedSwitcher(
                    duration: 150.milliseconds,
                    child: c.errorTimeout.value != 0
                        ? Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: c.secondary.isNotEmpty &&
                                        c.secondaryAlignment.value ==
                                            Alignment.topCenter
                                    ? 10 + c.secondaryHeight.value
                                    : 10,
                                right: c.secondary.isNotEmpty &&
                                        c.secondaryAlignment.value ==
                                            Alignment.centerRight
                                    ? 10 + c.secondaryWidth.value
                                    : 10,
                              ),
                              child: SizedBox(
                                width: 320,
                                child: HintWidget(
                                  text: '${c.error}.',
                                  onTap: () {
                                    c.errorTimeout.value = 0;
                                  },
                                  isError: true,
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  );
                }),

                Obx(() {
                  if (c.minimized.value && !c.fullscreen.value) {
                    return Container();
                  }

                  return Stack(children: footer);
                }),
              ];

              if (c.minimized.value && !c.fullscreen.value) {
                // Applies constraints on every rebuild.
                // This includes the screen size changes.
                c.applyConstraints(context);

                // Returns a stack of draggable [Scaler]s on each of the sides:
                //
                // +-------+
                // |       |
                // |       |
                // |       |
                // +-------+
                //
                // 1) + is a cornered scale point;
                // 2) | is a horizontal scale point;
                // 3) - is a vertical scale point;
                return Stack(
                  children: [
                    // top middle
                    Obx(() {
                      return Positioned(
                        top: c.top.value - Scaler.size / 2,
                        left: c.left.value + Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          cursor: SystemMouseCursors.resizeUpDown,
                          width: c.width.value - Scaler.size,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            y: ScaleModeY.top,
                            dy: dy,
                          ),
                        ),
                      );
                    }),
                    // center left
                    Obx(() {
                      return Positioned(
                        top: c.top.value + Scaler.size / 2,
                        left: c.left.value - Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          height: c.height.value - Scaler.size,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            x: ScaleModeX.left,
                            dx: dx,
                          ),
                        ),
                      );
                    }),
                    // center right
                    Obx(() {
                      return Positioned(
                        top: c.top.value + Scaler.size / 2,
                        left: c.left.value + c.width.value - Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          cursor: SystemMouseCursors.resizeLeftRight,
                          height: c.height.value - Scaler.size,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            x: ScaleModeX.right,
                            dx: -dx,
                          ),
                        ),
                      );
                    }),
                    // bottom center
                    Obx(() {
                      return Positioned(
                        top: c.top.value + c.height.value - Scaler.size / 2,
                        left: c.left.value + Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          cursor: SystemMouseCursors.resizeUpDown,
                          width: c.width.value - Scaler.size,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            y: ScaleModeY.bottom,
                            dy: -dy,
                          ),
                        ),
                      );
                    }),

                    // top left
                    Obx(() {
                      return Positioned(
                        top: c.top.value - Scaler.size / 2,
                        left: c.left.value - Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          // TODO: https://github.com/flutter/flutter/issues/89351
                          cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                              ? SystemMouseCursors.resizeRow
                              : SystemMouseCursors.resizeUpLeftDownRight,
                          width: Scaler.size * 2,
                          height: Scaler.size * 2,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            y: ScaleModeY.top,
                            x: ScaleModeX.left,
                            dx: dx,
                            dy: dy,
                          ),
                        ),
                      );
                    }),
                    // top right
                    Obx(() {
                      return Positioned(
                        top: c.top.value - Scaler.size / 2,
                        left:
                            c.left.value + c.width.value - 3 * Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                              ? SystemMouseCursors.resizeRow
                              : SystemMouseCursors.resizeUpRightDownLeft,
                          width: Scaler.size * 2,
                          height: Scaler.size * 2,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            y: ScaleModeY.top,
                            x: ScaleModeX.right,
                            dx: -dx,
                            dy: dy,
                          ),
                        ),
                      );
                    }),
                    // bottom left
                    Obx(() {
                      return Positioned(
                        top: c.top.value + c.height.value - 3 * Scaler.size / 2,
                        left: c.left.value - Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                              ? SystemMouseCursors.resizeRow
                              : SystemMouseCursors.resizeUpRightDownLeft,
                          width: Scaler.size * 2,
                          height: Scaler.size * 2,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            y: ScaleModeY.bottom,
                            x: ScaleModeX.left,
                            dx: dx,
                            dy: -dy,
                          ),
                        ),
                      );
                    }),
                    // bottom right
                    Obx(() {
                      return Positioned(
                        top: c.top.value + c.height.value - 3 * Scaler.size / 2,
                        left:
                            c.left.value + c.width.value - 3 * Scaler.size / 2,
                        child: MinimizedScalerWidget(
                          // TODO: https://github.com/flutter/flutter/issues/89351
                          cursor: PlatformUtils.isMacOS && !PlatformUtils.isWeb
                              ? SystemMouseCursors.resizeRow
                              : SystemMouseCursors.resizeUpLeftDownRight,
                          width: Scaler.size * 2,
                          height: Scaler.size * 2,
                          onDrag: (dx, dy) => c.resize(
                            context,
                            y: ScaleModeY.bottom,
                            x: ScaleModeX.right,
                            dx: -dx,
                            dy: -dy,
                          ),
                        ),
                      );
                    }),

                    Obx(() {
                      return Positioned(
                        left: c.left.value,
                        top: c.top.value,
                        width: c.width.value,
                        height: c.height.value,
                        child: Material(
                          type: MaterialType.card,
                          borderRadius: BorderRadius.circular(10),
                          elevation: 10,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: DesktopScaffoldWidget(
                                  content: content,
                                  ui: ui,
                                ),
                              ),
                              ClipRect(child: Stack(children: footer)),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }

              // If the call popup is not [minimized], then return the [scaffold].
              return DesktopScaffoldWidget(
                content: content,
                ui: ui,
              );
            },
          );
        });
  }
}

/// [Draggable] data consisting of a [participant] and its [chatId].
class DesktopDragData {
  const DesktopDragData(this.participant, this.chatId);

  /// [Participant] this [_DesktopDragData] represents.
  final Participant participant;

  /// [ChatId] of the [CallView] this [participant] takes place in.
  final ChatId chatId;

  @override
  bool operator ==(Object other) =>
      other is DesktopDragData &&
      participant == other.participant &&
      chatId == other.chatId;

  @override
  int get hashCode => participant.hashCode;
}
