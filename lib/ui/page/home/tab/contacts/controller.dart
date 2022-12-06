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
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart'
    show
        CallAlreadyJoinedException,
        CallAlreadyExistsException,
        CallIsInPopupException;
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/contact.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateChatContactNameException;
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the `HomeTab.contacts` tab.
class ContactsTabController extends GetxController {
  ContactsTabController(
    this._chatRepository,
    this._contactService,
    this._calls,
    this._settings,
  );

  /// [TextFieldState] of a [ChatContact.name].
  late TextFieldState contactName;

  /// Returns current reactive [ChatContact]s list.
  final RxList<RxChatContact> contacts = RxList<RxChatContact>();

  /// [ChatContactId] of a [ChatContact] to rename.
  final Rx<ChatContactId?> contactToChangeNameOf = Rx<ChatContactId?>(null);

  /// [Chat] repository used to create a dialog [Chat].
  final AbstractChatRepository _chatRepository;

  /// Address book used to get [ChatContact]s list.
  final ContactService _contactService;

  /// Call service used to start a [ChatCall].
  final CallService _calls;

  /// Settings repository, used to get the stored
  /// [ApplicationSettings.sortContactsByName] and update it.
  final AbstractSettingsRepository _settings;

  /// [Worker]s to [RxChatContact.user] reacting on its changes.
  final Map<ChatContactId, Worker> _userWorkers = {};

  /// Stored [User]s [_OnlineData].
  final Map<UserId, _OnlineData> _usersMap = {};

  /// [Worker]s to [RxUser.user] reacting on its changes.
  final Map<UserId, Worker> _userOnlineWorkers = {};

  /// [StreamSubscription]s to the [contacts] updates.
  StreamSubscription? _contactsSubscription;

  /// Returns the current reactive favorite [ChatContact]s map.
  RxMap<ChatContactId, RxChatContact> get favorites =>
      _contactService.favorites;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get contactsReady => _contactService.isReady;

  /// Indicates whether [contacts] should be sorted by name or not.
  bool get searchByName =>
      _settings.applicationSettings.value!.sortContactsByName;

  @override
  void onInit() {
    contacts.addAll(_contactService.contacts.values);
    sortContacts();

    contactName = TextFieldState(
      onChanged: (s) async {
        s.error.value = null;

        RxChatContact? contact = contacts.firstWhereOrNull(
                (e) => e.contact.value.id == contactToChangeNameOf.value) ??
            favorites.values.firstWhereOrNull(
                (e) => e.contact.value.id == contactToChangeNameOf.value);
        if (contact == null) return;

        if (contact.contact.value.name.val == s.text) {
          contactToChangeNameOf.value = null;
          return;
        }

        UserName? name;

        try {
          name = UserName(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }

        if (s.error.value == null) {
          try {
            s.status.value = RxStatus.loading();
            s.editable.value = false;

            await _contactService.changeContactName(
              contactToChangeNameOf.value!,
              name!,
            );

            s.clear();
            contactToChangeNameOf.value = null;
          } on UpdateChatContactNameException catch (e) {
            s.error.value = e.toMessage();
          } catch (e) {
            s.error.value = e.toString();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
      onSubmitted: (s) {
        RxChatContact? contact = contacts.firstWhereOrNull(
                (e) => e.contact.value.id == contactToChangeNameOf.value) ??
            favorites.values.firstWhereOrNull(
                (e) => e.contact.value.id == contactToChangeNameOf.value);
        if (contact?.contact.value.name.val == s.text) {
          contactToChangeNameOf.value = null;
          return;
        }
      },
    );

    _initUsersUpdates();

    super.onInit();
  }

  @override
  void onClose() {
    for (RxChatContact contact in contacts) {
      contact.user.value?.stopUpdates();
    }
    _contactsSubscription?.cancel();
    _userWorkers.forEach((_, v) => v.dispose());
    _userOnlineWorkers.forEach((_, v) => v.dispose());
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

  /// Changes [contacts] sorting mode.
  ///
  /// If [value] is `true` means sorting [contacts] by name ascending.
  /// If [value] is `false` means sorting [contacts] by their online.
  void updateSortingType(bool value) async {
    await _settings.setSortContactsByName(value);
    sortContacts();
  }

  /// Sorts [contacts] by sorting type defined in
  /// [ApplicationSettings.sortContactsByName].
  void sortContacts() {
    contacts.sort((a, b) {
      if (searchByName == true) {
        return a.contact.value.name.val.compareTo(b.contact.value.name.val);
      } else {
        User? userA = a.user.value?.user.value;
        User? userB = b.user.value?.user.value;

        if (userA?.online == true && userB?.online == false) {
          return -1;
        } else if (userA?.online == false && userB?.online == true) {
          return 1;
        } else {
          if (userB?.lastSeenAt == null || userA?.lastSeenAt == null) {
            return 0;
          } else {
            return userB!.lastSeenAt!.compareTo(userA!.lastSeenAt!);
          }
        }
      }
    });
  }

  /// Starts a [ChatCall] with a [user] [withVideo] or not.
  ///
  /// Creates a dialog [Chat] with a [user] if it doesn't exist yet.
  Future<void> _call(User user, bool withVideo) async {
    Chat? dialog = user.dialog;
    dialog ??= (await _chatRepository.createDialogChat(user.id)).chat.value;
    try {
      await _calls.call(dialog.id, withVideo: withVideo);
    } on CallAlreadyJoinedException catch (e) {
      MessagePopup.error(e);
    } on CallAlreadyExistsException catch (e) {
      MessagePopup.error(e);
    } on CallIsInPopupException catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Starts listen updates of [User].
  void _startUserListen(Rx<User> user) {
    User u = user.value;
    if (_userOnlineWorkers[u.id] == null && _usersMap[u.id] == null) {
      _usersMap[u.id] = _OnlineData(u.online, u.lastSeenAt);

      _userOnlineWorkers[u.id] = ever(user, (User u) {
        if (searchByName == false &&
            (_usersMap[u.id]!.online != u.online ||
                _usersMap[u.id]!.lastSeenAt != u.lastSeenAt)) {
          _usersMap[u.id] = _OnlineData(u.online, u.lastSeenAt);

          sortContacts();
        }
      });
    }
  }

  /// Maintains an interest in updates of every [RxChatContact.user] in the
  /// [contacts] list.
  void _initUsersUpdates() {
    /// States an interest in updates of the specified [RxChatContact.user].
    void listen(RxChatContact c) {
      RxUser? rxUser = c.user.value?..listenUpdates();
      _userWorkers[c.id] = ever(c.user, (RxUser? user) {
        if (rxUser?.id != user?.id) {
          rxUser?.stopUpdates();
          rxUser = user?..listenUpdates();
        }

        if (user != null) _startUserListen(user.user);
      });

      if (c.user.value != null) _startUserListen(c.user.value!.user);
    }

    for (RxChatContact c in contacts) {
      listen(c);
    }

    _contactsSubscription = _contactService.contacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          contacts.add(e.value!);
          listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          contacts.removeWhere((c) => c.id == e.key);
          _usersMap.remove(e.key);
          _userOnlineWorkers.remove(e.key)?.dispose();
          _userWorkers.remove(e.key)?.dispose();
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }

      sortContacts();
    });
  }
}

/// Wrapped [User]s online state data.
class _OnlineData {
  _OnlineData(this.online, this.lastSeenAt);

  /// Online state of [User].
  bool online;

  /// [PreciseDateTime] when [User] was seen online last time.
  PreciseDateTime? lastSeenAt;
}
