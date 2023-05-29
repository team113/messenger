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

import 'dart:async';

import 'package:flutter/material.dart';

import '../message_field/controller.dart';
import '/domain/model/chat_item.dart';
import '/domain/repository/chat.dart';
import 'blocked_field.dart';

/// [Widget] which returns a bottom bar of this [ChatView] to display under
/// the messages list containing a send/edit field.
class BottomBar extends StatelessWidget {
  const BottomBar({
    super.key,
    required this.edit,
    this.send,
    this.unblacklist,
    this.keepTyping,
    this.chat,
    this.onEdit,
    this.onSend,
  });

  /// [RxChat] object that represents the active chat.
  final RxChat? chat;

  /// Reactive [MessageFieldController] object that represents the message
  /// input [MessageFieldView] if the user is editing an existing message.
  final MessageFieldController? edit;

  /// [MessageFieldController] object that represents the message input
  /// [MessageFieldView] if the user is creating a new message.
  final MessageFieldController? send;

  /// [Function] that is called when the user chooses to unblock the chat.
  final void Function()? unblacklist;

  /// [Function] that is called when the user is typing a message.
  final void Function()? keepTyping;

  /// Reactive [MessageFieldController] object that represents the message
  /// input [MessageFieldView] if the user is editing an existing message.
  final Future<void> Function(ChatItemId)? onEdit;

  /// [MessageFieldController] object that represents the message input
  /// [MessageFieldView] if the user is creating a new message.
  final Future<void> Function(ChatItemId)? onSend;

  @override
  Widget build(BuildContext context) {
    if (chat?.blacklisted == true) {
      return BlockedField(onPressed: unblacklist);
    }

    return edit != null
        ? MessageFieldView(
            key: const Key('EditField'),
            controller: edit,
            onItemPressed: onEdit,
            canAttach: false,
          )
        : MessageFieldView(
            key: const Key('SendField'),
            controller: send,
            onChanged: chat!.chat.value.isMonolog ? null : keepTyping,
            onItemPressed: onSend,
            canForward: true,
          );
  }
}
