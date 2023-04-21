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

import '../controller.dart';
import 'animated_cliprrect.dart';
import 'participant.dart';

/// Builds the [Participant] with a [AnimatedClipRRect].
class MobileBuilder extends StatelessWidget {
  const MobileBuilder(
    this.e,
    this.muted,
    this.animated, {
    super.key,
  });

  /// Separate call entity participating in a call.
  final Participant e;

  /// Mute switching.
  final bool muted;

  /// Animated switching.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        return AnimatedClipRRect(
          key: Key(e.member.id.toString()),
          borderRadius:
              animated ? BorderRadius.circular(10) : BorderRadius.zero,
          child: AnimatedContainer(
            duration: 200.milliseconds,
            decoration: BoxDecoration(
              color:
                  animated ? const Color(0xFF132131) : const Color(0x00132131),
            ),
            width: animated ? MediaQuery.of(context).size.width - 20 : null,
            height: animated ? MediaQuery.of(context).size.height / 2 : null,
            child: StackWidget(e, muted, animated),
          ),
        );
      },
    );
  }
}

/// Сreating overlapping [Widget]'s of various functionality.
class StackWidget extends StatelessWidget {
  const StackWidget(this.e, this.muted, this.animated, {super.key});

  /// Separate call entity participating in a call.
  final Participant e;

  /// Mute switching.
  final bool muted;

  /// Animated switching.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        return Stack(
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
      },
    );
  }
}
