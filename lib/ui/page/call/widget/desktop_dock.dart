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
import '../../home/widget/animated_slider.dart';
import '/domain/model/ongoing_call.dart';
import '/themes.dart';

/// Builds the [Dock] containing the [CallController.buttons].
class DockWidget extends StatelessWidget {
  const DockWidget(
    this.c, {
    Key? key,
  }) : super(key: key);

  /// Controller of an [OngoingCall] overlay.
  final CallController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isOutgoing =
          (c.outgoing || c.state.value == OngoingCallState.local) && !c.started;

      bool showBottomUi = (c.showUi.isTrue ||
          c.draggedButton.value != null ||
          c.state.value != OngoingCallState.active ||
          (c.state.value == OngoingCallState.active &&
              c.locals.isEmpty &&
              c.remotes.isEmpty &&
              c.focused.isEmpty &&
              c.paneled.isEmpty));

      return AnimatedPadding(
        key: const Key('DockedAnimatedPadding'),
        padding: const EdgeInsets.only(bottom: 5),
        curve: Curves.ease,
        duration: 200.milliseconds,
        child: AnimatedSwitcher(
          key: const Key('DockedAnimatedSwitcher'),
          duration: 200.milliseconds,
          child: AnimatedSlider(
            key: const Key('DockedPanelPadding'),
            isOpen: showBottomUi,
            duration: 400.milliseconds,
            translate: false,
            listener: () => Future.delayed(Duration.zero, c.relocateSecondary),
            child: MouseRegion(
              onEnter: (d) => c.keepUi(true),
              onHover: (d) => c.keepUi(true),
              onExit: c.showUi.value && !c.displayMore.value
                  ? (d) => c.keepUi(false)
                  : (d) => c.keepUi(),
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
                margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                child: ConditionalBackdropFilter(
                  key: c.dockKey,
                  borderRadius: BorderRadius.circular(30),
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x301D6AAE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 5,
                    ),
                    child: Obx(() {
                      final bool answer =
                          (c.state.value != OngoingCallState.joining &&
                              c.state.value != OngoingCallState.active &&
                              !isOutgoing);

                      if (answer) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 11),
                            SizedBox.square(
                              dimension: CallController.buttonSize,
                              child: AcceptAudioButton(
                                c,
                                highlight: !c.withVideo,
                              ).build(),
                            ),
                            const SizedBox(width: 24),
                            SizedBox.square(
                              dimension: CallController.buttonSize,
                              child: AcceptVideoButton(
                                c,
                                highlight: c.withVideo,
                              ).build(),
                            ),
                            const SizedBox(width: 24),
                            SizedBox.square(
                              dimension: CallController.buttonSize,
                              child: DeclineButton(c).build(),
                            ),
                            const SizedBox(width: 11),
                          ],
                        );
                      } else {
                        return Dock<CallButton>(
                          items: c.buttons,
                          itemWidth: CallController.buttonSize,
                          itemBuilder: (e) => e.build(
                            hinted: c.draggedButton.value == null,
                          ),
                          onReorder: (buttons) {
                            c.buttons.clear();
                            c.buttons.addAll(buttons);
                            c.relocateSecondary();
                          },
                          onDragStarted: (b) {
                            c.showDragAndDropButtonsHint = false;
                            c.draggedButton.value = b;
                          },
                          onDragEnded: (_) => c.draggedButton.value = null,
                          onLeave: (_) => c.displayMore.value = true,
                          onWillAccept: (d) => d?.c == c,
                        );
                      }
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
