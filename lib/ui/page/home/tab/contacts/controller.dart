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
    show
        UpdateChatContactNameException,
        FavoriteChatContactException,
        UnfavoriteChatContactException;
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
  );

  /// [Chat] repository used to create a dialog [Chat].
  final AbstractChatRepository _chatRepository;

  /// Address book used to get [ChatContact]s list.
  final ContactService _contactService;

  /// Call service used to start a [ChatCall].
  final CallService _calls;

  /// [Worker]s to [RxChatContact.user] reacting on its changes.
  final Map<ChatContactId, Worker> _userWorkers = {};

  /// [StreamSubscription]s to the [contacts] updates.
  StreamSubscription? _contactsSubscription;

  /// [StreamSubscription]s to the [favorites] updates.
  StreamSubscription? _favoritesSubscription;

  /// Returns current reactive [ChatContact]s map.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactService.contacts;

  /// Reactive list of sorted [ChatContact]s.
  late final RxList<RxChatContact> favorites;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get contactsReady => _contactService.isReady;

  @override
  void onInit() {
    favorites =
        RxList<RxChatContact>(_contactService.favorites.values.toList());
    _sortFavorites();

    _initUsersUpdates();

    super.onInit();
  }

  @override
  void onClose() {
    contacts.forEach((_, c) => c.user.value?.stopUpdates());
    _contactsSubscription?.cancel();
    _favoritesSubscription?.cancel();
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
      });
    }

    contacts.forEach((_, c) => listen(c));
    _contactsSubscription = contacts.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          listen(e.value!);
          break;

        case OperationKind.removed:
          e.value?.user.value?.stopUpdates();
          _userWorkers.remove(e.key)?.dispose();
          break;

        case OperationKind.updated:
          // no-op
          break;
      }
    });

    for (var c in favorites) {
      listen(c);
    }
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

  /// Sorts the [favorites] by the [ChatContact.favoritePosition]
  void _sortFavorites() {
    favorites.sort(
      (a, b) => a.contact.value.favoritePosition!
          .compareTo(b.contact.value.favoritePosition!),
    );
  }
}
