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
import '/ui/widget/text_field.dart';

export 'view.dart';

/// Type of searching.
enum Search {
  /// Recent users.
  recent,

  /// Contacts.
  contacts,

  /// Global users.
  users,
}

/// Controller of the users search.
class SearchController extends GetxController {
  SearchController(
    this._chatService,
    this._userService,
    this._contactService, {
    required this.searchTypes,
    this.chat,
  });

  /// ID of the [Chat] this controller is bound to.
  final Rx<RxChat?>? chat;

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);

  /// Reactive list of the selected [User]s.
  final RxList<RxUser> selectedUsers = RxList<RxUser>([]);

  /// [User]s search results.
  final Rx<RxList<RxUser>?> searchResults = Rx(null);

  /// Status of an [_search] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [_search] is executing.
  /// - `status.isLoading`, meaning [_search] is executing.
  /// - `status.isLoadingMore`, meaning some [searchResults] is exist and
  /// [_search] is executing.
  /// - `status.isSuccess`, meaning the [_search] was successfully executed.
  /// - `status.isError`, meaning the [_search] got an error.
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  /// Reactive map of recent [User]s passed [query].
  final RxMap<UserId, RxUser> recent = RxMap();

  /// Reactive map of [ChatContact]s passed [query].
  final RxMap<UserId, RxChatContact> contacts = RxMap();

  /// Reactive map of [User]s passed [query].
  final RxMap<UserId, RxUser> users = RxMap();

  /// [FlutterListViewController] of a search results.
  final FlutterListViewController controller = FlutterListViewController();

  /// [TextFieldState] of the search field.
  late final TextFieldState search;

  /// [Search] types this controller doing.
  final List<Search> searchTypes;

  /// Reactive value of the [search] field.
  final RxnString query = RxnString();

  /// Selected [Search] type results.
  final Rx<Search> selectedSearch = Rx(Search.recent);

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchStatusWorker;

  /// Worker to react on [query] changes.
  Worker? _searchWorker;

  /// Worker performing a [_fetchChat] on [chatId] changes.
  Worker? _chatIdWorker;

  /// Worker performing a [_search] on [query] changes with debounce.
  Worker? _searchDebounce;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Users service used to search [Users]s.
  final UserService _userService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    assert(searchTypes.isNotEmpty);

    populate();

    _searchDebounce = debounce(
      query,
      (String? q) {
        if (q != null) {
          _search(q);
        }
      },
    );

    _searchWorker = ever(query, (String? q) {
      if (q == null || q.isEmpty) {
        searchResults.value = null;
        searchStatus.value = RxStatus.empty();
        populate();
      } else {
        searchStatus.value = RxStatus.loading();
        populate();
      }
    });

    search = TextFieldState(
      onChanged: (d) {
        query.value = d.text;
      },
    );

    controller.sliverController.onPaintItemPositionsCallback = (d, list) {
      int? first = list.firstOrNull?.index;
      if (first != null) {
        if (first >= recent.length + contacts.length) {
          selectedSearch.value = Search.users;
        } else if (first >= recent.length) {
          selectedSearch.value = Search.contacts;
        } else {
          selectedSearch.value = Search.recent;
        }
      }
    };

    super.onInit();
  }

  @override
  void onClose() {
    _searchDebounce?.dispose();
    _searchWorker?.dispose();
    _chatIdWorker?.dispose();
    _searchStatusWorker?.dispose();
    _searchStatusWorker = null;
    super.onClose();
  }

  /// Returns combined array of [UserId]s from [selectedUsers] and
  /// [selectedContacts].
  List<UserId> selected() {
    return [
      ...selectedContacts.expand((e) => e.contact.value.users.map((u) => u.id)),
      ...selectedUsers.map((u) => u.id),
    ].toList();
  }

  /// Selects or unselects the specified [contact].
  void selectContact(RxChatContact contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
  }

  /// Selects or unselects the specified [user].
  void selectUser(RxUser user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
  }

  /// Performs searching for [User]s based on the provided [query].
  ///
  /// Query may be a [UserNum], [UserName] or [UserLogin].
  Future<void> _search(String query) async {
    if (!searchTypes.contains(Search.users)) {
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

        searchStatus.value = RxStatus.success();
      }
    } else {
      searchStatus.value = RxStatus.empty();
      searchResults.value = null;
    }
  }

  /// Jumps to the provided [part] of the search results.
  void jumpTo(Search part) {
    if (controller.hasClients) {
      if (part == Search.recent && recent.isNotEmpty) {
        controller.jumpTo(0);
      } else if (part == Search.contacts && contacts.isNotEmpty) {
        double to = recent.length * (84 + 10);
        if (to > controller.position.maxScrollExtent) {
          controller.jumpTo(controller.position.maxScrollExtent);
        } else {
          controller.jumpTo(to);
        }
      } else if (part == Search.users && users.isNotEmpty) {
        double to = (recent.length + contacts.length) * (84 + 10);
        if (to > controller.position.maxScrollExtent) {
          controller.jumpTo(controller.position.maxScrollExtent);
        } else {
          controller.jumpTo(to);
        }
      }
    }
  }

  /// Gets [RxUser] or [RxChatContact] from combined array from [recent],
  /// [contacts] and [users].
  dynamic getIndex(int i) {
    return [...recent.values, ...contacts.values, ...users.values].elementAt(i);
  }

  /// Sets [recent], [contacts] and [users] according to [query].
  void populate() {
    if (searchTypes.contains(Search.recent)) {
      recent.value = {
        for (var u in _chatService.chats.values
            .map((e) {
              if (e.chat.value.isDialog) {
                RxUser? user = e.members.values
                    .firstWhereOrNull((u) => u.user.value.id != me);

                if (user != null &&
                    chat?.value?.members.containsKey(user.id) != true) {
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

    if (searchTypes.contains(Search.contacts)) {
      Map<UserId, RxChatContact> allContacts = {
        for (var u in _contactService.contacts.values.where((e) {
          if (e.contact.value.users.length == 1) {
            RxUser? user = e.user.value;

            if (chat?.value?.members.containsKey(user?.id) != true &&
                !recent.containsKey(user?.id)) {
              if (query.value != null) {
                if (e.contact.value.name.val.contains(query.value!) == true) {
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
              if (e.contact.value.name.val.contains(query.value!) == true) {
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

    if (searchTypes.contains(Search.users)) {
      if (searchResults.value?.isNotEmpty == true) {
        Map<UserId, RxUser> allUsers = {
          for (var u in searchResults.value!.where((e) {
            if (chat?.value?.members.containsKey(e.id) != true &&
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
              if (e.user.value.name?.val.contains(query.value!) == true) {
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

              if (chat?.value?.members.containsKey(user?.id) != true &&
                  !recent.containsKey(user?.id) &&
                  !contacts.containsKey(user?.id)) {
                if (query.value != null) {
                  if (user?.user.value.name?.val.contains(query.value!) ==
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
                if (e.user.value.name?.val.contains(query.value!) == true) {
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
}
