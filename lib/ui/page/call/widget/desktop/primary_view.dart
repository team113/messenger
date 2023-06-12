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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:medea_jason/medea_jason.dart';

import '../../../../../domain/model/user.dart';
import '../../component/desktop.dart';
import '../../controller.dart';
import '../animated_delayed_scale.dart';
import '../conditional_backdrop.dart';
import '../participant/decorator.dart';
import '../participant/overlay.dart';
import '../participant/widget.dart';
import '../reorderable_fit.dart';
import '../video_view.dart';
import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';

/// [ReorderableFit] of the [CallController.primary] participants.
class PrimaryView extends StatelessWidget {
  const PrimaryView({
    super.key,
    required this.me,
    required this.primary,
    required this.audioLabel,
    required this.videoLabel,
    required this.itemConstraintsSize,
    required this.preferBackdrop,
    required this.condition,
    required this.anyDragIsHappening,
    required this.targetOpacity,
    required this.children,
    required this.audioState,
    required this.rendererBoxFit,
    required this.focused,
    required this.remotes,
    required this.locals,
    required this.center,
    required this.toggleVideoEnabled,
    required this.toggleAudioEnabled,
    required this.removeChatCallMember,
    required this.refreshData,
    this.color,
    this.uncenter,
    this.toggleVideo,
    this.toggleAudio,
    this.onDragEnded,
    this.onAdded,
    this.onWillAccept,
    this.onLeave,
    this.onDragStarted,
    this.onOffset,
    this.onDoughBreak,
    this.onExit,
    this.hoveredRendererTimeout = 5,
    this.draggedRenderer,
    this.isCursorHidden = false,
  });

  ///
  final CallMember me;

  ///
  final List<Participant> primary;

  ///
  final LocalTrackState audioState;

  ///
  final Participant? draggedRenderer;

  ///
  final int hoveredRendererTimeout;

  ///
  final bool isCursorHidden;

  ///
  final Map<String, BoxFit?> rendererBoxFit;

  ///
  final List<Participant> focused;

  ///
  final List<Participant> remotes;

  ///
  final List<Participant> locals;

  ///
  final String audioLabel;

  ///
  final String videoLabel;

  ///
  final double itemConstraintsSize;

  ///
  final bool preferBackdrop;

  ///
  final bool condition;

  ///
  final bool anyDragIsHappening;

  ///
  final double targetOpacity;

  ///
  final Color? color;

  ///
  final void Function()? uncenter;

  final void Function(Participant participant) center;

  final Future<void> Function(Participant participant) toggleVideoEnabled;

  final Future<void> Function(Participant participant) toggleAudioEnabled;

  final Future<void> Function(UserId userId) removeChatCallMember;

  ///
  final void Function()? toggleVideo;

  ///
  final void Function()? toggleAudio;

  ///
  final void Function(DragData d)? onDragEnded;

  ///
  final dynamic Function(DragData, int)? onAdded;

  ///
  final bool Function(DragData?)? onWillAccept;

  ///
  final void Function(DragData?)? onLeave;

  ///
  final dynamic Function(DragData)? onDragStarted;

  ///
  final Offset Function()? onOffset;

  ///
  final void Function(DragData)? onDoughBreak;

  ///
  final void Function(PointerExitEvent)? onExit;

  final void Function() refreshData;

  ///
  final List<DragData> children;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    return Stack(
      children: [
        ReorderableFit<DragData>(
          key: const Key('PrimaryFitView'),
          allowEmptyTarget: true,
          onAdded: onAdded,
          onWillAccept: onWillAccept,
          onLeave: onLeave,
          onDragStarted: onDragStarted,
          onOffset: onOffset,
          onDoughBreak: onDoughBreak,
          onDragEnd: onDragEnded,
          onDragCompleted: onDragEnded,
          onDraggableCanceled: onDragEnded,
          overlayBuilder: (DragData data) {
            var participant = data.participant;

            return LayoutBuilder(builder: (context, constraints) {
              Participant? hoveredRenderer;

              bool? muted = participant.member.owner == MediaOwnerKind.local
                  ? !audioState.isEnabled
                  : null;

              bool isHovered =
                  hoveredRenderer == participant && !anyDragIsHappening;

              BoxFit? fit = participant.video.value?.renderer.value == null
                  ? null
                  : rendererBoxFit[participant
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
                  if (draggedRenderer == null) {
                    hoveredRenderer = data.participant;
                    hoveredRendererTimeout;
                    isCursorHidden;
                  }
                },
                onHover: (d) {
                  if (draggedRenderer == null) {
                    hoveredRenderer = data.participant;
                    hoveredRendererTimeout;
                    isCursorHidden;
                  }
                },
                onExit: onExit,
                child: AnimatedOpacity(
                  duration: 200.milliseconds,
                  opacity: draggedRenderer == data.participant ? 0 : 1,
                  child: ContextMenuRegion(
                    key: ObjectKey(participant),
                    preventContextMenu: true,
                    actions: [
                      if (participant.video.value?.renderer.value != null) ...[
                        if (participant.source == MediaSourceKind.Device)
                          ContextMenuButton(
                            label: fit == null || fit == BoxFit.cover
                                ? 'btn_call_do_not_cut_video'.l10n
                                : 'btn_call_cut_video'.l10n,
                            onPressed: () {
                              rendererBoxFit[participant
                                      .video.value!.renderer.value!.track
                                      .id()] =
                                  fit == null || fit == BoxFit.cover
                                      ? BoxFit.contain
                                      : BoxFit.cover;
                              refreshData();
                            },
                          ),
                      ],
                      primary.length == 1
                          ? ContextMenuButton(
                              label: 'btn_call_uncenter'.l10n,
                              onPressed: uncenter,
                            )
                          : ContextMenuButton(
                              label: 'btn_call_center'.l10n,
                              onPressed: () => center(participant),
                            ),
                      if (participant.member.id != me.id) ...[
                        if (participant
                                .video.value?.direction.value.isEmitting ??
                            false)
                          ContextMenuButton(
                            label:
                                participant.video.value?.renderer.value != null
                                    ? 'btn_call_disable_video'.l10n
                                    : 'btn_call_enable_video'.l10n,
                            onPressed: () => toggleVideoEnabled(participant),
                          ),
                        if (participant
                                .audio.value?.direction.value.isEmitting ??
                            false)
                          ContextMenuButton(
                            label: (participant.audio.value?.direction.value
                                        .isEnabled ==
                                    true)
                                ? 'btn_call_disable_audio'.l10n
                                : 'btn_call_enable_audio'.l10n,
                            onPressed: () => toggleAudioEnabled(participant),
                          ),
                        if (participant.member.isRedialing.isFalse)
                          ContextMenuButton(
                            label: 'btn_call_remove_participant'.l10n,
                            onPressed: () => removeChatCallMember(
                              participant.member.id.userId,
                            ),
                          ),
                      ] else ...[
                        ContextMenuButton(
                          label: videoLabel,
                          onPressed: toggleVideo,
                        ),
                        ContextMenuButton(
                          label: audioLabel,
                          onPressed: toggleAudio,
                        ),
                      ],
                    ],
                    child: IgnorePointer(
                      child: ParticipantOverlayWidget(
                        participant,
                        key: ObjectKey(participant),
                        muted: muted,
                        hovered: isHovered,
                        preferBackdrop: preferBackdrop,
                      ),
                    ),
                  ),
                ),
              );
            });
          },
          decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
          itemConstraints: (DragData data) {
            return BoxConstraints(
              maxWidth: itemConstraintsSize,
              maxHeight: itemConstraintsSize,
            );
          },
          itemBuilder: (DragData data) {
            var participant = data.participant;

            return ParticipantWidget(
              participant,
              key: ObjectKey(participant),
              offstageUntilDetermined: true,
              respectAspectRatio: true,
              borderRadius: BorderRadius.zero,
              onSizeDetermined: participant.video.value?.renderer.refresh,
              fit: rendererBoxFit[
                  participant.video.value?.renderer.value?.track.id() ?? ''],
            );
          },
          children: children,
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            duration: 200.milliseconds,
            opacity: targetOpacity,
            child: Container(
              color: style.colors.onBackgroundOpacity27,
              child: Center(
                child: AnimatedDelayedScale(
                  duration: const Duration(milliseconds: 300),
                  beginScale: 1,
                  endScale: 1.06,
                  child: ConditionalBackdropFilter(
                    condition: condition,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: color,
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
            ),
          ),
        ),
      ],
    );
  }
}
