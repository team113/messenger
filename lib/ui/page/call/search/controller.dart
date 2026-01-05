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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/my_user.dart';
import '/domain/service/session.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/log.dart';

export 'view.dart';

/// Category to search through.
enum SearchCategory {
  /// Recent (up to 3) [Chat]-dialogs.
  recent,

  /// [ChatContact]s of the authenticated [MyUser].
  contact,

  /// Global [User]s and [User]s having a [Chat]-dialog with the authenticated
  /// [MyUser].
  user,

  /// [Chat]s of the authenticated [MyUser].
  chat;

  /// Returns localized representation of this [SearchCategory].
  String get l10n => switch (this) {
    SearchCategory.user => 'label_search_category_users'.l10n,
    SearchCategory.chat ||
    SearchCategory.recent => 'label_search_category_chats'.l10n,
    SearchCategory.contact => 'label_search_category_contacts'.l10n,
  };
}

/// Controller for searching the provided [categories].
class SearchController extends GetxController {
  SearchController(
    this._chatService,
    this._userService,
    this._contactService,
    this._myUserService,
    this._sessionService, {
    required this.categories,
    this.chat,
    this.onSelected,
    this.prePopulate = true,
  }) : assert(categories.isNotEmpty);

  /// [RxChat] this controller is bound to, if any.
  ///
  /// If specified, then the [RxChat.members] of this [chat] will be omitted
  /// from the [usersSearch] and [contactsSearch].
  final RxChat? chat;

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);

  /// Reactive list of the selected [User]s.
  final RxList<RxUser> selectedUsers = RxList<RxUser>([]);

  /// Reactive list of the selected recent [User]s.
  final RxList<RxUser> selectedRecent = RxList<RxUser>([]);

  /// Reactive list of the selected [Chat]s.
  final RxList<RxChat> selectedChats = RxList<RxChat>([]);

  /// [User]s search results.
  final Rx<Paginated<UserId, RxUser>?> usersSearch = Rx(null);

  /// [ChatContact]s search results.
  final Rx<Paginated<ChatContactId, RxChatContact>?> contactsSearch = Rx(null);

  /// Status of a [_search] completion.
  ///
  /// May be:
  /// - `searchStatus.empty`, meaning no search.
  /// - `searchStatus.loading`, meaning search is in progress.
  /// - `searchStatus.loadingMore`, meaning search is in progress after some
  ///   [usersSearch] or [contactsSearch] were already acquired.
  /// - `searchStatus.success`, meaning search is done and [usersSearch]
  ///   or [contactsSearch] are acquired.
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  /// [RxUser]s found under the [SearchCategory.recent] category.
  final RxMap<UserId, RxUser> recent = RxMap();

  /// [RxChatContact]s found under the [SearchCategory.contact] category.
  final RxMap<UserId, RxChatContact> contacts = RxMap();

  /// [RxUser]s found under the [SearchCategory.user] category.
  final RxMap<UserId, RxUser> users = RxMap();

  /// [Chat]s found under the [SearchCategory.chat] category.
  final RxMap<ChatId, RxChat> chats = RxMap();

  /// [FlutterListViewController] of a [FlutterListView] displaying the search
  /// results.
  final FlutterListViewController scrollController =
      FlutterListViewController();

  /// [TextFieldState] of the search field.
  late final TextFieldState search;

  /// [SearchCategory]ies to search through.
  List<SearchCategory> categories;

  /// Reactive value of the [search] field passed to the [_search] method.
  final RxString query = RxString('');

  /// Callback, called on the [selectedContacts], [selectedChats],
  /// [selectedUsers] and [selectedRecent] changes.
  final void Function(SearchViewResults? results)? onSelected;

  /// Indicator whether this [SearchController] should try populating the
  /// results when initialized.
  final bool prePopulate;

  /// Worker to react on the [usersSearch] status changes.
  Worker? _usersSearchWorker;

  /// Worker to react on the [contactsSearch] status changes.
  Worker? _contactsSearchWorker;

  /// Worker to react on the [ChatService.status] changes.
  Worker? _chatStatusWorker;

  /// Subscriptions to the [usersSearch] updates.
  StreamSubscription? _usersSearchSubscription;

  /// Subscriptions to the [contactsSearch] updates.
  StreamSubscription? _contactsSearchSubscription;

  /// Worker to react on [query] changes.
  Worker? _searchWorker;

  /// Worker performing a [_search] on [query] changes with debounce.
  Worker? _searchDebounce;

  /// [interval] invoking [_next] on the [_scrollPosition] changes.
  Worker? _nextInterval;

  /// [Timer] invoking the [_ensureScrollable].
  Timer? _ensureScrollableTimer;

  /// Reactive value of the current [ScrollPosition.pixels].
  final RxDouble _scrollPosition = RxDouble(0);

  /// [Chat]s service searching the [Chat]s.
  final ChatService _chatService;

  /// [User]s service searching the [User]s.
  final UserService _userService;

  /// [ChatContact]s service searching the [ChatContact]s.
  final ContactService _contactService;

  /// [MyUserService] searching [myUser].
  final MyUserService _myUserService;

  /// [SessionService] for checking the current [_connected] status.
  final SessionService _sessionService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// Indicates whether the current device is connected to any network.
  bool get _connected => _sessionService.connected.value;

  /// Whether this [SearchController] has potentially more search results.
  bool get hasNext {
    final bool contactsHaveMore =
        categories.contains(SearchCategory.contact) &&
        (contactsSearch.value?.hasNext.isTrue ??
            _contactService.hasNext.isTrue);
    final bool usersHaveMore =
        categories.contains(SearchCategory.user) &&
        (usersSearch.value?.hasNext.isTrue ?? false);
    final bool chatsHaveMore = _chatService.hasNext.isTrue;

    return chatsHaveMore || usersHaveMore || contactsHaveMore;
  }

  @override
  void onInit() {
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

    search = TextFieldState(onFocus: (d) => query.value = d.text);
    _searchDebounce = debounce(query, (q) => _search(q.trim()));
    _searchWorker = ever(query, (String q) {
      if (q.length < 2) {
        _usersSearchSubscription?.cancel();
        usersSearch.value = null;
        _contactsSearchSubscription?.cancel();
        contactsSearch.value = null;
        users.clear();
        contacts.clear();
        chats.clear();
        recent.clear();
      }

      searchStatus.value = RxStatus.loading();

      populate();
    });

    _chatService.ensureInitialized();
    if (!_chatService.status.value.isSuccess) {
      _chatStatusWorker = ever(_chatService.status, (status) {
        if (status.isSuccess) {
          if (prePopulate || query.value.isNotEmpty) {
            _ensureScrollable();
            populate();
          }

          _chatStatusWorker?.dispose();
          _chatStatusWorker = null;
        }
      });
    }

    if (prePopulate) {
      _ensureScrollable();
      populate();
    }

    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    _nextInterval?.dispose();
    _searchDebounce?.dispose();
    _searchWorker?.dispose();
    _usersSearchWorker?.dispose();
    _usersSearchWorker = null;
    _ensureScrollableTimer?.cancel();
    _contactsSearchWorker?.dispose();
    _contactsSearchWorker = null;
    _usersSearchSubscription?.cancel();
    _contactsSearchSubscription?.cancel();
    _chatStatusWorker?.dispose();
    super.onClose();
  }

  /// Returns all the selected [UserId]s.
  List<UserId> selected() {
    return {
      ...selectedContacts.expand((e) => e.contact.value.users.map((u) => u.id)),
      ...selectedUsers.map((u) => u.id),
    }.toList();
  }

  /// Selects or unselects the specified [contact], [user], [chat] or [recent].
  void select({
    RxChatContact? contact,
    RxUser? user,
    RxChat? chat,
    RxUser? recent,
  }) {
    if (contact != null) {
      if (selectedContacts.contains(contact)) {
        selectedContacts.remove(contact);
      } else {
        selectedContacts.add(contact);
      }
    }

    if (user != null) {
      if (selectedUsers.contains(user)) {
        selectedUsers.remove(user);
      } else {
        selectedUsers.add(user);
      }
    }

    if (chat != null) {
      if (selectedChats.contains(chat)) {
        selectedChats.remove(chat);
      } else {
        selectedChats.add(chat);
      }
    }

    if (recent != null) {
      if (selectedRecent.contains(recent)) {
        selectedRecent.remove(recent);
      } else {
        selectedRecent.add(recent);
      }
    }

    if (contact != null || user != null || chat != null || recent != null) {
      onSelected?.call(
        SearchViewResults(
          selectedChats,
          selectedUsers,
          selectedContacts,
          selectedRecent,
        ),
      );
    }
  }

  /// Returns an item by its index from the search results.
  ///
  /// Returned item is either [RxUser], [RxChat] or [RxChatContact].
  dynamic elementAt(int i) {
    return [
      ...chats.values,
      ...recent.values,
      ...contacts.values,
      ...users.values,
    ].elementAt(i);
  }

  /// Updates the [chats], [recent], [contacts] and [users] according to the
  /// [query].
  void populate() {
    _populateChats();
    _populateRecent();
    _populateContacts();
    _populateUsers();

    Log.debug(
      'populate() -> recent($recent), chats($chats), users($users), contacts($contacts)',
      '$runtimeType',
    );
  }

  /// Returns a [User] from the [UserService] by the provided [id].
  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Searches the [User]s based on the provided [query].
  ///
  /// Query may be a [UserNum], [UserName] or [UserLogin].
  Future<void> _search(String query) async {
    // If any [contactsSearch] has been done, dispose it.
    if (contactsSearch.value != null) {
      _contactsSearchSubscription?.cancel();
      contactsSearch.value = null;

      _populateContacts();
    }

    // If any [usersSearch] has been done, dispose it.
    if (usersSearch.value != null) {
      if (!(usersSearch.value?.status.value.isEmpty ?? false)) {
        // Prevent [chats] from containing results of the previous [usersSearch]
        // as it will used during the [_populateUsers] call.
        _populateChats();
      }

      _usersSearchSubscription?.cancel();
      usersSearch.value = null;

      _populateUsers();
    }

    // TODO: Add `Chat`s and `ChatItem`s searching.
    if (categories.contains(SearchCategory.contact)) {
      _searchContacts(query);
    }

    if (categories.contains(SearchCategory.user)) {
      _searchUsers(query);
    }
  }

  /// Searches the [ChatContact]s based on the provided [query].
  ///
  /// Query may be a [UserName], [UserEmail] or [UserPhone].
  void _searchContacts(String query) {
    _contactsSearchWorker?.dispose();
    _contactsSearchWorker = null;

    if (query.isNotEmpty) {
      final UserName? name = UserName.tryParse(query);
      final UserEmail? email = UserEmail.tryParse(query.toLowerCase());
      final UserPhone? phone = UserPhone.tryParse(query);

      if (name != null || email != null || phone != null) {
        searchStatus.value = searchStatus.value.isSuccess
            ? RxStatus.loadingMore()
            : RxStatus.loading();

        final Paginated<ChatContactId, RxChatContact> result = _contactService
            .search(name: name, email: email, phone: phone);

        _contactsSearchSubscription?.cancel();
        contactsSearch.value = result;
        _contactsSearchSubscription = contactsSearch.value?.updates.listen(
          (_) {},
        );
        searchStatus.value = result.status.value;

        _contactsSearchWorker = ever(result.status, (RxStatus s) {
          if ((contactsSearch.value?.items.isNotEmpty ?? false) &&
              !categories.contains(SearchCategory.user)) {
            searchStatus.value = s;
          }

          if (s.isSuccess && !s.isLoadingMore) {
            _populateContacts();
            _ensureScrollable();
          }
        });

        _populateContacts();
      } else {
        if (!categories.contains(SearchCategory.user)) {
          // [query] still can be validated in [_searchUsers].
          searchStatus.value = RxStatus.empty();
        }

        _contactsSearchSubscription?.cancel();
        contactsSearch.value = null;
      }
    } else {
      searchStatus.value = RxStatus.empty();
      _contactsSearchSubscription?.cancel();
      contactsSearch.value = null;
    }
  }

  /// Searches the [User]s based on the provided [query].
  ///
  /// Query may be a [UserNum], [UserName], [UserLogin] or [ChatDirectLinkSlug].
  void _searchUsers(String query) {
    _usersSearchWorker?.dispose();
    _usersSearchWorker = null;

    if (query.isNotEmpty) {
      final UserNum? num = UserNum.tryParse(query);
      final UserName? name = UserName.tryParse(query);
      final UserLogin? login = UserLogin.tryParse(query.toLowerCase());
      final ChatDirectLinkSlug? link = ChatDirectLinkSlug.tryParse(query);

      if (num != null || name != null || login != null || link != null) {
        searchStatus.value = searchStatus.value.isSuccess
            ? RxStatus.loadingMore()
            : RxStatus.loading();
        final Paginated<UserId, RxUser> result = _userService.search(
          num: num,
          name: name,
          login: login,
          link: link,
        );

        _usersSearchSubscription?.cancel();
        usersSearch.value = result;
        _usersSearchSubscription = usersSearch.value?.updates.listen((_) {});
        searchStatus.value = result.status.value;

        _usersSearchWorker = ever(result.status, (RxStatus s) {
          if (!_chatService.hasNext.value) {
            searchStatus.value = s;
          }

          if (s.isSuccess && !s.isLoadingMore) {
            _populateUsers();
            _ensureScrollable();
          }
        });

        _populateUsers();
      } else {
        searchStatus.value = RxStatus.empty();
        _usersSearchSubscription?.cancel();
        usersSearch.value = null;
      }
    } else {
      searchStatus.value = RxStatus.empty();
      _usersSearchSubscription?.cancel();
      usersSearch.value = null;
    }
  }

  /// Updates [chats] by adding the [Chat]-monolog, if it matches the [query].
  Future<void> _populateMonolog() async {
    // Formatted string representations of the current [query].
    final String trimmed = query.value.trim();
    final String lowercase = trimmed.toLowerCase();

    final MyUser? myUser = _myUserService.myUser.value;

    if (myUser != null) {
      final ChatId monologId = _chatService.monolog;

      final FutureOr<RxChat?> monologOrFuture = _chatService.get(monologId);
      final RxChat? monolog = monologOrFuture is RxChat?
          ? monologOrFuture
          : await monologOrFuture;

      if (monolog != null) {
        if (trimmed.isEmpty) {
          // Display [monolog] as the first item in [chats] by default.
          chats.value = {monologId: monolog, ...chats};
          return;
        }

        // Account searching via [MyUser.chatDirectLink].
        final link = ChatDirectLinkSlug.tryParse(trimmed);
        if (link != null && myUser.chatDirectLink?.slug == link) {
          chats.value = {monologId: monolog, ...chats};
          return;
        }

        final String title = monolog.title();
        final String? name = myUser.name?.val;
        final String? login = myUser.login?.val;
        final String num = myUser.num.val;

        for (final param in [title, login, name].nonNulls) {
          if (param.toLowerCase().contains(lowercase)) {
            chats.value = {monologId: monolog, ...chats};
            return;
          }
        }

        // Account possible spaces in [UserNum].
        if (num.contains(trimmed.split(' ').join())) {
          chats.value = {monologId: monolog, ...chats};
        }
      }
    }
  }

  /// Updates the [chats] according to the [query].
  void _populateChats() {
    if (categories.contains(SearchCategory.chat)) {
      final Iterable<RxChat> allChats = _chatService.chats.values;

      // Predicates to filter [allChats] by.
      bool hidden(RxChat c) => c.chat.value.isHidden;
      bool matchesQuery(RxChat c) => _matchesQuery(
        title: c.title(),
        user: c.chat.value.isDialog
            ? c.members.values.firstWhereOrNull((u) => u.user.id != me)?.user
            : null,
      );
      bool localDialog(RxChat c) => c.id.isLocal && !c.id.isLocalWith(me);

      final List<RxChat> filtered = allChats
          .whereNot(hidden)
          .where(matchesQuery)
          .whereNot(localDialog)
          .sorted();

      chats.value = {for (final RxChat c in filtered) c.chat.value.id: c};

      _populateMonolog();
    }
  }

  /// Updates the [recent] according to the [query].
  void _populateRecent() {
    if (categories.contains(SearchCategory.recent)) {
      final Iterable<RxChat> allChats = _chatService.chats.values;

      // Predicates to filter [allChats] by.
      bool remoteDialog(RxChat c) => c.chat.value.isDialog && !c.id.isLocal;
      bool hidden(RxChat c) => c.chat.value.isHidden;
      bool inChats(RxChat c) =>
          categories.contains(SearchCategory.chat) &&
          chats.containsKey(c.chat.value.id);
      RxUser? toUser(RxChat c) =>
          c.members.values.firstWhereOrNull((u) => u.user.id != me)?.user;
      bool isMember(RxUser u) => chat?.members.items.containsKey(u.id) ?? false;
      bool matchesQuery(RxUser user) => _matchesQuery(user: user);

      Iterable<RxUser> filtered = allChats
          .where(remoteDialog)
          .whereNot(inChats)
          .whereNot(hidden)
          .sorted()
          .map(toUser)
          .nonNulls
          .whereNot(isMember);

      if (categories.contains(SearchCategory.chat)) {
        filtered = filtered.take(5);
      }

      filtered = filtered.where(matchesQuery);

      recent.value = {for (final RxUser u in filtered) u.id: u};
    }
  }

  /// Updates the [contacts] according to the [query].
  void _populateContacts() {
    if (categories.contains(SearchCategory.contact) &&
        _chatService.hasNext.isFalse) {
      final Iterable<RxChatContact> stored = _contactService.contacts.values;
      final Iterable<RxChatContact>? searched =
          contactsSearch.value?.items.values;

      final Iterable<RxChatContact> allContacts = {...stored, ...?searched};

      // Predicates to filter the [allContacts] by.
      bool isMember(RxChatContact c) =>
          chat?.members.items.containsKey(c.user.value!.id) ?? false;
      bool inRecent(RxChatContact c) => recent.containsKey(c.user.value!.id);
      bool inChats(RxChatContact c) => chats.values.any(
        (chat) =>
            chat.chat.value.isDialog &&
            chat.members.items.containsKey(c.user.value!.id),
      );
      bool matchesQuery(RxChatContact c) => _matchesQuery(user: c.user.value);

      final List<RxChatContact> filtered = allContacts
          .where(matchesQuery)
          .whereNot(isMember)
          .whereNot(inRecent)
          .whereNot(inChats)
          .sorted();

      final Iterable<RxChatContact> selected = selectedContacts
          .where(matchesQuery)
          .sorted();

      contacts.value = {
        for (final RxChatContact c in {...selected, ...filtered})
          c.user.value!.id: c,
      };
    } else {
      contacts.value = {};
    }
  }

  /// Updates the [users] according to the [query].
  ///
  /// [User]s are displayed in the following order:
  /// - [selectedUsers] obtained from global search;
  /// - [stored] [User]s obtained from paginated [Chat]-dialogs;
  /// - other [User]s obtained from global search.
  void _populateUsers() {
    if (categories.contains(SearchCategory.user) &&
        _chatService.hasNext.isFalse) {
      final Iterable<RxChat> storedChats = _chatService.chats.values;
      final Iterable<RxUser> searched = usersSearch.value?.items.values ?? [];

      // Predicates to filter non-hidden [Chat]-dialogs.
      bool remoteDialog(RxChat c) => c.chat.value.isDialog && !c.id.isLocal;
      bool hidden(RxChat c) => c.chat.value.isHidden;

      // Predicates to filter [User]s by.
      bool matchesQuery(RxUser user) => _matchesQuery(user: user);
      bool isMember(RxUser u) => chat?.members.items.containsKey(u.id) ?? false;
      bool inRecent(RxUser u) => recent.containsKey(u.id);
      bool inContacts(RxUser u) => contacts.containsKey(u.id);
      bool inChats(RxUser u) => chats.values.any(
        (c) => c.chat.value.isDialog && c.members.items.containsKey(u.id),
      );
      bool hasRemoteDialog(RxUser u) => !u.user.value.dialog.isLocal;

      RxUser? toUser(RxChat c) =>
          c.members.values.firstWhereOrNull((u) => u.user.id != me)?.user;
      RxChat? toChat(RxUser u) => u.dialog.value;

      // [Chat]s-dialogs with [User]s found in the global search and not
      // presented in [chats].
      final Iterable<RxChat> globalDialogs = searched
          .where(hasRemoteDialog)
          .whereNot(inChats)
          .map(toChat)
          .nonNulls
          .whereNot(hidden);

      if (globalDialogs.isNotEmpty &&
          categories.contains(SearchCategory.chat)) {
        final List<RxChat> sorted = [
          ...chats.values,
          ...globalDialogs,
        ].sorted();

        final RxChat? monolog = chats[_chatService.monolog];

        // Display users found globally in [chats] as [_matchesQuery] cannot
        // filter by [ChatDirectLink] and [UserLogin].
        chats.value = {
          if (monolog != null) _chatService.monolog: monolog,
          for (final c in sorted) c.chat.value.id: c,
        };
      }

      final Iterable<RxUser> stored = storedChats
          .where(remoteDialog)
          .whereNot(hidden)
          .sorted()
          .map(toUser)
          .nonNulls
          .where(matchesQuery);

      final Iterable<RxUser> selectedGlobals = selectedUsers
          .where(matchesQuery)
          .whereNot(stored.contains);

      final allUsers = {...selectedGlobals, ...stored, ...searched}
        ..removeWhere((u) => u.id == me);

      final List<RxUser> filtered = allUsers
          .whereNot(isMember)
          .whereNot(inRecent)
          .whereNot(inContacts)
          .whereNot(inChats)
          .toList();

      users.value = {for (final RxUser u in filtered) u.id: u};
    } else {
      users.value = {};
    }
  }

  /// Updates the [_scrollPosition] according to the [scrollController].
  void _updateScrollPosition() {
    if (scrollController.hasClients) {
      _scrollPosition.value = scrollController.position.pixels;
    }
  }

  /// Invokes [_nextContacts] and [_nextUsers] for fetching the next page.
  Future<void> _next() async {
    // Fetch all the [chats] first to prevent them from appearing in other
    // [SearchCategory]s.
    if (_chatService.hasNext.isTrue) {
      if (_chatService.nextLoading.isFalse) {
        searchStatus.value = RxStatus.loadingMore();

        await _chatService.next();
        await Future.delayed(16.milliseconds);

        // Populate [chats] first until there's no more [Chat]s to fetch from
        // [ChatService.paginated], then it is safe to populate other
        // [SearchCategory]s.
        if (_chatService.hasNext.isTrue) {
          _populateChats();
        } else {
          populate();
        }

        if (!hasNext) {
          searchStatus.value = RxStatus.success();
        }
      }
    } else if (query.value.length > 1) {
      await _nextContacts();
      await _nextUsers();
    }
  }

  /// Fetches the next [contactsSearch] page.
  Future<void> _nextContacts() async {
    if (categories.contains(SearchCategory.contact) &&
        contactsSearch.value?.hasNext.value == true &&
        contactsSearch.value?.nextLoading.value == false) {
      await contactsSearch.value!.next();
    }
  }

  /// Fetches the next [usersSearch] page.
  Future<void> _nextUsers() async {
    if ((contactsSearch.value == null ||
            contactsSearch.value!.hasNext.isFalse) &&
        categories.contains(SearchCategory.user)) {
      if (usersSearch.value == null) {
        _searchUsers(query.value);
      } else if (usersSearch.value!.hasNext.isTrue &&
          usersSearch.value!.nextLoading.isFalse) {
        await usersSearch.value!.next();
      }
    }
  }

  /// Ensures the [scrollController] is scrollable.
  Future<void> _ensureScrollable() async {
    if (hasNext) {
      await Future.delayed(1.milliseconds, () async {
        if (isClosed) {
          return;
        }

        // If the fetched initial page contains less elements than required to
        // fill the view and there's more pages available, then fetch those
        // pages.
        if (!scrollController.hasClients ||
            scrollController.position.maxScrollExtent < 50) {
          await _next();

          if (_connected) {
            Future.delayed(2.seconds, _ensureScrollable);
          }
        } else {
          // Ensure all animations are finished as [scrollController.hasClients]
          // may be `true` during an animation.
          _ensureScrollableTimer?.cancel();
          _ensureScrollableTimer = Timer(2.seconds, () async {
            if (!scrollController.hasClients ||
                scrollController.position.maxScrollExtent < 50) {
              await _next();
              Future.delayed(1.seconds, _ensureScrollable);
            }
          });
        }
      });
    }
  }

  /// Predicate to check whether the [user] or [title] corresponding to the
  /// [Chat], [User] or [ChatContact] being filtered matches the [query].
  ///
  /// Note that any entity with non-`null` [user] or [title] matches the empty
  /// [query].
  bool _matchesQuery({RxUser? user, String? title}) {
    if (user != null || title != null) {
      // Formatted string representation of the current [query].
      final String queryString = query.value.toLowerCase().trim();

      if (queryString.isNotEmpty) {
        String? num;
        String? name;
        String? contactName;
        // TODO: Add [UserLogin] searching.

        if (user != null) {
          num = user.user.value.num.val;
          name = user.user.value.name?.val;

          // [user] might be a contact with a custom [UserName].
          contactName =
              user.user.value.contacts.firstOrNull?.name.val ??
              user.contact.value?.contact.value.name.val;
        }

        for (final param in [title, name, contactName].nonNulls) {
          if (param.toLowerCase().contains(queryString)) {
            return true;
          }
        }

        // Account possible spaces in [UserNum].
        if (num?.contains(queryString.split(' ').join()) ?? false) {
          return true;
        }

        return false;
      } else {
        // Every non-`null` item matches the empty [query].
        return true;
      }
    } else {
      // If neither [user] nor [title] is specified, this item doesn't match.
      return false;
    }
  }
}

/// Combined [List]s of [RxChat]s, [RxUser]s, [RxChatContact]s and recent
/// [RxUser]s.
class SearchViewResults {
  const SearchViewResults(this.chats, this.users, this.contacts, this.recent);

  /// [RxChat]s themselves.
  final List<RxChat> chats;

  /// [RxUser]s themselves.
  final List<RxUser> users;

  /// [RxChatContact]s themselves.
  final List<RxChatContact> contacts;

  /// Recent [RxUser] themselves.
  final List<RxUser> recent;

  /// Indicates whether [chats], [users], [contacts] and [recent] are empty.
  bool get isEmpty =>
      chats.isEmpty && users.isEmpty && contacts.isEmpty && recent.isEmpty;
}
