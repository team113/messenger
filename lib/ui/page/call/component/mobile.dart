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

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controller.dart';
import '../widget/animated_delayed.dart';
import '../widget/animated_dots.dart';
import '../widget/call_cover.dart';
import '../widget/participant.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/fit_view.dart';
import '../widget/hint.dart';
import '../widget/minimizable_view.dart';
import '../widget/video_view.dart';
import '/domain/model/ongoing_call.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_delayed_scale.dart';
import '/ui/page/call/widget/fit_wrap.dart';
import '/ui/page/call/widget/reorderable_fit_view.dart';
import '/ui/page/call/widget/reorderable_fit_wrap.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';

/// Returns a mobile design of a [CallView].
Widget mobileCall(CallController c, BuildContext context) {
  c.padding = MediaQuery.of(context).padding;

  bool isOutgoing =
      (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;

  // Self minimized renderer.
  Participant? self;

  bool showUi = (c.showUi.isTrue ||
          c.state.value != OngoingCallState.active ||
          (c.state.value == OngoingCallState.active &&
              (c.primary.isEmpty ||
                  (c.primary.length == 1 &&
                      c.primary.first.video.value == null)))) &&
      !c.minimized.value;

  // Call stackable content.
  List<Widget> content = [
    SvgLoader.asset(
      'assets/images/background_dark.svg',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    ),
  ];

  // Layer of [MouseRegion]s to determine the hovered renderer.
  List<Widget> overlay = [];

  // Active call.
  if (c.state.value == OngoingCallState.active) {
    content.addAll([
      _primaryView(c, context),

      // Secondary panel itself.
      Obx(() {
        if (c.minimized.value) {
          return Container();
        }

        return GestureDetector(
          onPanStart: (d) {
            c.secondaryDragged.value = true;

            Offset block =
                (c.secondaryKey.currentContext?.findRenderObject() as RenderBox)
                    .localToGlobal(Offset.zero);

            c.panDragDifference.value = Offset(
              d.globalPosition.dx - block.dx,
              d.globalPosition.dy - block.dy,
            );

            var size = c.size;
            c.secondaryLeft.value ??= size.width -
                c.secondaryWidth.value -
                (c.secondaryRight.value ?? 0);
            c.secondaryTop.value ??= size.height -
                c.secondaryHeight.value -
                (c.secondaryBottom.value ?? 0);
            c.secondaryRight.value = null;
            c.secondaryBottom.value = null;

            c.applySecondaryConstraints(context);
          },
          onPanDown: (d) => c.secondaryDragged.value = true,
          onPanEnd: (d) {
            c.secondaryDragged.value = false;
            c.updateSecondaryAttach();
          },
          onPanCancel: () => c.secondaryDragged.value = false,
          onPanUpdate: (d) {
            c.secondaryDragged.value = true;
            c.secondaryLeft.value = c.secondaryLeft.value! + d.delta.dx;
            c.secondaryTop.value = c.secondaryTop.value! + d.delta.dy;
            c.updateSecondaryCoordinates(d.globalPosition);
            c.applySecondaryConstraints(context);
          },
          child: _floatingSecondaryView(c, context),
        );
      }),
    ]);
  } else {
    // Call is not active.
    content.add(Obx(() {
      RtcVideoRenderer? local = c.locals.firstOrNull?.video.value ??
          c.paneled.firstOrNull?.video.value;

      if (c.videoState.value != LocalTrackState.disabled && local != null) {
        return RtcVideoView(local, mirror: true, fit: BoxFit.cover);
      }

      return Stack(
        children: [
          if (!c.isGroup &&
              c.chat.value?.callCover == null &&
              c.minimized.value)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AvatarWidget.fromRxChat(c.chat.value, radius: 60),
              ),
            ),
          if (c.chat.value?.callCover != null)
            CallCoverWidget(c.chat.value?.callCover),
          AnimatedSwitcher(
            duration: 200.milliseconds,
            child: c.minimized.value
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xA0000000),
                        ),
                        height: 40,
                        child: Obx(() {
                          bool isOutgoing = (c.outgoing ||
                                  c.state.value == OngoingCallState.local) &&
                              !c.started;
                          bool withDots =
                              c.state.value != OngoingCallState.active &&
                                  (c.state.value == OngoingCallState.joining ||
                                      isOutgoing);
                          String state =
                              c.state.value == OngoingCallState.active
                                  ? c.duration.value
                                      .toString()
                                      .split('.')
                                      .first
                                      .padLeft(8, '0')
                                  : c.state.value == OngoingCallState.joining
                                      ? 'label_call_joining'.tr
                                      : isOutgoing
                                          ? 'label_call_calling'.tr
                                          : c.withVideo == true
                                              ? 'label_video_call'.tr
                                              : 'label_audio_call'.tr;

                          return Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state,
                                  style: context.textTheme.caption
                                      ?.copyWith(color: Colors.white),
                                ),
                                if (withDots) const AnimatedDots(),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  )
                : Container(),
          ),
        ],
      );
    }));
  }

  // If there's any error to show, display it.
  if (c.errorTimeout.value != 0) {
    overlay.add(
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 280,
          child: HintWidget(
            text: '${c.error}.',
            onTap: () => c.errorTimeout.value = 0,
          ),
        ),
      ),
    );
  }

  Widget _padding(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: child,
      );

  Widget _buttons(List<Widget> children) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children.map((e) => Expanded(child: e)).toList(),
        ),
      );

  c.isSlidingPanelEnabled.value = (c.state.value == OngoingCallState.active ||
          c.state.value == OngoingCallState.joining) &&
      showUi;

  List<Widget> ui = [
    // Dimmed container.
    Obx(() {
      return IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: (c.state.value != OngoingCallState.active &&
                  c.state.value != OngoingCallState.joining &&
                  ([...c.primary, ...c.secondary]
                              .firstWhereOrNull((e) => e.video.value != null) !=
                          null ||
                      self != null) &&
                  !c.minimized.value)
              ? Container(color: const Color(0x55000000))
              : null,
        ),
      );
    }),
    // Listen to the taps only if the call is not minimized.
    Obx(() {
      return c.minimized.value
          ? Container()
          : Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (d) {
                if (c.highlighted.value == null) {
                  c.downPosition = d.localPosition;
                  c.downButtons = d.buttons;
                } else {
                  c.downButtons = 0;
                  c.highlight(null);
                }
              },
              onPointerUp: (d) {
                if (c.draggedRenderer.value != null) return;
                if (c.secondaryDragged.value) return;
                if (c.downButtons & kPrimaryButton != 0) {
                  if (c.state.value == OngoingCallState.active) {
                    if ((d.localPosition.distanceSquared -
                                c.downPosition.distanceSquared)
                            .abs() <=
                        80000) {
                      if (c.highlighted.value == null) {
                        if (c.showUi.isFalse) {
                          c.keepUi();
                        } else {
                          c.keepUi(c.isPanelOpen.value);
                        }
                      } else {
                        c.keepUi(c.isPanelOpen.value);
                      }
                    }
                  }
                }
              },
            );
    }),
    // Sliding from the top title bar.
    SafeArea(
      child: Obx(() {
        bool showUi =
            (c.state.value != OngoingCallState.active && !c.minimized.value);
        return AnimatedSlider(
          duration: const Duration(milliseconds: 400),
          isOpen: showUi,
          beginOffset: Offset(0, -190 - MediaQuery.of(context).padding.top),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: c.size.height * 0.05,
              ),
              child: callTitle(c),
            ),
          ),
        );
      }),
    ),
    // Sliding from the bottom buttons panel.
    SafeArea(
      left: false,
      right: false,
      top: false,
      child: Obx(() {
        bool showUi =
            (c.showUi.isTrue || c.state.value != OngoingCallState.active) &&
                !c.minimized.value;

        double panelHeight = 0;
        List<Widget> panelChildren = [];

        // Populate the sliding panel height and its content.
        if (c.state.value == OngoingCallState.active ||
            c.state.value == OngoingCallState.joining) {
          panelHeight = 360;
          panelHeight = min(c.size.height - 45, panelHeight);

          Widget _divider() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Divider(
                      color: Color(0x99FFFFFF),
                      thickness: 1,
                      height: 1,
                    ),
                  ),
                ),
              );

          panelChildren = [
            const SizedBox(height: 12),
            _buttons(
              [
                if (PlatformUtils.isMobile)
                  _padding(
                    c.videoState.value.isEnabled()
                        ? hintedButton(
                            switchButton(c),
                            AnimatedOpacity(
                              opacity: c.isPanelOpen.value ? 1 : 0,
                              duration: 200.milliseconds,
                              child:
                                  Text('btn_call_switch_camera_two_lines'.tr),
                            ),
                          )
                        : hintedButton(
                            speakerButton(c),
                            AnimatedOpacity(
                              opacity: c.isPanelOpen.value ? 1 : 0,
                              duration: 200.milliseconds,
                              child:
                                  Text('btn_call_toggle_speaker_two_lines'.tr),
                            ),
                          ),
                  ),
                if (PlatformUtils.isDesktop)
                  _padding(hintedButton(
                    screenButton(c),
                    AnimatedOpacity(
                      opacity: c.isPanelOpen.value ? 1 : 0,
                      duration: 200.milliseconds,
                      child: Text(
                        c.screenShareState.value == LocalTrackState.enabled ||
                                c.screenShareState.value ==
                                    LocalTrackState.enabling
                            ? 'Выключить\nдемонстрацию'.tr
                            : 'Включить\nдемонстрацию'.tr,
                      ),
                    ),
                  )),
                _padding(hintedButton(
                  audioButton(c),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text(
                      c.audioState.value == LocalTrackState.enabled ||
                              c.audioState.value == LocalTrackState.enabling
                          ? 'btn_call_audio_off_two_lines'.tr
                          : 'btn_call_audio_on_two_lines'.tr,
                    ),
                  ),
                )),
                _padding(hintedButton(
                  videoButton(c),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text(
                      c.videoState.value == LocalTrackState.enabled ||
                              c.videoState.value == LocalTrackState.enabling
                          ? 'btn_call_video_off_two_lines'.tr
                          : 'btn_call_video_on_two_lines'.tr,
                    ),
                  ),
                )),
                _padding(hintedButton(
                  dropButton(c),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text('btn_call_end_two_lines'.tr),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buttons(
              [
                _padding(addParticipantButton(c, context)),
                _padding(
                  hintedButton(
                    handButton(c),
                    AnimatedOpacity(
                      opacity: c.isPanelOpen.value ? 1 : 0,
                      duration: 200.milliseconds,
                      child: Text(c.isHandRaised.value
                          ? 'btn_call_hand_down'.tr
                          : 'btn_call_hand_up'.tr),
                    ),
                  ),
                ),
                _padding(disableAudio(c)),
                _padding(disableVideo(c)),
              ],
            ),
            const SizedBox(height: 13),
            _divider(),
            const SizedBox(height: 13),
            _callTile(context, c),
            const SizedBox(height: 13),
          ];
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: c.state.value == OngoingCallState.active ||
                  c.state.value == OngoingCallState.joining
              ? AnimatedSlider(
                  beginOffset: Offset(
                    0,
                    130 + MediaQuery.of(context).padding.bottom,
                  ),
                  isOpen: showUi,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuad,
                  reverseCurve: Curves.easeOutQuad,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(size: c.size),
                    child: SlidingUpPanel(
                      controller: c.panelController,
                      boxShadow: null,
                      color: PlatformUtils.isIOS && WebUtils.isSafari
                          ? const Color(0xDD165084)
                          : const Color(0x9D165084),
                      backdropEnabled: true,
                      backdropOpacity: 0,
                      minHeight: min(c.size.height - 45, 130),
                      maxHeight: panelHeight,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                      panel: ConditionalBackdropFilter(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        condition: !PlatformUtils.isIOS || !WebUtils.isSafari,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                width: 60,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0x99FFFFFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: Column(children: panelChildren)),
                          ],
                        ),
                      ),
                      onPanelSlide: (d) {
                        c.keepUi(true);
                        c.isPanelOpen.value = d > 0;
                      },
                      onPanelOpened: () {
                        c.keepUi(true);
                        c.isPanelOpen.value = true;
                      },
                      onPanelClosed: () {
                        c.keepUi();
                        c.isPanelOpen.value = false;
                      },
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: AnimatedSlider(
                          isOpen: showUi,
                          duration: const Duration(milliseconds: 400),
                          beginOffset: Offset(
                            0,
                            150 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: _buttons(
                            isOutgoing
                                ? [
                                    if (PlatformUtils.isMobile)
                                      _padding(
                                        c.videoState.value.isEnabled()
                                            ? switchButton(c)
                                            : speakerButton(c),
                                      ),
                                    _padding(audioButton(c)),
                                    _padding(videoButton(c)),
                                    _padding(cancelButton(c)),
                                  ]
                                : [
                                    _padding(acceptAudioButton(c)),
                                    _padding(acceptVideoButton(c)),
                                    _padding(declineButton(c)),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      }),
    ),
  ];

  // Combines all the stackable content into [Scaffold].
  Widget scaffold = Scaffold(
    backgroundColor: const Color(0xFF444444),
    body: Stack(
      children: [
        ...content,
        const MouseRegion(
          opaque: false,
          cursor: SystemMouseCursors.basic,
        ),
        ...ui.map((e) => ClipRect(child: e)),
        ...overlay,
      ],
    ),
  );

  c.applyConstraints(context);

  return MinimizableView(
    onInit: (animation) {
      c.minimizedAnimation = animation;
      animation.addListener(() {
        if (animation.value != 0) {
          c.keepUi(false);
        }
        c.minimized.value = animation.value == 1;
        if (c.minimized.value) {
          c.hoveredRenderer.value = null;
        }
      });
    },
    onDispose: () => c.minimizedAnimation = null,
    child: Obx(() {
      return IgnorePointer(
        ignoring: c.minimized.value,
        child: scaffold,
      );
    }),
  );
}

/// Button with an [icon] and a [child] that has a strict layout.
Widget _layoutButton({
  required Widget icon,
  required Widget child,
  void Function()? onTap,
  Widget? trailing,
}) =>
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: InkWell(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(flex: 1, child: icon),
            Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(flex: 3, child: child),
                    if (trailing != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: trailing,
                      ),
                  ],
                )),
          ],
        ),
      ),
    );

/// Call's tile containing information about the call.
Widget _callTile(BuildContext context, CallController c) => Obx(
      () {
        bool isOutgoing =
            (c.outgoing || c.state.value == OngoingCallState.local) &&
                !c.started;
        String state = c.state.value == OngoingCallState.active
            ? c.duration.value.localizedString()
            : c.state.value == OngoingCallState.joining
                ? 'label_call_joining'.tr
                : isOutgoing
                    ? 'label_call_calling'.tr
                    : c.withVideo == true
                        ? 'label_video_call'.tr
                        : 'label_audio_call'.tr;

        String? subtitle;
        if (c.isGroup) {
          var actualMembers = c.members.keys.map((k) => k.userId).toSet();
          subtitle =
              '${1 + actualMembers.length} ${'label_of'.tr} ${c.chat.value?.members.length}';
        }

        return _layoutButton(
          icon: Center(
            child: SizedBox(
              width: 58,
              height: 58,
              child: AvatarWidget.fromRxChat(c.chat.value),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.chat.value?.title.value ?? ('.'.tr * 3),
                style: context.textTheme.headline4
                    ?.copyWith(color: Colors.white, fontSize: 20),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (c.isGroup) ...[
                const SizedBox(height: 5),
                Text(
                  '$subtitle',
                  style: context.textTheme.headline4
                      ?.copyWith(color: Colors.white, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
          trailing: Text(
            state,
            style: context.textTheme.headline4
                ?.copyWith(color: Colors.white, fontSize: 15),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            maxLines: 1,
          ),
          onTap: () {
            if (c.chat.value != null) {
              c.minimize();
              router.chat(c.chat.value!.chat.value.id);
            }
          },
        );
      },
    );

/// [FitView] of a [primary] widgets.
Widget _primaryView(CallController c, BuildContext context) {
  return Obx(() {
    List<Participant> primary;

    if (c.minimized.value) {
      primary = List.from([...c.primary, ...c.secondary]);
    } else {
      primary = List.from(c.primary);
    }

    void _onDragEnded(_DragData d) {
      c.primaryDrags.value = 0;
      c.draggedRenderer.value = null;
      c.hoveredRenderer.value = d.participant;
      c.doughDraggedRenderer.value = null;
      c.hoveredRendererTimeout = 5;
      c.isCursorHidden.value = false;
      c.addToSecondaryEntry?.remove();
      c.addToSecondaryEntry = null;
    }

    return Stack(
      children: [
        ReorderableFitView<_DragData>(
          key: const Key('PrimaryFitView'),
          onAdded: (d, i) => c.focus(d.participant),
          useLongDraggable: true,
          onWillAccept: (b) => c.primaryTargets.value = 1,
          onLeave: (b) => c.primaryTargets.value = 0,
          allowDraggingLast: false,
          onDragStarted: (r) {
            c.draggedRenderer.value = r.participant;
            c.isHintDismissed.value = true;
            c.primaryDrags.value = 1;
            c.keepUi(false);
            populateSecondaryEntry(context, c);
          },
          onDoughBreak: (d) => c.doughDraggedRenderer.value = d.participant,
          onDragEnd: _onDragEnded,
          onDragCompleted: _onDragEnded,
          onDraggableCanceled: _onDragEnded,
          overlayBuilder: (_DragData data) {
            var participant = data.participant;

            return LayoutBuilder(builder: (context, constraints) {
              return Obx(() {
                bool? muted = participant.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled()
                    : participant.source == MediaSourceKind.Display
                        ? c
                            .findParticipant(
                                participant.id, MediaSourceKind.Device)
                            ?.audio
                            .value
                            ?.muted
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
                        : ParticipantOverlayWidget(
                            participant,
                            key: ObjectKey(participant),
                            muted: muted,
                            hovered: isHovered,
                            preferBackdrop: !c.minimized.value,
                          ),
                  ),
                );
              });
            });
          },
          decoratorBuilder: (_DragData item) =>
              const ParticipantDecoratorWidget(),
          itemBuilder: (_DragData data) {
            var participant = data.participant;
            return Obx(() {
              return ParticipantWidget(
                participant,
                key: ObjectKey(participant),
                offstageUntilDetermined: true,
                respectAspectRatio: true,
                borderRadius: BorderRadius.zero,
                onSizeDetermined: participant.video.refresh,
                useCallCover: true,
                fit: c.minimized.value
                    ? BoxFit.cover
                    : c.rendererBoxFit[
                        participant.video.value?.track.id() ?? ''],
                isDragging: c.draggedRenderer.value == participant,
              );
            });
          },
          children: primary.map((e) => _DragData(e)).toList(),
        ),
        IgnorePointer(
          child: Obx(() {
            return AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.secondaryDrags.value != 0
                  ? Container(
                      color: const Color(0x40000000),
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: c.primaryTargets.value != 0 ? 1.06 : 1,
                          child: ConditionalBackdropFilter(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0x40000000),
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

/// [FitWrap] of a [secondary] widgets.
Widget _floatingSecondaryView(CallController c, BuildContext context) {
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(size: c.size),
    child: Obx(() {
      if (c.secondary.isEmpty) {
        return Container();
      }

      double? left = c.secondaryLeft.value;
      double? top = c.secondaryTop.value;
      double? right = c.secondaryRight.value;
      double? bottom = c.secondaryBottom.value;
      double width = c.secondaryWidth.value;
      double height = c.secondaryHeight.value;

      void _onDragEnded(_DragData d) {
        c.secondaryDrags.value = 0;
        c.draggedRenderer.value = null;
        c.doughDraggedRenderer.value = null;
        c.hoveredRenderer.value = d.participant;
        c.hoveredRendererTimeout = 5;
        c.isCursorHidden.value = false;
        c.addToSecondaryEntry?.remove();
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            key: c.secondaryKey,
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: IgnorePointer(
              child: Obx(() {
                if (c.secondaryAlignment.value == null &&
                    !(c.secondary.length == 1 &&
                        c.draggedRenderer.value != null)) {
                  return Container(
                    width: width,
                    height: height,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        CustomBoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 9,
                          blurStyle: BlurStyle.outer,
                        )
                      ],
                    ),
                  );
                }

                return Container();
              }),
            ),
          ),

          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: SizedBox(
              width: width,
              height: height,
              child: Obx(() {
                if (c.secondaryAlignment.value == null) {
                  return Stack(
                    children: [
                      SvgLoader.asset(
                        'assets/images/background_dark.svg',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(color: const Color(0x11FFFFFF)),
                    ],
                  );
                }

                return Container();
              }),
            ),
          ),

          // TODO: Make Avatar expand!!!!
          ReorderableFitWrap<_DragData>(
            key: const Key('SecondaryFitView'),
            onAdded: (d, i) => c.unfocus(d.participant),
            onWillAccept: (b) => c.secondaryTargets.value = 1,
            onLeave: (b) => c.secondaryTargets.value = 0,
            useLongPress: true,
            onDragStarted: (r) {
              c.draggedRenderer.value = r.participant;
              c.isHintDismissed.value = true;
              c.secondaryDrags.value = 1;
              c.keepUi(false);
            },
            onDoughBreak: (r) => c.doughDraggedRenderer.value = r.participant,
            onDragEnd: _onDragEnded,
            onDragCompleted: _onDragEnded,
            onDraggableCanceled: _onDragEnded,
            width: width,
            height: height,
            left: left,
            top: top,
            right: right,
            bottom: bottom,
            overlayBuilder: (_DragData data) {
              var participant = data.participant;

              return Obx(() {
                bool? muted = participant.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled()
                    : participant.source == MediaSourceKind.Display
                        ? c
                            .findParticipant(
                                participant.id, MediaSourceKind.Device)
                            ?.audio
                            .value
                            ?.muted
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
                        : ParticipantOverlayWidget(
                            participant,
                            key: ObjectKey(participant),
                            muted: muted,
                            hovered: isHovered,
                            preferBackdrop: !c.minimized.value,
                          ),
                  ),
                );
              });
            },
            decoratorBuilder: (_DragData item) {
              if (c.secondaryAlignment.value == null &&
                  !(c.secondary.length == 1 &&
                      c.draggedRenderer.value != null)) {
                return Container();
              }

              return const ParticipantDecoratorWidget();
            },
            itemBuilder: (_DragData data) {
              var participant = data.participant;
              return ParticipantWidget(
                participant,
                key: ObjectKey(participant),
                offstageUntilDetermined: true,
                respectAspectRatio: true,
                borderRadius: BorderRadius.zero,
                isDragging: c.draggedRenderer.value == participant,
                useCallCover: true,
              );
            },
            children: c.secondary.map((e) => _DragData(e)).toList(),
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

          // Displays `add` icon if secondary view is hovered.
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0x40000000),
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
        ],
      );
    }),
  );
}

/// Shows [SecondaryOverlayEntry].
void populateSecondaryEntry(BuildContext context, CallController c) {
  c.addToSecondaryEntry = OverlayEntry(builder: (context) {
    return SecondaryOverlayEntry(c);
  });

  Overlay.of(context)?.insert(c.addToSecondaryEntry!);
}

/// [DragTarget] of an empty [_secondaryView].
class SecondaryOverlayEntry extends StatefulWidget {
  const SecondaryOverlayEntry(this.c, {Key? key}) : super(key: key);

  final CallController c;

  @override
  State<SecondaryOverlayEntry> createState() => _SecondaryOverlayEntryState();
}

/// State of an [SecondaryOverlayEntry] maintaining the [hovered].
class _SecondaryOverlayEntryState extends State<SecondaryOverlayEntry> {
  /// [StreamSubscription] to the [CallController.secondaryTargets].
  StreamSubscription? _subscription;

  /// Indicator whether this [SecondaryOverlayEntry] is hovered by some call
  /// participant.
  bool hovered = false;

  @override
  void initState() {
    hovered = widget.c.secondaryTargets.value != 0;
    _subscription = widget.c.secondaryTargets.listen((p) {
      Future.delayed(Duration.zero, () {
        setState(() => hovered = widget.c.secondaryTargets.value != 0);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.c.secondary.isNotEmpty) {
      return Container();
    }
    Axis secondaryAxis = widget.c.size.width >= widget.c.size.height
        ? Axis.horizontal
        : Axis.vertical;

    // Pre-calculate the [FitWrap]'s size.
    double panelSize = max(
      FitWrap.calculateSize(
        maxSize: widget.c.size.shortestSide / 4,
        constraints: Size(widget.c.size.width, widget.c.size.height - 45),
        axis: widget.c.size.width >= widget.c.size.height
            ? Axis.horizontal
            : Axis.vertical,
        length: widget.c.secondary.length,
      ),
      130,
    );

    return AnimatedDelayed(
      key: const Key('SecondaryTargetAnimatedSwitcher'),
      duration: 200.milliseconds,
      delay: Duration.zero,
      child: SafeArea(
        child: Align(
          alignment: secondaryAxis == Axis.horizontal
              ? Alignment.centerRight
              : Alignment.bottomCenter,
          child: DragTarget<_DragData>(
            onAccept: (_DragData d) {
              widget.c.secondaryAlignment.value = null;
              widget.c.secondaryLeft.value = null;
              widget.c.secondaryTop.value = null;
              widget.c.secondaryRight.value = 10;
              widget.c.secondaryBottom.value = 10;
              widget.c.secondaryTargets.value = 0;

              widget.c.unfocus(d.participant);
            },
            onWillAccept: (b) {
              widget.c.secondaryTargets.value = 1;
              return true;
            },
            onLeave: (b) => widget.c.secondaryTargets.value = 0,
            builder: (context, candidate, rejected) {
              return SizedBox(
                width: secondaryAxis == Axis.horizontal
                    ? panelSize
                    : double.infinity,
                height: secondaryAxis == Axis.horizontal
                    ? double.infinity
                    : panelSize,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      width: panelSize,
                      height: panelSize,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        boxShadow: [
                          CustomBoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            blurStyle: BlurStyle.outer,
                          )
                        ],
                      ),
                      child: ConditionalBackdropFilter(
                        child: Container(
                          color: const Color(0x30000000),
                          child: Center(
                            child: SizedBox(
                              width: secondaryAxis == Axis.horizontal
                                  ? min(panelSize, 150 + 44)
                                  : null,
                              height: secondaryAxis == Axis.horizontal
                                  ? null
                                  : min(panelSize, 150 + 44),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                    scale: hovered ? 1.06 : 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0x40000000),
                                        borderRadius: BorderRadius.circular(16),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Drag data of an call [Participant].
class _DragData {
  const _DragData(this.participant);

  /// [Participant] to focus.
  final Participant participant;

  @override
  bool operator ==(Object other) =>
      other is _DragData && participant == other.participant;

  @override
  int get hashCode => participant.hashCode;
}
