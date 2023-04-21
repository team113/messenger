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
import 'package:messenger/l10n/l10n.dart';

import '../controller.dart';
import '/domain/model/ongoing_call.dart';

import 'call_title.dart';

/// [Widget] building the title call information.
class CallTitleCommon extends StatelessWidget {
  const CallTitleCommon({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (CallController c) {
        return Obx(() {
          final bool isOutgoing =
              (c.outgoing || c.state.value == OngoingCallState.local) &&
                  !c.started;
          final bool isDialog = c.chat.value?.chat.value.isDialog == true;
          final bool withDots = c.state.value != OngoingCallState.active &&
              (c.state.value == OngoingCallState.joining || isOutgoing);
          final String? state = c.state.value == OngoingCallState.active
              ? c.duration.value.toString().split('.').first.padLeft(8, '0')
              : c.state.value == OngoingCallState.joining
                  ? 'label_call_joining'.l10n
                  : isOutgoing
                      ? isDialog
                          ? null
                          : 'label_call_connecting'.l10n
                      : c.withVideo == true
                          ? 'label_video_call'.l10n
                          : 'label_audio_call'.l10n;

          return CallTitle(
            c.me.id.userId,
            chat: c.chat.value?.chat.value,
            title: c.chat.value?.title.value,
            avatar: c.chat.value?.avatar.value,
            state: state,
            withDots: withDots,
          );
        });
      },
    );
  }
}
