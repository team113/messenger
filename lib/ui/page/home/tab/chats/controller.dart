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

import 'package:async/async.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/contact.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyExistsException,
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
import '/domain/service/session.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        ClearChatException,
        CreateGroupChatException,
        FavoriteChatException,
        HideChatException,
        JoinChatCallException,
        RemoveChatMemberException,
        ToggleChatMuteException,
        UnfavoriteChatException;
import '/routes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/data_reader.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'view.dart';

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
    this._sessionService,
  );

  /// Reactive list of sorted [Chat]s.
  final RxList<ChatEntry> chats = RxList();

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

  /// Status of the [createGroup] progression.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the query has not yet started.
  /// - `status.isLoading`, meaning the [createGroup] is executing.
  final Rx<RxStatus> creatingStatus = Rx<RxStatus>(RxStatus.empty());

  /// Indicator whether multiple [Chat]s selection is active.
  final RxBool selecting = RxBool(false);

  /// Reactive list of [ChatId]s of the selected [Chat]s.
  final RxList<ChatId> selectedChats = RxList();

  /// Indicator whether an ongoing reordering is happening or not.
  ///
  /// Used to discard a broken [FadeInAnimation].
  final RxBool reordering = RxBool(false);

  /// [TextFieldState] for [ChatName] inputting while [groupCreating].
  final TextFieldState groupName = TextFieldState();

  /// [Timer] displaying the [chats] being fetched when it becomes `null`.
  late final Rx<Timer?> fetching = Rx(
    Timer(2.seconds, () => fetching.value = null),
  );

  /// [GlobalKey] of the more button.
  final GlobalKey moreKey = GlobalKey();

  /// [DismissedChat]s added in [dismiss].
  final RxList<DismissedChat> dismissed = RxList();

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

  /// [SessionService] for checking the current [connected] status.
  final SessionService _sessionService;

  /// Subscription for the [ChatService.paginated] changes.
  late final StreamSubscription _chatsSubscription;

  /// Subscription for [SearchController.chats], [SearchController.users] and
  /// [SearchController.contacts] changes updating the [elements].
  StreamSubscription? _searchSubscription;

  /// Subscription for the [ChatService.status] changes.
  StreamSubscription? _statusSubscription;

  /// Subscription for the [RxUser]s changes.
  final Map<UserId, StreamSubscription> _userSubscriptions = {};

  /// Indicator whether the [_scrollListener] is already invoked during the
  /// current frame.
  bool _scrollIsInvoked = false;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns the [RxStatus] of the [chats] fetching and initialization.
  Rx<RxStatus> get status => _chatService.status;

  /// Indicates whether the [chats] have a next page.
  RxBool get hasNext => _chatService.hasNext;

  /// Indicates whether the current device is connected to any network.
  RxBool get connected => _sessionService.connected;

  @override
  void onInit() {
    scrollController.addListener(_scrollListener);

    chats.value = RxList(
      _chatService.paginated.values
          .map((e) => ChatEntry(e, chats.sort))
          .toList(),
    );

    chats.sort();

    HardwareKeyboard.instance.addHandler(_escapeListener);
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    // Adds the recipient of the provided [chat] to the [_recipients] and starts
    // listening to its updates.
    Future<void> listenUpdates(ChatEntry chat) async {
      final UserId? userId = chat.chat.value.members
          .firstWhereOrNull((u) => u.user.id != me)
          ?.user
          .id;

      if (userId != null) {
        RxUser? rxUser = chat.members.values
            .toList()
            .firstWhereOrNull((u) => u.user.id != me)
            ?.user;
        rxUser ??= await getUser(userId);
        if (rxUser != null) {
          _userSubscriptions.remove(userId)?.cancel();
          _userSubscriptions[userId] = rxUser.updates.listen((_) {});
        }
      }
    }

    chats.where((c) => c.chat.value.isDialog).forEach(listenUpdates);
    _chatsSubscription = _chatService.paginated.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          final entry = ChatEntry(event.value!, chats.sort);
          chats.add(entry);
          chats.sort();

          if (event.value!.chat.value.isDialog) {
            listenUpdates(entry);
          }
          break;

        case OperationKind.removed:
          chats.removeWhere((e) {
            if (e.chat.value.id == event.key) {
              e.dispose();
              return true;
            }

            return false;
          });

          if (event.value!.chat.value.isDialog) {
            final UserId? userId = event.value!.chat.value.members
                .firstWhereOrNull((u) => u.user.id != me)
                ?.user
                .id;

            _userSubscriptions.remove(userId)?.cancel();
          }

          _scrollListener();
          break;

        case OperationKind.updated:
          chats.sort();
          break;
      }
    });

    if (_chatService.status.value.isSuccess) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _ensureScrollable());
    } else {
      _statusSubscription = _chatService.status.listen((status) {
        if (status.isSuccess) {
          SchedulerBinding.instance
              .addPostFrameCallback((_) => _ensureScrollable());
        }
      });
    }

    super.onInit();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_escapeListener);
    scrollController.dispose();

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    for (var data in chats) {
      data.dispose();
    }
    _chatsSubscription.cancel();
    _statusSubscription?.cancel();

    _searchSubscription?.cancel();
    search.value?.search.focus.removeListener(_disableSearchFocusListener);
    search.value?.onClose();

    for (StreamSubscription s in _userSubscriptions.values) {
      s.cancel();
    }

    for (var e in dismissed) {
      e._timer.cancel();
    }

    fetching.value?.cancel();

    router.navigation.value = true;

    super.onClose();
  }

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
        if (user.id == me) {
          router.chat(_chatService.monolog, push: true);
        } else {
          router.chat(user.user.value.dialog);
        }
      }
    }
  }

  /// Starts an [OngoingCall] in the [Chat] identified by the provided [id].
  Future<void> call(ChatId id, [bool withVideo = false]) async {
    try {
      await _callService.call(id, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Joins the call in the [Chat] identified by the provided [id] [withVideo]
  /// or without.
  Future<void> joinCall(ChatId id, {bool withVideo = false}) async {
    try {
      await _callService.join(id, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
      MessagePopup.error(e);
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
      if (router.route == '${Routes.chats}/$id') {
        router.pop();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Hides the [Chat] identified by the provided [id] and clears its history as
  /// well if [clear] is `true`.
  Future<void> hideChat(ChatId id, [bool clear = false]) async {
    try {
      await _chatService.hideChat(id);

      if (clear) {
        await _chatService.clearChat(id);
      }
    } on HideChatException catch (e) {
      MessagePopup.error(e);
    } on ClearChatException catch (e) {
      MessagePopup.error(e);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Hides the [selectedChats], clearing their histories as well if [clear] is
  /// `true`.
  Future<void> hideChats([bool clear = false]) async {
    selecting.value = false;
    router.navigation.value = !selecting.value;

    try {
      await Future.wait(selectedChats.map(_chatService.hideChat));

      if (clear) {
        await Future.wait(selectedChats.map(_chatService.clearChat));
      }
    } on HideChatException catch (e) {
      MessagePopup.error(e);
    } on ClearChatException catch (e) {
      MessagePopup.error(e);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      selectedChats.clear();
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
  Future<void> favoriteChat(
    ChatId id, [
    ChatFavoritePosition? position,
  ]) async {
    try {
      await _chatService.favoriteChat(id, position);
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
  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Indicates whether [User] from this [chat] is already in contacts.
  ///
  /// Only meaningful, if [chat] is dialog.
  bool inContacts(RxChat chat) {
    if (!chat.chat.value.isDialog) {
      return false;
    }

    return chat.members.values
            .firstWhereOrNull((e) => e.user.id != me)
            ?.user
            .user
            .value
            .contacts
            .isNotEmpty ==
        true;
  }

  /// Adds the [User] from this [chat] to the contacts list of the authenticated
  /// [MyUser].
  ///
  /// Only meaningful, if [chat] is dialog.
  Future<void> addToContacts(RxChat chat) async {
    if (inContacts(chat)) {
      return;
    }

    final User? user = chat.members.values
        .firstWhereOrNull((e) => e.user.id != me)
        ?.user
        .user
        .value;
    if (user == null) {
      return;
    }

    try {
      await _contactService.createChatContact(user);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the [User] from this [chat] from the contacts list of the
  /// authenticated [MyUser].
  ///
  /// Only meaningful, if [chat] is dialog.
  Future<void> removeFromContacts(RxChat chat) async {
    if (!inContacts(chat)) {
      return;
    }

    try {
      final ChatContactId? contactId = chat.members.values
          .firstWhereOrNull((e) => e.user.id != me)
          ?.user
          .user
          .value
          .contacts
          .firstOrNull
          ?.id;

      if (contactId != null) {
        await _contactService.deleteContact(contactId);
      }
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Drops an [OngoingCall] in a [Chat] identified by its [id], if any.
  Future<void> dropCall(ChatId id) => _callService.leave(id);

  /// Sends the dropped files of [event] to the [Chat] identified by its [id].
  Future<void> sendFiles(ChatId id, PerformDropEvent event) async {
    final List<Attachment> attachments = [];

    // Populate attachments with dropped files.
    for (final DropItem item in event.session.items) {
      final PlatformFile? file = await item.dataReader?.asPlatformFile();
      if (file != null) {
        if (file.size >= MessageFieldController.maxAttachmentSize) {
          MessagePopup.error('err_size_too_big'.l10n);
          continue;
        }

        attachments.add(
          LocalAttachment(
            NativeFile.fromPlatformFile(file),
            status: SendingStatus.sending,
          ),
        );
      }
    }

    if (attachments.isNotEmpty) {
      attachments
          .whereType<LocalAttachment>()
          .forEach(_chatService.uploadAttachment);

      await _chatService.sendChatMessage(id, attachments: attachments);
    }
  }

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
    groupName.clear();
    closeSearch(true);
    router.navigation.value = true;
  }

  /// Creates a [Chat]-group with [SearchController.selectedRecent],
  /// [SearchController.selectedContacts] and [SearchController.selectedUsers].
  Future<void> createGroup() async {
    creatingStatus.value = RxStatus.loading();

    try {
      final RxChat chat = await _chatService.createGroupChat(
        {
          ...search.value!.selectedRecent.map((e) => e.id),
          ...search.value!.selectedContacts
              .expand((e) => e.contact.value.users.map((u) => u.id)),
          ...search.value!.selectedUsers.map((e) => e.id),
        }.where((e) => e != me).toList(),
        name: ChatName.tryParse(groupName.text),
      );

      router.chat(chat.chat.value.id);

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

  /// Toggles the [Chat]s selection.
  void toggleSelecting() {
    selecting.toggle();
    router.navigation.value = !selecting.value;
    selectedChats.clear();
  }

  /// Selects or unselects the provided [chat], meaning adding or removing it
  /// from the [selectedChats].
  void selectChat(RxChat chat) {
    if (selectedChats.contains(chat.id)) {
      selectedChats.remove(chat.id);
    } else {
      selectedChats.add(chat.id);
    }
  }

  /// Reorders a [Chat] from the [from] position to the [to] position.
  Future<void> reorderChat(int from, int to) async {
    final List<ChatEntry> favorites = chats
        .where(
          (e) =>
              e.chat.value.ongoingCall == null &&
              e.chat.value.favoritePosition != null &&
              !e.chat.value.isHidden &&
              !e.hidden.value,
        )
        .toList();

    double position;

    if (to <= 0) {
      position = favorites.first.chat.value.favoritePosition!.val * 2;
    } else if (to >= favorites.length) {
      position = favorites.last.chat.value.favoritePosition!.val / 2;
    } else {
      position = (favorites[to].chat.value.favoritePosition!.val +
              favorites[to - 1].chat.value.favoritePosition!.val) /
          2;
    }

    if (to > from) {
      to--;
    }

    final int start = chats.indexOf(favorites[from]);
    final int end = chats.indexOf(favorites[to]);

    final ChatId chatId = chats[start].id;
    chats.insert(end, chats.removeAt(start));

    await favoriteChat(chatId, ChatFavoritePosition(position));
  }

  /// Dismisses the [chat], adding it to the [dismissed].
  void dismiss(RxChat chat) {
    for (var e in List<DismissedChat>.from(dismissed, growable: false)) {
      e._done(true);
    }
    dismissed.clear();

    DismissedChat? entry;

    entry = DismissedChat(
      chat,
      onDone: (d) {
        if (d) {
          hideChat(chat.id);
        } else {
          for (var e in chats) {
            if (e.id == chat.id) {
              e.hidden.value = false;
            }
          }
        }

        dismissed.remove(entry!);
      },
    );

    router.removeWhere((e) => chat.chat.value.isRoute(e, me));
    dismissed.add(entry);

    for (var e in chats) {
      if (e.id == chat.id) {
        e.hidden.value = true;
      }
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
        _myUserService,
        categories: [
          SearchCategory.recent,
          if (groupCreating.isFalse) SearchCategory.chat,
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

  /// Requests the next page of [Chat]s based on the [ScrollController.position]
  /// value.
  void _scrollListener() {
    if (!_scrollIsInvoked) {
      _scrollIsInvoked = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollIsInvoked = false;

        if (scrollController.hasClients &&
            hasNext.isTrue &&
            _chatService.nextLoading.isFalse &&
            scrollController.position.pixels >
                scrollController.position.maxScrollExtent - 500) {
          _chatService.next();
        }
      });
    }
  }

  /// Ensures the [ChatsTabView] is scrollable.
  Future<void> _ensureScrollable() async {
    if (isClosed) {
      return;
    }

    if (hasNext.isTrue) {
      await Future.delayed(1.milliseconds, () async {
        if (isClosed) {
          return;
        }

        if (!scrollController.hasClients) {
          return await _ensureScrollable();
        }

        // If the fetched initial page contains less elements than required to
        // fill the view and there's more pages available, then fetch those pages.
        if (scrollController.position.maxScrollExtent < 50 &&
            _chatService.nextLoading.isFalse) {
          await _chatService.next();
          _ensureScrollable();
        }
      });
    }
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
class ChatEntry implements Comparable<ChatEntry> {
  /// Returns a [ChatEntry] capturing the provided [chat] changes to
  /// invoke a [sort] on [Chat.updatedAt] or [Chat.ongoingCall] updates.
  ChatEntry(this._chat, [void Function()? sort]) {
    _updatedAt = _chat.chat.value.updatedAt;
    _hasCall = _chat.chat.value.ongoingCall != null;

    _worker = ever(
      _chat.chat,
      (Chat chat) {
        bool hasCall = chat.ongoingCall != null;
        if (chat.updatedAt != _updatedAt || hasCall != _hasCall) {
          sort?.call();
          _updatedAt = chat.updatedAt;
          _hasCall = hasCall;
        }
      },
    );
  }

  /// Indicator whether this [ChatEntry] is hidden.
  final RxBool hidden = RxBool(false);

  /// [RxChat] itself.
  final RxChat _chat;

  /// Worker capturing the [Chat] changes to invoke sorting on [_updatedAt] and
  /// [_hasCall] mismatches.
  late final Worker _worker;

  /// Previously captured [Chat.updatedAt] value.
  late PreciseDateTime _updatedAt;

  /// Previously captured indicator of [Chat.ongoingCall] being non-`null`.
  late bool _hasCall;

  /// Returns the [RxChat] this [ChatEntry] represents.
  RxChat get rx => _chat;

  /// Returns value of a [Chat] this [ChatEntry] represents.
  Rx<Chat> get chat => _chat.chat;

  /// Returns a [ChatId] of the [chat].
  ChatId get id => _chat.chat.value.id;

  /// Returns observable list of [ChatItem]s of the [chat].
  RxObsList<Rx<ChatItem>> get messages => _chat.messages;

  /// Reactive map of [User]s being members of this [chat].
  RxSortedObsMap<UserId, RxChatMember> get members => _chat.members.items;

  /// Disposes this [ChatEntry].
  void dispose() => _worker.dispose();

  @override
  int compareTo(ChatEntry other) => _chat.compareTo(other._chat);
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

/// [RxChat] being dismissed.
///
/// Invokes the irreversible action (e.g. hiding the [chat]) when the
/// [remaining] milliseconds have passed.
class DismissedChat {
  DismissedChat(this.chat, {void Function(bool)? onDone}) : _onDone = onDone {
    _timer = Timer.periodic(32.milliseconds, (t) {
      final value = remaining.value - 32;

      if (remaining.value <= 0) {
        remaining.value = 0;
        _done(true);
      } else {
        remaining.value = value;
      }
    });
  }

  /// [RxChat] itself.
  final RxChat chat;

  /// Time in milliseconds before the [chat] invokes the irreversible action.
  final RxInt remaining = RxInt(5000);

  /// Callback, called when [_timer] is done counting the [remaining]
  /// milliseconds.
  final void Function(bool)? _onDone;

  /// [Timer] counting milliseconds until the [remaining].
  late final Timer _timer;

  /// Indicator whether the [_done] was already invoked.
  bool _invoked = false;

  /// Cancels the dismissal.
  void cancel() => _done();

  /// Invokes the [_onDone] and cancels the [_timer].
  void _done([bool done = false]) {
    if (!_invoked) {
      _invoked = true;
      _onDone?.call(done);
      _timer.cancel();
    }
  }
}
