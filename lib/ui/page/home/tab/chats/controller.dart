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
import 'package:flutter/material.dart' hide SearchController, NavigationMode;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:log_me/log_me.dart';
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
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
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
        ToggleChatArchivationException,
        ToggleChatMuteException,
        UnfavoriteChatException;
import '/routes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
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

  /// Reactive list of sorted archived [Chat]s.
  final RxList<ChatEntry> archived = RxList();

  /// [SearchController] for searching the [Chat]s, [User]s and [ChatContact]s.
  final Rx<SearchController?> search = Rx(null);

  /// [ListElement]s representing the [search] results visually.
  final RxList<ListElement> elements = RxList([]);

  /// Indicator whether chat archive viewing is active.
  final RxBool archivedOnly = RxBool(false);

  /// [ScrollController] to pass to a [Scrollbar] of recent [RxChat]s.
  final ScrollController chatsController = ScrollController();

  /// [ScrollController] to pass to a [Scrollbar] of archived [RxChat]s.
  final ScrollController archiveController = ScrollController();

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

  /// [Timer] displaying the [chats] being fetched when it becomes `null`.
  late final Rx<Timer?> fetching = Rx(
    Timer(2.seconds, () => fetching.value = null),
  );

  /// [GlobalKey] of the more button.
  final GlobalKey moreKey = GlobalKey();

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

  /// Subscription for the [ChatService.archived] changes.
  late final StreamSubscription _archivedSubscription;

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

  /// [ChatService.paginated] length fetched during [ChatService.next] invoke
  /// used to guard against the method spamming again and again.
  int? _chatsInitiallyFetched;

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

  /// Returns [ChatId] of the [Chat]-monolog of the currently authenticated
  /// [MyUser], if any.
  ChatId get monolog => _chatService.monolog;

  /// Returns the [Paginated] of [RxChat] being in archive.
  Paginated<ChatId, RxChat> get archive => _chatService.archived;

  /// Indicator whether remote connection is still being configured.
  bool get synchronizing =>
      !connected.value ||
      (fetching.value == null && status.value.isLoadingMore);

  @override
  void onInit() {
    chatsController.addListener(_chatsListener);
    archiveController.addListener(_archiveListener);

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

          _chatsListener();
          break;

        case OperationKind.updated:
          chats.sort();
          break;
      }
    });

    archived.value = RxList(
      archive.values.map((e) => ChatEntry(e, chats.sort)).toList(),
    );
    archived.where((c) => c.chat.value.isDialog).forEach(listenUpdates);
    archived.sort();

    _archivedSubscription = _chatService.archived.items.changes.listen((event) {
      Log.debug(
        '_archivedSubscription -> ${event.op} -> ${event.value}',
        '$runtimeType',
      );

      switch (event.op) {
        case OperationKind.added:
          final entry = ChatEntry(event.value!, chats.sort);
          archived.add(entry);
          archived.sort();
          break;

        case OperationKind.removed:
          archived.removeWhere((e) {
            if (e.chat.value.id == event.key) {
              e.dispose();
              return true;
            }

            return false;
          });

          _archiveListener();
          break;

        case OperationKind.updated:
          archived.sort();
          break;
      }
    });

    if (_chatService.status.value.isSuccess) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _ensureScrollable(),
      );
    } else {
      _statusSubscription = _chatService.status.listen((status) {
        if (status.isSuccess) {
          SchedulerBinding.instance.addPostFrameCallback(
            (_) => _ensureScrollable(),
          );
        }
      });
    }

    _initSearch();

    super.onInit();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_escapeListener);

    chatsController.dispose();
    archiveController.dispose();

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    for (var data in chats) {
      data.dispose();
    }
    _chatsSubscription.cancel();
    _archivedSubscription.cancel();
    _statusSubscription?.cancel();

    _searchSubscription?.cancel();
    search.value?.onClose();

    for (StreamSubscription s in _userSubscriptions.values) {
      s.cancel();
    }

    fetching.value?.cancel();

    router.navigation.value = true;
    router.navigator.value = null;

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
      router.dialog(chat.chat.value, me);
    } else {
      user ??= contact?.user.value;

      if (user != null) {
        if (user.id == me) {
          router.chat(_chatService.monolog, mode: RouteAs.push);
        } else {
          router.chat(ChatId.local(user.user.value.id));
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
    }
  }

  /// Joins the call in the [Chat] identified by the provided [id] [withVideo]
  /// or without.
  Future<void> joinCall(ChatId id, {bool withVideo = false}) async {
    try {
      await _callService.join(id, withVideo: withVideo);
    } on JoinChatCallException catch (e) {
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

  /// Archives or unarchives the specified [Chat] identified by the provided
  /// [id].
  Future<void> archiveChat(ChatId id, bool archive) async {
    try {
      await _chatService.archiveChat(id, archive);
    } on ToggleChatArchivationException catch (e) {
      MessagePopup.error(e);
    } on UnfavoriteChatException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Archives or unarchives the [selectedChats].
  Future<void> archiveChats(bool archive) async {
    selecting.value = false;

    router.navigation.value = !selecting.value;
    router.navigator.value = null;

    try {
      await Future.wait(
        selectedChats.map(
          (chatId) => _chatService.archiveChat(chatId, archive),
        ),
      );
    } on ToggleChatArchivationException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      selectedChats.clear();
    }
  }

  /// Hides the [selectedChats], clearing their histories as well if [clear] is
  /// `true`.
  Future<void> hideChats([bool clear = false]) async {
    selecting.value = false;

    router.navigation.value = !selecting.value;
    router.navigator.value = null;

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
  Future<void> favoriteChat(ChatId id, [ChatFavoritePosition? position]) async {
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
      attachments.whereType<LocalAttachment>().forEach(
        _chatService.uploadAttachment,
      );

      await _chatService.sendChatMessage(id, attachments: attachments);
    }
  }

  /// Disables and disposes the [search]ing.
  void clearSearch() {
    search.value?.search.clear();
    search.value?.query.value = '';
  }

  /// Enables and initializes the group creating.
  void startGroupCreating() {
    groupCreating.value = true;
    search.value?.search.clear();
    search.value?.query.value = '';
    search.value?.categories = [
      SearchCategory.recent,
      SearchCategory.contact,
      SearchCategory.user,
    ];
    router.navigation.value = false;
    router.navigator.value = (context) =>
        ChatsTabView.createGroupBuilder(context, this);
    search.value?.populate();
  }

  /// Disables and disposes the group creating.
  void closeGroupCreating() {
    groupCreating.value = false;
    search.value?.search.clear();
    search.value?.query.value = '';
    search.value?.categories = [
      SearchCategory.recent,
      SearchCategory.chat,
      SearchCategory.contact,
      SearchCategory.user,
    ];
    router.navigation.value = true;
    router.navigator.value = null;
  }

  /// Creates a [Chat]-group with [SearchController.selectedRecent],
  /// [SearchController.selectedContacts] and [SearchController.selectedUsers].
  Future<void> createGroup() async {
    creatingStatus.value = RxStatus.loading();

    try {
      final RxChat chat = await _chatService.createGroupChat(
        {
          ...search.value!.selectedRecent.map((e) => e.id),
          ...search.value!.selectedContacts.expand(
            (e) => e.contact.value.users.map((u) => u.id),
          ),
          ...search.value!.selectedUsers.map((e) => e.id),
        }.where((e) => e != me).toList(),
      );

      router.chat(chat.id);
      router.chatInfo(chat.id, push: true);

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

    if (selecting.value) {
      router.navigator.value = (context) =>
          ChatsTabView.selectingBuilder(context, this);
    } else {
      router.navigator.value = null;
    }

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
              !e.chat.value.isArchived,
        )
        .toList();

    double position;

    if (to <= 0) {
      position = favorites.first.chat.value.favoritePosition!.val * 2;
    } else if (to >= favorites.length) {
      position = favorites.last.chat.value.favoritePosition!.val / 2;
    } else {
      position =
          (favorites[to].chat.value.favoritePosition!.val +
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

  /// Reads all the [RxChat]s in the [chats] list.
  Future<void> readAll() async {
    final Future<void> future = _chatService.readAll(
      selecting.value
          ? selectedChats.isEmpty
                ? null
                : selectedChats
          : null,
    );

    toggleSelecting();

    try {
      await future;
    } catch (e) {
      MessagePopup.error('err_data_transfer'.l10n);
      rethrow;
    }
  }

  /// Toggles the [archivedOnly].
  void toggleArchive() {
    archivedOnly.value = !archivedOnly.value;
  }

  /// Initializes the [search].
  void _initSearch() {
    search.value = SearchController(
      _chatService,
      _userService,
      _contactService,
      _myUserService,
      _sessionService,
      categories: [
        SearchCategory.recent,
        SearchCategory.chat,
        SearchCategory.contact,
        SearchCategory.user,
      ],
      prePopulate: false,
    )..onInit();

    _searchSubscription =
        StreamGroup.merge([
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
  }

  /// Closes the [searching] on the [LogicalKeyboardKey.escape] events.
  ///
  /// Intended to be used as a [HardwareKeyboard] listener.
  bool _escapeListener(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
      if (search.value?.query.value.isNotEmpty == true) {
        clearSearch();
        return true;
      } else if (groupCreating.value) {
        closeGroupCreating();
        return true;
      } else if (selecting.value) {
        toggleSelecting();
        return true;
      }
    }

    return false;
  }

  /// Requests the next page of [Chat]s based on the [ScrollController.position]
  /// value.
  void _chatsListener() {
    if (!_scrollIsInvoked) {
      _scrollIsInvoked = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollIsInvoked = false;

        if (chatsController.hasClients &&
            chatsController.position.pixels >
                chatsController.position.maxScrollExtent - 500 &&
            !status.value.isLoading) {
          if (archivedOnly.value) {
            if (archive.hasNext.isTrue && archive.nextLoading.isFalse) {
              archive.next();
            }
          } else {
            if (hasNext.isTrue && _chatService.nextLoading.isFalse) {
              _chatService.next();
            }
          }
        }
      });
    }
  }

  /// Requests the next page of archived [Chat]s based on the
  /// [ScrollController.position] value.
  void _archiveListener() {
    if (!_scrollIsInvoked) {
      _scrollIsInvoked = true;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollIsInvoked = false;

        if (chatsController.hasClients &&
            chatsController.position.pixels >
                chatsController.position.maxScrollExtent - 500 &&
            !status.value.isLoading) {
          if (archivedOnly.value) {
            if (archive.hasNext.isTrue && archive.nextLoading.isFalse) {
              archive.next();
            }
          } else {
            if (hasNext.isTrue && _chatService.nextLoading.isFalse) {
              _chatService.next();
            }
          }
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

        final ScrollController scroll = switch (archivedOnly.value) {
          true => archiveController,
          false => chatsController,
        };

        if (!scroll.hasClients) {
          return await _ensureScrollable();
        }

        // If the fetched initial page contains less elements than required to
        // fill the view and there's more pages available, then fetch those pages.
        if (scroll.position.maxScrollExtent < 50 &&
            _chatService.nextLoading.isFalse) {
          final int amount = _chatService.paginated.length;

          await switch (archivedOnly.value) {
            true => archive.next,
            false => _chatService.next,
          }();

          _chatsInitiallyFetched = _chatService.paginated.length;

          // Don't spam this method again and again if no chats were fetched.
          if (_chatsInitiallyFetched != amount) {
            _ensureScrollable();
          }
        }
      });
    }
  }

  /// Invokes [clearSearch] if [search]ing, or [closeGroupCreating] if
  /// [groupCreating].
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true`, if back button should be intercepted, or otherwise returns
  /// `false`.
  bool _onBack(bool _, RouteInfo _) {
    if (search.value?.query.value.isNotEmpty == true) {
      clearSearch();
      return true;
    } else if (groupCreating.isTrue) {
      closeGroupCreating();
      return true;
    } else if (selecting.value) {
      toggleSelecting();
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

    _worker = ever(_chat.chat, (Chat chat) {
      bool hasCall = chat.ongoingCall != null;
      if (chat.updatedAt != _updatedAt || hasCall != _hasCall) {
        sort?.call();
        _updatedAt = chat.updatedAt;
        _hasCall = hasCall;
      }
    });
  }

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
