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

import 'package:collection/collection.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/search.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/ui/widget/text_field.dart';

export 'view.dart';

/// Category to search through.
enum SearchCategory {
  /// Recent (up to 3) [Chat]-dialogs.
  recent,

  /// [ChatContact]s of the authenticated [MyUser].
  contact,

  /// Global [User]s.
  user,

  /// [Chat]s of the authenticated [MyUser].
  chat,
}

/// Controller for searching the provided [categories].
class SearchController extends GetxController {
  SearchController(
    this._chatService,
    this._userService,
    this._contactService, {
    required this.categories,
    this.chat,
    this.onSelected,
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
  final Rx<SearchResult<UserId, RxUser>?> usersSearch = Rx(null);

  /// [ChatContact]s search results.
  final Rx<SearchResult<ChatContactId, RxChatContact>?> contactsSearch =
      Rx(null);

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
  final List<SearchCategory> categories;

  /// Reactive value of the [search] field passed to the [_search] method.
  final RxString query = RxString('');

  /// Callback, called on the [selectedContacts], [selectedChats],
  /// [selectedUsers] and [selectedRecent] changes.
  final void Function(SearchViewResults? results)? onSelected;

  /// Worker to react on the [usersSearch] status changes.
  Worker? _usersSearchWorker;

  /// Worker to react on the [contactsSearch] status changes.
  Worker? _contactsSearchWorker;

  /// Worker to react on [query] changes.
  Worker? _searchWorker;

  /// Worker performing a [_search] on [query] changes with debounce.
  Worker? _searchDebounce;

  /// [Timer] invoking the [_ensureScrollable].
  Timer? _ensureScrollableTimer;

  /// [Chat]s service searching the [Chat]s.
  final ChatService _chatService;

  /// [User]s service searching the [User]s.
  final UserService _userService;

  /// [ChatContact]s service searching the [ChatContact]s.
  final ContactService _contactService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// Indicates whether the [usersSearch] or [contactsSearch] have
  /// next page.
  RxBool get hasNext => query.value.length < 2
      ? categories.contains(SearchCategory.chat)
          ? _chatService.hasNext
          : RxBool(false)
      : usersSearch.value?.hasNext ??
          contactsSearch.value?.hasNext ??
          RxBool(false);

  @override
  void onInit() {
    scrollController.addListener(_scrollListener);

    search = TextFieldState(onChanged: (d) => query.value = d.text);
    _searchDebounce = debounce(query, _search);
    _searchWorker = ever(query, (String q) {
      if (q.length < 2) {
        usersSearch.value?.dispose();
        usersSearch.value = null;
        contactsSearch.value?.dispose();
        contactsSearch.value = null;
        searchStatus.value = RxStatus.empty();
        users.clear();
        contacts.clear();
        chats.clear();
        recent.clear();
      } else {
        searchStatus.value = RxStatus.loading();
      }

      populate();
    });

    populate();

    super.onInit();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    usersSearch.value?.dispose();
    contactsSearch.value?.dispose();
    _searchDebounce?.dispose();
    _searchWorker?.dispose();
    _usersSearchWorker?.dispose();
    _usersSearchWorker = null;
    _ensureScrollableTimer?.cancel();
    _contactsSearchWorker?.dispose();
    _contactsSearchWorker = null;
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
  /// Returned item is either a [RxUser] or [RxChatContact].
  dynamic getIndex(int i) {
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
  }

  /// Searches the [User]s based on the provided [query].
  ///
  /// Query may be a [UserNum], [UserName] or [UserLogin].
  Future<void> _search(String query) async {
    if (contactsSearch.value != null) {
      contactsSearch.value?.dispose();
      contactsSearch.value = null;
      _populateContacts();
    }

    if (usersSearch.value != null) {
      usersSearch.value?.dispose();
      usersSearch.value = null;
      _populateUsers();
    }

    // TODO: Add `Chat`s and `ChatItem`s searching.
    if (categories.contains(SearchCategory.contact)) {
      _searchContacts(query);
    } else if (categories.contains(SearchCategory.user)) {
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
      UserName? name;
      UserEmail? email;
      UserPhone? phone;

      try {
        name = UserName(query);
      } catch (e) {
        // No-op.
      }

      try {
        email = UserEmail(query);
      } catch (e) {
        // No-op.
      }

      try {
        phone = UserPhone(query);
      } catch (e) {
        // No-op.
      }

      if (name != null || email != null || phone != null) {
        searchStatus.value = searchStatus.value.isSuccess
            ? RxStatus.loadingMore()
            : RxStatus.loading();

        final SearchResult<ChatContactId, RxChatContact> result =
            _contactService.search(name: name, email: email, phone: phone);

        contactsSearch.value?.dispose();
        contactsSearch.value = result;
        searchStatus.value = result.status.value;

        _contactsSearchWorker = ever(result.status, (RxStatus s) {
          if (contactsSearch.value?.items.isNotEmpty == true ||
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
        searchStatus.value = RxStatus.empty();
        contactsSearch.value?.dispose();
        contactsSearch.value = null;
      }
    } else {
      searchStatus.value = RxStatus.empty();
      contactsSearch.value?.dispose();
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
      UserNum? num;
      UserName? name;
      UserLogin? login;
      ChatDirectLinkSlug? link;

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

      try {
        link = ChatDirectLinkSlug(query);
      } catch (e) {
        // No-op.
      }

      if (num != null || name != null || login != null || link != null) {
        searchStatus.value = searchStatus.value.isSuccess
            ? RxStatus.loadingMore()
            : RxStatus.loading();
        final SearchResult<UserId, RxUser> result =
            _userService.search(num: num, name: name, login: login, link: link);

        usersSearch.value?.dispose();
        usersSearch.value = result;
        searchStatus.value = result.status.value;

        _usersSearchWorker = ever(result.status, (RxStatus s) {
          searchStatus.value = s;

          if (s.isSuccess && !s.isLoadingMore) {
            _populateUsers();
            _ensureScrollable();
          }
        });

        _populateUsers();
      } else {
        searchStatus.value = RxStatus.empty();
        usersSearch.value?.dispose();
        usersSearch.value = null;
      }
    } else {
      searchStatus.value = RxStatus.empty();
      usersSearch.value?.dispose();
      usersSearch.value = null;
    }
  }

  /// Updates the [chats] according to the [query].
  void _populateChats() {
    if (categories.contains(SearchCategory.chat)) {
      final List<RxChat> sorted = _chatService.paginated.values.toList();

      sorted.sort();

      chats.value = {
        for (var c in sorted.where((p) {
          if (p.id.isLocal && !p.id.isLocalWith(me) || p.chat.value.isHidden) {
            return false;
          }

          if (query.value.isNotEmpty) {
            return p.title.toLowerCase().contains(query.value.toLowerCase());
          }

          return true;
        }))
          c.chat.value.id: c,
      };
    }
  }

  /// Updates the [recent] according to the [query].
  void _populateRecent() {
    if (categories.contains(SearchCategory.recent)) {
      recent.value = {
        for (var u in _chatService.chats.values
            .map((e) {
              if (e.chat.value.isDialog && !e.chat.value.id.isLocal) {
                RxUser? user = e.members.values
                    .firstWhereOrNull((u) => u.user.value.id != me);

                if (user != null &&
                    chat?.members.containsKey(user.id) != true) {
                  if (query.value.isNotEmpty) {
                    if (user.user.value.name?.val.contains(query.value) ==
                        true) {
                      return user;
                    }
                  } else {
                    return user;
                  }
                }
              }

              return null;
            })
            .whereNotNull()
            .take(3))
          u.id: u,
      };
    }
  }

  /// Updates the [contacts] according to the [query].
  void _populateContacts() {
    if (categories.contains(SearchCategory.contact) &&
        contactsSearch.value?.items.isNotEmpty == true) {
      Map<UserId, RxChatContact> allContacts = {
        for (var u in contactsSearch.value!.items.values.where((e) {
          if (e.user.value != null &&
              chat?.members.containsKey(e.id) != true &&
              !recent.containsKey(e.id) &&
              chats.values.none((c) =>
                  c.chat.value.isDialog && c.members.containsKey(e.id))) {
            return true;
          }

          return false;
        }))
          u.user.value!.id: u,
      };

      contacts.value = {
        for (var u in selectedContacts.where((e) {
          if (!recent.containsKey(e.id) &&
              !allContacts.containsKey(e.user.value!.id)) {
            if (query.value.isNotEmpty) {
              if (e.contact.value.name.val
                      .toLowerCase()
                      .contains(query.value.toLowerCase()) ==
                  true) {
                return true;
              }
            } else {
              return true;
            }
          }

          return false;
        }))
          u.user.value!.id: u,
        ...allContacts,
      };
    } else {
      contacts.value = {};
    }
  }

  /// Updates the [users] according to the [query].
  void _populateUsers() {
    if (categories.contains(SearchCategory.user) &&
        usersSearch.value?.items.isNotEmpty == true &&
        (!categories.contains(SearchCategory.contact) ||
            contactsSearch.value?.hasNext.value == false)) {
      Map<UserId, RxUser> allUsers = {
        for (var u in usersSearch.value!.items.values.where((e) {
          if (chat?.members.containsKey(e.id) != true &&
              !recent.containsKey(e.id) &&
              !contacts.containsKey(e.id) &&
              chats.values.none((c) =>
                  c.chat.value.isDialog && c.members.containsKey(e.id))) {
            return true;
          }

          return false;
        }))
          u.id: u,
      };

      users.value = {
        for (var u in selectedUsers.where((e) {
          if (!recent.containsKey(e.id) && !allUsers.containsKey(e.id)) {
            if (query.value.isNotEmpty) {
              if (e.user.value.name?.val
                      .toLowerCase()
                      .contains(query.value.toLowerCase()) ==
                  true) {
                return true;
              }
            } else {
              return true;
            }
          }

          return false;
        }))
          u.id: u,
        ...allUsers,
      };
    } else {
      users.value = {};
    }
  }

  /// Invokes the [_next], fetching the next page, based on the
  /// [scrollController].
  Future<void> _scrollListener() async {
    if (scrollController.hasClients &&
        scrollController.position.pixels >
            scrollController.position.maxScrollExtent - 500) {
      await _next();
    }
  }

  /// Invokes [_nextContacts] and [_nextUsers] for fetching the next page.
  Future<void> _next() async {
    if (query.value.length < 2) {
      if (_chatService.hasNext.isTrue && _chatService.nextLoading.isFalse) {
        searchStatus.value = RxStatus.loadingMore();

        await _chatService.next();
        await Future.delayed(1.milliseconds);
        _populateChats();

        searchStatus.value = RxStatus.success();
      }
    } else {
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

  /// Fetches the next [contactsSearch] page.
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
    if ((categories.contains(SearchCategory.contact) &&
            contactsSearch.value?.hasNext.value != false) ||
        (categories.contains(SearchCategory.user) &&
            usersSearch.value?.hasNext.value != false)) {
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
          _ensureScrollable();
        } else {
          // Ensure all animations are finished as [scrollController.hasClients]
          // may be `true` during an animation.
          Timer(1.seconds, _ensureScrollable);
        }
      });
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
