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

import '../component/desktop.dart';
import '../controller.dart';
import '/domain/model/chat.dart';
import 'animated_delayed_scale.dart';
import 'conditional_backdrop.dart';
import 'participant.dart';
import 'reorderable_fit.dart';

/// [ReorderableFit] of the [CallController.primary] participants.
class PrimaryView extends StatelessWidget {
  const PrimaryView({
    super.key,
    required this.size,
    required this.doughDraggedRenderer,
    required this.chatId,
    required this.secondaryDrags,
    required this.primaryTargets,
    required this.primaryDrags,
    required this.secondaryDragged,
    required this.hoveredRenderer,
    required this.rendererBoxFit,
    required this.primary,
    required this.minimized,
    required this.fullscreen,
    this.onAdded,
    this.onWillAccept,
    this.onLeave,
    this.onDragStarted,
    this.onDragEnded,
    this.onOffset,
    this.onDoughBreak,
    this.overlayBuilder,
  });

  /// [Function] that is called when a drag event is completed.
  final void Function(DragData d)? onDragEnded;

  /// [Function] that is called when an item is added to the widget.
  final dynamic Function(DragData, int)? onAdded;

  /// Function that is called when an item is about to be accepted
  /// into the widget.
  final bool Function(DragData?)? onWillAccept;

  /// Function that is called when an item is removed from the widget.
  final void Function(DragData?)? onLeave;

  /// function that is called when a drag event starts.
  final dynamic Function(DragData)? onDragStarted;

  /// function that returns the current offset value.
  final Offset Function()? onOffset;

  /// function that is called when a "dough" is broken.
  final void Function(DragData)? onDoughBreak;

  /// double value representing the size of the widget.
  final double size;

  /// [Rx] variable that stores the dragged "dough" renderer.
  final Rx<Participant?> doughDraggedRenderer;

  /// [Rx] variable that stores the ID of the chat.
  final Rx<ChatId> chatId;

  /// [Rx] variable that stores the number of secondary drag events.
  final RxInt secondaryDrags;

  /// [Rx] variable that stores the number of primary targets.
  final RxInt primaryTargets;

  /// [Rx] variable that stores the number of primary drag events.
  final RxInt primaryDrags;

  /// [Rx] indicator that stores the state of the secondary drag event.
  final RxBool secondaryDragged;

  /// [Rx] variable that stores the hovered renderer.
  final Rx<Participant?> hoveredRenderer;

  /// [Function] that builds an overlay widget.
  final Widget Function(DragData)? overlayBuilder;

  /// [RxMap] that stores the fit of the renderer.
  final RxMap<String, BoxFit?> rendererBoxFit;

  /// [RxList] of participants.
  final RxList<Participant> primary;

  /// [Rx] indicator that stores the minimized state of the widget.
  final RxBool minimized;

  /// [Rx] indicator that stores the full-screen state of the widget.
  final RxBool fullscreen;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
            overlayBuilder: overlayBuilder,
            decoratorBuilder: (_) => const ParticipantDecoratorWidget(),
            itemConstraints: (DragData data) {
              return BoxConstraints(maxWidth: size, maxHeight: size);
            },
            itemBuilder: (DragData data) {
              var participant = data.participant;
              return Obx(() {
                return ParticipantWidget(
                  participant,
                  key: ObjectKey(participant),
                  offstageUntilDetermined: true,
                  respectAspectRatio: true,
                  borderRadius: BorderRadius.zero,
                  onSizeDetermined: participant.video.value?.renderer.refresh,
                  fit: rendererBoxFit[
                      participant.video.value?.renderer.value?.track.id() ??
                          ''],
                  expanded: doughDraggedRenderer.value == participant,
                );
              });
            },
            children: primary.map((e) => DragData(e, chatId.value)).toList(),
          ),
          IgnorePointer(
            child: Obx(() {
              return AnimatedSwitcher(
                duration: 200.milliseconds,
                child: secondaryDrags.value != 0 && primaryTargets.value != 0
                    ? Container(
                        color: const Color(0x40000000),
                        child: Center(
                          child: AnimatedDelayedScale(
                            duration: const Duration(milliseconds: 300),
                            beginScale: 1,
                            endScale: 1.06,
                            child: ConditionalBackdropFilter(
                              condition: !minimized.value || fullscreen.value,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: !minimized.value || fullscreen.value
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
}
