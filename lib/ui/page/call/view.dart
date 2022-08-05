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

import '/domain/model/ongoing_call.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';
import 'component/desktop.dart';
import 'component/mobile.dart';
import 'controller.dart';

/// View of an [OngoingCall] overlay.
class CallView extends StatelessWidget {
  const CallView(this._call, {Key? key}) : super(key: key);

  /// Current [OngoingCall].
  final Rx<OngoingCall> _call;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('Call'),
      init: CallController(
        _call,
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      tag: key?.hashCode.toString(),
      builder: (CallController c) {
        if (WebUtils.isPopup) {
          c.minimized.value = false;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [desktopCall(c, context)],
          );
        }

        if (c.isMobile != context.isMobile) {
          c.isMobile = context.isMobile;
          if (context.isMobile) {
            c.minimized.value = false;
          } else {
            c.minimized.value = true;
          }
        }

        if (c.isMobile) {
          return mobileCall(c, context);
        } else {
          return desktopCall(c, context);
        }
      },
    );
  }
}
