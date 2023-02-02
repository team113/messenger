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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../controller.dart';
import '../widget/animated_delayed_scale.dart';
import '../widget/call_cover.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/dock.dart';
import '../widget/hint.dart';
import '../widget/participant.dart';
import '../widget/reorderable_fit.dart';
import '../widget/scaler.dart';
import '../widget/tooltip_button.dart';
import '../widget/video_view.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';

/// Returns a desktop design of a [CallView].
Widget desktopCall(CallController c, BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Call stackable content.
      List<Widget> content = [
        SvgLoader.asset(
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
                color: const Color(0x4D165084),
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
                          bool isIncoming =
                              c.state.value != OngoingCallState.active &&
                                  c.state.value != OngoingCallState.joining &&
                                  !(c.outgoing ||
                                      c.state.value == OngoingCallState.local);

                          bool isDialog =
                              c.chat.value?.chat.value.isDialog == true;

                          final Widget child;

                          if (!isIncoming) {
                            child = _primaryView(c);
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
                color: const Color(0x70000000),
              ),
            );
          }

          return AnimatedSwitcher(duration: 200.milliseconds, child: child);
        }),

        // Dim the primary view in a non-active call.
        Obx(() {
          final Widget child;

          if (!c.connectionLost.value) {
            child = const SizedBox();
          } else {
            child = IgnorePointer(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xA0000000),
                padding: const EdgeInsets.all(21.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SpinKitDoubleBounce(
                        color: Color(0xFFEEEEEE),
                        size: 100 / 1.5,
                        duration: Duration(milliseconds: 4500),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Reconnecting...',
                        style: Theme.of(context).textTheme.caption?.copyWith(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
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
        _secondaryTarget(c),
      ]);

      /// Builds the [Dock] containing the [CallController.buttons].
      Widget dock() {
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
      }

      /// Builds the more panel containing the [CallController.panel].
      Widget launchpad() {
        Widget builder(
          BuildContext context,
          List<CallButton?> candidate,
          List<dynamic> rejected,
        ) {
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
        }

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
                      builder: builder,
                    )
                  : Container(),
            );
          }),
        );
      }

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
                    dock(),
                    launchpad(),
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
                      child: callTitle(c),
                    ),
                  )
                : Container(key: UniqueKey()),
          );
        }),

        // Sliding from the top info header.
        if (WebUtils.isPopup)
          Obx(() {
            return Align(
              alignment: Alignment.topCenter,
              child: AnimatedSlider(
                duration: 400.milliseconds,
                translate: false,
                beginOffset: const Offset(0, -1),
                endOffset: const Offset(0, 0),
                isOpen: c.state.value == OngoingCallState.active &&
                    c.showHeader.value &&
                    c.fullscreen.value,
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
                        style: context.textTheme.bodyText1?.copyWith(
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
          final bool isIncoming = c.state.value != OngoingCallState.active &&
              c.state.value != OngoingCallState.joining &&
              !(c.outgoing || c.state.value == OngoingCallState.local);

          if (isIncoming) {
            return const SizedBox();
          }

          return _secondaryView(c, context);
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
                  child: _titleBar(context, c),
                ),
              ),
            Expanded(child: Stack(children: [...content, ...ui])),
          ],
        ),
      );

      c.relocateSecondary();
      c.applySecondaryConstraints();

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
              onDragStart: (_) {
                c.secondaryScaled.value = true;
                c.secondaryBottomShifted = null;
              },
              onDragUpdate: onDrag,
              onDragEnd: (_) {
                c.secondaryScaled.value = false;
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

/// Title bar of the call containing information about the call and control
/// buttons.
Widget _titleBar(BuildContext context, CallController c) => Obx(() {
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
                          style: context.textTheme.bodyText1?.copyWith(
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
                      child: SvgLoader.asset(
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

/// [ReorderableFit] of the [CallController.primary] participants.
Widget _primaryView(CallController c) {
  return Obx(() {
    void onDragEnded(_DragData d) {
      c.primaryDrags.value = 0;
      c.draggedRenderer.value = null;
      c.doughDraggedRenderer.value = null;
      c.hoveredRenderer.value = d.participant;
      c.hoveredRendererTimeout = 5;
      c.isCursorHidden.value = false;
    }

    return Stack(
      children: [
        ReorderableFit<_DragData>(
          key: const Key('PrimaryFitView'),
          allowEmptyTarget: true,
          onAdded: (d, i) => c.focus(d.participant),
          onWillAccept: (d) {
            if (d?.chatId == c.chatId.value) {
              if (d?.participant.member.id.userId != c.me.id.userId ||
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
          onOffset: () {
            if (c.minimized.value && !c.fullscreen.value) {
              return Offset(-c.left.value, -c.top.value - 30);
            } else if (!WebUtils.isPopup) {
              return const Offset(0, -30);
            }

            return Offset.zero;
          },
          onDoughBreak: (r) => c.doughDraggedRenderer.value = r.participant,
          onDragEnd: onDragEnded,
          onDragCompleted: onDragEnded,
          onDraggableCanceled: onDragEnded,
          overlayBuilder: (_DragData data) {
            var participant = data.participant;

            return LayoutBuilder(builder: (context, constraints) {
              return Obx(() {
                bool? muted = participant.member.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled
                    : participant.audio.value?.isMuted.value ?? false;

                bool anyDragIsHappening = c.secondaryDrags.value != 0 ||
                    c.primaryDrags.value != 0 ||
                    c.secondaryDragged.value;

                bool isHovered = c.hoveredRenderer.value == participant &&
                    !anyDragIsHappening;

                BoxFit? fit = participant.video.value?.renderer.value == null
                    ? null
                    : c.rendererBoxFit[participant
                            .video.value?.renderer.value!.track
                            .id()] ??
                        RtcVideoView.determineBoxFit(
                          participant.video.value?.renderer.value
                              as RtcVideoRenderer,
                          participant.source,
                          constraints,
                          context,
                        );

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
                              if (participant.video.value?.renderer.value !=
                                  null) ...[
                                if (participant.source ==
                                    MediaSourceKind.Device)
                                  ContextMenuButton(
                                    label: fit == null || fit == BoxFit.cover
                                        ? 'btn_call_do_not_cut_video'.l10n
                                        : 'btn_call_cut_video'.l10n,
                                    onPressed: () {
                                      c.rendererBoxFit[participant
                                          .video.value!.renderer.value!.track
                                          .id()] = fit == null ||
                                              fit == BoxFit.cover
                                          ? BoxFit.contain
                                          : BoxFit.cover;
                                      if (c.focused.isNotEmpty) {
                                        c.focused.refresh();
                                      } else {
                                        c.remotes.refresh();
                                        c.locals.refresh();
                                      }
                                    },
                                  ),
                              ],
                              if (c.primary.length == 1)
                                ContextMenuButton(
                                  label: 'btn_call_uncenter'.l10n,
                                  onPressed: c.focusAll,
                                )
                              else
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
                                ContextMenuButton(
                                  label: 'btn_call_remove_participant'.l10n,
                                  onPressed: () {},
                                  // onPressed: () => c.removeChatMember(
                                  //   participant.member.id.userId,
                                  // ),
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
            });
          },
          decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
          itemConstraints: (_DragData data) {
            final double size = (c.size.longestSide * 0.33).clamp(100, 250);
            return BoxConstraints(maxWidth: size, maxHeight: size);
          },
          itemBuilder: (_DragData data) {
            var participant = data.participant;
            return Obx(() {
              return ParticipantWidget(
                participant,
                key: ObjectKey(participant),
                offstageUntilDetermined: true,
                useCallCover: true,
                respectAspectRatio: true,
                borderRadius: BorderRadius.zero,
                onSizeDetermined: participant.video.value?.renderer.refresh,
                fit: c.rendererBoxFit[
                    participant.video.value?.renderer.value?.track.id() ?? ''],
                expanded: c.doughDraggedRenderer.value == participant,
              );
            });
          },
          children: c.primary.map((e) => _DragData(e, c.chatId.value)).toList(),
        ),
        IgnorePointer(
          child: Obx(() {
            return AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.secondaryDrags.value != 0 && c.primaryTargets.value != 0
                  ? Container(
                      color: const Color(0x40000000),
                      child: Center(
                        child: AnimatedDelayedScale(
                          duration: const Duration(milliseconds: 300),
                          beginScale: 1,
                          endScale: 1.06,
                          child: ConditionalBackdropFilter(
                            condition: !c.minimized.value || c.fullscreen.value,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: !c.minimized.value || c.fullscreen.value
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
      ],
    );
  });
}

/// [ReorderableFit] of the [CallController.secondary] participants.
Widget _secondaryView(CallController c, BuildContext context) {
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
                onDragStart: (_) {
                  c.secondaryBottomShifted = null;
                  c.secondaryScaled.value = true;
                },
                onDragUpdate: onDrag,
                onDragEnd: (_) {
                  c.secondaryScaled.value = false;
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

      void onDragEnded(_DragData d) {
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
                  if (c.secondaryAlignment.value == null) {
                    return IgnorePointer(
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: Stack(
                          children: [
                            Container(color: const Color(0xFF0A1724)),
                            SvgLoader.asset(
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
          ReorderableFit<_DragData>(
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
            overlayBuilder: (_DragData data) {
              var participant = data.participant;

              return Obx(() {
                bool muted = participant.member.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled
                    : participant.audio.value?.isMuted.value ?? false;

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
                                ContextMenuButton(
                                  label: 'btn_call_remove_participant'.l10n,
                                  onPressed: () {},
                                  // onPressed: () => c.removeChatMember(
                                  //   participant.member.id.userId,
                                  // ),
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
            itemConstraints: (_DragData data) {
              final double size = (c.size.longestSide * 0.33).clamp(100, 250);
              return BoxConstraints(maxWidth: size, maxHeight: size);
            },
            itemBuilder: (_DragData data) {
              var participant = data.participant;
              return Obx(
                () => ParticipantWidget(
                  participant,
                  key: ObjectKey(participant),
                  offstageUntilDetermined: true,
                  respectAspectRatio: true,
                  useCallCover: true,
                  borderRadius: BorderRadius.zero,
                  expanded: c.doughDraggedRenderer.value == participant,
                ),
              );
            },
            children:
                c.secondary.map((e) => _DragData(e, c.chatId.value)).toList(),
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
                                    ? const Color(0x9D165084)
                                    : const Color(0xE9165084),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 7),
                                    const Expanded(
                                      child: Text(
                                        'Draggable',
                                        style: TextStyle(color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    InkResponse(
                                      onTap: isAnyDrag ? null : c.focusAll,
                                      child: SvgLoader.asset(
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
                            color: const Color(0x40000000),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 1,
                                        ),
                                        borderRadius: borderRadius,
                                      )
                                    : Border(
                                        top: c.secondaryAlignment.value ==
                                                Alignment.bottomCenter
                                            ? BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                        left: c.secondaryAlignment.value ==
                                                Alignment.centerRight
                                            ? BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                        right: c.secondaryAlignment.value ==
                                                Alignment.centerLeft
                                            ? BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                        bottom: c.secondaryAlignment.value ==
                                                Alignment.topCenter
                                            ? BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 1,
                                              )
                                            : BorderSide.none,
                                      )
                                : c.secondaryAlignment.value == null
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
}

/// [DragTarget] of an empty [_secondaryView].
Widget _secondaryTarget(CallController c) {
  return Obx(() {
    Axis secondaryAxis =
        c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical;

    // Pre-calculate the [ReorderableFit]'s size.
    double panelSize = max(
      ReorderableFit.calculateSize(
        maxSize: c.size.shortestSide / 4,
        constraints: Size(c.size.width, c.size.height - 45),
        axis: c.size.width >= c.size.height ? Axis.horizontal : Axis.vertical,
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
                child: DragTarget<_DragData>(
                  onWillAccept: (d) => d?.chatId == c.chatId.value,
                  onAccept: (_DragData d) {
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
}

/// [Draggable] data consisting of a [participant] and its [chatId].
class _DragData {
  const _DragData(this.participant, this.chatId);

  /// [Participant] this [_DragData] represents.
  final Participant participant;

  /// [ChatId] of the [CallView] this [participant] takes place in.
  final ChatId chatId;

  @override
  bool operator ==(Object other) =>
      other is _DragData &&
      participant == other.participant &&
      chatId == other.chatId;

  @override
  int get hashCode => participant.hashCode;
}
