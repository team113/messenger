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

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/ui/page/call/search/view.dart';
import '/ui/widget/text_field.dart';

export 'view.dart';

/// Category to search through.
enum SearchCategory {
  /// Recent (up to 3) [Chat]-dialogs.
  recent,

  /// [ChatContact]s of the authenticated [MyUser].
  contacts,

  /// Global [User]s.
  users,

  /// [Chat]s of the authenticated [MyUser].
  chats,
}

/// Controller for searching the provided [categories].
class SearchController extends GetxController {
  SearchController(
    this._chatService,
    this._userService,
    this._contactService, {
    required this.categories,
    this.chat,
    this.onChanged,
    this.onResultsUpdated,
    Rx<RxStatus>? search,
  })  : searchStatus = search ?? Rx<RxStatus>(RxStatus.empty()),
        assert(categories.isNotEmpty);

  /// [RxChat] this controller is bound to, if any.
  ///
  /// If specified, then the [RxChat.members] of this [chat] will be omitted
  /// from the [searchResults].
  final RxChat? chat;

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);

  /// Reactive list of the selected [User]s.
  final RxList<RxUser> selectedUsers = RxList<RxUser>([]);

  /// Reactive list of the selected [Chat]s.
  final RxList<RxChat> selectedChats = RxList<RxChat>([]);

  /// [User]s search results.
  final Rx<RxList<RxUser>?> searchResults = Rx(null);

  /// Status of a [_search] completion.
  ///
  /// May be:
  /// - `searchStatus.empty`, meaning no search.
  /// - `searchStatus.loading`, meaning search is in progress.
  /// - `searchStatus.loadingMore`, meaning search is in progress after some
  ///   [searchResults] were already acquired.
  /// - `searchStatus.success`, meaning search is done and [searchResults] are
  ///   acquired.
  late final Rx<RxStatus> searchStatus;

  /// [RxUser]s found under the [SearchCategory.recent] category.
  final RxMap<UserId, RxUser> recent = RxMap();

  /// [RxChatContact]s found under the [SearchCategory.contacts] category.
  final RxMap<UserId, RxChatContact> contacts = RxMap();

  /// [RxUser]s found under the [SearchCategory.users] category.
  final RxMap<UserId, RxUser> users = RxMap();

  /// [Chat]s found under the [SearchCategory.chats] category.
  final RxMap<ChatId, RxChat> chats = RxMap();

  /// [FlutterListViewController] of a [FlutterListView] displaying the search
  /// results.
  ///
  /// Used to determine the current [category].
  final FlutterListViewController controller = FlutterListViewController();

  /// [TextFieldState] of the search field.
  late final TextFieldState search;

  /// [SearchCategory]ies to search through.
  final List<SearchCategory> categories;

  /// Reactive value of the [search] field passed to the [_search] method.
  final RxnString query = RxnString();

  /// Selected [SearchCategory].
  final Rx<SearchCategory> category = Rx(SearchCategory.recent);

  /// Callback, called when the selected items was changed.
  final void Function(SearchViewResults results)? onChanged;

  /// Callback, called when the selected items was changed.
  final void Function(SearchViewResults result, String query)? onResultsUpdated;

  /// Reactive list of the sorted [Chat]s.
  late final RxList<RxChat> _sortedChats;

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchStatusWorker;

  /// Worker to react on [query] changes.
  Worker? _searchWorker;

  /// Worker performing a [_search] on [query] changes with debounce.
  Worker? _searchDebounce;

  /// [Chat]s service searching the [Chat]s.
  final ChatService _chatService;

  /// [User]s service searching the [User]s.
  final UserService _userService;

  /// [ChatContact]s service searching the [ChatContact]s.
  final ContactService _contactService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    _sortedChats = RxList<RxChat>(_chatService.chats.values.toList());
    _sortChats();
    search = TextFieldState(onChanged: (d) => query.value = d.text);
    _searchDebounce = debounce(query, _search);
    _searchWorker = ever(query, (String? q) {
      if (q == null || q.isEmpty) {
        searchResults.value = null;
        searchStatus.value = RxStatus.empty();
      } else {
        searchStatus.value = RxStatus.loading();
      }

      populate();
    });

    controller.sliverController.onPaintItemPositionsCallback = (d, list) {
      int? first = list.firstOrNull?.index;
      if (first != null) {
        if (first >= recent.length + contacts.length + chats.length) {
          category.value = SearchCategory.users;
        } else if (first >= recent.length + chats.length) {
          category.value = SearchCategory.contacts;
        } else if (first >= chats.length) {
          category.value = SearchCategory.recent;
        } else {
          category.value = SearchCategory.chats;
        }
      }
    };

    populate();

    super.onInit();
  }

  @override
  void onReady() {
    StreamGroup.mergeBroadcast(
            [chats.stream, recent.stream, contacts.stream, users.stream])
        .listen((event) {
      onResultsUpdated?.call(
        SearchViewResults(
          chats.values.map((e) => e).toList(),
          users.values.map((e) => e).toList(),
          contacts.values.map((e) => e).toList(),
        ),
        search.text,
      );
    });
    super.onReady();
  }

  @override
  void onClose() {
    _searchDebounce?.dispose();
    _searchWorker?.dispose();
    _searchStatusWorker?.dispose();
    _searchStatusWorker = null;
    super.onClose();
  }

  /// Returns all the selected [UserId]s.
  List<UserId> selected() {
    return {
      ...selectedContacts.expand((e) => e.contact.value.users.map((u) => u.id)),
      ...selectedUsers.map((u) => u.id),
    }.toList();
  }

  /// Selects or unselects the specified [contact].
  void selectContact(RxChatContact contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
    onChangedCall();
  }

  /// Selects or unselects the specified [user].
  void selectUser(RxUser user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
    onChangedCall();
  }

  /// Selects or unselects the specified [chat].
  void selectChat(RxChat chat) {
    if (selectedChats.contains(chat)) {
      selectedChats.remove(chat);
    } else {
      selectedChats.add(chat);
    }
    onChangedCall();
  }

  /// Calls [onChanged] callback.
  void onChangedCall() => onChanged?.call(
        SearchViewResults(
          selectedChats,
          selectedUsers,
          selectedContacts,
        ),
      );

  /// Searches the [User]s based on the provided [query].
  ///
  /// Query may be a [UserNum], [UserName] or [UserLogin].
  Future<void> _search(String? query) async {
    if (!categories.contains(SearchCategory.users) || query == null) {
      return;
    }

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
          populate();
        });

        populate();
      } else {
        searchStatus.value = RxStatus.empty();
        searchResults.value = null;
      }
    } else {
      searchStatus.value = RxStatus.empty();
      searchResults.value = null;
    }
  }

  /// Jumps the [controller] to the provided [category] of the search results.
  void jumpTo(SearchCategory category) {
    if (controller.hasClients) {
      switch (category) {
        case SearchCategory.chats:
          if (chats.isNotEmpty) {
            controller.jumpTo(0);
          }
          break;
        case SearchCategory.recent:
          if (recent.isNotEmpty) {
            double to = chats.length * (76 + 10);
            if (to > controller.position.maxScrollExtent) {
              controller.jumpTo(controller.position.maxScrollExtent);
            } else {
              controller.jumpTo(to);
            }
          }
          break;
        case SearchCategory.contacts:
          if (contacts.isNotEmpty) {
            double to = (recent.length + chats.length) * (76 + 10);
            if (to > controller.position.maxScrollExtent) {
              controller.jumpTo(controller.position.maxScrollExtent);
            } else {
              controller.jumpTo(to);
            }
          }
          break;
        case SearchCategory.users:
          if (users.isNotEmpty) {
            double to =
                (recent.length + contacts.length + chats.length) * (76 + 10);
            if (to > controller.position.maxScrollExtent) {
              controller.jumpTo(controller.position.maxScrollExtent);
            } else {
              controller.jumpTo(to);
            }
          }
          break;
      }
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
      ...users.values
    ].elementAt(i);
  }

  /// Updates the [recent], [contacts] and [users] according to the [query].
  void populate() {
    if (categories.contains(SearchCategory.chats)) {
      chats.value = {
        for (var c in _sortedChats.where((p) {
          if (query.value != null) {
            if (p.title.toLowerCase().contains(query.value!.toLowerCase())) {
              return true;
            }
            return false;
          }

          return true;
        }))
          c.chat.value.id: c,
      };
    }

    if (categories.contains(SearchCategory.recent)) {
      recent.value = {
        for (var u in _chatService.chats.values
            .map((e) {
              if (e.chat.value.isDialog) {
                RxUser? user = e.members.values
                    .firstWhereOrNull((u) => u.user.value.id != me);

                if (user != null &&
                    chat?.members.containsKey(user.id) != true) {
                  if (query.value != null) {
                    if (user.user.value.name?.val.contains(query.value!) ==
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

    if (categories.contains(SearchCategory.contacts)) {
      Map<UserId, RxChatContact> allContacts = {
        for (var u in _contactService.contacts.values.where((e) {
          if (e.contact.value.users.length == 1) {
            RxUser? user = e.user.value;

            if (chat?.members.containsKey(user?.id) != true &&
                !recent.containsKey(user?.id)) {
              if (query.value != null) {
                if (e.contact.value.name.val
                        .toLowerCase()
                        .contains(query.value!.toLowerCase()) ==
                    true) {
                  return true;
                }
              } else {
                return true;
              }
            }
          }

          return false;
        }))
          u.user.value!.id: u,
      };

      contacts.value = {
        for (var u in selectedContacts.where((e) {
          if (!recent.containsKey(e.id) &&
              !allContacts.containsKey(e.user.value!.id)) {
            if (query.value != null) {
              if (e.contact.value.name.val
                      .toLowerCase()
                      .contains(query.value!.toLowerCase()) ==
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
    }

    if (categories.contains(SearchCategory.users)) {
      if (searchResults.value?.isNotEmpty == true) {
        Map<UserId, RxUser> allUsers = {
          for (var u in searchResults.value!.where((e) {
            if (chat?.members.containsKey(e.id) != true &&
                !recent.containsKey(e.id) &&
                !contacts.containsKey(e.id)) {
              return true;
            }

            return false;
          }))
            u.id: u,
        };

        users.value = {
          for (var u in selectedUsers.where((e) {
            if (!recent.containsKey(e.id) && !allUsers.containsKey(e.id)) {
              if (e.user.value.name?.val
                      .toLowerCase()
                      .contains(query.value!.toLowerCase()) ==
                  true) {
                return true;
              }
            }

            return false;
          }))
            u.id: u,
          ...allUsers,
        };
      } else {
        Map<UserId, RxUser> allUsers = {
          for (var u in _chatService.chats.values.map((e) {
            if (e.chat.value.isDialog) {
              RxUser? user = e.members.values
                  .firstWhereOrNull((u) => u.user.value.id != me);

              if (chat?.members.containsKey(user?.id) != true &&
                  !recent.containsKey(user?.id) &&
                  !contacts.containsKey(user?.id)) {
                if (query.value != null) {
                  if (user?.user.value.name?.val
                          .toLowerCase()
                          .contains(query.value!.toLowerCase()) ==
                      true) {
                    return user;
                  }
                } else {
                  return user;
                }
              }
            }

            return null;
          }).whereNotNull())
            u.id: u
        };

        users.value = {
          for (var u in selectedUsers.where((e) {
            if (!recent.containsKey(e.id) && !allUsers.containsKey(e.id)) {
              if (query.value != null) {
                if (e.user.value.name?.val
                        .toLowerCase()
                        .contains(query.value!.toLowerCase()) ==
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
      }
    }
  }

  /// Sorts the [_sortedChats] by the [Chat.updatedAt] and [Chat.currentCall] values.
  void _sortChats() {
    _sortedChats.sort((a, b) {
      if (a.chat.value.ongoingCall != null &&
          b.chat.value.ongoingCall == null) {
        return -1;
      } else if (a.chat.value.ongoingCall == null &&
          b.chat.value.ongoingCall != null) {
        return 1;
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });

    populate();
  }
}

/// Wrapped [SearchView] selected items.
class SearchViewResults {
  const SearchViewResults(this.chats, this.users, this.contacts);

  /// Selected [Chat]s.
  final List<RxChat> chats;

  /// Selected [User]s.
  final List<RxUser> users;

  /// Selected [ChatContact]s.
  final List<RxChatContact> contacts;

  /// Indicates whether [chats], [users] and [contacts] are empty or not.
  bool get isEmpty =>
      chats.isEmpty && users.isEmpty && contacts.isEmpty ? true : false;
}
