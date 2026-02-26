// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../controller.dart';
import '../widget/animated_delayed_scale.dart';
import '../widget/call_cover.dart';
import '../widget/dock.dart';
import '../widget/dock_decorator.dart';
import '../widget/double_bounce_indicator.dart';
import '../widget/drop_box.dart';
import '../widget/drop_box_area.dart';
import '../widget/launchpad.dart';
import '../widget/notification.dart';
import '../widget/participant/decorator.dart';
import '../widget/participant/overlay.dart';
import '../widget/participant/widget.dart';
import '../widget/reorderable_fit.dart';
import '../widget/scaler.dart';
import '../widget/title_bar.dart';
import '/config.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';

/// Returns a desktop design of a [CallView].
Widget desktopCall(CallController c, BuildContext context) {
  final style = Theme.of(context).style;

  return LayoutBuilder(
    builder: (context, constraints) {
      // Call stackable content.
      List<Widget> content = [
        const SvgImage.asset(
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
            child: Container(
              height: height,
              width: width,
              color: style.colors.primaryAuxiliaryOpacity90,
            ),
          );
        });
      }

      content.addAll([
        // Call's primary view.
        Column(
          children: [
            Obx(
              () => SizedBox(
                width: double.infinity,
                height:
                    c.secondary.isNotEmpty &&
                        c.secondaryAlignment.value == Alignment.topCenter
                    ? c.secondaryHeight.value
                    : 0,
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Obx(
                    () => SizedBox(
                      height: double.infinity,
                      width:
                          c.secondary.isNotEmpty &&
                              c.secondaryAlignment.value == Alignment.centerLeft
                          ? c.secondaryWidth.value
                          : 0,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Obx(() {
                          final bool isOutgoing =
                              (c.outgoing ||
                                  c.state.value == OngoingCallState.local) &&
                              !c.started;

                          final bool isIncoming =
                              c.state.value != OngoingCallState.active &&
                              c.state.value != OngoingCallState.joining &&
                              !isOutgoing;

                          final Widget child;

                          if (!isIncoming) {
                            child = _primaryView(c);
                          } else {
                            if (c.isDialog) {
                              final RxUser? user = c.chat.value?.members.values
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
                                child = CallCoverWidget(
                                  null,
                                  chat: c.chat.value,
                                );
                              }
                            }
                          }

                          return SafeAnimatedSwitcher(
                            duration: 400.milliseconds,
                            child: child,
                          );
                        }),
                      ],
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                      height: double.infinity,
                      width:
                          c.secondary.isNotEmpty &&
                              c.secondaryAlignment.value ==
                                  Alignment.centerRight
                          ? c.secondaryWidth.value
                          : 0,
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height:
                    c.secondary.isNotEmpty &&
                        c.secondaryAlignment.value == Alignment.bottomCenter
                    ? c.secondaryHeight.value
                    : 0,
              ),
            ),
          ],
        ),

        // Reconnection indicator.
        Obx(() {
          if (!c.connectionLost.value) {
            return const SizedBox();
          }

          return IgnorePointer(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: style.colors.onBackgroundOpacity70,
              padding: const EdgeInsets.all(21.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!Config.disableInfiniteAnimations)
                      const DoubleBounceLoadingIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'label_reconnecting_ellipsis'.l10n,
                      style: style.fonts.normal.regular.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
          );
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
          final Axis secondaryAxis = c.size.width >= c.size.height
              ? Axis.horizontal
              : Axis.vertical;

          /// Pre-calculate the [ReorderableFit]'s size.
          final double panelSize = max(
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

          return SafeAnimatedSwitcher(
            key: const Key('SecondaryTargetAnimatedSwitcher'),
            duration: 200.milliseconds,
            child: c.secondary.isEmpty && c.doughDraggedRenderer.value != null
                ? DropBoxArea<_DragData>(
                    size: panelSize,
                    axis: secondaryAxis,
                    visible: c.primaryDrags.value >= 1,
                    onWillAccept: (d) => d?.chatId == c.chatId.value,
                    onAccept: (_DragData d) {
                      if (secondaryAxis == Axis.horizontal) {
                        c.secondaryAlignment.value = Alignment.centerRight;
                      } else {
                        c.secondaryAlignment.value = Alignment.topCenter;
                      }

                      c.unfocus(d.participant);
                    },
                  )
                : const SizedBox(),
          );
        }),
      ]);

      // Builds the [Dock] containing the [CallController.buttons].
      Widget dock() {
        return Obx(() {
          final bool isOutgoing =
              (c.outgoing || c.state.value == OngoingCallState.local) &&
              !c.started;

          final bool showBottomUi =
              (c.showUi.isTrue ||
              c.draggedButton.value != null ||
              c.state.value != OngoingCallState.active ||
              (c.state.value == OngoingCallState.active &&
                  c.locals.isEmpty &&
                  c.remotes.isEmpty &&
                  c.focused.isEmpty &&
                  c.paneled.isEmpty));

          final bool answer =
              c.state.value != OngoingCallState.joining &&
              c.state.value != OngoingCallState.active &&
              !isOutgoing;

          final Widget child;

          if (answer) {
            child = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 11),
                AcceptAudioButton(
                  c,
                  highlight: !c.withVideo,
                ).build(hinted: false),
                const SizedBox(width: 24),
                AcceptVideoButton(
                  c,
                  highlight: c.withVideo,
                ).build(hinted: false),
                const SizedBox(width: 24),
                DeclineButton(c).build(hinted: false),
                const SizedBox(width: 11),
              ],
            );
          } else {
            child = Dock<CallButton>(
              items: c.buttons,
              itemWidth: CallController.buttonSize,
              itemBuilder: (e) =>
                  e.build(hinted: c.draggedButton.value == null),
              onReorder: (buttons) {
                c.buttons.value = buttons;
                c.relocateSecondary();
              },
              onDragStarted: (b) {
                c.draggedButton.value = b;
                c.draggedFromDock = false;
              },
              onDragEnded: (_) => c.draggedButton.value = null,
              onLeave: (_) => c.displayMore.value = true,
              onWillAccept: (d) => d?.c == c,
            );
          }

          return DockDecorator(
            show: showBottomUi,
            dockKey: c.dockKey,
            onAnimation: () =>
                Future.delayed(Duration.zero, c.relocateSecondary),
            onEnter: (d) => c.keepUi(true),
            onHover: (d) => c.keepUi(true),
            onExit: c.showUi.value && !c.displayMore.value
                ? (d) => c.keepUi(false)
                : (d) => c.keepUi(),
            child: child,
          );
        });
      }

      // Builds the [Launchpad] panel containing the [CallController.panel].
      Widget launchpad() {
        return Obx(() {
          bool enabled =
              c.displayMore.isTrue &&
              c.primaryDrags.value == 0 &&
              c.secondaryDrags.value == 0;

          return Flexible(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: c.displayMore.value ? 1 : 0,
              child: IgnorePointer(
                ignoring: !c.displayMore.value,
                child: Launchpad(
                  onEnter: enabled ? (d) => c.keepUi(true) : null,
                  onHover: enabled ? (d) => c.keepUi(true) : null,
                  onExit: enabled ? (d) => c.keepUi() : null,
                  onAccept: (CallButton data) {
                    if (!c.draggedFromDock) {
                      Future.delayed(Duration.zero, () {
                        if (c.buttons.contains(data)) {
                          c.buttons.remove(data);
                        }
                      });

                      c.draggedButton.value = null;
                    }
                  },
                  onWillAccept: (CallButton? a) =>
                      a?.c == c && a?.isRemovable == true,
                  children: c.panel.map((e) {
                    return DelayedDraggable(
                      feedback: Transform.translate(
                        offset: const Offset(
                          CallController.buttonSize / 2 * -1,
                          CallController.buttonSize / 2 * -1,
                        ),
                        child: e.build(),
                      ),
                      data: e,
                      onDragStarted: () {
                        c.draggedFromDock = true;
                        c.draggedButton.value = e;
                      },
                      onDragCompleted: () => c.draggedButton.value = null,
                      onDragEnd: (_) => c.draggedButton.value = null,
                      onDraggableCanceled: (_, _) =>
                          c.draggedButton.value = null,
                      maxSimultaneousDrags: e.isRemovable ? null : 0,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      child: e.build(hinted: false, big: true, expanded: true),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        });
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
                  children: [dock(), launchpad()],
                ),
              ),
            ],
          ),
        ),
      ];

      List<Widget> ui = [
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

          return SafeAnimatedSwitcher(
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

        // Secondary panel itself.
        Obx(() {
          final bool isIncoming =
              c.state.value != OngoingCallState.active &&
              c.state.value != OngoingCallState.joining &&
              !(c.outgoing || c.state.value == OngoingCallState.local);

          if (isIncoming) {
            return const SizedBox();
          }

          return LayoutBuilder(
            builder: (_, constraints) {
              // Scale the secondary panel after this frame is displayed, as
              // otherwise it invokes re-drawing twice in a frame, resulting in an
              // error.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                c.scaleSecondary(constraints);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => c.relocateSecondary(),
                );
              });

              return _secondaryView(c, context);
            },
          );
        }),

        // [MouseRegion] changing the cursor.
        Obx(() {
          return MouseRegion(
            opaque: false,
            cursor:
                c.draggedRenderer.value != null ||
                    c.doughDraggedRenderer.value != null
                ? CustomMouseCursors.grabbing
                : c.isCursorHidden.value
                ? SystemMouseCursors.none
                : c.hoveredRenderer.value != null
                ? CustomMouseCursors.grab
                : c.hoveredParticipant.value != null
                ? SystemMouseCursors.basic
                : MouseCursor.defer,
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
              onEnter: (_) {
                c.showHeader.value = true;
                c.isCursorHidden.value = false;
              },
              onHover: (_) {
                c.showHeader.value = true;
                c.isCursorHidden.value = false;
              },
              onExit: (_) {
                c.showHeader.value = false;
              },
            ),
          ),
        ),

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
                isOpen:
                    c.state.value == OngoingCallState.active &&
                    c.showHeader.value,
                child: MouseRegion(
                  onEnter: (_) {
                    c.showHeader.value = true;
                    c.headerHovered = true;
                  },
                  onHover: (_) {
                    c.showHeader.value = true;
                    c.headerHovered = true;
                  },
                  onExit: (_) {
                    c.showHeader.value = false;
                    c.headerHovered = false;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        CustomBoxShadow(
                          color: style.colors.onBackgroundOpacity20,
                          blurRadius: 8,
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.fromLTRB(10, 5, 10, 2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.colors.primaryAuxiliaryOpacity90,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.fullscreen.value) ...[
                            Text(
                              'label_call_title'.l10nfmt(c.titleArguments),
                              style: style.fonts.small.regular.onPrimary,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                              color: style.colors.onPrimary,
                              width: 1,
                              height: 12,
                            ),
                          ],
                          AnimatedButton(
                            enabled: c.draggedRenderer.value == null,
                            onPressed: c.layoutAsPrimary,
                            child: const SvgIcon(SvgIcons.callGallery),
                          ),
                          const SizedBox(width: 16),
                          AnimatedButton(
                            enabled: c.draggedRenderer.value == null,
                            onPressed: () =>
                                c.layoutAsSecondary(floating: true),
                            child: const SvgIcon(SvgIcons.callFloating),
                          ),
                          const SizedBox(width: 16),
                          AnimatedButton(
                            enabled: c.draggedRenderer.value == null,
                            onPressed: () =>
                                c.layoutAsSecondary(floating: false),
                            child: const SvgIcon(SvgIcons.callSide),
                          ),
                          const SizedBox(width: 16),
                          AnimatedButton(
                            enabled: c.draggedRenderer.value == null,
                            onPressed: c.toggleFullscreen,
                            child: SvgIcon(
                              c.fullscreen.value
                                  ? SvgIcons.fullscreenExitSmall
                                  : SvgIcons.fullscreenEnterSmall,
                            ),
                          ),
                          if (c.fullscreen.value) const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

        // If there's any notifications to show, display them.
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Obx(() {
              if (c.notifications.isEmpty) {
                return const SizedBox();
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: c.notifications.reversed.take(3).map((e) {
                  return CallNotificationWidget(
                    e,
                    onClose: () => c.notifications.remove(e),
                  );
                }).toList(),
              );
            }),
          ),
        ),

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
                      ),
                    ],
                  ),
                  child: TitleBar(
                    titleBuilder: (_) {
                      return Obx(() {
                        return Text(
                          'label_call_title'.l10nfmt(c.titleArguments),
                        );
                      });
                    },
                    chat: c.chat.value,
                    fullscreen: c.fullscreen.value,
                    height: CallController.titleHeight,
                    toggleFullscreen: c.draggedRenderer.value == null
                        ? c.toggleFullscreen
                        : null,
                    onPrimary: c.draggedRenderer.value == null
                        ? c.layoutAsPrimary
                        : null,
                    onFloating: c.draggedRenderer.value == null
                        ? () => c.layoutAsSecondary(floating: true)
                        : null,
                    onSecondary: c.draggedRenderer.value == null
                        ? () => c.layoutAsSecondary(floating: false)
                        : null,
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

        if (c.hidden.value) {
          return const SizedBox();
        }

        // Returns a [Scaler] scaling the minimized view.
        Widget scaler({
          Key? key,
          MouseCursor cursor = MouseCursor.defer,
          required Function(double, double) onDrag,
          double? width,
          double? height,
        }) {
          return Obx(() {
            return MouseRegion(
              cursor: c.draggedRenderer.value != null
                  ? MouseCursor.defer
                  : cursor,
              child: Scaler(
                key: key,
                onDragUpdate: onDrag,
                onDragEnd: (_) => c.updateSecondaryAttach(),
                width: width ?? Scaler.size,
                height: height ?? Scaler.size,
              ),
            );
          });
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
        // 3) - is a vertical scale point.
        return Stack(
          children: [
            // Top middle.
            Obx(() {
              return Positioned(
                top: c.top.value - Scaler.size / 2,
                left: c.left.value + Scaler.size / 2,
                child: scaler(
                  cursor: SystemMouseCursors.resizeUpDown,
                  width: c.width.value - Scaler.size,
                  onDrag: (dx, dy) =>
                      c.resize(context, y: ScaleModeY.top, dy: dy),
                ),
              );
            }),

            // Center left.
            Obx(() {
              return Positioned(
                top: c.top.value + Scaler.size / 2,
                left: c.left.value - Scaler.size / 2,
                child: scaler(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  height: c.height.value - Scaler.size,
                  onDrag: (dx, dy) =>
                      c.resize(context, x: ScaleModeX.left, dx: dx),
                ),
              );
            }),

            // Center right.
            Obx(() {
              return Positioned(
                top: c.top.value + Scaler.size / 2,
                left: c.left.value + c.width.value - Scaler.size / 2,
                child: scaler(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  height: c.height.value - Scaler.size,
                  onDrag: (dx, dy) =>
                      c.resize(context, x: ScaleModeX.right, dx: -dx),
                ),
              );
            }),

            // Bottom center.
            Obx(() {
              return Positioned(
                top: c.top.value + c.height.value - Scaler.size / 2,
                left: c.left.value + Scaler.size / 2,
                child: scaler(
                  cursor: SystemMouseCursors.resizeUpDown,
                  width: c.width.value - Scaler.size,
                  onDrag: (dx, dy) =>
                      c.resize(context, y: ScaleModeY.bottom, dy: -dy),
                ),
              );
            }),

            // Top left.
            Obx(() {
              return Positioned(
                top: c.top.value - Scaler.size / 2,
                left: c.left.value - Scaler.size / 2,
                child: scaler(
                  cursor: CustomMouseCursors.resizeUpLeftDownRight,
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

            // Top right.
            Obx(() {
              return Positioned(
                top: c.top.value - Scaler.size / 2,
                left: c.left.value + c.width.value - 3 * Scaler.size / 2,
                child: scaler(
                  cursor: CustomMouseCursors.resizeUpRightDownLeft,
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

            // Bottom left.
            Obx(() {
              return Positioned(
                top: c.top.value + c.height.value - 3 * Scaler.size / 2,
                left: c.left.value - Scaler.size / 2,
                child: scaler(
                  cursor: CustomMouseCursors.resizeUpRightDownLeft,
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

            // Bottom right.
            Obx(() {
              return Positioned(
                top: c.top.value + c.height.value - 3 * Scaler.size / 2,
                left: c.left.value + c.width.value - 3 * Scaler.size / 2,
                child: scaler(
                  cursor: CustomMouseCursors.resizeUpLeftDownRight,
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

/// [ReorderableFit] of the [CallController.primary] participants.
Widget _primaryView(CallController c) {
  void onDragEnded(_DragData d) {
    c.primaryDrags.value = 0;
    c.draggedRenderer.value = null;
    c.doughDraggedRenderer.value = null;
    c.hoveredParticipant.value = null;
    c.hoveredRenderer.value = null;
    c.hoveredParticipantTimeout = 5;
    c.isCursorHidden.value = false;
  }

  return Stack(
    children: [
      Obx(() {
        return ReorderableFit<_DragData>(
          key: const Key('PrimaryFitView'),
          allowEmptyTarget: true,
          onAdded: (d, i) => c.focus(d.participant),
          onWillAccept: (d) {
            if (d?.chatId == c.chatId.value) {
              c.primaryTargets.value = 1;
              return true;
            }

            return false;
          },
          onLeave: (b) => c.primaryTargets.value = 0,
          onDragStarted: (r) {
            c.draggedRenderer.value = r.participant;
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

            // TODO: Uncomment when WebAssembly performance is fixed.
            // return LayoutBuilder(
            //               builder: (context, constraints) {
            return Obx(() {
              final bool? muted =
                  participant.member.owner == MediaOwnerKind.local
                  ? !c.audioState.value.isEnabled
                  : null;

              final bool anyDragIsHappening =
                  c.secondaryDrags.value != 0 ||
                  c.primaryDrags.value != 0 ||
                  c.secondaryDragged.value;

              final bool isHovered =
                  c.hoveredParticipant.value == participant &&
                  !anyDragIsHappening;

              final String? id = participant.video.value?.renderer.value?.track
                  .id();

              final BoxFit? fit =
                  participant.video.value?.renderer.value == null
                  ? null
                  : c.rendererBoxFit[id] ?? participant.fit.value;

              return MouseRegion(
                opaque: false,
                onEnter: (d) {
                  if (c.draggedRenderer.value == null) {
                    c.hoveredParticipant.value = data.participant;
                    c.hoveredParticipantTimeout = 5;
                    c.isCursorHidden.value = false;
                  }
                },
                onHover: (d) {
                  if (c.draggedRenderer.value == null) {
                    c.hoveredParticipant.value = data.participant;
                    c.hoveredParticipantTimeout = 5;
                    c.isCursorHidden.value = false;
                  }
                },
                onExit: (d) {
                  c.hoveredParticipantTimeout = 0;
                  c.hoveredParticipant.value = null;
                  c.isCursorHidden.value = false;
                },
                child: AnimatedOpacity(
                  duration: 200.milliseconds,
                  opacity: c.draggedRenderer.value == data.participant ? 0 : 1,
                  child: ContextMenuRegion(
                    key: ObjectKey(participant),
                    preventContextMenu: true,
                    actions: [
                      if (participant.video.value?.renderer.value != null) ...[
                        if (participant.source == MediaSourceKind.device)
                          ContextMenuButton(
                            label: fit == null || fit == BoxFit.cover
                                ? 'btn_call_do_not_cut_video'.l10n
                                : 'btn_call_cut_video'.l10n,
                            onPressed: () {
                              c.rendererBoxFit[id!] =
                                  fit == null || fit == BoxFit.cover
                                  ? BoxFit.contain
                                  : BoxFit.cover;

                              if (c.focused.isNotEmpty) {
                                c.focused.refresh();
                              } else {
                                c.remotes.refresh();
                                c.locals.refresh();
                              }
                            },
                            trailing: SvgIcon(
                              fit == null || fit == BoxFit.cover
                                  ? SvgIcons.callNotCutVideo
                                  : SvgIcons.callCutVideo,
                            ),
                            inverted: SvgIcon(
                              fit == null || fit == BoxFit.cover
                                  ? SvgIcons.callNotCutVideoWhite
                                  : SvgIcons.callCutVideoWhite,
                            ),
                          ),
                      ],
                      if (c.primary.length == 1)
                        ContextMenuButton(
                          label: 'btn_call_uncenter'.l10n,
                          onPressed: c.focusAll,
                          trailing: SvgIcon(SvgIcons.callDeCenter),
                          inverted: SvgIcon(SvgIcons.callDeCenterWhite),
                        )
                      else
                        ContextMenuButton(
                          label: 'btn_call_center'.l10n,
                          onPressed: () => c.center(participant),
                          trailing: SvgIcon(SvgIcons.callCenter),
                          inverted: SvgIcon(SvgIcons.callCenterWhite),
                        ),
                      if (participant.member.id != c.me.id) ...[
                        if (participant
                                .video
                                .value
                                ?.direction
                                .value
                                .isEmitting ??
                            false)
                          ContextMenuButton(
                            label:
                                participant.video.value?.renderer.value != null
                                ? 'btn_call_disable_video'.l10n
                                : 'btn_call_enable_video'.l10n,
                            onPressed: () => c.toggleVideoEnabled(participant),
                            trailing: SvgIcon(
                              participant.video.value?.renderer.value != null
                                  ? SvgIcons.callDisableVideo
                                  : SvgIcons.callEnableVideo,
                            ),
                            inverted: SvgIcon(
                              participant.video.value?.renderer.value != null
                                  ? SvgIcons.callDisableVideoWhite
                                  : SvgIcons.callEnableVideoWhite,
                            ),
                          ),
                        if (participant
                                .audio
                                .value
                                ?.direction
                                .value
                                .isEmitting ??
                            false)
                          ContextMenuButton(
                            label:
                                (participant
                                        .audio
                                        .value
                                        ?.direction
                                        .value
                                        .isEnabled ==
                                    true)
                                ? 'btn_call_disable_audio'.l10n
                                : 'btn_call_enable_audio'.l10n,
                            onPressed: () => c.toggleAudioEnabled(participant),
                            trailing: SvgIcon(
                              participant
                                          .audio
                                          .value
                                          ?.direction
                                          .value
                                          .isEnabled ==
                                      true
                                  ? SvgIcons.callDisableAudio
                                  : SvgIcons.callEnableAudio,
                            ),
                            inverted: SvgIcon(
                              participant
                                          .audio
                                          .value
                                          ?.direction
                                          .value
                                          .isEnabled ==
                                      true
                                  ? SvgIcons.callDisableAudioWhite
                                  : SvgIcons.callEnableAudioWhite,
                            ),
                          ),
                        if (participant.member.isDialing.isFalse)
                          ContextMenuButton(
                            label: 'btn_call_remove_participant'.l10n,
                            onPressed: () => c.removeChatCallMember(
                              participant.member.id.userId,
                            ),
                            trailing: SvgIcon(SvgIcons.callRemoveFrom),
                            inverted: SvgIcon(SvgIcons.callRemoveFromWhite),
                          ),
                      ] else ...[
                        ContextMenuButton(
                          label: c.videoState.value.isEnabled
                              ? 'btn_call_video_off'.l10n
                              : 'btn_call_video_on'.l10n,
                          onPressed: c.toggleVideo,
                          trailing: SvgIcon(
                            c.videoState.value.isEnabled
                                ? SvgIcons.callTurnVideoOff
                                : SvgIcons.callTurnVideoOn,
                          ),
                          inverted: SvgIcon(
                            c.videoState.value.isEnabled
                                ? SvgIcons.callTurnVideoOffWhite
                                : SvgIcons.callTurnVideoOnWhite,
                          ),
                        ),
                        ContextMenuButton(
                          label: c.audioState.value.isEnabled
                              ? 'btn_call_audio_off'.l10n
                              : 'btn_call_audio_on'.l10n,
                          onPressed: c.toggleAudio,
                          trailing: SvgIcon(
                            c.audioState.value.isEnabled
                                ? SvgIcons.callMute
                                : SvgIcons.callUnmute,
                          ),
                          inverted: SvgIcon(
                            c.audioState.value.isEnabled
                                ? SvgIcons.callMuteWhite
                                : SvgIcons.callUnmuteWhite,
                          ),
                        ),
                      ],
                    ],
                    child: IgnorePointer(
                      child: ParticipantOverlayWidget(
                        participant,
                        key: ObjectKey(participant),
                        muted: muted,
                        hovered: isHovered,
                      ),
                    ),
                  ),
                ),
              );
            });
          },
          itemConstraints: (_DragData data) {
            final double size = (c.size.longestSide * 0.33).clamp(100, 250);
            return BoxConstraints(maxWidth: size, maxHeight: size);
          },
          itemBuilder: (_DragData data) {
            final Participant participant = data.participant;

            return Obx(() {
              return ParticipantWidget(
                participant,
                key: ObjectKey(participant),
                offstageUntilDetermined: true,
                respectAspectRatio: true,
                borderRadius: BorderRadius.zero,
                fit:
                    c.rendererBoxFit[participant
                            .video
                            .value
                            ?.renderer
                            .value
                            ?.track
                            .id() ??
                        ''],
                onHovered: (v) {
                  if (c.draggedRenderer.value == null) {
                    c.hoveredRenderer.value = v ? participant : null;
                  }
                },
              );
            });
          },
          children: c.primary.map((e) => _DragData(e, c.chatId.value)).toList(),
        );
      }),
      Obx(() {
        return IgnorePointer(
          child: AnimatedOpacity(
            opacity: c.secondaryDrags.value != 0 && c.primaryTargets.value != 0
                ? 1
                : 0,
            duration: const Duration(milliseconds: 300),
            child: DropBox(withBlur: !c.minimized.value || c.fullscreen.value),
          ),
        );
      }),
    ],
  );
}

/// [ReorderableFit] of the [CallController.secondary] participants.
Widget _secondaryView(CallController c, BuildContext context) {
  final style = Theme.of(context).style;

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
              cursor: c.draggedRenderer.value == null
                  ? cursor
                  : MouseCursor.defer,
              child: Scaler(
                key: key,
                onDragUpdate: onDrag,
                onDragEnd: (_) => c.updateSecondaryAttach(),
                width: width ?? Scaler.size,
                height: height ?? Scaler.size,
              ),
            );
          });
        }

        Widget widget = Container();

        switch (alignment) {
          case Alignment.centerLeft:
            widget = scaler(
              cursor: SystemMouseCursors.resizeLeftRight,
              height: height - Scaler.size,
              onDrag: (dx, dy) =>
                  c.resizeSecondary(context, x: ScaleModeX.left, dx: dx),
            );

          case Alignment.centerRight:
            widget = scaler(
              cursor: SystemMouseCursors.resizeLeftRight,
              height: height - Scaler.size,
              onDrag: (dx, dy) =>
                  c.resizeSecondary(context, x: ScaleModeX.right, dx: -dx),
            );

          case Alignment.bottomCenter:
            widget = scaler(
              cursor: SystemMouseCursors.resizeUpDown,
              width: width - Scaler.size,
              onDrag: (dx, dy) =>
                  c.resizeSecondary(context, y: ScaleModeY.bottom, dy: -dy),
            );

          case Alignment.topCenter:
            widget = scaler(
              cursor: SystemMouseCursors.resizeUpDown,
              width: width - Scaler.size,
              onDrag: (dx, dy) =>
                  c.resizeSecondary(context, y: ScaleModeY.top, dy: dy),
            );

          case Alignment.topLeft:
            widget = scaler(
              cursor: CustomMouseCursors.resizeUpLeftDownRight,
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

          case Alignment.topRight:
            widget = scaler(
              cursor: CustomMouseCursors.resizeUpRightDownLeft,
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

          case Alignment.bottomLeft:
            widget = scaler(
              cursor: CustomMouseCursors.resizeUpRightDownLeft,
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

          case Alignment.bottomRight:
            widget = scaler(
              cursor: CustomMouseCursors.resizeUpLeftDownRight,
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

      // Returns the [Positioned] aligned with the provided [align].
      Widget positionedBoilerplate(Alignment? alignment, Alignment align) {
        return Positioned(
          left: left == null ? null : (left - Scaler.size / 2),
          right: right == null ? null : (right - Scaler.size / 2),
          top: top == null ? null : (top - Scaler.size / 2),
          bottom: bottom == null ? null : (bottom - Scaler.size / 2),
          child: SizedBox(
            width: width + Scaler.size,
            height: height + Scaler.size,
            child: Obx(
              () => c.secondaryAlignment.value == alignment
                  ? buildDragHandle(align)
                  : Container(),
            ),
          ),
        );
      }

      void onDragEnded(_DragData d) {
        c.secondaryDrags.value = 0;
        c.draggedRenderer.value = null;
        c.doughDraggedRenderer.value = null;
        c.hoveredParticipant.value = null;
        c.hoveredRenderer.value = null;
        c.hoveredParticipantTimeout = 5;
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
                        ),
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
                            const SvgImage.asset(
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

          positionedBoilerplate(null, Alignment.centerLeft),
          positionedBoilerplate(null, Alignment.centerRight),
          positionedBoilerplate(null, Alignment.bottomCenter),
          positionedBoilerplate(null, Alignment.topCenter),
          positionedBoilerplate(null, Alignment.topLeft),
          positionedBoilerplate(null, Alignment.topRight),
          positionedBoilerplate(null, Alignment.bottomLeft),
          positionedBoilerplate(null, Alignment.bottomRight),

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
                bool? muted = participant.member.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled
                    : null;

                bool anyDragIsHappening =
                    c.secondaryDrags.value != 0 ||
                    c.primaryDrags.value != 0 ||
                    c.secondaryDragged.value;

                bool isHovered =
                    c.hoveredParticipant.value == participant &&
                    !anyDragIsHappening;

                return MouseRegion(
                  opaque: false,
                  onEnter: (d) {
                    if (c.draggedRenderer.value == null) {
                      c.hoveredParticipant.value = data.participant;
                      c.hoveredParticipantTimeout = 5;
                      c.isCursorHidden.value = false;
                    }
                  },
                  onHover: (d) {
                    if (c.draggedRenderer.value == null) {
                      c.hoveredParticipant.value = data.participant;
                      c.hoveredParticipantTimeout = 5;
                      c.isCursorHidden.value = false;
                    }
                  },
                  onExit: (d) {
                    c.hoveredParticipantTimeout = 0;
                    c.hoveredParticipant.value = null;
                    c.isCursorHidden.value = false;
                  },
                  child: SafeAnimatedSwitcher(
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
                                trailing: SvgIcon(SvgIcons.callCenter),
                                inverted: SvgIcon(SvgIcons.callCenterWhite),
                              ),
                              if (participant.member.id != c.me.id) ...[
                                if (participant
                                        .video
                                        .value
                                        ?.direction
                                        .value
                                        .isEmitting ??
                                    false)
                                  ContextMenuButton(
                                    label:
                                        participant
                                                .video
                                                .value
                                                ?.renderer
                                                .value !=
                                            null
                                        ? 'btn_call_disable_video'.l10n
                                        : 'btn_call_enable_video'.l10n,
                                    onPressed: () =>
                                        c.toggleVideoEnabled(participant),
                                    trailing: SvgIcon(
                                      participant.video.value?.renderer.value !=
                                              null
                                          ? SvgIcons.callDisableVideo
                                          : SvgIcons.callEnableVideo,
                                    ),
                                    inverted: SvgIcon(
                                      participant.video.value?.renderer.value !=
                                              null
                                          ? SvgIcons.callDisableVideoWhite
                                          : SvgIcons.callEnableVideoWhite,
                                    ),
                                  ),
                                if (participant
                                        .audio
                                        .value
                                        ?.direction
                                        .value
                                        .isEmitting ??
                                    false)
                                  ContextMenuButton(
                                    label:
                                        (participant
                                                .audio
                                                .value
                                                ?.direction
                                                .value
                                                .isEnabled ==
                                            true)
                                        ? 'btn_call_disable_audio'.l10n
                                        : 'btn_call_enable_audio'.l10n,
                                    onPressed: () =>
                                        c.toggleAudioEnabled(participant),
                                    trailing: SvgIcon(
                                      participant
                                                  .audio
                                                  .value
                                                  ?.direction
                                                  .value
                                                  .isEnabled ==
                                              true
                                          ? SvgIcons.callDisableAudio
                                          : SvgIcons.callEnableAudio,
                                    ),
                                    inverted: SvgIcon(
                                      participant
                                                  .audio
                                                  .value
                                                  ?.direction
                                                  .value
                                                  .isEnabled ==
                                              true
                                          ? SvgIcons.callDisableAudioWhite
                                          : SvgIcons.callEnableAudioWhite,
                                    ),
                                  ),
                                if (participant.member.isDialing.isFalse)
                                  ContextMenuButton(
                                    label: 'btn_call_remove_participant'.l10n,
                                    onPressed: () => c.removeChatCallMember(
                                      participant.member.id.userId,
                                    ),
                                    trailing: SvgIcon(SvgIcons.callRemoveFrom),
                                    inverted: SvgIcon(
                                      SvgIcons.callRemoveFromWhite,
                                    ),
                                  ),
                              ] else ...[
                                ContextMenuButton(
                                  label: c.videoState.value.isEnabled
                                      ? 'btn_call_video_off'.l10n
                                      : 'btn_call_video_on'.l10n,
                                  onPressed: c.toggleVideo,
                                  trailing: SvgIcon(
                                    c.videoState.value.isEnabled
                                        ? SvgIcons.callTurnVideoOff
                                        : SvgIcons.callTurnVideoOn,
                                  ),
                                  inverted: SvgIcon(
                                    c.videoState.value.isEnabled
                                        ? SvgIcons.callTurnVideoOffWhite
                                        : SvgIcons.callTurnVideoOnWhite,
                                  ),
                                ),
                                ContextMenuButton(
                                  label: c.audioState.value.isEnabled
                                      ? 'btn_call_audio_off'.l10n
                                      : 'btn_call_audio_on'.l10n,
                                  onPressed: c.toggleAudio,
                                  trailing: SvgIcon(
                                    c.audioState.value.isEnabled
                                        ? SvgIcons.callMute
                                        : SvgIcons.callUnmute,
                                  ),
                                  inverted: SvgIcon(
                                    c.audioState.value.isEnabled
                                        ? SvgIcons.callMuteWhite
                                        : SvgIcons.callUnmuteWhite,
                                  ),
                                ),
                              ],
                            ],
                            child: IgnorePointer(
                              child: ParticipantOverlayWidget(
                                participant,
                                key: ObjectKey(participant),
                                muted: muted,
                                hovered: isHovered,
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
              return ParticipantWidget(
                data.participant,
                key: ObjectKey(data.participant),
                offstageUntilDetermined: true,
                respectAspectRatio: true,
                borderRadius: BorderRadius.zero,
                onHovered: (v) {
                  if (c.draggedRenderer.value == null) {
                    c.hoveredRenderer.value = v ? data.participant : null;
                  }
                },
              );
            },
            children: c.secondary
                .map((e) => _DragData(e, c.chatId.value))
                .toList(),
            borderRadius: c.secondaryAlignment.value == null
                ? borderRadius
                : null,
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
                child: SizedBox(width: width, height: height),
              ),
            ),
          ),

          // Sliding from top draggable title bar.
          if (c.primaryDrags.value == 0)
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
                            : c.secondaryDragged.isTrue
                            ? CustomMouseCursors.grabbing
                            : CustomMouseCursors.grab,
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
                              c.secondaryLeft.value ??=
                                  c.size.width -
                                  c.secondaryWidth.value -
                                  (c.secondaryRight.value ?? 0);
                              c.secondaryTop.value ??=
                                  c.size.height -
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
                              child: ColoredBox(
                                color: style.colors.onSecondaryOpacity88,
                                child: Row(
                                  children: [
                                    const Spacer(),
                                    AnimatedButton(
                                      enabled: !isAnyDrag,
                                      onPressed: c.focusAll,
                                      decorator: (child) => Container(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          0,
                                          12,
                                          0,
                                        ),
                                        height: double.infinity,
                                        child: child,
                                      ),
                                      child: const SvgIcon(SvgIcons.closeSmall),
                                    ),
                                  ],
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

          positionedBoilerplate(Alignment.centerRight, Alignment.centerLeft),
          positionedBoilerplate(Alignment.centerLeft, Alignment.centerRight),
          positionedBoilerplate(Alignment.topCenter, Alignment.bottomCenter),
          positionedBoilerplate(Alignment.bottomCenter, Alignment.topCenter),

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
                  return SafeAnimatedSwitcher(
                    duration: 200.milliseconds,
                    child:
                        c.primaryDrags.value != 0 &&
                            c.secondaryTargets.value != 0
                        ? Container(
                            color: style.colors.onBackgroundOpacity27,
                            child: Center(
                              child: AnimatedDelayedScale(
                                duration: const Duration(milliseconds: 300),
                                beginScale: 1,
                                endScale: 1.06,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color:
                                        !c.minimized.value || c.fullscreen.value
                                        ? style.colors.onBackgroundOpacity27
                                        : style.colors.onBackgroundOpacity50,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: SvgIcon(SvgIcons.addBigger),
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
                            shape:
                                c.secondaryHovered.value ||
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
                                          top:
                                              c.secondaryAlignment.value ==
                                                  Alignment.bottomCenter
                                              ? BorderSide(
                                                  color: style.colors.secondary,
                                                  width: 1,
                                                )
                                              : BorderSide.none,
                                          left:
                                              c.secondaryAlignment.value ==
                                                  Alignment.centerRight
                                              ? BorderSide(
                                                  color: style.colors.secondary,
                                                  width: 1,
                                                )
                                              : BorderSide.none,
                                          right:
                                              c.secondaryAlignment.value ==
                                                  Alignment.centerLeft
                                              ? BorderSide(
                                                  color: style.colors.secondary,
                                                  width: 1,
                                                )
                                              : BorderSide.none,
                                          bottom:
                                              c.secondaryAlignment.value ==
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
                                      color: style.colors.secondary.withValues(
                                        alpha: 0,
                                      ),
                                      width: 1,
                                    ),
                                    borderRadius: borderRadius,
                                  )
                                : Border.all(
                                    color: style.colors.secondary.withValues(
                                      alpha: 0,
                                    ),
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
