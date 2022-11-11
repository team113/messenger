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

  /// ID of the [Chat] the would be muted.
  final ChatId chatId;

  /// Callback called, when need to close popup.
  final void Function()? pop;

  /// [StreamSubscription] to chats changes.
  late final StreamSubscription? chatsSubscription;

  /// [Chat]s service.
  final ChatService _chatService;

  @override
  void onInit() {
    chatsSubscription = _chatService.chats.changes.listen((event) {
      if (event.op == OperationKind.removed && chatId == event.key) {
        pop?.call();
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    chatsSubscription?.cancel();
    super.onClose();
  }
}
