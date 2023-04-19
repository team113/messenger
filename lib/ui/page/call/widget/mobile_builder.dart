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
import 'mobile_stack.dart';

/// Builds the [Participant] with a [AnimatedClipRRect].
class MobileBuilder extends StatelessWidget {
  const MobileBuilder({
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
        child: StackWidget(
          e: e,
          muted: muted,
          animated: animated,
          c: c,
        ),
      ),
    );
  }
}
