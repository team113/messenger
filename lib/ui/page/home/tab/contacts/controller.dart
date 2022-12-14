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
import '/provider/gql/exceptions.dart'
    show FavoriteChatContactException, UnfavoriteChatContactException;
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the `HomeTab.contacts` tab.
class ContactsTabController extends GetxController {
  ContactsTabController(
    this._chatRepository,
    this._contactService,
    this._calls,
    this._settingsRepository,
  );

  /// Returns current reactive [ChatContact]s list.
  final RxList<RxChatContact> contacts = RxList<RxChatContact>();

  /// [Chat] repository used to create a dialog [Chat].
  final AbstractChatRepository _chatRepository;

  /// Address book used to get [ChatContact]s list.
  final ContactService _contactService;

  /// Call service used to start a [ChatCall].
  final CallService _calls;

  /// Settings repository, used to get the stored
  /// [ApplicationSettings.sortContactsByName] and update it.
  final AbstractSettingsRepository _settingsRepository;

  /// [Worker]s to [RxChatContact.user] reacting on its changes.
  final Map<ChatContactId, Worker> _rxUserWorkers = {};

  /// [Worker]s to [RxUser.user] reacting on its changes.
  final Map<UserId, Worker> _userWorkers = {};

  /// [StreamSubscription]s to the [contacts] updates.
  StreamSubscription? _contactsSubscription;

  /// [StreamSubscription]s to the [favorites] updates.
  StreamSubscription? _favoritesSubscription;

  /// Reactive list of sorted [ChatContact]s.
  late final RxList<RxChatContact> favorites;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get contactsReady => _contactService.isReady;

  /// Indicates whether [contacts] should be sorted by their names or otherwise
  /// by their [User.lastSeenAt] dates.
  bool get sortByName =>
      _settingsRepository.applicationSettings.value?.sortContactsByName ?? true;

  @override
  void onInit() {
    contacts.addAll(_contactService.contacts.values);
    _sortContacts();
    favorites = RxList(_contactService.favorites.values.toList());
    _sortFavorites();

    _initUsersUpdates();

    super.onInit();
  }

  @override
  void onClose() {
    for (RxChatContact contact in contacts) {
      contact.user.value?.stopUpdates();
    }

    _contactsSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _rxUserWorkers.forEach((_, v) => v.dispose());
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

  /// Marks the specified [ChatContact] identified by its [id] as favorited.
  Future<void> favoriteContact(ChatContactId id) async {
    try {
      await _contactService.favoriteChatContact(id);
    } on FavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the specified [ChatContact] identified by its [id] from the
  /// favorites.
  Future<void> unfavoriteContact(ChatContactId id) async {
    try {
      await _contactService.unfavoriteChatContact(id);
    } on UnfavoriteChatContactException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Toggles the [sortByName] sorting the [contacts].
  void toggleSorting() {
    _settingsRepository.setSortContactsByName(!sortByName);
    _sortContacts();
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
    final User u = user.value;

    if (_userWorkers[u.id] == null) {
      bool online = u.online;
      PreciseDateTime? lastSeenAt = u.lastSeenAt;

      _userWorkers[u.id] = ever(user, (User u) {
        if (sortByName == false &&
            (online != u.online || lastSeenAt != u.lastSeenAt)) {
          online = u.online;
          lastSeenAt = u.lastSeenAt;

          _sortContacts();
        }
      });
    }
    _sortContacts();
  }

  /// Maintains an interest in updates of every [RxChatContact.user] in the
  /// [contacts] list.
  void _initUsersUpdates() {
    /// States an interest in updates of the specified [RxChatContact.user].
    void listen(RxChatContact c) {
      RxUser? rxUser = c.user.value?..listenUpdates();
      _rxUserWorkers[c.id] = ever(c.user, (RxUser? user) {
        if (rxUser?.id != user?.id) {
          rxUser?.stopUpdates();
          rxUser = user?..listenUpdates();
          _userWorkers.remove(user?.id)?.dispose();
        }

        if (user != null) {
          _startUserListen(user.user);
        }
      });

      if (c.user.value != null) {
        _startUserListen(c.user.value!.user);
      }
    }

    contacts.forEach(listen);

    _contactsSubscription = _contactService.contacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          contacts.add(e.value!);
          listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          contacts.removeWhere((c) => c.id == e.key);
          _userWorkers.remove(e.key)?.dispose();
          _rxUserWorkers.remove(e.key)?.dispose();
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }

      _sortContacts();
    });

    favorites.forEach(listen);

    _favoritesSubscription = _contactService.favorites.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          favorites.add(e.value!);
          _sortFavorites();
          listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          _userWorkers.remove(e.key)?.dispose();
          favorites.removeWhere((c) => c.contact.value.id == e.key);
          break;

        case OperationKind.updated:
          _sortFavorites();
          break;
      }
    });
  }

  /// Sorts the [contacts] by their names or by their [User.lastSeenAt] based on
  /// the [sortByName] indicator.
  void _sortContacts() {
    contacts.sort((a, b) {
      if (sortByName == true) {
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

  /// Sorts the [favorites] by the [ChatContact.favoritePosition].
  void _sortFavorites() {
    favorites.sort(
      (a, b) => a.contact.value.favoritePosition!
          .compareTo(b.contact.value.favoritePosition!),
    );
  }
}
