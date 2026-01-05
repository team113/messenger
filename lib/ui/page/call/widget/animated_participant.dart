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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/call/controller.dart';
import 'animated_cliprrect.dart';
import 'participant/decorator.dart';
import 'participant/overlay.dart';
import 'participant/widget.dart';

/// [ParticipantWidget] in [Stack] with its [ParticipantDecoratorWidget] and
/// [ParticipantOverlayWidget], animating its [rounded] changes.
class AnimatedParticipant extends StatelessWidget {
  const AnimatedParticipant(
    this.participant, {
    super.key,
    this.muted = false,
    this.rounded = false,
  });

  /// [Participant] to display.
  final Participant participant;

  /// Indicator whether to display a muted label in [ParticipantOverlayWidget].
  final bool? muted;

  /// Indicator whether this [AnimatedParticipant] should be rounded.
  ///
  /// If `true`, occupies the [MediaQuery] sizes, thus intended to be displayed
  /// in center.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedClipRRect(
      key: Key(participant.member.id.toString()),
      borderRadius: rounded ? BorderRadius.circular(10) : BorderRadius.zero,
      child: AnimatedContainer(
        duration: 200.milliseconds,
        decoration: BoxDecoration(
          color: rounded
              ? style.colors.backgroundAuxiliaryLight
              : style.colors.transparent,
        ),
        width: rounded ? MediaQuery.of(context).size.width - 20 : null,
        height: rounded ? MediaQuery.of(context).size.height / 2 : null,
        child: Stack(
          children: [
            const ParticipantDecoratorWidget(),
            IgnorePointer(
              child: ParticipantWidget(
                participant,
                offstageUntilDetermined: true,
              ),
            ),
            ParticipantOverlayWidget(
              participant,
              muted: muted,
              hovered: rounded,
            ),
          ],
        ),
      ),
    );
  }
}
