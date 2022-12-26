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

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallDoesNotExistException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart'
    show
        FavoriteChatException,
        HideChatException,
        RemoveChatMemberException,
        ToggleChatMuteException,
        UnfavoriteChatException;
import '/routes.dart';
import '/ui/page/call/search/controller.dart';
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
    this._contactService,
  );

  /// Reactive list of sorted [Chat]s.
  late final RxList<RxChat> chats;

  /// [ScrollController] of a chats [ListView].
  final ScrollController listController = ScrollController();

  /// [SearchController] for searching the [Chat]s, [User]s and [ChatContact]s.
  final Rx<SearchController?> search = Rx(null);

  /// [ListElement]s representing the [search] results visually.
  final RxList<ListElement> elements = RxList([]);

  /// [Chat]s service used to update the [chats].
  final ChatService _chatService;

  /// Calls service used to join the ongoing call in the [Chat].
  final CallService _callService;

  /// [AuthService] used to get [me] value.
  final AuthService _authService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// [ChatContact]s service used by a [SearchController].
  final ContactService _contactService;

  /// Indicator whether a loading indicator should be showed.
  RxBool isLoadingNextPage = RxBool(false);

  /// Subscription for [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Subscription for [SearchController.chats], [SearchController.users] and
  /// [SearchController.contacts] changes updating the [elements].
  StreamSubscription? _searchSubscription;

  /// Map of [_ChatSortingData]s used to sort the [chats].
  final HashMap<ChatId, _ChatSortingData> _sortingData =
      HashMap<ChatId, _ChatSortingData>();

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Indicates whether [ChatService] is ready to be used.
  RxBool get chatsReady => _chatService.isReady;

  @override
  void onInit() {
    listController.addListener(_scrollListener);
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
          _sortChats();
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
    listController.removeListener(_scrollListener);

    _searchSubscription?.cancel();
    search.value?.search.focus.removeListener(_disableSearchFocusListener);
    search.value?.onClose();

    super.onClose();
  }

  // TODO: No [Chat] should be created.
  /// Opens a [Chat]-dialog with this [user].
  ///
  /// Creates a new one if it doesn't exist.
  Future<void> openChat({
    RxUser? user,
    RxChatContact? contact,
    RxChat? chat,
  }) async {
    if (chat != null) {
      router.chat(chat.chat.value.id);
    } else {
      user ??= contact?.user.value;

      if (user != null) {
        Chat? dialog = user.user.value.dialog;
        dialog ??= (await _chatService.createDialogChat(user.id)).chat.value;
        router.chat(dialog.id);
      }
    }
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

  /// Unmutes a [Chat] identified by the provided [id].
  Future<void> unmuteChat(ChatId id) async {
    try {
      await _chatService.toggleChatMute(id, null);
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Mutes a [Chat] identified by the provided [id].
  Future<void> muteChat(ChatId id) async {
    try {
      await _chatService.toggleChatMute(id, MuteDuration.forever());
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Marks the specified [Chat] identified by its [id] as favorited.
  Future<void> favoriteChat(ChatId id) async {
    try {
      await _chatService.favoriteChat(id);
    } on FavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the specified [Chat] identified by its [id] from the favorites.
  Future<void> unfavoriteChat(ChatId id) async {
    try {
      await _chatService.unfavoriteChat(id);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Indicates whether this device of the currently authenticated [MyUser]
  /// takes part in an [OngoingCall] in a [Chat] identified by the provided
  /// [id].
  bool inCall(ChatId id) {
    final Rx<OngoingCall>? call = _callService.calls[id];
    if (call != null) {
      return call.value.state.value == OngoingCallState.active ||
          call.value.state.value == OngoingCallState.joining;
    }

    return WebUtils.containsCall(id);
  }

  /// Drops an [OngoingCall] in a [Chat] identified by its [id], if any.
  Future<void> dropCall(ChatId id) => _callService.leave(id);

  /// Enables and initializes or disables and disposes the [search].
  void toggleSearch([bool enable = true]) {
    search.value?.onClose();
    search.value?.search.focus.removeListener(_disableSearchFocusListener);
    _searchSubscription?.cancel();

    if (enable) {
      search.value = SearchController(
        _chatService,
        _userService,
        _contactService,
        categories: const [
          SearchCategory.chat,
          SearchCategory.contact,
          SearchCategory.user,
        ],
      )..onInit();

      _searchSubscription = StreamGroup.merge([
        search.value!.chats.stream,
        search.value!.contacts.stream,
        search.value!.users.stream,
      ]).listen((_) {
        elements.clear();

        if (search.value?.chats.isNotEmpty == true) {
          elements.add(const DividerElement(SearchCategory.chat));
          for (RxChat c in search.value!.chats.values) {
            elements.add(ChatElement(c));
          }
        }

        if (search.value?.contacts.isNotEmpty == true) {
          elements.add(const DividerElement(SearchCategory.contact));
          for (RxChatContact c in search.value!.contacts.values) {
            elements.add(ContactElement(c));
          }
        }

        if (search.value?.users.isNotEmpty == true) {
          elements.add(const DividerElement(SearchCategory.user));
          for (RxUser c in search.value!.users.values) {
            elements.add(UserElement(c));
          }
        }
      });

      search.value!.search.focus.addListener(_disableSearchFocusListener);
      search.value!.search.focus.requestFocus();
    } else {
      search.value = null;
      elements.clear();
    }
  }

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

      if (a.chat.value.favoritePosition != null &&
          b.chat.value.favoritePosition == null) {
        return -1;
      } else if (a.chat.value.favoritePosition == null &&
          b.chat.value.favoritePosition != null) {
        return 1;
      } else if (a.chat.value.favoritePosition != null &&
          b.chat.value.favoritePosition != null) {
        return a.chat.value.favoritePosition!
            .compareTo(b.chat.value.favoritePosition!);
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });
  }

  final List<FutureOr> _nextPageLoadings = [];

  /// Uploads next page of [Chat]s based on the [ScrollController.position]
  /// value.
  void _scrollListener() async {
    if (listController.hasClients) {
      if (listController.position.pixels <
          MediaQuery.of(router.context!).size.height + 200) {
        isLoadingNextPage.value = true;

        FutureOr future = _chatService.loadNextPage();
        _nextPageLoadings.add(future);
        await future;
        _nextPageLoadings.remove(future);

        if (_nextPageLoadings.isEmpty) {
          isLoadingNextPage.value = false;
        }
      }
    }
  }

  /// Disables the [search], if its focus is lost or its query is empty.
  void _disableSearchFocusListener() {
    if (search.value?.search.focus.hasFocus == false &&
        search.value?.search.text.isEmpty == true) {
      toggleSearch(false);
    }
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

/// Element to display in a [ListView].
abstract class ListElement {
  const ListElement();
}

/// [ListElement] representing a [RxChat].
class ChatElement extends ListElement {
  const ChatElement(this.chat);

  /// [RxChat] itself.
  final RxChat chat;
}

/// [ListElement] representing a [RxChatContact].
class ContactElement extends ListElement {
  const ContactElement(this.contact);

  /// [RxChatContact] itself.
  final RxChatContact contact;
}

/// [ListElement] representing a [RxUser].
class UserElement extends ListElement {
  const UserElement(this.user);

  /// [RxUser] itself.
  final RxUser user;
}

/// [ListElement] representing a visual divider of the provided [category].
class DividerElement extends ListElement {
  const DividerElement(this.category);

  /// [SearchCategory] of this [DividerElement].
  final SearchCategory category;
}
