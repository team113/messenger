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

import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/contact.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show UpdateChatContactNameException;
import '/routes.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of the [Routes.contact] page.
class ContactController extends GetxController {
  ContactController(
    this.id,
    this._contactService,
    this._chatService,
    this._callService,
  );

  /// ID of a [ChatContact] this [ContactController] represents.
  final ChatContactId id;

  /// Indicator whether this [contact] is already in the contacts list of the
  /// authenticated [MyUser]'s address book.
  final RxBool inContacts = RxBool(false);

  /// Indicator whether [ChatContact] is in favorite list or not.
  final RxBool inFavorites = RxBool(false);

  /// [ChatContact.name]'s field state.
  late final TextFieldState name;

  /// Adding new [ChatContact.emails]'s field state.
  late final TextFieldState email;

  /// Adding new [ChatContact.phones]'s field state.
  late final TextFieldState phone;

  /// Reactive value of [ChatContact].
  late final RxChatContact contact;

  /// [ContactService] used to get contacts list.
  final ContactService _contactService;

  /// [ChatService] used to create [Chat]-dialog.
  final ChatService _chatService;

  /// [CallService] used to make calls.
  final CallService _callService;

  @override
  void onInit() {
    contact = _contactService.contacts[id]!;

    inContacts.value = _contactService.contacts.values.any((e) => e.id == id);
    inFavorites.value = _contactService.favorites.values.any((e) => e.id == id);

    name = TextFieldState(
      text: contact.contact.value.name.val,
      approvable: true,
      onChanged: (s) {
        s.error.value = null;
        try {
          if (s.text.isNotEmpty) {
            UserName(s.text);
          }
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
        }
      },
      onSubmitted: (s) async {
        s.error.value = null;

        if (contact.contact.value.name.val == s.text) {
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
              contact.id,
              name!,
            );
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
    );

    email = TextFieldState(
      approvable: true,
      onChanged: (s) {
        s.error.value = null;
        if (s.text.isEmpty) {
          s.clear();
        }
      },
      onSubmitted: (s) async {
        if (s.status.value == RxStatus.loading()) return;
        UserEmail? email;
        try {
          email = UserEmail(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }

        if (s.error.value == null ||
            contact.contact.value.emails.contains(email)) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _contactService.createChatContactRecord(id, email: email);

            s.clear();
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          } catch (e) {
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
    );

    phone = TextFieldState(
      approvable: true,
      onChanged: (s) {
        s.error.value = null;
        if (s.text.isEmpty) {
          s.clear();
        }
      },
      onSubmitted: (s) async {
        if (s.status.value == RxStatus.loading()) return;
        UserPhone? phone;
        try {
          phone = UserPhone(s.text);
        } on FormatException {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }

        if (s.error.value == null ||
            !contact.contact.value.phones.contains(phone)) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();

          try {
            await _contactService.createChatContactRecord(id, phone: phone);

            s.clear();
          } on FormatException {
            s.error.value = 'err_incorrect_input'.l10n;
          } catch (e) {
            MessagePopup.error(e);
            s.unsubmit();
            rethrow;
          } finally {
            s.editable.value = true;
            s.status.value = RxStatus.empty();
          }
        }
      },
    );

    super.onInit();
  }

  // TODO: No [Chat] should be created.
  /// Opens a [Chat]-dialog with this [contact.user].
  ///
  /// Creates a new one if it doesn't exist.
  Future<void> openChat() async {
    Chat? dialog = contact.user.value?.user.value.dialog;
    if (contact.user.value?.id != null) {
      dialog ??= (await _chatService.createDialogChat(contact.user.value!.id))
          .chat
          .value;
      router.chat(dialog.id, push: true);
    }
  }

  /// Starts an [OngoingCall] with this [contact] [withVideo] or without.
  Future<void> call(bool withVideo) async {
    Chat? dialog = contact.user.value?.user.value.dialog;
    if (contact.user.value?.id != null) {
      dialog ??= (await _chatService.createDialogChat(contact.user.value!.id))
          .chat
          .value;

      try {
        await _callService.call(dialog.id, withVideo: withVideo);
      } on CallDoesNotExistException catch (e) {
        MessagePopup.error(e);
      }
    }
  }

  /// Removes specified [email] or [phone] from [contact] records of this
  /// [ChatContact].
  Future<void> removeContactRecord({UserEmail? email, UserPhone? phone}) async {
    try {
      await _contactService.deleteChatContactRecord(
        id,
        email: email,
        phone: phone,
      );
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Adds the [contact] to the contacts list of the authenticated [MyUser]'s.
  Future<void> addToContacts() async {
    if (!inContacts.value) {
      try {
        await _contactService.createChatContact(contact.user.value!.user.value);

        inContacts.value = true;
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      }
    }
  }

  /// Removes the [contact] from the contacts list of the authenticated [MyUser]'s.
  Future<void> removeFromContacts() async {
    if (inContacts.value) {
      if (await MessagePopup.alert('alert_are_you_sure'.l10n) == true) {
        try {
          await _contactService.deleteContact(contact.contact.value.id);

          inContacts.value = false;
        } catch (e) {
          MessagePopup.error(e);
          rethrow;
        }
      }
    }
  }
}
