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
import 'package:messenger/domain/model/mute_duration.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/user.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallAlreadyExistsException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/contact.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show ToggleChatMuteException, UpdateChatContactNameException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the `HomeTab.contacts` tab.
class ContactsTabController extends GetxController {
  ContactsTabController(
    this._chatService,
    this._contactService,
    this._userService,
    this._callService,
    this._myUserService,
  );

  final RxBool searching = RxBool(false);
  late final TextFieldState search;

  final RxMap<ChatContactId, RxChatContact> favorites = RxMap();
  final RxMap<ChatContactId, RxChatContact> contacts = RxMap();
  final RxMap<UserId, RxUser> users = RxMap();

  final RxBool sorting = RxBool(false);

  final RxnString query = RxnString();
  final Rx<RxList<RxUser>?> searchResults = Rx(null);
  final Rx<RxStatus> searchStatus = Rx<RxStatus>(RxStatus.empty());

  /// [Chat] repository used to create a dialog [Chat].
  final ChatService _chatService;

  /// Address book used to get [ChatContact]s list.
  final ContactService _contactService;

  final UserService _userService;

  /// Call service used to start a [ChatCall].
  final CallService _callService;

  /// Service managing [MyUser].
  final MyUserService _myUserService;

  /// [Worker]s to [RxChatContact.user] reacting on its changes.
  final Map<ChatContactId, Worker> _userWorkers = {};

  /// Worker to react on [SearchResult.status] changes.
  Worker? _searchStatusWorker;
  Worker? _searchWorker;
  Worker? _searchDebounce;

  /// [StreamSubscription]s to the [contacts] updates.
  StreamSubscription? _contactsSubscription;

  /// Returns current reactive [ChatContact]s map.
  RxObsMap<ChatContactId, RxChatContact> get allContacts =>
      _contactService.contacts;

  /// Returns the current reactive favorite [ChatContact]s map.
  RxMap<ChatContactId, RxChatContact> get allFavorites =>
      _contactService.favorites;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get contactsReady => _contactService.isReady;

  Rx<MyUser?> get myUser => _myUserService.myUser;

  @override
  void onInit() {
    _searchWorker = ever(
      query,
      (String? q) {
        if (q == null || q.isEmpty) {
          searchResults.value = null;
          searchStatus.value = RxStatus.empty();
          query.value = null;
          search.clear();
          _populate();
        } else {
          searchStatus.value = RxStatus.loading();
          _populate();
        }
      },
    );

    search = TextFieldState(
      onChanged: (d) {
        query.value = d.text;
        if (d.text.isEmpty) {
          query.value = null;
          searchResults.value = null;
          searchStatus.value = RxStatus.empty();
          users.clear();
          contacts.clear();
          favorites.clear();
          _populate();
        } else {
          searchStatus.value = RxStatus.loading();
          _populate();
        }
      },
    );

    search.focus.addListener(() {
      if (search.focus.hasFocus == false) {
        if (search.text.isEmpty) {
          searching.value = false;
          query.value = null;
          search.clear();
          searchResults.value = null;
          searchStatus.value = RxStatus.empty();
          _populate();
        }
      }
    });

    _searchDebounce = debounce(query, (String? v) {
      if (v != null) {
        _search(v);
      }
    });

    controller.sliverController.onPaintItemPositionsCallback = (d, list) {
      int? first = list.firstOrNull?.index;
      if (first != null) {
        if (first >= contacts.length) {
          selected.value = 1;
        } else {
          selected.value = 0;
        }
      }
    };

    _populate();

    _initUsersUpdates();

    super.onInit();
  }

  @override
  void onClose() {
    contacts.forEach((_, c) => c.user.value?.stopUpdates());
    _contactsSubscription?.cancel();
    _userWorkers.forEach((_, v) => v.dispose());
    super.onClose();
  }

  /// Starts an audio [ChatCall] with a [to] [User].
  Future<void> startAudioCall(User to) => _call(to, false);

  /// Starts a video [ChatCall] with a [to] [User].
  Future<void> startVideoCall(User to) => _call(to, true);

  /// Adds a [user] to the [ContactService]'s address book.
  void addToContacts(User user) {
    _contactService.createChatContact(user);
  }

  /// Removes a [contact] from the [ContactService]'s address book.
  Future<void> deleteFromContacts(ChatContact contact) async {
    if (await MessagePopup.alert('alert_are_you_sure'.l10n) == true) {
      await _contactService.deleteContact(contact.id);
    }
  }

  Future<void> favorite(RxChatContact contact) => _contactService
      .favoriteChatContact(contact.id, const ChatContactPosition(1000000));

  Future<void> unfavorite(RxChatContact contact) =>
      _contactService.unfavoriteChatContact(contact.id);

  final RxInt selected = RxInt(0);
  final FlutterListViewController controller = FlutterListViewController();

  void jumpTo(int i) {
    if (i == 0) {
      controller.jumpTo(0);
    } else if (i == 1) {
      double to = users.length * (84 + 10);
      if (to > controller.position.maxScrollExtent) {
        controller.jumpTo(controller.position.maxScrollExtent);
      } else {
        controller.jumpTo(to);
      }
    }
  }

  Future<RxChat?> getChat(ChatId? id) async =>
      id == null ? null : await _chatService.get(id);

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
  Future<void> muteChat(ChatId id, {Duration? duration}) async {
    try {
      PreciseDateTime? until;
      if (duration != null) {
        until = PreciseDateTime.now().add(duration);
      }

      await _chatService.toggleChatMute(
        id,
        duration == null ? MuteDuration.forever() : MuteDuration(until: until),
      );
    } on ToggleChatMuteException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Starts a [ChatCall] with a [user] [withVideo] or not.
  ///
  /// Creates a dialog [Chat] with a [user] if it doesn't exist yet.
  Future<void> _call(User user, bool withVideo) async {
    Chat? dialog = user.dialog;
    dialog ??= (await _chatService.createDialogChat(user.id)).chat.value;
    try {
      await _callService.call(dialog.id, withVideo: withVideo);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  void _populate() {
    if (query.value?.isNotEmpty != true) {
      contacts.value = {
        for (var c in allContacts.entries) c.key: c.value,
      };

      users.clear();
      favorites.clear();
      return;
    }

    favorites.value = {
      for (var u in allFavorites.values.where((e) {
        if (e.user.value != null && e.contact.value.users.length == 1) {
          if (e.contact.value.name.val.contains(query.value!) == true) {
            return true;
          }
        }

        return false;
      }))
        u.id: u,
    };

    contacts.value = {
      for (var u in allContacts.values.where((e) {
        if (e.user.value != null && e.contact.value.users.length == 1) {
          if (e.contact.value.name.val.contains(query.value!) == true) {
            return true;
          }
        }

        return false;
      }))
        u.id: u,
    };

    if (searchResults.value?.isNotEmpty == true) {
      users.value = {
        for (var u in searchResults.value!.where((e) {
          if (contacts.values
                      .firstWhereOrNull((c) => c.user.value?.id == e.id) ==
                  null &&
              favorites.values
                      .firstWhereOrNull((c) => c.user.value?.id == e.id) ==
                  null) {
            return true;
          }

          return false;
        }))
          u.id: u,
      };
    } else {
      users.value = {};
    }

    print(
      '_populate, contact: ${contacts.length}, user: ${users.length}',
    );
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
          _populate();
        });

        _populate();

        searchStatus.value = RxStatus.success();
      }
    } else {
      searchStatus.value = RxStatus.empty();
      searchResults.value = null;
    }
  }

  /// Maintains an interest in updates of every [RxChatContact.user] in the
  /// [contacts] list.
  void _initUsersUpdates() {
    /// States an interest in updates of the specified [RxChatContact.user].
    void _listen(RxChatContact c) {
      RxUser? rxUser = c.user.value?..listenUpdates();
      _userWorkers[c.id] = ever(c.user, (RxUser? user) {
        if (rxUser?.id != user?.id) {
          rxUser?.stopUpdates();
          rxUser = user?..listenUpdates();
        }
      });
    }

    contacts.forEach((_, c) => _listen(c));
    _contactsSubscription = allContacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          _listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          _userWorkers.remove(e.key)?.dispose();
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });
  }
}
