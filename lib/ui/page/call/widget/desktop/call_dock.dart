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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../conditional_backdrop.dart';
import '/themes.dart';
import '/ui/page/call/controller.dart';
import '/ui/page/home/widget/animated_slider.dart';

/// [CallDock] which contains the [CallController.buttons].
class CallDock extends StatelessWidget {
  const CallDock({
    super.key,
    required this.showBottomUi,
    required this.answer,
    required this.relocateSecondary,
    this.dock,
    this.audioButton,
    this.videoButton,
    this.declineButton,
    this.isOutgoing,
    this.onEnter,
    this.onHover,
    this.onExit,
    this.dockKey,
  });

  /// [Widget] that will be shown at the bottom of the screen.
  final Widget? dock;

  /// [Widget] of the call button with audio.
  final Widget? audioButton;

  /// [Widget] of a call button with a video.
  final Widget? videoButton;

  /// [Widget] of the reject call button.
  final Widget? declineButton;

  /// [Function] that is called when the mouse cursor enters the area
  /// of this [CallDock].
  final void Function(PointerEnterEvent)? onEnter;

  /// [Function] that is called when the mouse cursor moves in the area
  /// of this [CallDock].
  final void Function(PointerHoverEvent)? onHover;

  /// [Function] that is called when the mouse cursor leaves the area
  /// of this [CallDock].
  final void Function(PointerExitEvent)? onExit;

  /// Indicator whether the call is outgoing.
  final bool? isOutgoing;

  /// Indicator whether to show the [dock].
  final bool showBottomUi;

  /// Indicator whether the call is incoming.
  final bool answer;

  /// [Key] for handling [dock] widget states.
  final Key? dockKey;

  /// Relocates the secondary view accounting the possible intersections.
  final VoidCallback relocateSecondary;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: const EdgeInsets.only(bottom: 5),
      curve: Curves.ease,
      duration: 200.milliseconds,
      child: AnimatedSwitcher(
        duration: 200.milliseconds,
        child: AnimatedSlider(
          isOpen: showBottomUi,
          duration: 400.milliseconds,
          translate: false,
          listener: relocateSecondary,
          child: MouseRegion(
            onEnter: onEnter,
            onHover: onHover,
            onExit: onExit,
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
                key: dockKey,
                borderRadius: BorderRadius.circular(30),
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Material(
                  color: const Color(0x301D6AAE),
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 5,
                    ),
                    child: answer
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 11),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: audioButton,
                              ),
                              const SizedBox(width: 24),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: videoButton,
                              ),
                              const SizedBox(width: 24),
                              SizedBox.square(
                                dimension: CallController.buttonSize,
                                child: declineButton,
                              ),
                              const SizedBox(width: 11),
                            ],
                          )
                        : dock,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
