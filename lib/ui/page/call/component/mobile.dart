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
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controller.dart';
import '../widget/animated_participant.dart';
import '../widget/call_cover.dart';
import '../widget/floating_fit/view.dart';
import '../widget/minimizable_view.dart';
import '../widget/notification.dart';
import '../widget/participant/decorator.dart';
import '../widget/participant/overlay.dart';
import '../widget/participant/widget.dart';
import '../widget/swappable_fit.dart';
import '../widget/video_view.dart';
import '/config.dart';
import '/domain/model/avatar.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/widget/animated_slider.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/safe_area/safe_area.dart';
import '/ui/widget/svg/svg.dart';
import '/util/global_key.dart';
import '/util/platform_utils.dart';
import 'common.dart';

/// Returns a mobile design of a [CallView].
Widget mobileCall(CallController c, BuildContext context) {
  final style = Theme.of(context).style;

  return LayoutBuilder(
    builder: (context, constraints) {
      final bool isOutgoing =
          (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;

      // Call stackable content.
      List<Widget> content = [
        const SvgImage.asset(
          'assets/images/background_dark.svg',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ];

      // Layer of [Widget]s to display above the UI.
      List<Widget> overlay = [];

      // Active call.
      if ((c.isGroup && isOutgoing) ||
          c.state.value == OngoingCallState.active) {
        content.addAll([
          Obx(() {
            if (c.isDialog &&
                c.primary.length == 1 &&
                c.secondary.length == 1) {
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
                    final bool audioEnabled = c.audioState.value.isEnabled;

                    final bool? muted = e.member.owner == MediaOwnerKind.local
                        ? !audioEnabled
                        : null;

                    // TODO: Implement opened context menu detection for
                    //       `hovered` indicator.
                    return ParticipantOverlayWidget(
                      e,
                      muted: muted,
                      hovered: false,
                    );
                  });
                },
              );
            }

            final Participant? center = c.secondary.isNotEmpty
                ? c.primary.firstOrNull
                : null;

            return SwappableFit<Participant>(
              items: [...c.primary, ...c.secondary],
              center: center,
              fit: c.minimized.value,
              itemBuilder: (e) {
                return Obx(() {
                  final bool audioEnabled = c.audioState.value.isEnabled;

                  final bool? muted = e.member.owner == MediaOwnerKind.local
                      ? !audioEnabled
                      : null;

                  return ContextMenuRegion(
                    actions: [
                      if (c.primary.length + c.secondary.length > 1) ...[
                        if (center == e)
                          ContextMenuButton(
                            label: 'btn_call_uncenter'.l10n,
                            onPressed: c.focusAll,
                            trailing: const SvgIcon(SvgIcons.uncenterVideo),
                          )
                        else
                          ContextMenuButton(
                            label: 'btn_call_center'.l10n,
                            onPressed: () => c.center(e),
                            trailing: const SvgIcon(SvgIcons.centerVideo),
                          ),
                      ],
                      if (e.member.id != c.me.id) ...[
                        if (e.video.value?.direction.value.isEmitting ?? false)
                          ContextMenuButton(
                            label: e.video.value?.renderer.value != null
                                ? 'btn_call_disable_video'.l10n
                                : 'btn_call_enable_video'.l10n,
                            onPressed: () => c.toggleVideoEnabled(e),
                            trailing: SvgIcon(
                              e.video.value?.renderer.value != null
                                  ? SvgIcons.incomingVideoOn
                                  : SvgIcons.incomingVideoOff,
                            ),
                          ),
                        if (e.audio.value?.direction.value.isEmitting ?? false)
                          ContextMenuButton(
                            label:
                                (e.audio.value?.direction.value.isEnabled ==
                                    true)
                                ? 'btn_call_disable_audio'.l10n
                                : 'btn_call_enable_audio'.l10n,
                            onPressed: () => c.toggleAudioEnabled(e),
                            trailing: SvgIcon(
                              e.audio.value?.renderer.value != null
                                  ? SvgIcons.incomingAudioOn
                                  : SvgIcons.incomingAudioOff,
                            ),
                          ),
                        if (e.member.isDialing.isFalse)
                          ContextMenuButton(
                            label: 'btn_call_remove_participant'.l10n,
                            trailing: const SvgIcon(SvgIcons.removeFromCall),
                            onPressed: () =>
                                c.removeChatCallMember(e.member.id.userId),
                          ),
                      ] else ...[
                        ContextMenuButton(
                          label: c.videoState.value.isEnabled
                              ? 'btn_call_video_off'.l10n
                              : 'btn_call_video_on'.l10n,
                          onPressed: c.toggleVideo,
                          trailing: SvgIcon(
                            c.videoState.value.isEnabled
                                ? SvgIcons.cameraOn
                                : SvgIcons.cameraOff,
                          ),
                        ),
                        ContextMenuButton(
                          label: c.audioState.value.isEnabled
                              ? 'btn_call_audio_off'.l10n
                              : 'btn_call_audio_on'.l10n,
                          onPressed: c.toggleAudio,
                          trailing: SvgIcon(
                            c.audioState.value.isEnabled
                                ? SvgIcons.micOn
                                : SvgIcons.micOff,
                          ),
                        ),
                      ],
                    ],
                    unconstrained: true,
                    builder: (animated) {
                      return AnimatedParticipant(
                        e,
                        muted: muted,
                        rounded: animated,
                      );
                    },
                  );
                });
              },
            );
          }),
        ]);
      } else {
        // Call is not active.
        content.add(
          Obx(() {
            RtcVideoRenderer? local =
                (c.locals.firstOrNull?.video.value?.renderer.value ??
                        c.paneled.firstOrNull?.video.value?.renderer.value)
                    as RtcVideoRenderer?;

            if (c.videoState.value != LocalTrackState.disabled &&
                local != null) {
              return RtcVideoView(local, fit: BoxFit.cover);
            }

            return Stack(
              children: [
                // Display a [CallCover] of the call.
                Obx(() {
                  final bool isDialog =
                      c.chat.value?.chat.value.isDialog == true;

                  if (isDialog) {
                    final RxUser? user = c.chat.value?.members.values
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
                    } else {
                      return CallCoverWidget(null, chat: c.chat.value);
                    }
                  }
                }),
              ],
            );
          }),
        );
      }

      // If there's any notifications to show, display them.
      overlay.add(
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 8 + context.mediaQueryPadding.top),
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

      final List<Widget> ui = [
        // Dimmed container if any video is displayed while calling.
        Obx(() {
          return IgnorePointer(
            child: SafeAnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child:
                  (c.state.value != OngoingCallState.active &&
                      c.state.value != OngoingCallState.joining &&
                      ([...c.primary, ...c.secondary].firstWhereOrNull(
                            (e) => e.video.value?.renderer.value != null,
                          ) !=
                          null) &&
                      !c.minimized.value)
                  ? Container(color: style.colors.onBackgroundOpacity27)
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
                        final distance =
                            (d.localPosition.distanceSquared -
                                    c.downPosition.distanceSquared)
                                .abs() <=
                            80000;

                        final time =
                            DateTime.now()
                                .difference(c.downAt!)
                                .inMilliseconds <
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
        CustomSafeArea(
          child: Obx(() {
            final bool active = c.state.value == OngoingCallState.active;
            final bool incoming = !isOutgoing;

            final bool showUi =
                (!c.isGroup || incoming) && !active && !c.minimized.value;

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

        // Sliding from the top call information.
        CustomSafeArea(
          child: Obx(() {
            final bool active = c.state.value == OngoingCallState.active;
            final bool showUi = c.showUi.value && active && !c.minimized.value;

            return Align(
              alignment: Alignment.topCenter,
              child: AnimatedSlider(
                duration: const Duration(milliseconds: 250),
                isOpen: showUi,
                beginOffset: Offset(
                  0,
                  -50 - MediaQuery.of(context).padding.top,
                ),
                endOffset: const Offset(0, 0),
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
                      color: style.colors.primaryAuxiliaryOpacity25,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            c.chat.value?.title() ?? ('dot'.l10n * 3),
                            style: style.fonts.small.regular.onPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(7, 0, 5, 0),
                          width: 1,
                          height: 14,
                          color: style.colors.onPrimary,
                        ),
                        if (c.isGroup) ...[
                          Text(
                            'label_a_of_b'.l10nfmt({
                              'a': c.members.keys
                                  .where((e) => e.deviceId != null)
                                  .map((k) => k.userId)
                                  .toSet()
                                  .length,
                              'b': c.chat.value?.chat.value.membersCount ?? 1,
                            }),
                            style: style.fonts.small.regular.onPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(7, 0, 5, 0),
                            width: 1,
                            height: 14,
                            color: style.colors.onPrimary,
                          ),
                        ],
                        Text(
                          Config.disableInfiniteAnimations
                              ? '00:00'
                              : c.duration.value.hhMmSs(),
                          style: style.fonts.small.regular.onPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        // Sliding from the bottom buttons panel.
        Obx(() {
          final bool showUi =
              (c.showUi.isTrue || c.state.value != OngoingCallState.active) &&
              !c.minimized.value;

          double panelHeight = 0;
          double minHeight = 0;
          List<Widget> panelChildren = [];

          final bool panel =
              (c.isGroup && isOutgoing) ||
              c.state.value == OngoingCallState.active ||
              c.state.value == OngoingCallState.joining;

          // Populate the sliding panel height and its content.
          if (panel) {
            panelHeight = 260 + max(37, MediaQuery.of(context).padding.bottom);
            panelHeight = min(c.size.height - 45, panelHeight);

            minHeight = 95 + max(35, MediaQuery.of(context).padding.bottom);
            minHeight = min(c.size.height - 45, minHeight);

            panelChildren = [
              const SizedBox(height: 12),
              buttons([
                if (PlatformUtils.isMobile)
                  padding(
                    c.videoState.value.isEnabled
                        ? SwitchButton(c).build(expanded: c.isPanelOpen.value)
                        : SpeakerButton(c).build(expanded: c.isPanelOpen.value),
                  ),
                if (PlatformUtils.isDesktop)
                  padding(ScreenButton(c).build(expanded: c.isPanelOpen.value)),
                padding(AudioButton(c).build(expanded: c.isPanelOpen.value)),
                padding(VideoButton(c).build(expanded: c.isPanelOpen.value)),
                padding(EndCallButton(c).build(expanded: c.isPanelOpen.value)),
              ]),
              const SizedBox(height: 32),
              buttons([
                padding(ParticipantsButton(c).build(expanded: true)),
                padding(HandButton(c).build(expanded: true)),
                padding(RemoteAudioButton(c).build(expanded: true)),
                padding(RemoteVideoButton(c).build(expanded: true)),
              ]),
            ];
          }

          final Widget child;

          if (panel) {
            child = AnimatedSlider(
              beginOffset: Offset(0, minHeight),
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
                  color: style.colors.primaryAuxiliaryOpacity90,
                  backdropEnabled: true,
                  backdropOpacity: 0,
                  minHeight: minHeight,
                  maxHeight: panelHeight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  panel: Column(
                    key: c.dockKey,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            color: style.colors.onPrimaryOpacity50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(child: Column(children: panelChildren)),
                    ],
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
            );
          } else {
            final List<Widget> widgets;

            if (isOutgoing) {
              widgets = [
                if (PlatformUtils.isMobile)
                  padding(
                    c.videoState.value.isEnabled
                        ? SwitchButton(c).build(hinted: false, opaque: true)
                        : SpeakerButton(c).build(hinted: false, opaque: true),
                  ),
                padding(AudioButton(c).build(hinted: false, opaque: true)),
                padding(VideoButton(c).build(hinted: false, opaque: true)),
                padding(EndCallButton(c).build(hinted: false, opaque: true)),
              ];
            } else {
              widgets = [
                padding(
                  AcceptAudioButton(
                    c,
                    highlight: !c.withVideo,
                    shadows: true,
                  ).build(expanded: true),
                ),
                padding(
                  AcceptVideoButton(
                    c,
                    highlight: c.withVideo,
                    shadows: true,
                  ).build(expanded: true),
                ),
                padding(DeclineButton(c, shadows: true).build(expanded: true)),
              ];
            }

            child = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: isOutgoing
                          ? max(0, MediaQuery.of(context).padding.bottom - 30)
                          : max(30, MediaQuery.of(context).padding.bottom),
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: c.minimized.value ? 0 : 1,
                      child: buttons(widgets),
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeAnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: child,
          );
        }),
      ];

      // Combines all the stackable content into [Scaffold].
      Widget scaffold = Scaffold(
        backgroundColor: style.colors.secondaryBackgroundLight,
        body: Stack(
          children: [
            ...content,
            const MouseRegion(opaque: false, cursor: SystemMouseCursors.basic),
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
            return IgnorePointer(ignoring: c.minimized.value, child: scaffold);
          }),
        );
      });
    },
  );
}
