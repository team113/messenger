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
import 'dart:collection';

import 'package:async/async.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/my_user.dart';
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
import '/domain/service/my_user.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart'
    show
        CreateGroupChatException,
        FavoriteChatException,
        HideChatException,
        RemoveChatMemberException,
        ToggleChatMuteException,
        UnfavoriteChatException;
import '/routes.dart';
import '/ui/page/call/search/controller.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of the [HomeTab.chats] tab.
class ChatsTabController extends GetxController {
  ChatsTabController(
    this._chatService,
    this._callService,
    this._authService,
    this._userService,
    this._contactService,
    this._myUserService,
  );

  /// Reactive list of sorted [Chat]s.
  late final RxList<ListElement> chats;

  /// [SearchController] for searching the [Chat]s, [User]s and [ChatContact]s.
  final Rx<SearchController?> search = Rx(null);

  /// [ListElement]s representing the [search] results visually.
  final RxList<ListElement> elements = RxList([]);

  /// Indicator whether [search]ing is active.
  final RxBool searching = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicator whether group creation is active.
  final RxBool groupCreating = RxBool(false);

  final Rx<LoaderElement?> loader = Rx(null);
  late final Rx<Timer?> timer;

  /// Status of the [createGroup] progression.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the query has not yet started.
  /// - `status.isLoading`, meaning the [createGroup] is executing.
  final Rx<RxStatus> creatingStatus = Rx<RxStatus>(RxStatus.empty());

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

  /// [MyUserService] maintaining the [myUser].
  final MyUserService _myUserService;

  /// Subscription for [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Subscription for [SearchController.chats], [SearchController.users] and
  /// [SearchController.contacts] changes updating the [elements].
  StreamSubscription? _searchSubscription;

  /// Map of [_ChatSortingData]s used to sort the [chats].
  final HashMap<ChatId, _ChatSortingData> _sortingData =
      HashMap<ChatId, _ChatSortingData>();

  /// [RxUser]s being recipients of the [Chat]-dialogs in the [chats].
  ///
  /// Used to call [RxUser.listenUpdates] and [RxUser.stopUpdates] invocations.
  final List<RxUser> _recipients = [];

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get chatsReady => _chatService.isReady;
  Rx<RxStatus> get status => _chatService.status;

  @override
  void onInit() {
    chats = RxList<ListElement>(
      _chatService.chats.values.map((e) => ChatElement(e)).toList(),
    );

    HardwareKeyboard.instance.addHandler(_escapeListener);
    if (PlatformUtils.isMobile) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    timer = Rx(Timer(2.seconds, () => timer.value = null));
    chats.add(const LoaderElement());

    // _timer = Timer(
    //   2.seconds,
    //   () {
    //     if (!status.value.isSuccess || status.value.isLoadingMore) {
    //       const LoaderElement element = LoaderElement();
    //       chats.insert(0, element);

    //       SchedulerBinding.instance.addPostFrameCallback((_) {
    //         loader.value = element;
    //       });

    //       Worker? worker;
    //       worker = ever(status, (RxStatus status) {
    //         if (status.isSuccess && !status.isLoadingMore && worker != null) {
    //           worker = null;
    //           loader.value = null;

    //           Future.delayed(
    //             const Duration(milliseconds: 200),
    //             () => chats.removeWhere((e) => e is LoaderElement),
    //           );
    //         }
    //       });
    //     }
    //   },
    // );

    Future.delayed(30.seconds, () => loader.value = null);

    _sortChats();

    for (ListElement chat in chats) {
      if (chat is ChatElement) {
        _sortingData[chat.chat.chat.value.id] =
            _ChatSortingData(chat.chat.chat, _sortChats);
      }
    }

    // Adds the recipient of the provided [chat] to the [_recipients] and starts
    // listening to its updates.
    Future<void> listenUpdates(RxChat chat) async {
      final UserId? userId = chat.chat.value.members
          .firstWhereOrNull((u) => u.user.id != me)
          ?.user
          .id;

      if (userId != null) {
        RxUser? rxUser =
            chat.members.values.toList().firstWhereOrNull((u) => u.id != me);
        rxUser ??= await getUser(userId);
        if (rxUser != null) {
          _recipients.add(rxUser..listenUpdates());
        }
      }
    }

    chats
        .whereType<ChatElement>()
        .where((c) => c.chat.chat.value.isDialog)
        .map((e) => e.chat)
        .forEach(listenUpdates);
    _chatsSubscription = _chatService.chats.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          chats.add(ChatElement(event.value!));
          _sortChats();
          _sortingData[event.value!.chat.value.id] ??=
              _ChatSortingData(event.value!.chat, _sortChats);

          if (event.value!.chat.value.isDialog) {
            listenUpdates(event.value!);
          }
          break;

        case OperationKind.removed:
          _sortingData.remove(event.key)?.dispose();
          chats.removeWhere(
            (e) => e is ChatElement && e.chat.chat.value.id == event.key,
          );

          if (event.value!.chat.value.isDialog) {
            final UserId? userId = event.value!.chat.value.members
                .firstWhereOrNull((u) => u.user.id != me)
                ?.user
                .id;

            _recipients.removeWhere((e) {
              if (e.id == userId) {
                e.stopUpdates();
                return true;
              }

              return false;
            });
          }
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
    HardwareKeyboard.instance.removeHandler(_escapeListener);
    if (PlatformUtils.isMobile) {
      BackButtonInterceptor.remove(_onBack);
    }

    for (var data in _sortingData.values) {
      data.dispose();
    }
    _chatsSubscription.cancel();

    _searchSubscription?.cancel();
    search.value?.search.focus.removeListener(_disableSearchFocusListener);
    search.value?.onClose();

    for (RxUser v in _recipients) {
      v.stopUpdates();
    }

    router.navigation.value = true;

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
        Chat? dialog = user.dialog.value?.chat.value ?? user.user.value.dialog;
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
    if (WebUtils.containsCall(id)) {
      return true;
    }

    final Rx<OngoingCall>? call = _callService.calls[id];
    if (call != null) {
      return call.value.state.value == OngoingCallState.active ||
          call.value.state.value == OngoingCallState.joining;
    }

    return false;
  }

  /// Drops an [OngoingCall] in a [Chat] identified by its [id], if any.
  Future<void> dropCall(ChatId id) => _callService.leave(id);

  /// Enables and initializes the [search]ing.
  void startSearch() {
    searching.value = true;
    _toggleSearch();
    search.value?.search.focus.requestFocus();
  }

  /// Disables and disposes the [search]ing.
  void closeSearch([bool disableSearch = false]) {
    searching.value = false;
    if (disableSearch) {
      _toggleSearch(false);
    } else {
      search.value?.search.clear();
      search.value?.query.value = '';
    }
  }

  /// Enables and initializes the group creating.
  void startGroupCreating() {
    groupCreating.value = true;
    _toggleSearch();
    router.navigation.value = false;
    search.value?.populate();
  }

  /// Disables and disposes the group creating.
  void closeGroupCreating() {
    groupCreating.value = false;
    closeSearch(true);
    router.navigation.value = true;
  }

  /// Creates a [Chat]-group with [SearchController.selectedRecent],
  /// [SearchController.selectedContacts] and [SearchController.selectedUsers].
  Future<void> createGroup() async {
    creatingStatus.value = RxStatus.loading();

    try {
      RxChat chat = await _chatService.createGroupChat(
        {
          ...search.value!.selectedRecent.map((e) => e.id),
          ...search.value!.selectedContacts
              .expand((e) => e.contact.value.users.map((u) => u.id)),
          ...search.value!.selectedUsers.map((e) => e.id),
        }.where((e) => e != me).toList(),
        name: null,
      );

      router.chatInfo(chat.chat.value.id);

      closeGroupCreating();
    } on CreateGroupChatException catch (e) {
      MessagePopup.error(e);
    } on FormatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      creatingStatus.value = RxStatus.empty();
    }
  }

  /// Enables and initializes or disables and disposes the [search].
  void _toggleSearch([bool enable = true]) {
    if (search.value != null && enable) {
      return;
    }

    search.value?.onClose();
    search.value?.search.focus.removeListener(_disableSearchFocusListener);
    _searchSubscription?.cancel();

    if (enable) {
      search.value = SearchController(
        _chatService,
        _userService,
        _contactService,
        categories: const [
          SearchCategory.recent,
          SearchCategory.chat,
          SearchCategory.contact,
          SearchCategory.user,
        ],
      )..onInit();

      _searchSubscription = StreamGroup.merge([
        search.value!.recent.stream,
        search.value!.chats.stream,
        search.value!.contacts.stream,
        search.value!.users.stream,
      ]).listen((_) {
        elements.clear();

        if (groupCreating.value) {
          if (search.value?.query.isEmpty == true) {
            elements.add(const MyUserElement());
          }

          search.value?.users.removeWhere((k, v) => me == k);

          if (search.value?.recent.isNotEmpty == true) {
            elements.add(const DividerElement(SearchCategory.chat));
            for (RxUser c in search.value!.recent.values) {
              elements.add(RecentElement(c));
            }
          }
        } else {
          if (search.value?.chats.isNotEmpty == true) {
            elements.add(const DividerElement(SearchCategory.chat));
            for (RxChat c in search.value!.chats.values) {
              elements.add(ChatElement(c));
            }
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
    } else {
      search.value = null;
    }
  }

  /// Sorts the [chats] by the [Chat.updatedAt] and [Chat.ongoingCall] values.
  void _sortChats() {
    chats.sort((a, b) {
      if (a is LoaderElement) {
        return 1;
      } else if (b is LoaderElement) {
        return -1;
      } else if (a is ChatElement && b is ChatElement) {
        final RxChat c = a.chat;
        final RxChat d = b.chat;

        if (c.chat.value.favoritePosition != null &&
            d.chat.value.favoritePosition == null) {
          return -1;
        } else if (c.chat.value.favoritePosition == null &&
            d.chat.value.favoritePosition != null) {
          return 1;
        } else if (c.chat.value.favoritePosition != null &&
            d.chat.value.favoritePosition != null) {
          return c.chat.value.favoritePosition!
              .compareTo(d.chat.value.favoritePosition!);
        }

        if (c.chat.value.ongoingCall != null &&
            d.chat.value.ongoingCall == null) {
          return -1;
        } else if (c.chat.value.ongoingCall == null &&
            d.chat.value.ongoingCall != null) {
          return 1;
        }

        return c.chat.value.updatedAt.compareTo(d.chat.value.updatedAt);
      }

      return 0;
    });
  }

  /// Disables the [search], if its focus is lost or its query is empty.
  void _disableSearchFocusListener() {
    if (search.value?.search.focus.hasFocus == false &&
        search.value?.search.text.isEmpty == true) {
      closeSearch(!groupCreating.value);
    }
  }

  /// Closes the [searching] on the [LogicalKeyboardKey.escape] events.
  ///
  /// Intended to be used as a [HardwareKeyboard] listener.
  bool _escapeListener(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      if (searching.value) {
        closeSearch(!groupCreating.value);
        return true;
      } else if (groupCreating.value) {
        closeGroupCreating();
        return true;
      }
    }

    return false;
  }

  /// Invokes [closeSearch] if [searching], or [closeGroupCreating] if
  /// [groupCreating].
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo __) {
    if (searching.isTrue) {
      closeSearch(!groupCreating.value);
      return true;
    } else if (groupCreating.isTrue) {
      closeGroupCreating();
      return true;
    }

    return false;
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

/// [ListElement] representing the currently authenticated [MyUser].
class MyUserElement extends ListElement {
  const MyUserElement();
}

/// [ListElement] representing a recent [RxUser].
class RecentElement extends ListElement {
  const RecentElement(this.user);

  /// [RxUser] itself.
  final RxUser user;
}

class LoaderElement extends ListElement {
  const LoaderElement();
}
