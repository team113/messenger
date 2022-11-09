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
import 'dart:collection';

import 'package:get/get.dart';
import 'package:messenger/ui/page/call/search/controller.dart';
import 'package:messenger/domain/repository/contact.dart';

import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallDoesNotExistException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart'
    show RemoveChatMemberException, HideChatException;
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/web/web_utils.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the [HomeTab.chats] tab .
class ChatsTabController extends GetxController {
  ChatsTabController(
    this._chatService,
    this._callService,
    this._authService,
    this._userService,
  );

  /// Reactive list of sorted [Chat]s.
  late final RxList<RxChat> chats;

  /// [Chat]s service used to update the [chats].
  final ChatService _chatService;

  /// Calls service used to join the ongoing call in the [Chat].
  final CallService _callService;

  final Rx<SearchViewResults?> searchResult = Rx<SearchViewResults?>(null);

  final RxString searchQuery = RxString('');

  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  final RxBool searching = RxBool(false);

  final RxList<ListElement> elements = RxList([]);

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Subscription for [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Map of [_ChatSortingData]s used to sort the [chats].
  final HashMap<ChatId, _ChatSortingData> _sortingData =
      HashMap<ChatId, _ChatSortingData>();

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get chatsReady => _chatService.isReady;

  @override
  void onInit() {
    chats = RxList<RxChat>(_chatService.chats.values.toList());
    _sortChats();

    for (RxChat chat in chats) {
      _sortingData[chat.chat.value.id] =
          _ChatSortingData(chat.chat, _sortChats);
    }

    _chatsSubscription = _chatService.chats.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          chats.add(event.value!);
          _sortChats();
          _sortingData[event.value!.chat.value.id] ??=
              _ChatSortingData(event.value!.chat, _sortChats);
          break;

        case OperationKind.removed:
          _sortingData.remove(event.key)?.dispose();
          chats.removeWhere((e) => e.chat.value.id == event.key);
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    for (var data in _sortingData.values) {
      data.dispose();
    }
    _chatsSubscription.cancel();

    super.onClose();
  }

  /// Joins the call in the [Chat] identified by the provided [id] [withVideo]
  /// or without.
  Future<void> joinCall(ChatId id, {bool withVideo = false}) async {
    try {
      await _callService.join(id, withVideo: withVideo);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallDoesNotExistException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Leaves the [Chat] identified by the provided [id].
  Future<void> leaveChat(ChatId id) async {
    try {
      await _chatService.removeChatMember(id, me!);
      if (router.route == '${Routes.chat}/$id') {
        router.pop();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Hides the [Chat] identified by the provided [id].
  Future<void> hideChat(ChatId id) async {
    try {
      await _chatService.hideChat(id);
      if (router.route == '${Routes.chat}/$id') {
        router.go('/');
      }
    } on HideChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  void populate() {
    elements.clear();

    if (searchResult.value?.chats.isNotEmpty == true) {
      elements.add(const DividerElement(SearchCategory.chats));
      for (var c in searchResult.value!.chats) {
        elements.add(ChatElement(c));
      }
    }

    if (searchResult.value?.contacts.isNotEmpty == true) {
      elements.add(const DividerElement(SearchCategory.contacts));
      for (var c in searchResult.value!.contacts) {
        elements.add(ContactElement(c));
      }
    }

    if (searchResult.value?.users.isNotEmpty == true) {
      elements.add(const DividerElement(SearchCategory.users));
      for (var c in searchResult.value!.users) {
        elements.add(UserElement(c));
      }
    }
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Indicates whether this device of the currently authenticated [MyUser]
  /// takes part in an [OngoingCall] in a [Chat] identified by the provided
  /// [id].
  bool inCall(ChatId id) =>
      _callService.calls[id] != null || WebUtils.containsCall(id);

  /// Drops an [OngoingCall] in a [Chat] identified by its [id], if any.
  Future<void> dropCall(ChatId id) => _callService.leave(id);

  /// Sorts the [chats] by the [Chat.updatedAt] and [Chat.ongoingCall] values.
  void _sortChats() {
    chats.sort((a, b) {
      if (a.chat.value.ongoingCall != null &&
          b.chat.value.ongoingCall == null) {
        return -1;
      } else if (a.chat.value.ongoingCall == null &&
          b.chat.value.ongoingCall != null) {
        return 1;
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });
  }
}

/// Container of data used to sort a [Chat].
class _ChatSortingData {
  /// Returns a [_ChatSortingData] capturing the provided [chat] changes to
  /// invoke a [sort] on [Chat.updatedAt] or [Chat.ongoingCall] updates.
  _ChatSortingData(Rx<Chat> chat, [void Function()? sort]) {
    updatedAt = chat.value.updatedAt;
    hasCall = chat.value.ongoingCall != null;

    worker = ever(
      chat,
      (Chat chat) {
        bool hasCall = chat.ongoingCall != null;
        if (chat.updatedAt != updatedAt || hasCall != hasCall) {
          sort?.call();
          updatedAt = chat.updatedAt;
          hasCall = hasCall;
        }
      },
    );
  }

  /// Worker capturing the [Chat] changes to invoke sorting on [updatedAt] and
  /// [hasCall] mismatches.
  late final Worker worker;

  /// Previously captured [Chat.updatedAt] value.
  late PreciseDateTime updatedAt;

  /// Previously captured indicator of [Chat.ongoingCall] being non-`null`.
  late bool hasCall;

  /// Disposes this [_ChatSortingData].
  void dispose() => worker.dispose();
}

abstract class ListElement {
  const ListElement();
}

class ChatElement extends ListElement {
  const ChatElement(this.chat);
  final RxChat chat;
}

class ContactElement extends ListElement {
  const ContactElement(this.contact);
  final RxChatContact contact;
}

class UserElement extends ListElement {
  const UserElement(this.user);
  final RxUser user;
}

class DividerElement extends ListElement {
  const DividerElement(this.category);
  final SearchCategory category;
}
