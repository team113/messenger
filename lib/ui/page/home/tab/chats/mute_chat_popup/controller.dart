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

import 'dart:async';

import 'package:get/get.dart';

import '/util/obs/obs.dart';
import '/domain/model/chat.dart';
import '/domain/service/chat.dart';

export 'view.dart';

/// Controller of a [MuteChatView].
class MuteChatController extends GetxController {
  MuteChatController(
    this._chatService, {
    required this.chatId,
    this.pop,
  });

  /// ID of the [Chat] to mute.
  final ChatId chatId;

  /// Callback, called when a [MuteChatView] this controller should be popped
  /// from the [Navigator].
  final void Function()? pop;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription? _chatsSubscription;

  /// [ChatService] for [pop]ping the view when a [Chat] identified by the
  /// [chatId] is removed.
  final ChatService _chatService;

  @override
  void onInit() {
    _chatsSubscription = _chatService.chats.changes.listen((e) {
      switch (e.op) {
        case OperationKind.removed:
          if (chatId == e.key) {
            pop?.call();
          }
          break;

        case OperationKind.added:
        case OperationKind.updated:
          // No-op.
          break;
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    _chatsSubscription?.cancel();
    super.onClose();
  }
}
