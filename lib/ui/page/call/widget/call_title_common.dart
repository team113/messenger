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

import '/domain/repository/chat.dart';
import '/domain/model/ongoing_call.dart';

import 'call_title.dart';

/// [Widget] building the title call information.
class CallTitleCommon extends StatelessWidget {
  const CallTitleCommon({
    super.key,
    required this.isOutgoing,
    required this.isDialog,
    required this.withDots,
    required this.state,
    required this.me,
    required this.chat,
  });

  final bool isOutgoing;

  final bool isDialog;

  final bool withDots;

  final String? state;

  final CallMember me;

  final Rx<RxChat?> chat;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return CallTitle(
        me.id.userId,
        chat: chat.value?.chat.value,
        title: chat.value?.title.value,
        avatar: chat.value?.avatar.value,
        state: state,
        withDots: withDots,
      );
    });
  }
}
