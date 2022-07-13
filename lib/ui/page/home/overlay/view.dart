// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '../../../../domain/model/ongoing_call.dart';
import '../../call/controller.dart';
import 'controller.dart';

/// View of an [OngoingCall]s overlay.
///
/// Builds [CallView]s in a [Stack] with a [child] as a first element.
class CallOverlayView extends StatelessWidget {
  const CallOverlayView({required this.child, Key? key}) : super(key: key);

  /// Overlay's [Stack] first child.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CallOverlayController>(
      init: CallOverlayController(Get.find(), Get.find()),
      builder: (CallOverlayController c) => Obx(
        () {
          return SafeArea(
            child: Stack(
              children: [
                child,
                ...c.calls
                    .map(
                      (e) => Obx(
                        () => e.call.value.state.value == OngoingCallState.ended
                            ? Container()
                            : Listener(
                                onPointerDown: (_) => c.orderFirst(e),
                                child: CallView(
                                  e.call,
                                  key: e.key,
                                  edgeInsets: MediaQuery.of(context).padding,
                                ),
                              ),
                      ),
                    )
                    .toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
