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
import '/domain/model/ongoing_call.dart';
import '/domain/repository/contact.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/util/message_popup.dart';
import '/util/obs/rxmap.dart';

export 'view.dart';

/// Controller of the dialog member addition modal.
class AddDialogMemberController extends GetxController {
  AddDialogMemberController(
    this.pop,
    this.chatId,
    this._currentCall,
    this._chatService,
    this._callService,
    this._contactService,
  );

  /// Reactive state of the [Chat] this modal is about.
  Rx<Rx<Chat>?> chat = Rx<Rx<Chat>?>(null);

  /// Status of an [transformDialogCallIntoGroupCall] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [transformDialogCallIntoGroupCall] is
  ///   executing.
  /// - `status.isLoading`, meaning [transformDialogCallIntoGroupCall] is
  ///   executing.
  /// - `status.isError`, meaning [transformDialogCallIntoGroupCall] got an
  ///   error.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);

  /// Reactive list of the selected [User]s.
  final RxList<User> selectedUsers = RxList<User>([]);

  /// Pops the [AddDialogMemberView] this controller is bound to.
  final Function() pop;

  /// ID of the [Chat] this modal is about.
  final ChatId chatId;

  /// Current [OngoingCall].
  final Rx<OngoingCall> _currentCall;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Calls service used to transform current call into group call.
  final CallService _callService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop.
  late final Worker _stateWorker;

  /// Returns the current reactive map of [ChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactService.contacts;

  @override
  void onInit() {
    super.onInit();

    _stateWorker = ever(_currentCall.value.state, (state) {
      if (state == OngoingCallState.ended) {
        pop();
      }
    });
  }

  @override
  void onReady() {
    _fetchChat();
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    _stateWorker.dispose();
  }

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group with the current [Chat]-dialog members, [selectedContacts]
  /// and [selectedUsers].
  Future<void> transformDialogCallIntoGroupCall({ChatName? groupName}) async {
    status.value = RxStatus.loading();
    try {
      await _callService.transformDialogCallIntoGroupCall(
        chatId,
        [
          ...selectedContacts.map((e) => e.contact.value.users.first.id),
          ...selectedUsers.map((e) => e.id)
        ],
        groupName,
      );
      pop();
    } on TransformDialogCallIntoGroupCallException catch (e) {
      status.value = RxStatus.error(e.toMessage());
    } catch (e) {
      status.value = RxStatus.empty();
      MessagePopup.error(e);
      rethrow;
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

  /// Selects the specified [user].
  void selectUser(User user) {
    if (!selectedUsers.any((u) => u.id == user.id)) {
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
      MessagePopup.error('err_unknown_chat'.td);
      pop();
    }
  }
}
