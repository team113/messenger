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
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';

import '/domain/model/user.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/repository/contact.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';

export 'view.dart';

enum SearchFlowStage { group }

/// Controller of the chat member addition modal.
class SearchController extends GetxController {
  SearchController(
    this.pop,
    this._chatService,
    this._userService,
    this._contactService,
  );

  final Rx<RxUser?> hoveredUser = Rx(null);

  /// Pops the [ParticipantsView] this controller is bound to.
  final Function() pop;

  final Rx<SearchFlowStage?> stage = Rx(null);

  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// [User]s search results.
  final Rx<RxList<RxUser>?> searchResults = Rx(null);
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  late final TextFieldState search;

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchStatusWorker;

  Worker? _searchWorker;
  Worker? _searchDebounce;

  final RxnString query = RxnString();

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  final UserService _userService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop.
  late final Worker _stateWorker;

  UserId? get me => _chatService.me;

  @override
  void onInit() {
    _searchDebounce = debounce(query, (String? v) {
      if (v != null) {
        _search(v);
      }
    });

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
        if (first >= chats.length + contacts.length) {
          selected.value = 2;
        } else if (first >= chats.length) {
          selected.value = 1;
        } else {
          selected.value = 0;
        }
      }
    };

    super.onInit();
  }

  @override
  void onReady() {
    populate();
    super.onReady();
  }

  @override
  void onClose() {
    _stateWorker.dispose();
    _searchDebounce?.dispose();
    _searchWorker?.dispose();
    _searchStatusWorker?.dispose();
    _searchStatusWorker = null;
    super.onClose();
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

  final RxInt selected = RxInt(0);
  final FlutterListViewController controller = FlutterListViewController();

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
        router.chat(dialog.id, push: true);
      }
    }
  }

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

  final RxMap<ChatId, RxChat> chats = RxMap();
  final RxMap<UserId, RxChatContact> contacts = RxMap();
  final RxMap<UserId, RxUser> users = RxMap();

  RxMap<dynamic, dynamic> getMap(int i) {
    if (i >= chats.length + contacts.length) {
      return chats;
    } else if (i >= chats.length) {
      return contacts;
    }

    return users;
  }

  dynamic getIndex(int i) {
    return [...chats.values, ...contacts.values, ...users.values].elementAt(i);
  }

  void populate() {
    chats.value = {
      for (var u in _chatService.chats.values.where((e) {
        if (!e.chat.value.isDialog) {
          if (query.value != null) {
            if (e.title.value.contains(query.value!) == true) {
              return true;
            }
          } else {
            return true;
          }
        }

        return false;
      }))
        u.chat.value.id: u,
      // for (var u in _chatService.chats.values
      //     .map((e) {
      //       if (e.chat.value.isDialog) {
      //         RxUser? user = e.members.values
      //             .firstWhereOrNull((u) => u.user.value.id != me);

      //         if (query.value != null) {
      //           if (user?.user.value.name?.val.contains(query.value!) == true) {
      //             return user;
      //           }
      //         } else {
      //           return user;
      //         }
      //       }

      //       return null;
      //     })
      //     .whereNotNull()
      //     .take(3))
      //   u.id: u,
    };

    contacts.value = {
      for (var u in _contactService.contacts.values.where((e) {
        if (e.contact.value.users.length == 1) {
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
    };

    if (searchResults.value?.isNotEmpty == true) {
      users.value = {
        for (var u in searchResults.value!.where((e) {
          if (!contacts.containsKey(e.id)) {
            return true;
          }

          return false;
        }))
          u.id: u,
      };
    } else {
      users.value = {
        for (var u in _chatService.chats.values.map((e) {
          if (e.chat.value.isDialog) {
            RxUser? user =
                e.members.values.firstWhereOrNull((u) => u.user.value.id != me);

            if (!contacts.containsKey(user?.id)) {
              if (query.value != null) {
                if (user?.user.value.name?.val.contains(query.value!) == true) {
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
    }

    print(
      '_populate, recent: ${chats.length}, contact: ${contacts.length}, user: ${users.length}',
    );
  }
}
