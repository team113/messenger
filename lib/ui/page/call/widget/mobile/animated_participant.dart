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

import '../animated_cliprrect.dart';
import '/ui/page/call/controller.dart';
import 'participant_stack.dart';

/// [Widget] which builds the [Participant] with a [AnimatedClipRRect].
class AnimatedParticipant extends StatelessWidget {
  const AnimatedParticipant(
    this.e,
    this.muted,
    this.animated,
    this.minimized, {
    super.key,
  });

  /// [Participant] object that represents a separate call entity
  /// participating in a call.
  final Participant e;

  /// Indicator that determines whether the participant's
  /// sound is muted or not.
  final bool muted;

  /// Indicator that determines whether animation is turned on or off.
  final bool animated;

  /// Indicator that determines whether the widget is minimized or not.
  final RxBool minimized;

  @override
  Widget build(BuildContext context) {
    return AnimatedClipRRect(
      key: Key(e.member.id.toString()),
      borderRadius: animated ? BorderRadius.circular(10) : BorderRadius.zero,
      child: AnimatedContainer(
        duration: 200.milliseconds,
        decoration: BoxDecoration(
          color: animated ? const Color(0xFF132131) : const Color(0x00132131),
        ),
        width: animated ? MediaQuery.of(context).size.width - 20 : null,
        height: animated ? MediaQuery.of(context).size.height / 2 : null,
        child: ParticipantStack(e, muted, animated, minimized),
      ),
    );
  }
}
