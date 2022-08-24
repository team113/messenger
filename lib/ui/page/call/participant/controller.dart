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

export 'view.dart';

enum ParticipantsFlowStage {
  adding,
  addedSuccess,
}

/// Controller of the chat member addition modal.
class ParticipantController extends GetxController {
  ParticipantController(
    this.pop,
    this._call,
    this._chatService,
    this._callService,
    this._userService,
    this._contactService,
  );

  /// Reactive state of the [Chat] this modal is about.
  Rx<RxChat?> chat = Rx(null);

  final Rx<RxUser?> hoveredUser = Rx(null);

  /// Pops the [ParticipantsView] this controller is bound to.
  final Function() pop;

  final Rx<ParticipantsFlowStage?> stage = Rx(null);

  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);

  /// Reactive list of the selected [User]s.
  final RxList<RxUser> selectedUsers = RxList<RxUser>([]);

  final RxList<RxUser> searchResults = RxList<RxUser>([]);
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  late final TextFieldState search;
  Worker? _searchWorker;
  Worker? _searchDebounce;

  final RxnString query = RxnString();

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Calls service used to transform current call into group call.
  final CallService _callService;

  final UserService _userService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop.
  late final Worker _stateWorker;

  UserId? get me => _chatService.me;

  /// ID of the [Chat] this modal is about.
  Rx<ChatId> get chatId => _call.value.chatId;

  // /// Returns the current reactive map of [ChatContact]s.
  // RxObsMap<ChatContactId, RxChatContact> get contacts =>
  //     _contactService.contacts;

  // RxObsMap<ChatId, RxChat> get chats => _chatService.chats;

  @override
  void onInit() {
    _chatsSubscription = _chatService.chats.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          // No-op.
          break;

        case OperationKind.removed:
          if (e.key == chatId.value) {
            pop();
          }
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _stateWorker = ever(_call.value.state, (state) {
      if (state == OngoingCallState.ended) {
        pop();
      }
    });

    _searchDebounce = debounce(query, (String? v) {
      if (v != null) {
        _search(v);
      }
    });

    _searchWorker = ever(query, (String? q) {
      if (q == null || q.isEmpty) {
        searchResults.clear();
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
          selected.value = 2;
        } else if (first >= recent.length) {
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
    _fetchChat();
    super.onReady();
  }

  @override
  void onClose() {
    _chatsSubscription.cancel();
    _stateWorker.dispose();
    super.onClose();
  }

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group with the current [Chat]-dialog members, [selectedContacts]
  /// and [selectedUsers].
  Future<void> addMembers({ChatName? groupName}) async {
    status.value = RxStatus.loading();

    try {
      List<UserId> ids = {
        ...selectedContacts
            .expand((e) => e.contact.value.users.map((u) => u.id)),
        ...selectedUsers.map((u) => u.id),
      }.toList();

      if (chat.value?.chat.value.isGroup != false) {
        List<Future> futures = ids
            .map((e) => _chatService.addChatMember(chatId.value, e))
            .toList();

        await Future.wait(futures);
      } else {
        await _callService.transformDialogCallIntoGroupCall(
          chatId.value,
          ids,
          groupName,
        );
      }

      status.value = RxStatus.success();
      stage.value = ParticipantsFlowStage.addedSuccess;
    } on AddChatMemberException catch (e) {
      MessagePopup.error(e);
    } on TransformDialogCallIntoGroupCallException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      status.value = RxStatus.empty();
    }
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

  /// Fetches the [chat].
  void _fetchChat() async {
    chat.value = (await _chatService.get(chatId.value));
    if (chat.value == null) {
      MessagePopup.error('err_unknown_chat'.l10n);
      pop();
    }
  }

  Future<void> _search(String query) async {
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
        searchResults.value =
            await _userService.search(num: num, name: name, login: login);

        populate();

        searchStatus.value = RxStatus.success();
      }
    } else {
      searchStatus.value = RxStatus.empty();
      searchResults.clear();
    }
  }

  final RxInt selected = RxInt(0);
  final FlutterListViewController controller = FlutterListViewController();

  void jumpTo(int i) {
    if (i == 0) {
      controller.jumpTo(0);
    } else if (i == 1) {
      double to = recent.length * (84 + 10);
      if (to > controller.position.maxScrollExtent) {
        controller.jumpTo(controller.position.maxScrollExtent);
      } else {
        controller.jumpTo(to);
      }
    } else if (i == 2) {
      double to = (recent.length + contacts.length) * (84 + 10);
      if (to > controller.position.maxScrollExtent) {
        controller.jumpTo(controller.position.maxScrollExtent);
      } else {
        controller.jumpTo(to);
      }
    }
  }

  final RxMap<UserId, RxUser> recent = RxMap();
  final RxMap<UserId, RxChatContact> contacts = RxMap();
  final RxMap<UserId, RxUser> users = RxMap();

  RxMap<UserId, dynamic> getMap(int i) {
    if (i >= recent.length + contacts.length) {
      return recent;
    } else if (i >= recent.length) {
      return contacts;
    }

    return users;
  }

  dynamic getIndex(int i) {
    return [...recent.values, ...contacts.values, ...users.values].elementAt(i);
  }

  void populate() {
    recent.value = {
      for (var u in _chatService.chats.values
          .map((e) {
            if (e.chat.value.isDialog) {
              RxUser? user = e.members.values
                  .firstWhereOrNull((u) => u.user.value.id != me);

              if (chat.value?.members.containsKey(user?.id) != true) {
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
          })
          .whereNotNull()
          .take(1))
        u.id: u,
    };

    Map allContacts = {
      for (var u in _contactService.contacts.values.where((e) {
        if (e.contact.value.users.length == 1) {
          RxUser? user = e.user.value;

          if (chat.value?.members.containsKey(user?.id) != true &&
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

    if (searchResults.isNotEmpty) {
      Map allUsers = {
        for (var u in searchResults.where((e) {
          if (chat.value?.members.containsKey(e.id) != true &&
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
      Map allUsers = {
        for (var u in _chatService.chats.values.map((e) {
          if (e.chat.value.isDialog) {
            RxUser? user =
                e.members.values.firstWhereOrNull((u) => u.user.value.id != me);

            if (chat.value?.members.containsKey(user?.id) != true &&
                !recent.containsKey(user?.id) &&
                !contacts.containsKey(user?.id)) {
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

    print(
        '_populate, recent: ${recent.length}, contact: ${contacts.length}, user: ${users.length}');
  }
}
