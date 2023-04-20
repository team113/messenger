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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller.dart';
import '../component/common.dart';
import '../widget/conditional_backdrop.dart';
import '../widget/dock.dart';
import '/themes.dart';

/// Builds the more panel containing the [CallController.panel].
class LaunchpadWidget extends StatelessWidget {
  const LaunchpadWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Obx(() {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: c.displayMore.value
                ? DragTarget<CallButton>(
                    onAccept: (CallButton data) {
                      c.buttons.remove(data);
                      c.draggedButton.value = null;
                    },
                    onWillAccept: (CallButton? a) =>
                        a?.c == c && a?.isRemovable == true,
                    builder: (context, candidateData, rejectedData) =>
                        LaunchpadBuilder(
                      candidate: candidateData,
                      rejected: rejectedData,
                    ),
                  )
                : Container(),
          );
        }),
      );
    });
  }
}

/// Displays a call panel with buttons.
class LaunchpadBuilder extends StatelessWidget {
  const LaunchpadBuilder({
    Key? key,
    required this.candidate,
    required this.rejected,
  }) : super(key: key);

  /// [candidate] of [DragTarget] builder.
  final List<CallButton?> candidate;

  /// [rejected] of [DragTarget] builder.
  final List<dynamic> rejected;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(builder: (CallController c) {
      return Obx(() {
        bool enabled = c.displayMore.isTrue &&
            c.primaryDrags.value == 0 &&
            c.secondaryDrags.value == 0;

        return MouseRegion(
          onEnter: enabled ? (d) => c.keepUi(true) : null,
          onHover: enabled ? (d) => c.keepUi(true) : null,
          onExit: enabled ? (d) => c.keepUi() : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                CustomBoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  blurStyle: BlurStyle.outer,
                )
              ],
            ),
            margin: const EdgeInsets.all(2),
            child: ConditionalBackdropFilter(
              borderRadius: BorderRadius.circular(30),
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Obx(() {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: candidate.any((e) => e?.c == c)
                        ? const Color(0xE0165084)
                        : const Color(0x9D165084),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 35),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.start,
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 21,
                          children: c.panel.map((e) {
                            return SizedBox(
                              width: 100,
                              height: 100,
                              child: Column(
                                children: [
                                  DelayedDraggable(
                                    feedback: Transform.translate(
                                      offset: const Offset(
                                        CallController.buttonSize / 2 * -1,
                                        CallController.buttonSize / 2 * -1,
                                      ),
                                      child: SizedBox(
                                        height: CallController.buttonSize,
                                        width: CallController.buttonSize,
                                        child: e.build(),
                                      ),
                                    ),
                                    data: e,
                                    onDragStarted: () {
                                      c.showDragAndDropButtonsHint = false;
                                      c.draggedButton.value = e;
                                    },
                                    onDragCompleted: () =>
                                        c.draggedButton.value = null,
                                    onDragEnd: (_) =>
                                        c.draggedButton.value = null,
                                    onDraggableCanceled: (_, __) =>
                                        c.draggedButton.value = null,
                                    maxSimultaneousDrags:
                                        e.isRemovable ? null : 0,
                                    dragAnchorStrategy:
                                        pointerDragAnchorStrategy,
                                    child: e.build(hinted: false),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    e.hint,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      });
    });
  }
}
