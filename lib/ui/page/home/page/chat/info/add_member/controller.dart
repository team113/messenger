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

import '/domain/model/user.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/fluent/extension.dart';
import '/provider/gql/exceptions.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of the chat member addition modal.
class AddChatMemberController extends GetxController {
  AddChatMemberController(
    this.pop,
    this.chatId,
    this._chatService,
    this._contactService,
  );

  /// ID of the [Chat] this modal is about.
  final ChatId chatId;

  /// Reactive state of the [Chat] this modal is about.
  Rx<Rx<Chat>?> chat = Rx<Rx<Chat>?>(null);

  /// Status of an [addChatMembers] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [addChatMembers] is executing.
  /// - `status.isLoading`, meaning [addChatMembers] is executing.
  /// - `status.isError`, meaning [addChatMembers] got an error.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of the selected [ChatContact]s.
  final RxList<Rx<ChatContact>> selectedContacts = RxList<Rx<ChatContact>>([]);

  /// Reactive list of the selected [User]s.
  final RxList<User> selectedUsers = RxList<User>([]);

  /// Pops the [AddChatMemberView] this controller is bound to.
  final Function() pop;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Returns the current reactive observable map of [ChatContact]s.
  RxObsMap<ChatContactId, Rx<ChatContact>> get contacts =>
      _contactService.contacts;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  @override
  void onInit() {
    _chatsSubscription = _chatService.chats.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          // No-op.
          break;

        case OperationKind.removed:
          if (e.key == chatId) {
            pop();
          }
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

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
    super.onClose();
  }

  /// Adds [User]s of [selectedContacts] to a [Chat]-group.
  Future<void> addChatMembers() async {
    status.value = RxStatus.loading();
    try {
      List<Future> futures = [];
      for (var id in [
        ...selectedContacts.expand((e) => e.value.users.map((u) => u.id)),
        ...selectedUsers.map((u) => u.id),
      ]) {
        futures.add(_chatService.addChatMember(chatId, id));
      }

      await Future.wait(futures);

      selectedContacts.clear();
      pop();
    } on AddChatMemberException catch (e) {
      status.value = RxStatus.error(e.toMessage());
    } catch (e) {
      status.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Selects or unselects the specified [contact].
  void selectContact(Rx<ChatContact> contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
  }

  /// Selects the specified [user].
  void selectUser(User user) {
    if (!selectedUsers.any((u) => u.id.val == user.id.val)) {
      selectedUsers.add(user);
    }
  }

  /// Unselects the specified [user].
  void unselectUser(User user) {
    if (selectedUsers.contains(user)) {
      selectedUsers.remove(user);
    }
  }

  /// Fetches the [chat].
  void _fetchChat() async {
    chat.value = (await _chatService.get(chatId))?.chat;
    if (chat.value == null) {
      MessagePopup.error('err_unknown_chat'.td());
      pop();
    }
  }
}
