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

import '../../../../domain/model/chat.dart';
import '../component/desktop.dart';
import '../controller.dart';
import 'animated_delayed_scale.dart';
import 'conditional_backdrop.dart';
import 'participant.dart';
import 'reorderable_fit.dart';

/// [ReorderableFit] of the [CallController.primary] participants.
class PrimaryView extends StatelessWidget {
  const PrimaryView({
    super.key,
    required this.onDragEnded,
    required this.onAdded,
    required this.onWillAccept,
    required this.onLeave,
    required this.onDragStarted,
    required this.onOffset,
    required this.onDoughBreak,
    required this.size,
    required this.doughDraggedRenderer,
    required this.chatId,
    required this.secondaryDrags,
    required this.primaryTargets,
    required this.overlayBuilder,
    required this.primaryDrags,
    required this.secondaryDragged,
    required this.hoveredRenderer,
    required this.rendererBoxFit,
    required this.primary,
    required this.minimized,
    required this.fullscreen,
  });

  ///
  final void Function(DesktopDragData d) onDragEnded;

  ///
  final dynamic Function(DesktopDragData, int)? onAdded;

  ///
  final bool Function(DesktopDragData?)? onWillAccept;

  ///
  final void Function(DesktopDragData?)? onLeave;

  ///
  final dynamic Function(DesktopDragData)? onDragStarted;

  ///
  final Offset Function()? onOffset;

  ///
  final void Function(DesktopDragData)? onDoughBreak;

  ///
  final double size;

  ///
  final Rx<Participant?> doughDraggedRenderer;

  ///
  final Rx<ChatId> chatId;

  ///
  final RxInt secondaryDrags;

  ///
  final RxInt primaryTargets;

  ///
  final RxInt primaryDrags;

  ///
  final RxBool secondaryDragged;

  ///
  final Rx<Participant?> hoveredRenderer;

  ///
  final Widget Function(DesktopDragData)? overlayBuilder;

  ///
  final RxMap<String, BoxFit?> rendererBoxFit;

  ///
  final RxList<Participant> primary;

  ///
  final RxBool minimized;

  ///
  final RxBool fullscreen;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Stack(
        children: [
          ReorderableFit<DesktopDragData>(
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
            itemConstraints: (DesktopDragData data) {
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
                  fit: rendererBoxFit[
                      participant.video.value?.renderer.value?.track.id() ??
                          ''],
                  expanded: doughDraggedRenderer.value == participant,
                );
              });
            },
            children:
                primary.map((e) => DesktopDragData(e, chatId.value)).toList(),
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
