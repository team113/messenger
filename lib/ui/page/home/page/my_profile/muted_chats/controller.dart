// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of a [MutedChatsView].
class MutedChatsController extends GetxController {
  MutedChatsController(this._chatService);

  /// [Chat]s found being [Chat.muted].
  final RxMap<ChatId, RxChat> chats = RxMap();

  /// [RxStatus] of the [chats].
  final Rx<RxStatus> status = Rx(RxStatus.success());

  /// [ChatService] for retrieving [Chat]s.
  final ChatService _chatService;

  /// [interval] invoking [_next] on the [_scrollPosition] changes.
  Worker? _nextInterval;

  /// Reactive value of the current [ScrollPosition.pixels].
  final RxDouble _scrollPosition = RxDouble(0);

  /// [ScrollController] of a [ListView] displaying the [chats].
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    _populateChats();

    scrollController.addListener(_updateScrollPosition);

    _nextInterval = interval(
      _scrollPosition,
      (_) => _next(),
      time: const Duration(milliseconds: 100),
      condition: () =>
          scrollController.hasClients &&
          (scrollController.position.pixels >
              scrollController.position.maxScrollExtent - 500),
    );

    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    _nextInterval?.dispose();
    super.onClose();
  }

  /// Unmutes the [Chat] with the provided [id].
  Future<void> unmute(ChatId id) async {
    final RxChat? chat = chats.remove(id);

    try {
      await _chatService.toggleChatMute(id, null);
    } catch (e) {
      MessagePopup.error(e);

      if (chat != null) {
        chats[id] = chat;
      }
    }
  }

  /// Updates the [_scrollPosition] according to the [scrollController].
  void _updateScrollPosition() {
    if (scrollController.hasClients) {
      _scrollPosition.value = scrollController.position.pixels;
    }
  }

  /// Updates the [chats] with [RxChat]s that are [Chat.muted].
  void _populateChats() {
    final Iterable<RxChat> allChats = _chatService.paginated.values;

    // Predicates to filter [allChats] by.
    bool hidden(RxChat c) => c.chat.value.isHidden;
    bool muted(RxChat c) => c.chat.value.muted != null;
    bool localDialog(RxChat c) =>
        c.id.isLocal && !c.id.isLocalWith(_chatService.me);

    final List<RxChat> filtered = allChats
        .whereNot(hidden)
        .where(muted)
        .whereNot(localDialog)
        .sorted();

    chats.value = {for (final RxChat c in filtered) c.chat.value.id: c};
  }

  /// Invokes [ChatService.next] for fetching the next page.
  Future<void> _next() async {
    // Fetch all the [chats] first to prevent them from appearing in other
    // [SearchCategory]s.
    if (_chatService.hasNext.isTrue) {
      if (_chatService.nextLoading.isFalse) {
        status.value = RxStatus.loadingMore();

        await _chatService.next();
        await Future.delayed(1.milliseconds);

        // Populate [chats] first until there's no more [Chat]s to fetch from
        // [ChatService.paginated].
        if (_chatService.hasNext.value) {
          _populateChats();
        }

        if (!_chatService.hasNext.value) {
          status.value = RxStatus.success();
        }
      }
    }
  }
}
