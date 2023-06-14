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

import '../animated_delayed_scale.dart';
import '../conditional_backdrop.dart';
import '../participant/decorator.dart';
import '../participant/overlay.dart';
import '../participant/widget.dart';
import '../reorderable_fit.dart';
import '../video_view.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/component/desktop.dart';
import '/ui/page/call/controller.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';

/// [ReorderableFit] of the primary participants.
class PrimaryView extends StatelessWidget {
  const PrimaryView({
    super.key,
    required this.me,
    required this.audioLabel,
    required this.videoLabel,
    required this.itemConstraintsSize,
    required this.condition,
    required this.anyDragIsHappening,
    required this.targetOpacity,
    required this.children,
    required this.audioState,
    required this.rendererBoxFit,
    required this.center,
    required this.toggleVideoEnabled,
    required this.toggleAudioEnabled,
    required this.removeChatCallMember,
    required this.refreshParticipants,
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
    this.draggedRenderer,
    this.isCenter = true,
    this.hoveredRendererTimeout = 5,
    this.isCursorHidden = false,
  });

  /// [CallMember] of the currently authorized [MyUser]
  final CallMember me;

  /// Local audio stream enabled flag.
  final LocalTrackState audioState;

  /// [Participant] being dragged currently.
  final Participant? draggedRenderer;

  /// Timeout of a hoveredRenderer used to hide it.
  final int hoveredRendererTimeout;

  /// [Participant]s to display in the fit view.
  final bool isCenter;

  /// Indicator whether the cursor should be hidden or not.
  final bool isCursorHidden;

  /// Indicator whether [BackdropFilter] should be enabled or not.
  final bool condition;

  /// Indicator whether a drag event is happening.
  final bool anyDragIsHappening;

  /// [Map] of [BoxFit]s that [RtcVideoRenderer] should explicitly have.
  final Map<String, BoxFit?> rendererBoxFit;

  /// Children widgets needed to be placed in a [Wrap].
  final List<DragData> children;

  /// Label name for audio.
  final String audioLabel;

  /// Label name for video.
  final String videoLabel;

  /// Maximum width and height that satisfies the constraints.
  final double itemConstraintsSize;

  /// Opacity of the [IgnorePointer].
  final double targetOpacity;

  /// Color of the [IgnorePointer].
  final Color? color;

  /// Callback, called when an participant is uncentered.
  final void Function()? uncenter;

  /// Toggles local audio stream on and off.
  final void Function()? toggleVideo;

  /// Toggles local video stream on and off.
  final void Function()? toggleAudio;

  /// Updates the list of participants.
  final void Function() refreshParticipants;

  /// Centers the participant, which means focusing the participant and
  /// unfocusing every participant in focused.
  final void Function(Participant participant) center;

  /// Toggles the provided participant's incoming video on and off.
  final Future<void> Function(Participant participant) toggleVideoEnabled;

  /// Toggles the provided participant's incoming audio on and off.
  final Future<void> Function(Participant participant) toggleAudioEnabled;

  /// Removes [User] identified by the provided user id from the
  /// current call.
  final Future<void> Function(UserId userId) removeChatCallMember;

  /// Callback, called when item dragging is started.
  final dynamic Function(DragData)? onDragStarted;

  /// Callback, called when item dragging is ended.
  final void Function(DragData d)? onDragEnded;

  /// Callback, called when a new item is added.
  final dynamic Function(DragData, int)? onAdded;

  /// Callback, called when some [DragTarget] may accept the dragged item.
  final bool Function(DragData?)? onWillAccept;

  /// Callback, called when a dragged item leaves some [DragTarget].
  final void Function(DragData?)? onLeave;

  /// Callback, specifying an [Offset] of this view.
  final Offset Function()? onOffset;

  /// Callback, called when an item breaks its dough.
  final void Function(DragData)? onDoughBreak;

  /// Triggered when a mouse pointer has exited this widget when the widget
  /// is still mounted.
  final void Function(PointerExitEvent)? onExit;

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
                              refreshParticipants();
                            },
                          ),
                      ],
                      isCenter
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
                        if (participant.member.isDialing.isFalse)
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
                        preferBackdrop: condition,
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
