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
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

/// Controller of the [MessageInfo] popup.
class MessageInfoController extends GetxController {
  MessageInfoController(this.id, this._chatService);

  /// ID of the [ChatItem] this page is about.
  final ChatItemId? id;

  /// [ChatItem] of a [RxChat] this [MessageInfo] is about.
  final Rx<ChatItem?> item = Rx(null);

  /// [RxUser]s who may read [ChatItem] this [MessageInfo] is about.
  final RxList<RxUser> members = RxList();

  /// [LastChatRead]s of a [ChatItem] this [MessageInfo] is about.
  RxList<LastChatRead> reads = RxList();

  /// Indicator whether to display the status of all [RxChat.members].
  final RxBool displayMembers = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [RxStatus] of [item] and [members] initialization.
  final Rx<RxStatus> status = Rx(RxStatus.loading());

  /// [Chat]s service used to get the [_chat] value.
  final ChatService _chatService;

  /// Reactive state of the [RxChat] this page is about.
  RxChat? _chat;

  /// Indicator whether the [_scrollListener] is already invoked during the
  /// current frame.
  bool _scrollIsInvoked = false;

  /// Subscription for the [RxChat.members] changes.
  StreamSubscription? _membersSubscription;

  /// Indicates whether the [RxChat.members] have a next page.
  RxBool get hasNext => _chat?.members.hasNext ?? RxBool(false);

  @override
  void onInit() {
    super.onInit();

    scrollController.addListener(_scrollListener);
    _fetchItem();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    _membersSubscription?.cancel();
    scrollController.dispose();

    super.onClose();
  }

  /// Fetches [ChatItem] and then afterwards a [Chat] with [ChatMember]s.
  void _fetchItem() {
    status.value = RxStatus.loading();

    if (id == null) {
      status.value = RxStatus.empty();
      return;
    }

    try {
      final FutureOr<ChatItem?> itemOrFuture = _chatService.getItem(id!);
      if (itemOrFuture is Future<ChatItem?>) {
        itemOrFuture.then((e) {
          item.value = e;
          _fetchChat();
        });
      } else {
        item.value = itemOrFuture;
        _fetchChat();
      }
    } catch (e) {
      status.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Fetches the [RxChat] by its ID.
  void _fetchChat() {
    final ChatId? chatId = item.value?.chatId;

    if (chatId == null) {
      status.value = RxStatus.empty();
      return;
    }

    status.value = RxStatus.loadingMore();

    final FutureOr<RxChat?> chatOrFuture = _chatService.get(chatId);
    if (chatOrFuture is Future<RxChat?>) {
      chatOrFuture.then((e) {
        _chat = e;
        _fetchMembers();
      });
    } else {
      _chat = chatOrFuture;
      _fetchMembers();
    }
  }

  /// Populates [reads] and [members].
  void _fetchMembers() {
    status.value = RxStatus.success();

    final RxChat? chat = _chat;
    final ChatItem? item = this.item.value;

    if (chat == null || item == null) {
      return;
    }

    reads.addAll(
      chat.chat.value.lastReads.where((e) => !e.at.val.isBefore(item.at.val)),
    );

    // [Chat.lastReads] keeps only 10 members, so it's impossible to properly
    // display everyone's status when members exceed 10.
    displayMembers.value =
        chat.chat.value.isGroup && chat.chat.value.membersCount <= 10;

    // Do not query the members if we won't display them.
    if (displayMembers.value) {
      members.addAll(
        chat.members.values
            .where((e) => !e.joinedAt.isAfter(item.at))
            .map((e) => e.user),
      );

      _membersSubscription = chat.members.items.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
            final RxChatMember? member = event.value;

            if (member != null &&
                !members.contains(member.user) &&
                !member.joinedAt.isAfter(item.at)) {
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

      if (chat.members.values.length < chat.chat.value.membersCount) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _chat!.members.around();
        });
      }
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
            hasNext.isTrue &&
            _chat?.members.nextLoading.value == false &&
            scrollController.position.pixels >
                scrollController.position.maxScrollExtent - 100) {
          await _chat?.members.next();
        }
      });
    }
  }
}
