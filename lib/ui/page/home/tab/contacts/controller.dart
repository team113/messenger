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
  );

  /// [TextFieldState] of a [ChatContact.name].
  late TextFieldState contactName;

  /// [ChatContactId] of a [ChatContact] to rename.
  final Rx<ChatContactId?> contactToChangeNameOf = Rx<ChatContactId?>(null);

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

  /// Returns current reactive [ChatContact]s map.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactService.contacts;

  /// Returns the current reactive favorite [ChatContact]s map.
  RxMap<ChatContactId, RxChatContact> get favorites =>
      _contactService.favorites;

  /// Indicates whether [ContactService] is ready to be used.
  RxBool get contactsReady => _contactService.isReady;

  @override
  void onInit() {
    contactName = TextFieldState(
      onChanged: (s) async {
        s.error.value = null;

        RxChatContact? contact = contacts.values.firstWhereOrNull(
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
          s.error.value = 'err_incorrect_input'.tr;
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
        var contact = contacts.values.firstWhereOrNull(
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
    if (await MessagePopup.alert('alert_are_you_sure'.tr) == true) {
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
    _contactsSubscription = contacts.changes.listen((e) {
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
