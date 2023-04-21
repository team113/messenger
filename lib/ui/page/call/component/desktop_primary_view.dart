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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/l10n/l10n.dart';

import '../controller.dart';
import '../widget/animated_delayed_scale.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/participant.dart';
import '../widget/reorderable_fit.dart';
import '../widget/video_view.dart';
import '../../../widget/context_menu/menu.dart';
import '../../../widget/context_menu/region.dart';
import '/domain/model/ongoing_call.dart';
import '/util/web/non_web.dart';

import 'desktop.dart';

/// [ReorderableFit] of the [CallController.primary] participants.
class PrimaryView extends StatelessWidget {
  const PrimaryView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        void onDragEnded(DesktopDragData d) {
          c.primaryDrags.value = 0;
          c.draggedRenderer.value = null;
          c.doughDraggedRenderer.value = null;
          c.hoveredRenderer.value = d.participant;
          c.hoveredRendererTimeout = 5;
          c.isCursorHidden.value = false;
        }

        return Stack(
          children: [
            ReorderableFit<DesktopDragData>(
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
              overlayBuilder: (DesktopDragData data) {
                var participant = data.participant;

                return LayoutBuilder(builder: (context, constraints) {
                  return Obx(() {
                    bool? muted =
                        participant.member.owner == MediaOwnerKind.local
                            ? !c.audioState.value.isEnabled
                            : participant.audio.value?.isMuted.value ?? false;

                    bool anyDragIsHappening = c.secondaryDrags.value != 0 ||
                        c.primaryDrags.value != 0 ||
                        c.secondaryDragged.value;

                    bool isHovered = c.hoveredRenderer.value == participant &&
                        !anyDragIsHappening;

                    BoxFit? fit =
                        participant.video.value?.renderer.value == null
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
                      child: AnimatedOpacity(
                        duration: 200.milliseconds,
                        opacity:
                            c.draggedRenderer.value == data.participant ? 0 : 1,
                        child: ContextMenuRegion(
                          key: ObjectKey(participant),
                          preventContextMenu: true,
                          actions: [
                            if (participant.video.value?.renderer.value !=
                                null) ...[
                              if (participant.source == MediaSourceKind.Device)
                                ContextMenuButton(
                                  label: fit == null || fit == BoxFit.cover
                                      ? 'btn_call_do_not_cut_video'.l10n
                                      : 'btn_call_cut_video'.l10n,
                                  onPressed: () {
                                    c.rendererBoxFit[participant
                                            .video.value!.renderer.value!.track
                                            .id()] =
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
                                  label:
                                      participant.video.value?.renderer.value !=
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
                });
              },
              decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
              itemConstraints: (DesktopDragData data) {
                final double size = (c.size.longestSide * 0.33).clamp(100, 250);
                return BoxConstraints(maxWidth: size, maxHeight: size);
              },
              itemBuilder: (DesktopDragData data) {
                var participant = data.participant;
                return Obx(() {
                  return ParticipantWidget(
                    participant,
                    key: ObjectKey(participant),
                    offstageUntilDetermined: true,
                    respectAspectRatio: true,
                    borderRadius: BorderRadius.zero,
                    onSizeDetermined: participant.video.value?.renderer.refresh,
                    fit: c.rendererBoxFit[
                        participant.video.value?.renderer.value?.track.id() ??
                            ''],
                    expanded: c.doughDraggedRenderer.value == participant,
                  );
                });
              },
              children: c.primary
                  .map((e) => DesktopDragData(e, c.chatId.value))
                  .toList(),
            ),
            IgnorePointer(
              child: Obx(() {
                return AnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: c.secondaryDrags.value != 0 &&
                          c.primaryTargets.value != 0
                      ? Container(
                          color: const Color(0x40000000),
                          child: Center(
                            child: AnimatedDelayedScale(
                              duration: const Duration(milliseconds: 300),
                              beginScale: 1,
                              endScale: 1.06,
                              child: ConditionalBackdropFilter(
                                condition:
                                    !c.minimized.value || c.fullscreen.value,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color:
                                        !c.minimized.value || c.fullscreen.value
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
    });
  }
}
