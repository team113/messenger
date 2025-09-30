// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

/// Controller of the [MessageInfo] popup.
class MessageInfoController extends GetxController {
  MessageInfoController(
    this.chatId,
    this.chatService, {
    this.reads = const [],
  });

  /// ID of the [Chat] this page is about.
  final ChatId? chatId;

  /// [Chat]s service used to get the [chat] value.
  final ChatService chatService;

  /// [LastChatRead]s who read the [ChatItem] this [MessageInfo] is about.
  final Iterable<LastChatRead> reads;

  /// [RxUser]s who may read [ChatItem] this [MessageInfo] is about.
  final RxList<RxUser> members = RxList();

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicates whether the [RxChat.members] have a next page.
  RxBool get haveNext => _chat?.members.hasNext ?? RxBool(false);

  /// Reactive state of the [RxChat] this page is about.
  RxChat? _chat;

  /// Indicator whether the [_scrollListener] is already invoked during the
  /// current frame.
  bool _scrollIsInvoked = false;

  /// Subscription for the [RxChat.members] changes.
  StreamSubscription? _membersSubscription;

  @override
  void onInit() {
    super.onInit();

    scrollController.addListener(_scrollListener);
    _initChat();
  }

  @override
  void onClose() {
    _membersSubscription?.cancel();
    scrollController.dispose();

    super.onClose();
  }

  Future<void> _initChat() async {
    if(chatId == null) {
      return;
    }

    try {
      _chat = await chatService.get(chatId!);

      if (_chat != null) {
        for (final member in _chat!.members.values) {
          members.add(member.user);
        }

        _membersSubscription = _chat!.members.items.changes.listen((event) {
          switch (event.op) {
            case OperationKind.added:
              if (event.value != null && !members.contains(event.value!.user)) {
                members.add(event.value!.user);
              }
              break;
            case OperationKind.removed:
              members.removeWhere((e) => e.id == event.key);

              _scrollListener();
              break;

            case OperationKind.updated:
              // No-op
              break;
          }
        });

        _chat!.members.around();
      }
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Requests the next page of [RxUser]s based on the
  /// [ScrollController.position] value.
  void _scrollListener() {
    if (!_scrollIsInvoked) {
      _scrollIsInvoked = true;

      SchedulerBinding.instance.addPostFrameCallback((_) async {
        _scrollIsInvoked = false;

        if (scrollController.hasClients &&
            haveNext.isTrue &&
            _chat?.members.nextLoading.value == false &&
            scrollController.position.pixels >
                scrollController.position.maxScrollExtent - 100) {
          await _chat?.members.next();
        }
      });
    }
  }
}
