// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../controller.dart';
import '../widget/call_cover.dart';
import '../widget/participant.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/fit_view.dart';
import '../widget/fit_wrap.dart';
import '../widget/hint.dart';
import '../widget/scaler.dart';
import '../widget/tooltip_button.dart';
import '../widget/video_view.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'common.dart';

/// Returns a desktop design of a [CallView].
Widget desktopCall(
  CallController c,
  BuildContext context, {
  bool isPopup = false,
}) {
  return Obx(
    () {
      // Indicator whether the call should display a [CallTitle] instead of the
      // title bar.
      bool preferTitle = c.state.value != OngoingCallState.active;

      bool isOutgoing =
          (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;

      bool minimized = c.minimized.value && !c.fullscreen.value;
      bool showUi = (c.showUi.isTrue ||
              c.state.value != OngoingCallState.active ||
              (c.state.value == OngoingCallState.active &&
                  c.locals.isEmpty &&
                  c.remotes.isEmpty &&
                  c.focused.isEmpty &&
                  c.paneled.isEmpty)) &&
          (c.size.width > 300 && c.size.height > 200);

      Axis secondaryAxis = (c.size.width >= c.size.height && !c.panelUp.value)
          ? Axis.horizontal
          : Axis.vertical;

      bool hideSecondary = c.size.width < 500 && c.size.height < 500;
      bool mayDragVideo = !hideSecondary &&
          (c.focused.length > 1 ||
              (c.focused.isEmpty && c.locals.length + c.remotes.length > 1));

      // Participants to display in a fit view.
      List<Participant> primary =
          c.focused.isNotEmpty ? c.focused : [...c.locals, ...c.remotes];

      // Participants to display in a panel.
      List<Participant> secondary = hideSecondary
          ? []
          : c.focused.isNotEmpty
              ? [...c.locals, ...c.paneled, ...c.remotes]
              : c.paneled;

      // Pre-calculate the [FitWrap]'s size.
      double panelSize = FitWrap.calculateSize(
        maxSize: c.size.shortestSide / 4,
        constraints: Size(c.size.width, c.size.height - 45),
        axis: secondaryAxis,
        length: secondary.length,
      );

      // Call stackable content.
      List<Widget> content = [];

      // Layer of [MouseRegion]s to determine the hovered renderer.
      Widget? hoverOverlay;

      // Active call.
      if (c.state.value == OngoingCallState.active) {
        List<Widget> primaryWidgets = primary
            .map((e) => _primaryVideo(
                  c,
                  participant: e,
                  panelSize: panelSize,
                  showUi: showUi,
                  mayDragVideo: mayDragVideo,
                  secondary: secondary,
                  mirror: e.owner == MediaOwnerKind.local &&
                      e.source == MediaSourceKind.Device,
                  hoveredRenderer: c.hoveredRenderer.value,
                ))
            .toList();

        List<Widget> secondaryWidgets = secondary
            .map(
              (e) => _secondaryVideo(
                c,
                participant: e,
                panelSize: panelSize,
                showUi: showUi,
                fit: e.owner == MediaOwnerKind.local &&
                        e.source == MediaSourceKind.Display
                    ? BoxFit.contain
                    : BoxFit.cover,
                mirror: e.owner == MediaOwnerKind.local &&
                    e.source == MediaSourceKind.Device,
              ),
            )
            .toList();

        content = [
          // Call's primary and secondary views.
          Column(
            children: [
              Container(
                child: secondaryWidgets.isEmpty
                    ? null
                    : secondaryAxis == Axis.horizontal
                        ? null
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: panelSize,
                                padding: const EdgeInsets.only(bottom: 1),
                                child: _secondaryView(
                                  c,
                                  secondaryAxis,
                                  secondaryWidgets,
                                ),
                              ),
                              Container(height: 1, color: Colors.white),
                            ],
                          ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _primaryView(c, primaryWidgets)),
                    Container(
                      child: secondaryWidgets.isEmpty
                          ? null
                          : secondaryAxis == Axis.horizontal
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 1, color: Colors.white),
                                    Container(
                                      width: panelSize,
                                      padding: const EdgeInsets.only(left: 1),
                                      child: _secondaryView(
                                        c,
                                        secondaryAxis,
                                        secondaryWidgets,
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Empty drop zone if [secondary] is empty.
          Container(
            child: secondaryWidgets.isEmpty
                ? secondaryAxis == Axis.horizontal
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: panelSize,
                          child: _secondaryTarget(c, panelSize),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          height: panelSize,
                          child: _secondaryTarget(c, panelSize),
                        ),
                      )
                : null,
          ),
        ];

        hoverOverlay = Column(
          children: [
            Container(
              child: secondaryWidgets.isEmpty
                  ? null
                  : secondaryAxis == Axis.horizontal
                      ? null
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 1),
                            _hoverSecondary(c, secondaryAxis, secondary),
                          ],
                        ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _hoverPrimary(c, primary)),
                  Container(
                    child: secondaryWidgets.isEmpty
                        ? null
                        : secondaryAxis == Axis.horizontal
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 1),
                                  _hoverSecondary(c, secondaryAxis, secondary),
                                ],
                              )
                            : null,
                  ),
                ],
              ),
            ),
          ],
        );

        // Show a hint if any renderer is draggable.
        if (!c.isHintDismissed.value && mayDragVideo) {
          content.add(
            Align(
              alignment: Alignment.topRight,
              child: Transform.translate(
                offset: secondaryWidgets.isNotEmpty
                    ? Offset(
                        secondaryAxis == Axis.horizontal ? -panelSize : 0,
                        secondaryAxis == Axis.horizontal ? 0 : panelSize,
                      )
                    : Offset.zero,
                child: SizedBox(
                  width: 240,
                  height: 110,
                  child: HintWidget(
                    text: 'label_hint_drag_n_drop_video'.td,
                    onTap: c.isHintDismissed.toggle,
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        // Call is not active.
        RtcVideoRenderer? local = c.locals.firstOrNull?.video.value ??
            c.paneled.firstOrNull?.video.value;
        var callCover = c.chat.value?.callCover;

        content =
            c.videoState.value == LocalTrackState.disabled || local == null
                ? [CallCoverWidget(callCover)]
                : [RtcVideoView(local, mirror: true, fit: BoxFit.cover)];

        // Display a caller's name if the call is not outgoing and the chat is
        // a group.
        if (!preferTitle &&
            !isOutgoing &&
            c.chat.value?.chat.value.isGroup == true) {
          content.add(
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: (c.minimized.value && !c.fullscreen.value ? 0 : 45) +
                        8),
                child: Text(
                  c.callerName ?? '...',
                  style: context.textTheme.bodyText1?.copyWith(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          );
        }
      }

      // If there's any error to show, display it.
      if (c.errorTimeout.value != 0) {
        content.add(
          Align(
            alignment: Alignment.topRight,
            child: Transform.translate(
              offset: secondary.isNotEmpty
                  ? Offset(
                      secondaryAxis == Axis.horizontal ? -panelSize : 0,
                      secondaryAxis == Axis.horizontal ? 0 : panelSize,
                    )
                  : Offset.zero,
              child: SizedBox(
                width: 240,
                height: 110,
                child: HintWidget(
                  text: '${c.error}.',
                  onTap: () {
                    c.errorTimeout.value = 0;
                  },
                ),
              ),
            ),
          ),
        );
      }

      _padding(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2), child: child);

      List<Widget> buttons = c.state.value == OngoingCallState.active ||
              c.state.value == OngoingCallState.joining
          ? [
              if (PlatformUtils.isDesktop) _padding(screenButton(c, 0.8)),
              if (PlatformUtils.isMobile)
                _padding(
                  c.videoState.value.isEnabled()
                      ? switchButton(c, 0.8)
                      : speakerButton(c, 0.8),
                ),
              _padding(videoButton(c, 0.8)),
              _padding(dropButton(c, 0.8)),
              _padding(audioButton(c, 0.8)),
              _padding(handButton(c, 0.8)),
            ]
          : isOutgoing
              ? [
                  if (PlatformUtils.isMobile)
                    _padding(
                      c.videoState.value.isEnabled()
                          ? switchButton(c)
                          : speakerButton(c),
                    ),
                  _padding(videoButton(c)),
                  _padding(cancelButton(c)),
                  _padding(audioButton(c)),
                ]
              : [
                  _padding(acceptAudioButton(c)),
                  _padding(acceptVideoButton(c)),
                  _padding(declineButton(c)),
                ];

      // Indicator whether the [_activeButtons] should be in a dock or not.
      bool isDocked = c.state.value == OngoingCallState.active ||
          c.state.value == OngoingCallState.joining;

      Widget _activeButtons() => ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDocked
                  ? 330
                  : isOutgoing
                      ? 270
                      : 380,
            ),
            child: Row(
              crossAxisAlignment: isDocked
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: buttons.map((e) => Expanded(child: e)).toList(),
            ),
          );

      // Footer part of the call with buttons.
      List<Widget> footer = [
        // Animated bottom buttons.
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: isDocked ? 5 : 30),
                child: AnimatedSlider(
                  isOpen: showUi,
                  duration: const Duration(milliseconds: 400),
                  translate: false,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Draw a blurred dock with the invisible [_activeButtons]
                      // if [isDocked].
                      if (isDocked)
                        ConditionalBackdropFilter(
                          borderRadius: BorderRadius.circular(30),
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0x55000000),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 5,
                            ),
                            child: Visibility(
                              visible: false,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: _activeButtons(),
                            ),
                          ),
                        ),
                      _activeButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom [MouseRegion] that toggles UI on hover.
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 100,
            width: double.infinity,
            child: MouseRegion(
              opaque: false,
              onEnter: (d) {
                c.isPanelOpen.value = true;
                c.keepUi(true);
              },
              onExit: (d) {
                c.isPanelOpen.value = false;
                if (c.showUi.value) {
                  c.keepUi(false);
                }
              },
            ),
          ),
        ),
      ];

      List<Widget> ui = [
        IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: preferTitle &&
                    primary.where((e) => e.video.value != null).isNotEmpty
                ? Container(color: const Color(0x55000000))
                : null,
          ),
        ),
        // Makes UI to appear on click and handles double tap to toggle
        // fullscreen.
        //
        // Also, if [showTitle] is false, allows dragging the window.
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (d) {
            if ((d.kind != PointerDeviceKind.mouse &&
                    d.kind != PointerDeviceKind.stylus) ||
                !c.handleLmb.value) {
              c.downPosition = d.localPosition;
              c.downButtons = d.buttons;
            }
          },
          onPointerUp: (d) {
            if (c.downButtons & kPrimaryButton != 0 &&
                (d.localPosition.distanceSquared -
                            c.downPosition.distanceSquared)
                        .abs() <=
                    1500) {
              if (c.primaryDrags.value == 0 && c.secondaryDrags.value == 0) {
                if (c.state.value == OngoingCallState.active) {
                  if (c.showUi.isFalse) {
                    c.keepUi();
                  } else {
                    c.keepUi(c.isPanelOpen.value);
                  }
                }
              }
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: c.toggleFullscreen,
            onPanUpdate: preferTitle
                ? (d) {
                    c.left.value = c.left.value + d.delta.dx;
                    c.top.value = c.top.value + d.delta.dy;
                    c.applyConstraints(context);
                  }
                : null,
          ),
        ),
        // Settings button on the top right if call [isOutgoing].
        if (isOutgoing &&
            c.state.value != OngoingCallState.active &&
            c.state.value != OngoingCallState.joining)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: TooltipButton(
                verticalOffset: 8,
                hint: 'btn_call_settings'.td,
                onTap: () => c.openSettings(context),
                child: SvgLoader.asset(
                  'assets/icons/settings.svg',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ),
        // Sliding from the top title bar.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: preferTitle
              ? Align(
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
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder: (child, animation) => SlideTransition(
                        position: Tween(
                          begin: const Offset(0.0, -1.0),
                          end: const Offset(0.0, 0.0),
                        ).animate(animation),
                        child: child,
                      ),
                      child:
                          showUi && (!c.minimized.value || c.fullscreen.value)
                              ? _titleBar(context, c, isPopup: isPopup)
                              : Container(),
                    ),
                  ],
                ),
        ),
        // Top [MouseRegion] that toggles UI on hover.
        if (!c.minimized.value || c.fullscreen.value)
          SizedBox(
            height: 45,
            width: double.infinity,
            child: MouseRegion(
              opaque: false,
              onEnter: (d) {
                c.isTitleBarShown.value = true;
                c.isPanelOpen.value = true;
                c.keepUi(true);
              },
              onExit: (d) {
                c.isTitleBarShown.value = false;
                c.isPanelOpen.value = false;
                if (c.showUi.value) {
                  c.keepUi(false);
                }
              },
            ),
          ),
        // Sliding from the bottom buttons.
        if (!minimized) ...footer,
      ];

      // Combines all the stackable content into [Scaffold].
      Widget scaffold = Scaffold(
        backgroundColor: const Color(0xFF444444),
        body: KeyboardListener(
          focusNode: FocusNode()..requestFocus(),
          onKeyEvent: !PlatformUtils.isWeb &&
                  (PlatformUtils.isWindows || PlatformUtils.isLinux)
              ? (k) {
                  if (k is KeyDownEvent &&
                      k.physicalKey == PhysicalKeyboardKey.escape &&
                      c.fullscreen.isTrue) {
                    c.toggleFullscreen();
                  }
                }
              : null,
          child: Stack(
            children: [
              ...content,
              MouseRegion(
                opaque: false,
                cursor: c.isCursorHidden.value
                    ? SystemMouseCursors.none
                    : SystemMouseCursors.basic,
              ),
              ...ui.map((e) => ClipRect(child: e)),
              if (!minimized && hoverOverlay != null) hoverOverlay,
            ],
          ),
        ),
      );

      if (minimized) {
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
            Positioned(
              top: c.top.value - Scaler.size / 2,
              left: c.left.value + Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: Scaler(
                  width: c.width.value - Scaler.size,
                  onDrag: (dx, dy) => c.resize(
                    context,
                    y: ScaleModeY.top,
                    dy: dy,
                  ),
                ),
              ),
            ),
            // center left
            Positioned(
              top: c.top.value + Scaler.size / 2,
              left: c.left.value - Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Scaler(
                  height: c.height.value - Scaler.size,
                  onDrag: (dx, dy) => c.resize(
                    context,
                    x: ScaleModeX.left,
                    dx: dx,
                  ),
                ),
              ),
            ),
            // center right
            Positioned(
              top: c.top.value + Scaler.size / 2,
              left: c.left.value + c.width.value - Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Scaler(
                  height: c.height.value - Scaler.size,
                  onDrag: (dx, dy) => c.resize(
                    context,
                    x: ScaleModeX.right,
                    dx: -dx,
                  ),
                ),
              ),
            ),
            // bottom center
            Positioned(
              top: c.top.value + c.height.value - Scaler.size / 2,
              left: c.left.value + Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: Scaler(
                  width: c.width.value - Scaler.size,
                  onDrag: (dx, dy) => c.resize(
                    context,
                    y: ScaleModeY.bottom,
                    dy: -dy,
                  ),
                ),
              ),
            ),

            // top left
            Positioned(
              top: c.top.value - Scaler.size / 2,
              left: c.left.value - Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                child: Scaler(
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
              ),
            ),
            // top right
            Positioned(
              top: c.top.value - Scaler.size / 2,
              left: c.left.value + c.width.value - 3 * Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                child: Scaler(
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
              ),
            ),
            // bottom left
            Positioned(
              top: c.top.value + c.height.value - 3 * Scaler.size / 2,
              left: c.left.value - Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpRightDownLeft,
                child: Scaler(
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
              ),
            ),
            // bottom right
            Positioned(
              top: c.top.value + c.height.value - 3 * Scaler.size / 2,
              left: c.left.value + c.width.value - 3 * Scaler.size / 2,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpLeftDownRight,
                child: Scaler(
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
              ),
            ),

            Positioned(
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
                      child: Column(
                        children: [
                          preferTitle
                              ? Container()
                              : GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  child:
                                      _titleBar(context, c, isPopup: isPopup),
                                  onPanUpdate: (d) {
                                    c.left.value = c.left.value + d.delta.dx;
                                    c.top.value = c.top.value + d.delta.dy;
                                    c.applyConstraints(context);
                                  },
                                ),
                          Expanded(child: scaffold),
                        ],
                      ),
                    ),
                    ClipRect(child: Stack(children: footer)),
                    if (hoverOverlay != null)
                      Column(
                        children: [
                          const SizedBox(height: 45),
                          Expanded(child: hoverOverlay),
                        ],
                      ),
                  ],
                ),
              ),
            ),
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
Widget _titleBar(
  BuildContext context,
  CallController c, {
  bool isPopup = false,
}) =>
    Obx(
      () {
        bool isOutgoing =
            (c.outgoing || c.state.value == OngoingCallState.local) &&
                !c.started;
        String state = c.state.value == OngoingCallState.active
            ? c.duration.value.localizedString()
            : c.state.value == OngoingCallState.joining
                ? 'label_call_joining'.td
                : isOutgoing
                    ? 'label_call_calling'.td
                    : c.withVideo == true
                        ? 'label_video_call'.td
                        : 'label_audio_call'.td;

        return Container(
          key: const ValueKey('TitleBar'),
          color: const Color(0xFF222222),
          height: 45,
          child: Material(
            color: const Color(0xFF222222),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Handles double tap to toggle fullscreen.
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: c.toggleFullscreen,
                ),
                // Left part of the title bar that displays the recipient or
                // the caller and its avatar.
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.size.width / 2),
                    child: InkWell(
                      onTap: isPopup
                          ? null
                          : () {
                              router.chat(c.chatId);
                              if (c.fullscreen.value) {
                                c.toggleFullscreen();
                              }
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          AvatarWidget.fromRxChat(c.chat.value, radius: 15),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                c.chat.value?.title.value ?? ('dot'.td * 3),
                                style: context.textTheme.bodyText1?.copyWith(
                                  fontSize: 17,
                                  color: const Color(0xFFBBBBBB),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Center part of the title bar that displays the call state.
                IgnorePointer(
                  child: Container(
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 90),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00222222),
                          Color(0xFF222222),
                          Color(0xFF222222),
                          Color(0xFF222222),
                          Color(0xFF222222),
                          Color(0xFF222222),
                          Color(0xFF222222),
                          Color(0xFF222222),
                          Color(0x00222222),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state,
                          style: context.textTheme.bodyText1?.copyWith(
                            fontSize: 17,
                            color: const Color(0xFFBBBBBB),
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                        if (c.state.value == OngoingCallState.active) ...[
                          TooltipButton(
                            onTap: c.toggleRemoteVideos,
                            hint: c.isRemoteVideoEnabled.value
                                ? 'btn_call_disable_video'.td
                                : 'btn_call_enable_video'.td,
                            child: Icon(
                              c.isRemoteVideoEnabled.value
                                  ? Icons.videocam
                                  : Icons.videocam_off,
                              color: const Color(0xFFBBBBBB),
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TooltipButton(
                            onTap: () => c.openAddMember(context),
                            hint: 'btn_add_participant'.td,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: SvgLoader.asset(
                                'assets/icons/add_user.svg',
                                color: const Color(0xFFBBBBBB),
                                width: 19,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        TooltipButton(
                          onTap: () => c.openSettings(context),
                          hint: 'btn_call_settings'.td,
                          child: SvgLoader.asset(
                            'assets/icons/settings.svg',
                            color: const Color(0xFFBBBBBB),
                            width: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        TooltipButton(
                          onTap: c.toggleFullscreen,
                          hint: c.fullscreen.value
                              ? 'btn_fullscreen_exit'.td
                              : 'btn_fullscreen_enter'.td,
                          child: SvgLoader.asset(
                            'assets/icons/fullscreen_${c.fullscreen.value ? 'exit' : 'enter'}.svg',
                            width: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

/// [RtcVideoView] in a primary (fit) view.
Widget _primaryVideo(
  CallController c, {
  required Participant participant,
  required List<Participant> secondary,
  required bool mayDragVideo,
  required double panelSize,
  required bool showUi,
  required Participant? hoveredRenderer,
  bool mirror = false,
}) =>
    Obx(() {
      bool? muted = participant.owner == MediaOwnerKind.local
          ? !c.audioState.value.isEnabled()
          : participant.source == MediaSourceKind.Display
              ? c
                  .findParticipant(participant.id, MediaSourceKind.Device)
                  ?.audio
                  .value
                  ?.muted
              : null;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: c.handleLmb.value
            ? (d) {
                if (d.kind == PointerDeviceKind.mouse ||
                    d.kind == PointerDeviceKind.stylus) {
                  if (c.lmbTimeout > 0) {
                    if (secondary.isNotEmpty) {
                      c.unfocus(participant);
                    } else {
                      c.center(participant);
                    }
                  }

                  c.lmbTimeout = 7;
                }
              }
            : null,
        // Required for `Flutter` to handle the [ContextMenuRegion]'s
        // secondary tap.
        onSecondaryTap: () {},
        child: Draggable<_DragDataMinimize>(
          hitTestBehavior: HitTestBehavior.translucent,
          maxSimultaneousDrags: mayDragVideo ? null : 0,
          data: _DragDataMinimize(participant),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: () {
            c.primaryDrags.value += 1;
            c.primaryDrags.refresh();
            c.keepUi(false);
          },
          onDragEnd: (d) {
            c.primaryDrags.value -= 1;
            c.primaryDrags.refresh();
          },
          feedback: Transform.translate(
            offset: Offset(-panelSize / 2, -panelSize / 2),
            child: SizedBox(
              width: panelSize,
              height: panelSize,
              child: ParticipantWidget(
                participant,
                outline: participant.owner == MediaOwnerKind.local &&
                        participant.source == MediaSourceKind.Display
                    ? Colors.red
                    : null,
              ),
            ),
          ),
          childWhenDragging: Container(color: Colors.transparent),
          child: StatefulBuilder(builder: (context, setState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                BoxFit? fit = BoxFit.contain;

                if (participant.video.value != null) {
                  RtcVideoRenderer renderer = participant.video.value!;

                  if (renderer.source != MediaSourceKind.Display) {
                    fit = c.rendererBoxFit[renderer.track.id()];
                  }

                  // Calculate the default [BoxFit] if there's no explicit fit
                  // and this renderer's stream is from camera.
                  if (renderer.source == MediaSourceKind.Device &&
                      fit == null) {
                    // If a video still doesn't have width and height, then
                    // request a refresh of this view one frame later.
                    if (renderer.width == 0 && renderer.height == 0) {
                      fit = BoxFit.contain;
                    } else {
                      bool contain = false;

                      // Video is horizontal.
                      if (renderer.aspectRatio >= 1) {
                        double width = constraints.maxWidth;
                        double height = renderer.height *
                            (constraints.maxWidth / renderer.width);
                        double factor = constraints.maxHeight / height;
                        contain = factor >= 2.41;
                        if (factor < 1) {
                          width = renderer.width *
                              (constraints.maxHeight / renderer.height);
                          height = constraints.maxHeight;
                          factor = constraints.maxWidth / width;
                          contain = factor >= 1.5;
                        }
                      }
                      // Video is vertical.
                      else {
                        double width = renderer.width *
                            (constraints.maxHeight / renderer.height);
                        double height = constraints.maxHeight;
                        double factor = constraints.maxWidth / width;
                        contain = factor >= 1.5;
                        if (factor < 1) {
                          width = constraints.maxWidth;
                          height = renderer.height *
                              (constraints.maxWidth / renderer.width);
                          factor = constraints.maxHeight / height;
                          contain = factor >= 2.2;
                        }
                      }

                      fit = contain ? BoxFit.contain : BoxFit.cover;
                    }
                  }
                }

                return ContextMenuRegion(
                  preventContextMenu: false,
                  enabled: participant.video.value != null,
                  menu: ContextMenu(
                    actions: [
                      if (participant.video.value?.isEnabled == true) ...[
                        if (participant.source == MediaSourceKind.Device)
                          ContextMenuButton(
                            label: fit == null || fit == BoxFit.cover
                                ? 'btn_call_do_not_cut_video'.td
                                : 'btn_call_cut_video'.td,
                            onPressed: () {
                              c.rendererBoxFit[
                                      participant.video.value!.track.id()] =
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
                          ),
                        if (mayDragVideo)
                          ContextMenuButton(
                            label: 'btn_call_center_video'.td,
                            onPressed: () => c.center(participant),
                          ),
                      ],
                      ContextMenuButton(
                        label: participant.video.value?.isEnabled == true
                            ? 'btn_call_disable_video'.td
                            : 'btn_call_enable_video'.td,
                        onPressed: () =>
                            c.toggleRendererEnabled(participant.video),
                      ),
                    ],
                  ),
                  child: ParticipantWidget(
                    participant,
                    offstageUntilDetermined: true,
                    onSizeDetermined: () => setState(() {}),
                    fit: fit ?? BoxFit.cover,
                    enableContextMenu: c.isTitleBarShown.value,
                    muted: muted,
                    borderRadius: BorderRadius.zero,
                    hovered: hoveredRenderer == participant,
                  ),
                );
              },
            );
          }),
        ),
      );
    });

/// [RtcVideoView] in a secondary (panel) view.
Widget _secondaryVideo(
  CallController c, {
  required Participant participant,
  required double panelSize,
  required bool showUi,
  BoxFit fit = BoxFit.contain,
  bool mirror = false,
}) =>
    Obx(() {
      bool? muted = participant.owner == MediaOwnerKind.local
          ? !c.audioState.value.isEnabled()
          : participant.source == MediaSourceKind.Display
              ? c
                  .findParticipant(participant.id, MediaSourceKind.Device)
                  ?.audio
                  .value
                  ?.muted
              : null;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: c.handleLmb.value
            ? (d) {
                if (d.kind == PointerDeviceKind.mouse ||
                    d.kind == PointerDeviceKind.stylus) {
                  c.focus(participant);
                }
              }
            : null,
        // Required for `Flutter` to handle the [ContextMenuRegion]'s
        // secondary tap.
        onSecondaryTap: () {},
        child: Draggable<_DragDataFocus>(
          hitTestBehavior: HitTestBehavior.translucent,
          maxSimultaneousDrags: participant.owner == MediaOwnerKind.local &&
                  participant.source == MediaSourceKind.Display
              ? 0
              : null,
          data: _DragDataFocus(participant),
          onDragStarted: () {
            c.secondaryDrags.value += 1;
            c.secondaryDrags.refresh();
            c.keepUi(false);
          },
          onDragEnd: (d) {
            c.secondaryDrags.value -= 1;
            c.secondaryDrags.refresh();
          },
          feedback: Transform.translate(
            offset: const Offset(-10, -10),
            child: Container(
              margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
              height: panelSize + 20,
              width: panelSize + 20,
              child: ParticipantWidget(
                participant,
                fit: fit,
                outline: participant.owner == MediaOwnerKind.local &&
                        participant.source == MediaSourceKind.Display
                    ? Colors.red
                    : null,
              ),
            ),
          ),
          childWhenDragging: const SizedBox(height: 0, width: 0),
          child: Container(
            margin: const EdgeInsets.fromLTRB(1, 1, 1, 1),
            height: panelSize,
            width: panelSize,
            child: ContextMenuRegion(
              preventContextMenu: false,
              enabled: participant.video.value != null,
              menu: ContextMenu(
                actions: [
                  if ((participant.owner != MediaOwnerKind.local ||
                          participant.source != MediaSourceKind.Display) &&
                      participant.video.value?.isEnabled == true)
                    ContextMenuButton(
                      label: 'btn_call_center_video'.td,
                      onPressed: () => c.center(participant),
                    ),
                  ContextMenuButton(
                    label: participant.video.value?.isEnabled == true
                        ? 'btn_call_disable_video'.td
                        : 'btn_call_enable_video'.td,
                    onPressed: () => c.toggleRendererEnabled(participant.video),
                  )
                ],
              ),
              child: ParticipantWidget(
                participant,
                fit: fit,
                outline: participant.owner == MediaOwnerKind.local &&
                        participant.source == MediaSourceKind.Display
                    ? Colors.red
                    : null,
                muted: muted,
                hovered: c.hoveredRenderer.value == participant,
                enableContextMenu: c.isTitleBarShown.value,
              ),
            ),
          ),
        ),
      );
    });

/// [FitView] of a [primary] widgets.
Widget _primaryView(CallController c, List<Widget> primary) =>
    DragTarget<_DragDataFocus>(
      onAccept: (_DragDataFocus d) => c.focus(d.participant),
      builder: (context, candidate, rejected) {
        return Stack(
          children: [
            primary.isEmpty
                ? Obx(
                    () => CallCoverWidget(c.chat.value?.callCover),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: FitView(
                      key: Key('${primary.length}'),
                      children: primary,
                    ),
                  ),
            if (candidate.isNotEmpty)
              IgnorePointer(
                child: Container(
                  color: const Color(0x40000000),
                  child: Center(
                    child: SvgLoader.asset(
                      'assets/icons/drag_n_drop_plus.svg',
                      width: c.size.shortestSide / 6,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

/// [FitWrap] of a [secondary] widgets.
Widget _secondaryView(
  CallController c,
  Axis axis,
  List<Widget> secondary,
) =>
    DragTarget<_DragDataMinimize>(
      onAccept: (_DragDataMinimize d) => c.unfocus(d.participant),
      builder: (context, candidate, rejected) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Obx(
              () => FitWrap(
                maxSize: c.size.shortestSide / 4,
                axis: axis,
                children: secondary,
              ),
            ),
            if (candidate.isNotEmpty)
              IgnorePointer(
                child: Container(
                  color: const Color(0x80000000),
                  child: Center(
                    child: SvgLoader.asset(
                      'assets/icons/drag_n_drop_plus.svg',
                      width: 44,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

/// Layer of [MouseRegion]s to determine the hovered [primary] renderer.
Widget _hoverPrimary(
  CallController c,
  List<Participant> primary,
) =>
    FitView(
      dividerColor: Colors.transparent,
      children: primary
          .map(
            (e) => MouseRegion(
              opaque: false,
              onEnter: (d) {
                c.hoveredRenderer.value = e;
                c.hoveredRendererTimeout = 7;
                c.isCursorHidden.value = false;
              },
              onHover: (d) {
                c.hoveredRenderer.value = e;
                c.hoveredRendererTimeout = 7;
                c.isCursorHidden.value = false;
              },
              onExit: (d) {
                c.hoveredRendererTimeout = 0;
                c.hoveredRenderer.value = null;
                c.isCursorHidden.value = false;
              },
            ),
          )
          .toList(),
    );

/// Layer of [MouseRegion]s to determine the hovered [secondary] renderer.
Widget _hoverSecondary(
  CallController c,
  Axis axis,
  List<Participant> secondary,
) =>
    FitWrap(
      maxSize: c.size.shortestSide / 4,
      axis: axis,
      children: secondary
          .map(
            (e) => MouseRegion(
              opaque: false,
              onEnter: (d) {
                c.hoveredRenderer.value = e;
                c.hoveredRendererTimeout = 7;
                c.isCursorHidden.value = false;
              },
              onHover: (d) {
                c.hoveredRenderer.value ??= e;
                c.hoveredRendererTimeout = 7;
                c.isCursorHidden.value = false;
              },
              onExit: (d) {
                c.hoveredRendererTimeout = 0;
                c.hoveredRenderer.value = null;
                c.isCursorHidden.value = false;
              },
            ),
          )
          .toList(),
    );

/// [DragTarget] of an empty [_secondaryView].
Widget _secondaryTarget(
  CallController c,
  double panelSize,
) =>
    DragTarget<_DragDataMinimize>(
      onAccept: (_DragDataMinimize d) => c.unfocus(d.participant),
      builder: (context, candidate, rejected) => IgnorePointer(
        child: Obx(
          () => c.primaryDrags.value >= 1
              ? Container(
                  color: const Color(0x80000000),
                  child: Center(
                    child: SizedBox(
                      width: min(panelSize, 120),
                      height: min(panelSize, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          candidate.isNotEmpty
                              ? SvgLoader.asset(
                                  'assets/icons/drag_n_drop_plus.svg',
                                  width: 44,
                                )
                              : SvgLoader.asset(
                                  'assets/icons/drag_n_drop.svg',
                                  width: 44,
                                ),
                          const SizedBox(height: 5),
                          Text(
                            'btn_call_drop_video_here'.td,
                            style: context.textTheme.subtitle1?.copyWith(
                              color: const Color(0xFFBBBBBB),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
        ),
      ),
    );

/// Data required for dragging [participant] into the focus.
class _DragDataFocus {
  _DragDataFocus(this.participant);

  /// [Participant] to focus.
  Participant participant;
}

/// Data required for dragging [participant] outside the focus.
class _DragDataMinimize {
  _DragDataMinimize(this.participant);

  /// [Participant] to unfocus.
  Participant participant;
}
