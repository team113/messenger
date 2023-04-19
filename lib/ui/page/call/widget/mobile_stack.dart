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

import '../controller.dart';

import 'participant.dart';

/// Сreating overlapping [Widget]'s of various functionality.
class StackWidget extends StatelessWidget {
  const StackWidget({
    Key? key,
    required this.e,
    required this.muted,
    required this.animated,
    required this.c,
  }) : super(key: key);

  /// Separate call entity participating in a call.
  final Participant e;

  /// Mute switching.
  final bool muted;

  /// Animated switching.
  final bool animated;

  /// Controller of an [OngoingCall] overlay.
  final CallController c;

  @override
  Widget build(BuildContext context) {
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
  }
}
