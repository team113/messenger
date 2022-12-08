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
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/mute_duration.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/contact.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/provider/gql/exceptions.dart'
    show
        DeleteChatContactRecordException,
        ToggleChatMuteException,
        UpdateChatContactNameException;
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';

import '../../../../../domain/model/precise_date_time/precise_date_time.dart';
import '../../../../../util/message_popup.dart';
import '/domain/model/contact.dart';

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

  /// Indicator whether this [user] is already in the contacts list of the
  /// authenticated [MyUser].
  late final RxBool inContacts = RxBool(false);
  final ContactService _contactService;
  final ChatService _chatService;
  final CallService _callService;

  late final TextFieldState name;

  late final TextFieldState email;

  late final TextFieldState phone;
  final RxBool inFavorites = RxBool(false);
  late final RxChatContact contact;

  /// Status of the [user] fetching.
  ///
  /// May be:
  /// - `status.isLoading`, meaning [user] is being fetched from the service.
  /// - `status.isEmpty`, meaning [user] with specified [id] was not found.
  /// - `status.isSuccess`, meaning [user] is successfully fetched.
  /// - `status.isLoadingMore`, meaning a request is being made.
  Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());
  final RxList<UserEmail> emails = RxList();
  final RxList<UserPhone> phones = RxList();

  final RxBool blocked = RxBool(false);
  @override
  void onInit() {
    contact = _contactService.contacts[id]!;

    inContacts.value = _contactService.contacts.values.any((e) => e.id == id);
    inFavorites.value = _contactService.favorites.values.any((e) => e.id == id);

    name = TextFieldState(
      text: contact.contact.value.name.val,
      approvable: true,
      onChanged: (s) async {
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
  /// Opens a [Chat]-dialog with this [user].
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

  /// Starts an [OngoingCall] in this [Chat] [withVideo] or without.
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

  Future<void> addToFavorites() async {
    inFavorites.value = true;
  }

  Future<void> removeFromFavorites() async {
    inFavorites.value = false;
  }

  Future<void> removePhone(UserPhone phone) async {
    try {
      await _contactService.deleteChatContactRecord(id, phone: phone);
    } on DeleteChatContactRecordException catch (e) {
      MessagePopup.error(e);
      rethrow;
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  Future<void> removeEmail(UserEmail email) async {
    try {
      await _contactService.deleteChatContactRecord(id, email: email);
    } on DeleteChatContactRecordException catch (e) {
      MessagePopup.error(e);
      rethrow;
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

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

  /// Adds the [user] to the contacts list of the authenticated [MyUser].
  Future<void> addToContacts() async {
    if (!inContacts.value) {
      status.value = RxStatus.loadingMore();
      try {
        await _contactService.createChatContact(contact.user.value!.user.value);
        inContacts.value = true;
      } catch (e) {
        MessagePopup.error(e);
        rethrow;
      } finally {
        status.value = RxStatus.success();
      }
    }
  }

  /// Removes the [user] from the contacts list of the authenticated [MyUser].
  Future<void> removeFromContacts() async {
    if (inContacts.value) {
      if (await MessagePopup.alert('alert_are_you_sure'.l10n) == true) {
        status.value = RxStatus.loadingMore();
        try {
          await _contactService.deleteContact(contact.contact.value.id);

          inContacts.value = false;
        } catch (e) {
          MessagePopup.error(e);
          rethrow;
        } finally {
          status.value = RxStatus.success();
        }
      }
    }
  }
}
