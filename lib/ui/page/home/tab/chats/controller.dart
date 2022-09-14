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

import 'package:collection/collection.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/web/web_utils.dart';

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
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/my_user.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart'
    show RemoveChatMemberException, HideChatException;
import '/routes.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the [HomeTab.chats] tab .
class ChatsTabController extends GetxController {
  ChatsTabController(
    this._chatService,
    this._callService,
    this._myUserService,
    this._userService,
    this._contactService,
  );

  final RxBool searching = RxBool(false);
  late final TextFieldState search;

  final RxMap<ChatId, RxChat> chats = RxMap();
  final RxMap<UserId, RxChatContact> contacts = RxMap();
  final RxMap<UserId, RxUser> users = RxMap();

  final RxnString query = RxnString();
  final Rx<RxList<RxUser>?> searchResults = Rx(null);
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of sorted [Chat]s.
  late final RxList<RxChat> sortedChats;

  /// [Chat]s service used to update the [sortedChats].
  final ChatService _chatService;

  /// Calls service used to join the ongoing call in the [Chat].
  final CallService _callService;

  /// [MyUser] service used to get [me] value.
  final MyUserService _myUserService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  final ContactService _contactService;

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchStatusWorker;
  Worker? _searchWorker;
  Worker? _searchDebounce;

  /// Subscription for [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Map of [_ChatSortingData]s used to sort the [chats].
  final HashMap<ChatId, _ChatSortingData> _sortingData =
      HashMap<ChatId, _ChatSortingData>();

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _myUserService.myUser.value?.id;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get chatsReady => _chatService.isReady;

  @override
  void onInit() {
    _searchWorker = ever(
      query,
      (String? q) {
        if (q == null || q.isEmpty) {
          searchResults.value = null;
          searchStatus.value = RxStatus.empty();
          query.value = null;
          search.clear();
          _populate();
        } else {
          searchStatus.value = RxStatus.loading();
          _populate();
        }
      },
    );

    search = TextFieldState(
      onChanged: (d) {
        query.value = d.text;
        if (d.text.isEmpty) {
          query.value = null;
          searchResults.value = null;
          searchStatus.value = RxStatus.empty();
          users.clear();
          contacts.clear();
          chats.clear();
          _populate();
        } else {
          searchStatus.value = RxStatus.loading();
          _populate();
        }
      },
    );

    search.focus.addListener(() {
      if (search.focus.hasFocus == false) {
        if (search.text.isEmpty) {
          searching.value = false;
          query.value = null;
          search.clear();
          searchResults.value = null;
          searchStatus.value = RxStatus.empty();
          _populate();
        }
      }
    });

    sortedChats = RxList<RxChat>(_chatService.chats.values.toList());
    _sortChats();

    _searchDebounce = debounce(query, (String? v) {
      if (v != null) {
        _search(v);
      }
    });

    for (RxChat chat in sortedChats) {
      _sortingData[chat.chat.value.id] =
          _ChatSortingData(chat.chat, _sortChats);
    }

    _chatsSubscription = _chatService.chats.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          sortedChats.add(event.value!);
          _sortChats();
          _sortingData[event.value!.chat.value.id] ??=
              _ChatSortingData(event.value!.chat, _sortChats);
          break;

        case OperationKind.removed:
          _sortingData.remove(event.key)?.dispose();
          sortedChats.removeWhere((e) => e.chat.value.id == event.key);
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    controller.sliverController.onPaintItemPositionsCallback = (d, list) {
      int? first = list.firstOrNull?.index;
      if (first != null) {
        if (first >= chats.length + contacts.length) {
          selected.value = 2;
        } else if (first >= chats.length) {
          selected.value = 1;
        } else {
          selected.value = 0;
        }
      }
    };

    _populate();

    super.onInit();
  }

  dynamic getIndex(int i) {
    return [...chats.values, ...contacts.values, ...users.values].elementAt(i);
  }

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

  @override
  void onClose() {
    for (var data in _sortingData.values) {
      data.dispose();
    }
    _chatsSubscription.cancel();

    _searchWorker?.dispose();
    _searchStatusWorker?.dispose();
    _searchDebounce?.dispose();

    super.onClose();
  }

  final RxInt selected = RxInt(0);
  final FlutterListViewController controller = FlutterListViewController();

  void jumpTo(int i) {
    if (i == 0) {
      controller.jumpTo(0);
    } else if (i == 1) {
      double to = chats.length * (84 + 10);
      if (to > controller.position.maxScrollExtent) {
        controller.jumpTo(controller.position.maxScrollExtent);
      } else {
        controller.jumpTo(to);
      }
    } else if (i == 2) {
      double to = (chats.length + contacts.length) * (84 + 10);
      if (to > controller.position.maxScrollExtent) {
        controller.jumpTo(controller.position.maxScrollExtent);
      } else {
        controller.jumpTo(to);
      }
    }
  }

  bool isInCall(ChatId id) =>
      _callService.calls[id] != null || WebUtils.containsCall(id);
  Future<void> dropCall(ChatId id) => _callService.drop(id);

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

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Sorts the [chats] by the [Chat.updatedAt] and [Chat.currentCall] values.
  void _sortChats() {
    sortedChats.sort((a, b) {
      if (a.chat.value.currentCall != null &&
          b.chat.value.currentCall == null) {
        return -1;
      } else if (a.chat.value.currentCall == null &&
          b.chat.value.currentCall != null) {
        return 1;
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });
  }

  void _populate() {
    if (query.value?.isNotEmpty != true) {
      chats.value = {
        for (var c in sortedChats) c.chat.value.id: c,
      };

      users.clear();
      contacts.clear();
      return;
    }

    chats.value = {
      for (var u in _chatService.chats.values.where((e) {
        if (e.title.value.contains(query.value!) == true) {
          return true;
        }

        return false;
      }))
        u.chat.value.id: u,
    };

    contacts.value = {
      for (var u in _contactService.contacts.values.where((e) {
        if (e.user.value != null && e.contact.value.users.length == 1) {
          if (e.contact.value.name.val.contains(query.value!) == true) {
            if (chats.values.firstWhereOrNull((c) =>
                    c.chat.value.isDialog &&
                    c.members.containsKey(e.user.value!.id)) ==
                null) {
              return true;
            }
          }
        }

        return false;
      }))
        u.user.value!.id: u,
    };

    if (searchResults.value?.isNotEmpty == true) {
      users.value = {
        for (var u in searchResults.value!.where((e) {
          if (!contacts.containsKey(e.id)) {
            if (chats.values.firstWhereOrNull((c) =>
                    c.chat.value.isDialog && c.members.containsKey(e.id)) ==
                null) {
              return true;
            }
          }

          return false;
        }))
          u.id: u,
      };
    } else {
      users.value = {};
    }

    print(
      '_populate, recent: ${chats.length}, contact: ${contacts.length}, user: ${users.length}',
    );
  }

  Future<void> _search(String query) async {
    _searchStatusWorker?.dispose();
    _searchStatusWorker = null;

    if (query.isNotEmpty) {
      UserNum? num;
      UserName? name;
      UserLogin? login;

      try {
        num = UserNum(query);
      } catch (e) {
        // No-op.
      }

      try {
        name = UserName(query);
      } catch (e) {
        // No-op.
      }

      try {
        login = UserLogin(query);
      } catch (e) {
        // No-op.
      }

      if (num != null || name != null || login != null) {
        searchStatus.value = searchStatus.value.isSuccess
            ? RxStatus.loadingMore()
            : RxStatus.loading();
        final SearchResult result =
            _userService.search(num: num, name: name, login: login);

        searchResults.value = result.users;
        searchStatus.value = result.status.value;
        _searchStatusWorker = ever(result.status, (RxStatus s) {
          searchStatus.value = s;
          _populate();
        });

        _populate();

        searchStatus.value = RxStatus.success();
      }
    } else {
      searchStatus.value = RxStatus.empty();
      searchResults.value = null;
    }
  }
}

/// Container of data used to sort a [Chat].
class _ChatSortingData {
  /// Returns a [_ChatSortingData] capturing the provided [chat] changes to
  /// invoke a [sort] on [Chat.updatedAt] or [Chat.currentCall] updates.
  _ChatSortingData(Rx<Chat> chat, [void Function()? sort]) {
    updatedAt = chat.value.updatedAt;
    hasCall = chat.value.currentCall != null;

    worker = ever(
      chat,
      (Chat chat) {
        bool hasCall = chat.currentCall != null;
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

  /// Previously captured indicator of [Chat.currentCall] being non-`null`.
  late bool hasCall;

  /// Disposes this [_ChatSortingData].
  void dispose() => worker.dispose();
}
