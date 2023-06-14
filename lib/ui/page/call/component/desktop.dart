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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/ui/page/call/widget/desktop/launchpad.dart';
import 'package:messenger/ui/page/call/widget/desktop/primary_view.dart';
import 'package:messenger/ui/page/call/widget/desktop/secondary_target.dart';
import 'package:messenger/ui/page/call/widget/desktop/title_bar.dart';

import '../../home/widget/avatar.dart';
import '../controller.dart';
import '../widget/animated_delayed_scale.dart';
import '../widget/call_cover.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/desktop/call_dock.dart';
import '../widget/dock.dart';
import '../widget/hint.dart';
import '../widget/participant/decorator.dart';
import '../widget/participant/overlay.dart';
import '../widget/participant/widget.dart';
import '../widget/reorderable_fit.dart';
import '../widget/scaler.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';

/// Returns a desktop design of a [CallView].
Widget desktopCall(CallController c, BuildContext context) {
  final Style style = Theme.of(context).extension<Style>()!;

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

      // Secondary view possible alignment.
      Widget possibleContainer() {
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
                color: style.colors.onSecondaryOpacity20,
              ),
            ),
          );
        });
      }

      content.addAll([
        // Call's primary view.
        Column(
          children: [
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: c.secondary.isNotEmpty &&
                          c.secondaryAlignment.value == Alignment.topCenter
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
                                  c.state.value == OngoingCallState.local) &&
                              !c.started;

                          final bool isIncoming =
                              c.state.value != OngoingCallState.active &&
                                  c.state.value != OngoingCallState.joining &&
                                  !isOutgoing;

                          final bool isDialog =
                              c.chat.value?.chat.value.isDialog == true;

                          final Widget child;

                          if (!isIncoming) {
                            child = PrimaryView(
                              me: c.me,
                              primary: c.primary,
                              audioState: c.audioState.value,
                              draggedRenderer: c.draggedRenderer.value,
                              isCursorHidden: c.isCursorHidden.value,
                              rendererBoxFit: c.rendererBoxFit,
                              focused: c.focused,
                              remotes: c.remotes,
                              locals: c.locals,
                              audioLabel: c.audioState.value.isEnabled
                                  ? 'btn_call_audio_off'.l10n
                                  : 'btn_call_audio_on'.l10n,
                              videoLabel: c.videoState.value.isEnabled
                                  ? 'btn_call_video_off'.l10n
                                  : 'btn_call_video_on'.l10n,
                              center: c.center,
                              toggleAudioEnabled: c.toggleAudioEnabled,
                              toggleVideoEnabled: c.toggleVideoEnabled,
                              removeChatCallMember: c.removeChatCallMember,
                              toggleAudio: c.toggleAudio,
                              toggleVideo: c.toggleVideo,
                              uncenter: c.focusAll,
                              itemConstraintsSize:
                                  (c.size.longestSide * 0.33).clamp(100, 250),
                              condition:
                                  !c.minimized.value || c.fullscreen.value,
                              anyDragIsHappening: c.secondaryDrags.value != 0 ||
                                  c.primaryDrags.value != 0 ||
                                  c.secondaryDragged.value,
                              targetOpacity: c.secondaryDrags.value != 0 &&
                                      c.primaryTargets.value != 0
                                  ? 1
                                  : 0,
                              color: !c.minimized.value || c.fullscreen.value
                                  ? style.colors.onBackgroundOpacity27
                                  : style.colors.onBackgroundOpacity50,
                              onAdded: (d, i) => c.focus(d.participant),
                              onWillAccept: (d) {
                                if (d?.chatId == c.chatId.value) {
                                  if (d?.participant.member.id.userId !=
                                          c.me.id.userId ||
                                      d?.participant.video.value?.source !=
                                          MediaSourceKind.Display) {
                                    c.primaryTargets.value = 1;
                                  }

                                  return true;
                                }

                                return false;
                              },
                              onLeave: (b) => c.primaryTargets.value = 0,
                              onDragStarted: (r) {
                                c.draggedRenderer.value = r.participant;
                                c.showDragAndDropVideosHint = false;
                                c.primaryDrags.value = 1;
                                c.keepUi(false);
                              },
                              onDragEnded: (DragData d) {
                                c.primaryDrags.value = 0;
                                c.draggedRenderer.value = null;
                                c.doughDraggedRenderer.value = null;
                                c.hoveredRenderer.value = d.participant;
                                c.hoveredRendererTimeout = 5;
                                c.isCursorHidden.value = false;
                              },
                              onOffset: () {
                                if (c.minimized.value && !c.fullscreen.value) {
                                  return Offset(
                                      -c.left.value, -c.top.value - 30);
                                } else if (!WebUtils.isPopup) {
                                  return const Offset(0, -30);
                                }

                                return Offset.zero;
                              },
                              onDoughBreak: (r) =>
                                  c.doughDraggedRenderer.value = r.participant,
                              onExit: (d) {
                                c.hoveredRendererTimeout = 0;
                                c.hoveredRenderer.value = null;
                                c.isCursorHidden.value = false;
                              },
                              refreshParticipants: () {
                                if (c.focused.isNotEmpty) {
                                  c.focused.refresh();
                                } else {
                                  c.remotes.refresh();
                                  c.locals.refresh();
                                }
                              },
                              children: c.primary
                                  .map((e) => DragData(e, c.chatId.value))
                                  .toList(),
                            );
                          } else {
                            if (isDialog) {
                              final User? user = c.chat.value?.members.values
                                      .firstWhereOrNull(
                                        (e) => e.id != c.me.id.userId,
                                      )
                                      ?.user
                                      .value ??
                                  c.chat.value?.chat.value.members
                                      .firstWhereOrNull(
                                        (e) => e.user.id != c.me.id.userId,
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
                          c.secondaryAlignment.value == Alignment.bottomCenter
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
                color: style.colors.onBackgroundOpacity40,
              ),
            );
          }

          return AnimatedSwitcher(duration: 200.milliseconds, child: child);
        }),

        possibleContainer(),

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
              if (c.primaryDrags.value == 0 && c.secondaryDrags.value == 0) {
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
        Obx(() {
          Axis secondaryAxis =
              c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical;

          /// Pre-calculate the [ReorderableFit]'s size.
          double panelSize = max(
            ReorderableFit.calculateSize(
              maxSize: c.size.shortestSide / 4,
              constraints: Size(c.size.width, c.size.height - 45),
              axis: c.size.width >= c.size.height
                  ? Axis.horizontal
                  : Axis.vertical,
              length: c.secondary.length,
            ),
            130,
          );

          return SecondaryTarget(
            size: panelSize,
            axis: secondaryAxis,
            showTarget:
                c.secondary.isEmpty && c.doughDraggedRenderer.value != null,
            drags: c.primaryDrags.value,
            onWillAccept: (d) => d?.chatId == c.chatId.value,
            onAccept: (DragData d) {
              if (secondaryAxis == Axis.horizontal) {
                c.secondaryAlignment.value = Alignment.centerRight;
              } else {
                c.secondaryAlignment.value = Alignment.topCenter;
              }
              c.unfocus(d.participant);
            },
          );
        })
      ]);

      // Footer part of the call with buttons.
      List<Widget> footer = [
        // Animated bottom buttons.
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  verticalDirection: VerticalDirection.up,
                  children: [
                    Obx(() {
                      final bool isOutgoing = (c.outgoing ||
                              c.state.value == OngoingCallState.local) &&
                          !c.started;

                      bool showBottomUi = (c.showUi.isTrue ||
                          c.draggedButton.value != null ||
                          c.state.value != OngoingCallState.active ||
                          (c.state.value == OngoingCallState.active &&
                              c.locals.isEmpty &&
                              c.remotes.isEmpty &&
                              c.focused.isEmpty &&
                              c.paneled.isEmpty));

                      final bool answer =
                          (c.state.value != OngoingCallState.joining &&
                              c.state.value != OngoingCallState.active &&
                              !isOutgoing);

                      return CallDockWidget(
                        dockKey: c.dockKey,
                        isOutgoing: isOutgoing,
                        showBottomUi: showBottomUi,
                        isIncoming: answer,
                        listener: () =>
                            Future.delayed(Duration.zero, c.relocateSecondary),
                        onEnter: (d) => c.keepUi(true),
                        onHover: (d) => c.keepUi(true),
                        onExit: c.showUi.value && !c.displayMore.value
                            ? (d) => c.keepUi(false)
                            : (d) => c.keepUi(),
                        child: Dock<CallButton>(
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
                        ),
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
                    }),
                    Obx(() {
                      bool enabled = c.displayMore.isTrue &&
                          c.primaryDrags.value == 0 &&
                          c.secondaryDrags.value == 0;
                      return LaunchpadWidget(
                        displayMore: c.displayMore.value,
                        test: (e) => e?.c == c,
                        onEnter: enabled ? (d) => c.keepUi(true) : null,
                        onHover: enabled ? (d) => c.keepUi(true) : null,
                        onExit: enabled ? (d) => c.keepUi() : null,
                        onAccept: (CallButton data) {
                          c.buttons.remove(data);
                          c.draggedButton.value = null;
                        },
                        onWillAccept: (CallButton? a) =>
                            a?.c == c && a?.isRemovable == true,
                        paneledItems: c.panel.map((e) {
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
                                  dragAnchorStrategy: pointerDragAnchorStrategy,
                                  child: e.build(hinted: false),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  e.hint,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: style.colors.onPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ],
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
                                          : CallController.titleHeight)),
                              child: HintWidget(
                                text: 'label_hint_drag_n_drop_buttons'.l10n,
                                onTap: () =>
                                    c.showDragAndDropButtonsHint = false,
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
                          .where((e) => e.video.value?.renderer.value != null)
                          .isNotEmpty
                  ? Container(color: style.colors.onBackgroundOpacity27)
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
                      child: callTitle(c),
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
                    boxShadow: [
                      CustomBoxShadow(
                        color: style.colors.onBackgroundOpacity20,
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
                        color: style.colors.onSecondaryOpacity20,
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
                          color: style.colors.onPrimary,
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
          final bool isIncoming = c.state.value != OngoingCallState.active &&
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

            return _secondaryView(c, context);
          });
        }),

        // Show a hint if any renderer is draggable.
        Obx(() {
          final bool hideSecondary = c.size.width < 500 && c.size.height < 500;
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
                              c.secondaryAlignment.value == Alignment.topCenter
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
                          onTap: () => c.showDragAndDropVideosHint = false,
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

      // Combines all the stackable content into [Scaffold].
      Widget scaffold = Scaffold(
        backgroundColor: style.colors.onBackground,
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
                    color: style.colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      CustomBoxShadow(
                        color: style.colors.onBackgroundOpacity20,
                        blurRadius: 8,
                        blurStyle: BlurStyle.outer,
                      )
                    ],
                  ),
                  child: Obx(
                    () => TitleBar(
                      fullscreen: c.fullscreen.value,
                      height: CallController.titleHeight,
                      constraints: BoxConstraints(maxWidth: c.size.width - 60),
                      toggleFullscreen: c.toggleFullscreen,
                      onTap: WebUtils.isPopup
                          ? null
                          : () {
                              router.chat(c.chatId.value);
                              if (c.fullscreen.value) {
                                c.toggleFullscreen();
                              }
                            },
                      children: [
                        const SizedBox(width: 10),
                        AvatarWidget.fromRxChat(c.chat.value, radius: 8),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'label_call_title'.l10nfmt(c.titleArguments),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 13,
                                      color: style.colors.onPrimary,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: Stack(children: [...content, ...ui])),
          ],
        ),
      );

      if (c.minimized.value && !c.fullscreen.value) {
        // Applies constraints on every rebuild.
        // This includes the screen size changes.
        c.applyConstraints(context);

        // Returns a [Scaler] scaling the minimized view.
        Widget scaler({
          Key? key,
          MouseCursor cursor = MouseCursor.defer,
          required Function(double, double) onDrag,
          double? width,
          double? height,
        }) {
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
        }

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
                child: scaler(
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
                child: scaler(
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
                child: scaler(
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
                child: scaler(
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
                child: scaler(
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
                left: c.left.value + c.width.value - 3 * Scaler.size / 2,
                child: scaler(
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
                child: scaler(
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
                left: c.left.value + c.width.value - 3 * Scaler.size / 2,
                child: scaler(
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
                        child: scaffold,
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
      return scaffold;
    },
  );
}

/// [ReorderableFit] of the [CallController.secondary] participants.
Widget _secondaryView(CallController c, BuildContext context) {
  final Style style = Theme.of(context).extension<Style>()!;

  return MediaQuery(
    data: MediaQuery.of(context).copyWith(size: c.size),
    child: Obx(() {
      if (c.secondary.isEmpty) {
        return Container();
      }

      // [BorderRadius] to decorate the secondary panel with.
      final BorderRadius borderRadius = BorderRadius.circular(10);

      double? left, right;
      double? top, bottom;
      Axis? axis;

      if (c.secondaryAlignment.value == Alignment.centerRight) {
        top = 0;
        right = 0;
        axis = Axis.horizontal;
      } else if (c.secondaryAlignment.value == Alignment.centerLeft) {
        top = 0;
        left = 0;
        axis = Axis.horizontal;
      } else if (c.secondaryAlignment.value == Alignment.topCenter) {
        top = 0;
        left = 0;
        axis = Axis.vertical;
      } else if (c.secondaryAlignment.value == Alignment.bottomCenter) {
        bottom = 0;
        left = 0;
        axis = Axis.vertical;
      } else {
        left = c.secondaryLeft.value;
        top = c.secondaryTop.value;
        right = c.secondaryRight.value;
        bottom = c.secondaryBottom.value;

        axis = null;
      }

      double width, height;
      if (axis == Axis.horizontal) {
        width = c.secondaryWidth.value;
        height = c.size.height;
      } else if (axis == Axis.vertical) {
        width = c.size.width;
        height = c.secondaryHeight.value;
      } else {
        width = c.secondaryWidth.value;
        height = c.secondaryHeight.value;
      }

      Widget buildDragHandle(Alignment alignment) {
        // Returns a [Scaler] scaling the secondary view.
        Widget scaler({
          Key? key,
          MouseCursor cursor = MouseCursor.defer,
          Function(double, double)? onDrag,
          double? width,
          double? height,
        }) {
          return Obx(() {
            return MouseRegion(
              cursor:
                  c.draggedRenderer.value == null ? cursor : MouseCursor.defer,
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

        Widget widget = Container();

        if (alignment == Alignment.centerLeft) {
          widget = scaler(
            cursor: SystemMouseCursors.resizeLeftRight,
            height: height - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              x: ScaleModeX.left,
              dx: dx,
            ),
          );
        } else if (alignment == Alignment.centerRight) {
          widget = scaler(
            cursor: SystemMouseCursors.resizeLeftRight,
            height: height - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              x: ScaleModeX.right,
              dx: -dx,
            ),
          );
        } else if (alignment == Alignment.bottomCenter) {
          widget = scaler(
            cursor: SystemMouseCursors.resizeUpDown,
            width: width - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
              context,
              y: ScaleModeY.bottom,
              dy: -dy,
            ),
          );
        } else if (alignment == Alignment.topCenter) {
          widget = scaler(
            cursor: SystemMouseCursors.resizeUpDown,
            width: width - Scaler.size,
            onDrag: (dx, dy) => c.resizeSecondary(
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
            onDrag: (dx, dy) => c.resizeSecondary(
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
            onDrag: (dx, dy) => c.resizeSecondary(
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
            onDrag: (dx, dy) => c.resizeSecondary(
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
      }

      Widget positionedBoilerplate(Widget child) {
        return Positioned(
          left: left == null ? null : (left - Scaler.size / 2),
          right: right == null ? null : (right - Scaler.size / 2),
          top: top == null ? null : (top - Scaler.size / 2),
          bottom: bottom == null ? null : (bottom - Scaler.size / 2),
          child: SizedBox(
            width: width + Scaler.size,
            height: height + Scaler.size,
            child: child,
          ),
        );
      }

      void onDragEnded(DragData d) {
        c.secondaryDrags.value = 0;
        c.draggedRenderer.value = null;
        c.doughDraggedRenderer.value = null;
        c.hoveredRenderer.value = d.participant;
        c.hoveredRendererTimeout = 5;
        c.isCursorHidden.value = false;
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
                if (c.secondaryAlignment.value == null) {
                  return Container(
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
                  if (c.secondaryAlignment.value == null) {
                    return IgnorePointer(
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: Stack(
                          children: [
                            Container(color: style.colors.backgroundAuxiliary),
                            SvgImage.asset(
                              'assets/images/background_dark.svg',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(color: style.colors.onPrimaryOpacity7),
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

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.centerLeft)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.centerRight)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.bottomCenter)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.topCenter)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.topLeft)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.topRight)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.bottomLeft)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == null
                ? buildDragHandle(Alignment.bottomRight)
                : Container(),
          )),

          // Secondary panel itself.
          ReorderableFit<DragData>(
            key: const Key('SecondaryFitView'),
            onAdded: (d, i) => c.unfocus(d.participant),
            onWillAccept: (d) {
              if (d?.chatId == c.chatId.value) {
                c.secondaryTargets.value = 1;
                return true;
              }

              return false;
            },
            onLeave: (b) => c.secondaryTargets.value = 0,
            onDragStarted: (r) {
              c.draggedRenderer.value = r.participant;
              c.showDragAndDropVideosHint = false;
              c.secondaryDrags.value = 1;
              c.displayMore.value = false;
              c.keepUi(false);
            },
            onDoughBreak: (r) => c.doughDraggedRenderer.value = r.participant,
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
            onOffset: () {
              if (c.minimized.value && !c.fullscreen.value) {
                return Offset(-c.left.value, -c.top.value - 30);
              } else if (!WebUtils.isPopup) {
                return const Offset(0, -30);
              }

              return Offset.zero;
            },
            overlayBuilder: (DragData data) {
              var participant = data.participant;

              return Obx(() {
                bool? muted = participant.member.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled
                    : null;

                bool anyDragIsHappening = c.secondaryDrags.value != 0 ||
                    c.primaryDrags.value != 0 ||
                    c.secondaryDragged.value;

                bool isHovered = c.hoveredRenderer.value == participant &&
                    !anyDragIsHappening;

                return MouseRegion(
                  opaque: false,
                  onEnter: (d) {
                    if (c.draggedRenderer.value == null) {
                      c.hoveredRenderer.value = data.participant;
                      c.hoveredRendererTimeout = 5;
                      c.isCursorHidden.value = false;
                    }
                  },
                  onHover: (d) {
                    if (c.draggedRenderer.value == null) {
                      c.hoveredRenderer.value = data.participant;
                      c.hoveredRendererTimeout = 5;
                      c.isCursorHidden.value = false;
                    }
                  },
                  onExit: (d) {
                    c.hoveredRendererTimeout = 0;
                    c.hoveredRenderer.value = null;
                    c.isCursorHidden.value = false;
                  },
                  child: AnimatedSwitcher(
                    duration: 200.milliseconds,
                    child: c.draggedRenderer.value == data.participant
                        ? Container()
                        : ContextMenuRegion(
                            key: ObjectKey(participant),
                            preventContextMenu: true,
                            actions: [
                              ContextMenuButton(
                                label: 'btn_call_center'.l10n,
                                onPressed: () => c.center(participant),
                              ),
                              if (participant.member.id != c.me.id) ...[
                                if (participant.video.value?.direction.value
                                        .isEmitting ??
                                    false)
                                  ContextMenuButton(
                                    label: participant
                                                .video.value?.renderer.value !=
                                            null
                                        ? 'btn_call_disable_video'.l10n
                                        : 'btn_call_enable_video'.l10n,
                                    onPressed: () =>
                                        c.toggleVideoEnabled(participant),
                                  ),
                                if (participant.audio.value?.direction.value
                                        .isEmitting ??
                                    false)
                                  ContextMenuButton(
                                    label: (participant.audio.value?.direction
                                                .value.isEnabled ==
                                            true)
                                        ? 'btn_call_disable_audio'.l10n
                                        : 'btn_call_enable_audio'.l10n,
                                    onPressed: () =>
                                        c.toggleAudioEnabled(participant),
                                  ),
                                if (participant.member.isRedialing.isFalse)
                                  ContextMenuButton(
                                    label: 'btn_call_remove_participant'.l10n,
                                    onPressed: () => c.removeChatCallMember(
                                      participant.member.id.userId,
                                    ),
                                  ),
                              ] else ...[
                                ContextMenuButton(
                                  label: c.videoState.value.isEnabled
                                      ? 'btn_call_video_off'.l10n
                                      : 'btn_call_video_on'.l10n,
                                  onPressed: c.toggleVideo,
                                ),
                                ContextMenuButton(
                                  label: c.audioState.value.isEnabled
                                      ? 'btn_call_audio_off'.l10n
                                      : 'btn_call_audio_on'.l10n,
                                  onPressed: c.toggleAudio,
                                ),
                              ],
                            ],
                            child: IgnorePointer(
                              child: ParticipantOverlayWidget(
                                participant,
                                key: ObjectKey(participant),
                                muted: muted,
                                hovered: isHovered,
                                preferBackdrop:
                                    !c.minimized.value || c.fullscreen.value,
                              ),
                            ),
                          ),
                  ),
                );
              });
            },
            decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
            itemConstraints: (DragData data) {
              final double size = (c.size.longestSide * 0.33).clamp(100, 250);
              return BoxConstraints(maxWidth: size, maxHeight: size);
            },
            itemBuilder: (DragData data) {
              return ParticipantWidget(
                data.participant,
                key: ObjectKey(data.participant),
                offstageUntilDetermined: true,
                respectAspectRatio: true,
                borderRadius: BorderRadius.zero,
              );
            },
            children:
                c.secondary.map((e) => DragData(e, c.chatId.value)).toList(),
            borderRadius:
                c.secondaryAlignment.value == null ? borderRadius : null,
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
              child:
                  IgnorePointer(child: SizedBox(width: width, height: height)),
            ),
          ),

          // Sliding from top draggable title bar.
          Positioned(
            key: c.secondaryKey,
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Obx(() {
              bool isAnyDrag =
                  c.secondaryDrags.value != 0 || c.primaryDrags.value != 0;

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
                        onPanStart: (d) {
                          c.secondaryBottomShifted = null;
                          c.secondaryDragged.value = true;
                          c.displayMore.value = false;
                          c.keepUi(false);

                          c.calculateSecondaryPanning(d.globalPosition);

                          if (c.secondaryAlignment.value != null) {
                            c.secondaryAlignment.value = null;
                            c.updateSecondaryOffset(d.globalPosition);
                          } else {
                            c.secondaryLeft.value ??= c.size.width -
                                c.secondaryWidth.value -
                                (c.secondaryRight.value ?? 0);
                            c.secondaryTop.value ??= c.size.height -
                                c.secondaryHeight.value -
                                (c.secondaryBottom.value ?? 0);
                            c.applySecondaryConstraints();
                          }

                          c.secondaryRight.value = null;
                          c.secondaryBottom.value = null;
                        },
                        onPanUpdate: (d) {
                          c.updateSecondaryOffset(d.globalPosition);
                          c.applySecondaryConstraints();
                        },
                        onPanEnd: (d) {
                          c.secondaryDragged.value = false;
                          if (c.possibleSecondaryAlignment.value != null) {
                            c.secondaryAlignment.value =
                                c.possibleSecondaryAlignment.value;
                            c.possibleSecondaryAlignment.value = null;
                            c.applySecondaryConstraints();
                          } else {
                            c.updateSecondaryAttach();
                          }
                        },
                        child: AnimatedOpacity(
                          duration: 200.milliseconds,
                          key: const ValueKey('TitleBar'),
                          opacity: c.secondaryHovered.value ? 1 : 0,
                          child: ClipRRect(
                            borderRadius: c.secondaryAlignment.value == null
                                ? BorderRadius.only(
                                    topLeft: borderRadius.topLeft,
                                    topRight: borderRadius.topRight,
                                  )
                                : BorderRadius.zero,
                            child: ConditionalBackdropFilter(
                              condition: PlatformUtils.isWeb &&
                                  (c.minimized.isFalse || c.fullscreen.isTrue),
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
                                      onTap: isAnyDrag ? null : c.focusAll,
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

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == Alignment.centerRight
                ? buildDragHandle(Alignment.centerLeft)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == Alignment.centerLeft
                ? buildDragHandle(Alignment.centerRight)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == Alignment.topCenter
                ? buildDragHandle(Alignment.bottomCenter)
                : Container(),
          )),

          positionedBoilerplate(Obx(
            () => c.secondaryAlignment.value == Alignment.bottomCenter
                ? buildDragHandle(Alignment.topCenter)
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
                    child: c.primaryDrags.value != 0 &&
                            c.secondaryTargets.value != 0
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
                                  condition:
                                      !c.minimized.value || c.fullscreen.value,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: !c.minimized.value ||
                                              c.fullscreen.value
                                          ? style.colors.onBackgroundOpacity27
                                          : style.colors.onBackgroundOpacity50,
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
              onEnter: (p) => c.secondaryHovered.value = true,
              onHover: (p) => c.secondaryHovered.value = true,
              onExit: (p) => c.secondaryHovered.value = false,
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
                            shape: c.secondaryHovered.value ||
                                    c.primaryDrags.value != 0
                                ? c.secondaryAlignment.value == null
                                    ? RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: style.colors.secondary,
                                          width: 1,
                                        ),
                                        borderRadius: borderRadius,
                                      )
                                    : Border(
                                        top: c.secondaryAlignment.value ==
                                                Alignment.bottomCenter
                                            ? BorderSide(
                                                color: style.colors.secondary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                        left: c.secondaryAlignment.value ==
                                                Alignment.centerRight
                                            ? BorderSide(
                                                color: style.colors.secondary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                        right: c.secondaryAlignment.value ==
                                                Alignment.centerLeft
                                            ? BorderSide(
                                                color: style.colors.secondary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                        bottom: c.secondaryAlignment.value ==
                                                Alignment.topCenter
                                            ? BorderSide(
                                                color: style.colors.secondary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                      )
                                : c.secondaryAlignment.value == null
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
                  );
                }),
              ),
            ),
          ),
        ],
      );
    }),
  );
}

/// [Draggable] data consisting of a [participant] and its [chatId].
class DragData {
  const DragData(this.participant, this.chatId);

  /// [Participant] this [DragData] represents.
  final Participant participant;

  /// [ChatId] of the [CallView] this [participant] takes place in.
  final ChatId chatId;

  @override
  bool operator ==(Object other) =>
      other is DragData &&
      participant == other.participant &&
      chatId == other.chatId;

  @override
  int get hashCode => participant.hashCode;
}
