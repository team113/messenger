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
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import 'view.dart';

export 'view.dart';

/// Stage of an chat member addition modal.
enum ParticipantsFlowStage {
  /// Participants adding stage.
  adding,

  /// Chat participants stage.
  participants,
}

/// Part of an users search result.
enum SearchResultPart {
  /// Recent users part.
  recent,

  /// Contacts part.
  contacts,

  /// Global users part.
  users,
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

  /// Pops the [ParticipantsView] this controller is bound to.
  final Function() pop;

  /// [ParticipantsFlowStage] of this addition modal.
  final Rx<ParticipantsFlowStage> stage =
      Rx(ParticipantsFlowStage.participants);

  /// Status of an [addMembers] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [addMembers] is executing.
  /// - `status.isLoading`, meaning [addMembers] is executing.
  /// - `status.isSuccess`, meaning the [addMembers] was successfully executed.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

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
  /// - `status.isLoadingMore`, meaning some [searchResults] is exist.
  /// - `status.isSuccess`, meaning the [_search] was successfully executed.
  /// - `status.isError`, meaning the [_search] got an error.
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  /// Reactive map of recent [User]s passed [query].
  final RxMap<UserId, RxUser> recent = RxMap();

  /// Reactive map of [ChatContact]s passed [query].
  final RxMap<UserId, RxChatContact> contacts = RxMap();

  /// Reactive map of [User]s passed [query].
  final RxMap<UserId, RxUser> users = RxMap();

  /// [FlutterListViewController] of a [User]s and [ChatContact]s.
  final FlutterListViewController controller = FlutterListViewController();

  /// [TextFieldState] of a [User]s search field.
  late final TextFieldState search;

  /// Reactive value of the [search].
  final RxnString query = RxnString();

  /// Selected contacts users or recent
  final Rx<SearchResultPart> selected = Rx(SearchResultPart.recent);

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchStatusWorker;

  /// Worker to react on [query] changes.
  Worker? _searchWorker;

  /// Worker performing a [_search] on [query] changes with debounce.
  Worker? _searchDebounce;

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Calls service used to transform dialog call into group call.
  final CallService _callService;

  /// Users service used to search [Users]s.
  final UserService _userService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop.
  late final Worker _stateWorker;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// ID of the [Chat] this modal is about.
  Rx<ChatId> get chatId => _call.value.chatId;

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

    _searchDebounce = debounce(
      query,
      (String? q) {
        if (q != null) {
          _search(q);
        }
      },
      time: 100.milliseconds,
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
          selected.value = SearchResultPart.users;
        } else if (first >= recent.length) {
          selected.value = SearchResultPart.contacts;
        } else {
          selected.value = SearchResultPart.recent;
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
    _searchDebounce?.dispose();
    _searchWorker?.dispose();
    _searchStatusWorker?.dispose();
    _searchStatusWorker = null;
    super.onClose();
  }

  /// Adds [selectedContacts] and [selectedUsers] to [chat].
  ///
  /// If [chat] is [Chat]-dialog then moves an ongoing [ChatCall] in a
  /// [Chat]-dialog to a newly created [Chat]-group with the current
  /// [Chat]-dialog members, [selectedContacts] and [selectedUsers].
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
      stage.value = ParticipantsFlowStage.participants;
      MessagePopup.success('label_participants_added_successfully'.l10n);
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

  /// Selects or unselects the specified [user].
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

  /// Performs searching for [User]s based on the provided [query].
  ///
  /// Query may be a [UserNum], [UserName] or [UserLogin].
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
        name = UserName.unchecked(query);
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
          .take(3))
        u.id: u,
    };

    Map<UserId, RxChatContact> allContacts = {
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

    if (searchResults.value?.isNotEmpty == true) {
      Map<UserId, RxUser> allUsers = {
        for (var u in searchResults.value!.where((e) {
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
      Map<UserId, RxUser> allUsers = {
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
  }
}
