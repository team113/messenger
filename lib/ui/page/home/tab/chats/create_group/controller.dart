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
import 'package:messenger/ui/widget/text_field.dart';

import '/domain/model/user.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/repository/contact.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'controller.dart';

enum CreateGroupFlowStage { success }

/// Controller of the chat member addition modal.
class CreateGroupController extends GetxController {
  CreateGroupController(
    this._chatService,
    this._callService,
    this._userService,
    this._contactService,
  );

  final Rx<RxUser?> hoveredUser = Rx(null);

  final Rx<CreateGroupFlowStage?> stage = Rx(null);

  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);
  final RxList<RxChat> selectedChats = RxList();

  /// Reactive list of the selected [User]s.
  final RxList<RxUser> selectedUsers = RxList<RxUser>([]);

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

  /// Calls service used to transform current call into group call.
  final CallService _callService;

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

    populate();

    super.onInit();
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

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group with the current [Chat]-dialog members, [selectedContacts]
  /// and [selectedUsers].
  Future<void> addMembers({ChatName? groupName}) async {
    // status.value = RxStatus.loading();

    // try {
    //   List<UserId> ids = {
    //     ...selectedContacts
    //         .expand((e) => e.contact.value.users.map((u) => u.id)),
    //     ...selectedUsers.map((u) => u.id),
    //   }.toList();

    //   if (chat.value?.chat.value.isGroup != false) {
    //     List<Future> futures = ids
    //         .map((e) => _chatService.addChatMember(chatId.value, e))
    //         .toList();

    //     await Future.wait(futures);
    //   } else {
    //     await _callService.transformDialogCallIntoGroupCall(
    //       chatId.value,
    //       ids,
    //       groupName,
    //     );
    //   }

    //   status.value = RxStatus.success();
    //   stage.value = ParticipantsFlowStage.addedSuccess;
    // } on AddChatMemberException catch (e) {
    //   MessagePopup.error(e);
    // } on TransformDialogCallIntoGroupCallException catch (e) {
    //   MessagePopup.error(e);
    // } catch (e) {
    //   MessagePopup.error(e);
    //   rethrow;
    // } finally {
    //   status.value = RxStatus.empty();
    // }
  }

  /// Selects or unselects the specified [contact].
  void selectContact(RxChatContact contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
  }

  void selectUser(RxUser user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    } else {
      selectedUsers.add(user);
    }
  }

  void selectChat(RxChat chat) {
    if (selectedChats.contains(chat)) {
      selectedChats.remove(chat);
    } else {
      selectedChats.add(chat);
    }
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
    Map allChats = {
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
    };

    chats.value = {
      for (var u in selectedChats.where((e) {
        if (!allChats.containsKey(e.chat.value.id)) {
          if (query.value != null) {
            if (e.title.contains(query.value!) == true) {
              return true;
            }
          } else {
            return true;
          }
        }

        return false;
      }))
        u.chat.value.id: u,
      ...allChats,
    };

    Map allContacts = {
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

    contacts.value = {
      for (var u in selectedContacts.where((e) {
        if (!allContacts.containsKey(e.user.value!.id)) {
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

    if (searchResults.value?.isNotEmpty == true) {
      Map allUsers = {
        for (var u in searchResults.value!.where((e) {
          if (!contacts.containsKey(e.id)) {
            return true;
          }

          return false;
        }))
          u.id: u,
      };

      users.value = {
        for (var u in selectedUsers.where((e) {
          if (!allUsers.containsKey(e.id)) {
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
      Map allUsers = {
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

      users.value = {
        for (var u in selectedUsers.where((e) {
          if (!allUsers.containsKey(e.id)) {
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

    print(
      '_populate, recent: ${chats.length}, contact: ${contacts.length}, user: ${users.length}',
    );
  }
}
