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
import '/domain/model/chat_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/store/chat_rx.dart';
import '/store/model/chat_item.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

/// Controller of the [MessageInfo] popup.
class MessageInfoController extends GetxController {
  MessageInfoController(this.chatId, this.chatItemId, this._chatService);

  /// ID of the [Chat] this page is about.
  final ChatId? chatId;

  /// ID of the [ChatItem] this page is about.
  final ChatItemId? chatItemId;

  /// [DtoChatItem] of a [RxChat] this [MessageInfo] is about.
  final Rx<DtoChatItem?> chatItem = Rx(null);

  /// [RxUser]s who may read [ChatItem] this [MessageInfo] is about.
  final RxList<RxUser> members = RxList();

  /// [LastChatRead]s of a [ChatItem] this [MessageInfo] is about.
  RxList<LastChatRead> reads = RxList();

  /// Specifies whether to display the status of all [RxChat.members].
  final Rx<bool?> displayMembers = Rx(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicates whether the [RxChat.members] have a next page.
  RxBool get haveNext => _chat?.members.hasNext ?? RxBool(false);

  /// Reactive state of the [RxChat] this page is about.
  RxChat? _chat;

  /// [Chat]s service used to get the [_chat] value.
  final ChatService _chatService;

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

  /// Init [RxChat] and [DtoChatItem].
  Future<void> _initChat() async {
    if (chatId == null || chatItemId == null) {
      return;
    }

    try {
      _chat = await _chatService.get(chatId!);

      if (_chat != null) {
        chatItem.value = await (_chat as RxChatImpl).get(chatItemId!);
        displayMembers.value = _chat!.chat.value.isGroup;

        _populateLists();
      }
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Populate [reads] and [members]
  void _populateLists() {
    final PreciseDateTime? at = chatItem.value?.value.at;

    if (at != null) {
      final UserId? authorId = chatItem.value?.value.author.id;

      reads.addAll(
        _chat!.chat.value.lastReads.where(
          (e) => !e.at.val.isBefore(at.val) && e.memberId != authorId,
        ),
      );
    }

    members.addAll(_chat!.members.values.map((e) => e.user));

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
