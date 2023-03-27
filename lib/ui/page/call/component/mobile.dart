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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controller.dart';
import '../widget/animated_dots.dart';
import '../widget/call_cover.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/floating_fit/view.dart';
import '../widget/hint.dart';
import '../widget/minimizable_view.dart';
import '../widget/participant.dart';
import '../widget/swappable_fit.dart';
import '../widget/video_view.dart';
import '/domain/model/avatar.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_cliprrect.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'common.dart';

/// Returns a mobile design of a [CallView].
Widget mobileCall(CallController c, BuildContext context) {
  return LayoutBuilder(builder: (context, constraints) {
    bool isOutgoing =
        (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;

    // Call stackable content.
    List<Widget> content = [
      SvgLoader.asset(
        'assets/images/background_dark.svg',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      ),
    ];

    // Layer of [Widget]s to display above the UI.
    List<Widget> overlay = [];

    // Active call.
    if (c.state.value == OngoingCallState.active) {
      content.addAll([
        Obx(() {
          if (c.isDialog && c.primary.length == 1 && c.secondary.length == 1) {
            return FloatingFit<Participant>(
              primary: c.primary.first,
              panel: c.secondary.first,
              onSwapped: (p, _) => c.center(p),
              fit: !c.minimized.isFalse,
              intersection: c.dockRect,
              onManipulated: (bool m) => c.secondaryManipulated.value = m,
              itemBuilder: (e) {
                return Stack(
                  children: [
                    const ParticipantDecoratorWidget(),
                    IgnorePointer(
                      child: ParticipantWidget(
                        e,
                        offstageUntilDetermined: true,
                      ),
                    ),
                  ],
                );
              },
              overlayBuilder: (e) {
                return Obx(() {
                  final bool muted = e.member.owner == MediaOwnerKind.local
                      ? !c.audioState.value.isEnabled
                      : e.audio.value?.isMuted.value ?? false;

                  // TODO: Implement opened context menu detection for
                  //       `hovered` indicator.
                  return ParticipantOverlayWidget(
                    e,
                    muted: muted,
                    hovered: false,
                    preferBackdrop: !c.minimized.value,
                  );
                });
              },
            );
          }

          final Participant? center =
              c.secondary.isNotEmpty ? c.primary.firstOrNull : null;

          return SwappableFit<Participant>(
            items: [...c.primary, ...c.secondary],
            center: center,
            fit: c.minimized.value,
            itemBuilder: (e) {
              return Obx(() {
                final bool muted = e.member.owner == MediaOwnerKind.local
                    ? !c.audioState.value.isEnabled
                    : e.audio.value?.isMuted.value ?? false;

                // Builds the [Participant] with a [AnimatedClipRRect].
                Widget builder(bool animated) {
                  final Widget stack = Stack(
                    children: [
                      const ParticipantDecoratorWidget(),
                      IgnorePointer(
                        child: ParticipantWidget(
                          e,
                          offstageUntilDetermined: true,
                        ),
                      ),
                      ParticipantOverlayWidget(
                        e,
                        muted: muted,
                        hovered: animated,
                        preferBackdrop: !c.minimized.value,
                      ),
                    ],
                  );

                  return AnimatedClipRRect(
                    key: Key(e.member.id.toString()),
                    borderRadius: animated
                        ? BorderRadius.circular(10)
                        : BorderRadius.zero,
                    child: AnimatedContainer(
                      duration: 200.milliseconds,
                      decoration: BoxDecoration(
                        color: animated
                            ? const Color(0xFF132131)
                            : const Color(0x00132131),
                      ),
                      width: animated
                          ? MediaQuery.of(context).size.width - 20
                          : null,
                      height: animated
                          ? MediaQuery.of(context).size.height / 2
                          : null,
                      child: stack,
                    ),
                  );
                }

                return ContextMenuRegion(
                  actions: [
                    if (center == e)
                      ContextMenuButton(
                        label: 'btn_call_uncenter'.l10n,
                        onPressed: c.focusAll,
                        trailing: const Icon(Icons.center_focus_weak),
                      )
                    else
                      ContextMenuButton(
                        label: 'btn_call_center'.l10n,
                        onPressed: () => c.center(e),
                        trailing: const Icon(Icons.center_focus_strong),
                      ),
                    if (e.member.id != c.me.id) ...[
                      if (e.video.value?.direction.value.isEmitting ?? false)
                        ContextMenuButton(
                          label: e.video.value?.renderer.value != null
                              ? 'btn_call_disable_video'.l10n
                              : 'btn_call_enable_video'.l10n,
                          onPressed: () => c.toggleVideoEnabled(e),
                          trailing: e.video.value?.renderer.value != null
                              ? const Icon(Icons.videocam)
                              : const Icon(Icons.videocam_off),
                        ),
                      if (e.audio.value?.direction.value.isEmitting ?? false)
                        ContextMenuButton(
                          label:
                              (e.audio.value?.direction.value.isEnabled == true)
                                  ? 'btn_call_disable_audio'.l10n
                                  : 'btn_call_enable_audio'.l10n,
                          onPressed: () => c.toggleAudioEnabled(e),
                          trailing: e.video.value?.renderer.value != null
                              ? const Icon(Icons.volume_up)
                              : const Icon(Icons.volume_off),
                        ),
                      ContextMenuButton(
                        label: 'btn_call_remove_participant'.l10n,
                        onPressed: () {},
                        trailing: const Icon(Icons.remove_circle),
                      ),
                    ] else ...[
                      ContextMenuButton(
                        label: c.videoState.value.isEnabled
                            ? 'btn_call_video_off'.l10n
                            : 'btn_call_video_on'.l10n,
                        onPressed: c.toggleVideo,
                        trailing: c.videoState.value.isEnabled
                            ? const Icon(Icons.videocam)
                            : const Icon(Icons.videocam_off),
                      ),
                      ContextMenuButton(
                        label: c.audioState.value.isEnabled
                            ? 'btn_call_audio_off'.l10n
                            : 'btn_call_audio_on'.l10n,
                        onPressed: c.toggleAudio,
                        trailing: e.video.value?.renderer.value != null
                            ? const Icon(Icons.mic)
                            : const Icon(Icons.mic_off),
                      ),
                    ],
                  ],
                  unconstrained: true,
                  builder: builder,
                );
              });
            },
          );
        }),
      ]);
    } else {
      // Call is not active.
      content.add(Obx(() {
        RtcVideoRenderer? local =
            (c.locals.firstOrNull?.video.value?.renderer.value ??
                    c.paneled.firstOrNull?.video.value?.renderer.value)
                as RtcVideoRenderer?;

        if (c.videoState.value != LocalTrackState.disabled && local != null) {
          return RtcVideoView(local, mirror: true, fit: BoxFit.cover);
        }

        return Stack(
          children: [
            // Display a [CallCover] of the call.
            Obx(() {
              final bool isDialog = c.chat.value?.chat.value.isDialog == true;

              if (isDialog) {
                final User? user = c.chat.value?.members.values
                        .firstWhereOrNull((e) => e.id != c.me.id.userId)
                        ?.user
                        .value ??
                    c.chat.value?.chat.value.members
                        .firstWhereOrNull((e) => e.user.id != c.me.id.userId)
                        ?.user;

                return CallCoverWidget(c.chat.value?.callCover, user: user);
              } else {
                if (c.chat.value?.avatar.value != null) {
                  final Avatar avatar = c.chat.value!.avatar.value!;
                  return CallCoverWidget(
                    UserCallCover(
                      full: avatar.full,
                      original: avatar.original,
                      square: avatar.full,
                      vertical: avatar.full,
                    ),
                  );
                }
              }

              return const SizedBox();
            }),

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
                    color: const Color(0x00D1E1F0),
                  ),
                );
              }

              return AnimatedSwitcher(duration: 200.milliseconds, child: child);
            }),

            // Display call's state info only if minimized.
            AnimatedSwitcher(
              duration: 200.milliseconds,
              child: c.minimized.value
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context)
                                .extension<Style>()!
                                .transparentOpacity25,
                          ),
                          height: 40,
                          child: Obx(() {
                            bool withDots = c.state.value !=
                                    OngoingCallState.active &&
                                (c.state.value == OngoingCallState.joining ||
                                    isOutgoing);
                            bool isDialog =
                                c.chat.value?.chat.value.isDialog == true;

                            String state =
                                c.state.value == OngoingCallState.active
                                    ? c.duration.value
                                        .toString()
                                        .split('.')
                                        .first
                                        .padLeft(8, '0')
                                    : c.state.value == OngoingCallState.joining
                                        ? 'label_call_joining'.l10n
                                        : isOutgoing
                                            ? isDialog
                                                ? 'label_call_calling'.l10n
                                                : 'label_call_connecting'.l10n
                                            : c.withVideo == true
                                                ? 'label_video_call'.l10n
                                                : 'label_audio_call'.l10n;

                            return Padding(
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state,
                                    style: context.textTheme.bodySmall
                                        ?.copyWith(
                                            color: Theme.of(context)
                                                .extension<Style>()!
                                                .transparentOpacity98),
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

            if (isOutgoing)
              const Padding(
                padding: EdgeInsets.all(21.0),
                child: Center(
                  child: SpinKitDoubleBounce(
                    color: Color(0xFFEEEEEE),
                    size: 66,
                    duration: Duration(milliseconds: 4500),
                  ),
                ),
              ),
          ],
        );
      }));
    }

    // If there's any error to show, display it.
    overlay.add(
      Obx(() {
        return AnimatedSwitcher(
          duration: 200.milliseconds,
          child: c.errorTimeout.value != 0 &&
                  c.minimizing.isFalse &&
                  c.minimized.isFalse
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 10),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        width: 280,
                        child: HintWidget(
                          text: '${c.error}.',
                          onTap: () => c.errorTimeout.value = 0,
                          isError: true,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(),
        );
      }),
    );

    Widget padding(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Center(child: child),
        );

    Widget buttons(List<Widget> children) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children.map((e) => Expanded(child: e)).toList(),
          ),
        );

    List<Widget> ui = [
      // Dimmed container if any video is displayed while calling.
      Obx(() {
        return IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: (c.state.value != OngoingCallState.active &&
                    c.state.value != OngoingCallState.joining &&
                    ([...c.primary, ...c.secondary].firstWhereOrNull(
                            (e) => e.video.value?.renderer.value != null) !=
                        null) &&
                    !c.minimized.value)
                ? Container(
                    color: Theme.of(context)
                        .extension<Style>()!
                        .transparentOpacity67)
                : null,
          ),
        );
      }),

      // Listen to the taps only if the call is not minimized.
      Obx(() {
        return c.minimized.isTrue
            ? Container()
            : Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (d) {
                  c.downAt = DateTime.now();
                  c.downPosition = d.localPosition;
                  c.downButtons = d.buttons;
                },
                onPointerUp: (d) {
                  if (c.secondaryManipulated.isTrue) return;
                  if (c.downButtons & kPrimaryButton != 0) {
                    if (c.state.value == OngoingCallState.active) {
                      final distance = (d.localPosition.distanceSquared -
                                  c.downPosition.distanceSquared)
                              .abs() <=
                          80000;

                      final time =
                          DateTime.now().difference(c.downAt!).inMilliseconds <
                              340;

                      if (distance && time) {
                        if (c.showUi.isFalse) {
                          c.keepUi();
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
      Obx(() {
        bool showUi =
            (c.showUi.isTrue || c.state.value != OngoingCallState.active) &&
                !c.minimized.value;

        double panelHeight = 0;
        List<Widget> panelChildren = [];

        // Populate the sliding panel height and its content.
        if (c.state.value == OngoingCallState.active ||
            c.state.value == OngoingCallState.joining) {
          panelHeight = 360 + 36;
          panelHeight = min(c.size.height - 45, panelHeight);

          panelChildren = [
            const SizedBox(height: 12),
            buttons(
              [
                if (PlatformUtils.isMobile)
                  padding(
                    c.videoState.value.isEnabled
                        ? withDescription(
                            SwitchButton(c).build(),
                            AnimatedOpacity(
                              opacity: c.isPanelOpen.value ? 1 : 0,
                              duration: 200.milliseconds,
                              child: Text('btn_call_switch_camera_desc'.l10n),
                            ),
                          )
                        : withDescription(
                            SpeakerButton(c).build(),
                            AnimatedOpacity(
                              opacity: c.isPanelOpen.value ? 1 : 0,
                              duration: 200.milliseconds,
                              child: Text('btn_call_toggle_speaker_desc'.l10n),
                            ),
                          ),
                  ),
                if (PlatformUtils.isDesktop)
                  padding(withDescription(
                    ScreenButton(c).build(),
                    AnimatedOpacity(
                      opacity: c.isPanelOpen.value ? 1 : 0,
                      duration: 200.milliseconds,
                      child: Text(
                        c.screenShareState.value == LocalTrackState.enabled ||
                                c.screenShareState.value ==
                                    LocalTrackState.enabling
                            ? 'btn_call_screen_off_desc'.l10n
                            : 'btn_call_screen_on_desc'.l10n,
                      ),
                    ),
                  )),
                padding(withDescription(
                  AudioButton(c).build(),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text(
                      c.audioState.value == LocalTrackState.enabled ||
                              c.audioState.value == LocalTrackState.enabling
                          ? 'btn_call_audio_off_desc'.l10n
                          : 'btn_call_audio_on_desc'.l10n,
                    ),
                  ),
                )),
                padding(withDescription(
                  VideoButton(c).build(),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text(
                      c.videoState.value == LocalTrackState.enabled ||
                              c.videoState.value == LocalTrackState.enabling
                          ? 'btn_call_video_off_desc'.l10n
                          : 'btn_call_video_on_desc'.l10n,
                    ),
                  ),
                )),
                padding(withDescription(
                  DropButton(c).build(),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text('btn_call_end_desc'.l10n),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 32),
            buttons(
              [
                padding(withDescription(
                  ParticipantsButton(c).build(),
                  Text('btn_participants_desc'.l10n),
                )),
                padding(withDescription(
                  HandButton(c).build(),
                  AnimatedOpacity(
                    opacity: c.isPanelOpen.value ? 1 : 0,
                    duration: 200.milliseconds,
                    child: Text(c.me.isHandRaised.value
                        ? 'btn_call_hand_down_desc'.l10n
                        : 'btn_call_hand_up_desc'.l10n),
                  ),
                )),
                padding(withDescription(
                  RemoteAudioButton(c).build(),
                  Text(c.isRemoteAudioEnabled.value
                      ? 'btn_call_remote_audio_off_desc'.l10n
                      : 'btn_call_remote_audio_on_desc'.l10n),
                )),
                padding(withDescription(
                  RemoteVideoButton(c).build(),
                  Text(c.isRemoteVideoEnabled.value
                      ? 'btn_call_remote_video_off_desc'.l10n
                      : 'btn_call_remote_video_on_desc'.l10n),
                )),
              ],
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 366),
              child: _chat(context, c),
            ),
            const SizedBox(height: 15),
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
                  listener: () => Future.delayed(
                    Duration.zero,
                    () => c.dockRect.value = c.dockKey.globalPaintBounds,
                  ),
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
                        key: c.dockKey,
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
                        c.dockRect.value = c.dockKey.globalPaintBounds;
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
                          child: buttons(
                            isOutgoing
                                ? [
                                    if (PlatformUtils.isMobile)
                                      padding(
                                        c.videoState.value.isEnabled
                                            ? SwitchButton(c).build(blur: true)
                                            : SpeakerButton(c)
                                                .build(blur: true),
                                      ),
                                    padding(AudioButton(c).build(blur: true)),
                                    padding(VideoButton(c).build(blur: true)),
                                    padding(CancelButton(c).build(blur: true)),
                                  ]
                                : [
                                    padding(AcceptAudioButton(
                                      c,
                                      highlight: !c.withVideo,
                                    ).build(expanded: true)),
                                    padding(AcceptVideoButton(
                                      c,
                                      highlight: c.withVideo,
                                    ).build(expanded: true)),
                                    padding(
                                      DeclineButton(c).build(expanded: true),
                                    ),
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      }),
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

    if (c.minimized.value) {
      c.applyConstraints(context);
    } else {
      c.applySecondaryConstraints();
    }

    return Obx(() {
      return MinimizableView(
        minimizationEnabled: !c.secondaryManipulated.value,
        onInit: (animation) {
          c.minimizedAnimation = animation;
          animation.addListener(() {
            if (c.state.value != OngoingCallState.joining &&
                c.state.value != OngoingCallState.active) {
              c.minimized.value = animation.value != 0;
            } else {
              if (animation.value != 0) {
                c.hoveredRenderer.value = null;
                c.keepUi(false);
              }
              c.minimized.value = animation.value == 1;
              if (animation.value == 1 || animation.value == 0) {
                c.minimizing.value = false;
              } else {
                c.minimizing.value = true;
              }
            }
          });
        },
        onDispose: () => c.minimizedAnimation = null,
        onSizeChanged: (s) {
          c.width.value = s.width;
          c.height.value = s.height;
        },
        child: Obx(() {
          return IgnorePointer(
            ignoring: c.minimized.value,
            child: scaffold,
          );
        }),
      );
    });
  });
}

/// Builds a tile representation of the [CallController.chat].
Widget _chat(BuildContext context, CallController c) {
  return Obx(() {
    final Style style = Theme.of(context).extension<Style>()!;
    final RxChat? chat = c.chat.value;

    final Set<UserId> actualMembers =
        c.members.keys.map((k) => k.userId).toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          color: Theme.of(context).extension<Style>()!.transparent,
        ),
        child: Material(
          type: MaterialType.card,
          borderRadius: style.cardRadius,
          color: const Color(0x794E5A78),
          child: InkWell(
            borderRadius: style.cardRadius,
            onTap: () => c.openAddMember(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
              child: Row(
                children: [
                  AvatarWidget.fromRxChat(chat, radius: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat?.title.value ?? 'dot'.l10n * 3,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<Style>()!
                                            .onPrimary),
                              ),
                            ),
                            Text(
                              c.duration.value.hhMmSs(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .extension<Style>()!
                                          .onPrimary),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Text(
                                c.chat.value?.members.values
                                        .firstWhereOrNull(
                                          (e) => e.id != c.me.id.userId,
                                        )
                                        ?.user
                                        .value
                                        .status
                                        ?.val ??
                                    'label_online'.l10n,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<Style>()!
                                            .onPrimary),
                              ),
                              const Spacer(),
                              Text(
                                'label_a_of_b'.l10nfmt({
                                  'a': '${actualMembers.length}',
                                  'b': '${c.chat.value?.members.length}',
                                }),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .extension<Style>()!
                                            .onPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });
}
