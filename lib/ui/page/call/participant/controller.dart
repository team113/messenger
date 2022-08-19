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
import 'dart:collection';

import 'package:get/get.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/domain/service/call.dart';

import '/domain/model/user.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/repository/contact.dart';
import '/domain/service/chat.dart';
import '/domain/service/contact.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

enum ParticipantsFlowStage {
  adding,
  addedSuccess,
}

/// Controller of the chat member addition modal.
class ParticipantController extends GetxController {
  ParticipantController(
    this.pop,
    this._call,
    this._chatService,
    this._callService,
    this._contactService,
  );

  /// Reactive state of the [Chat] this modal is about.
  Rx<RxChat?> chat = Rx(null);

  final Rx<RxUser?> hoveredUser = Rx(null);

  /// Pops the [ParticipantsView] this controller is bound to.
  final Function() pop;

  final Rx<ParticipantsFlowStage?> stage = Rx(null);

  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Reactive list of the selected [ChatContact]s.
  final RxList<RxChatContact> selectedContacts = RxList<RxChatContact>([]);

  /// Reactive list of the selected [User]s.
  final RxList<User> selectedUsers = RxList<User>([]);

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Calls service used to transform current call into group call.
  final CallService _callService;

  /// [ChatContact]s service used to get [contacts] list.
  final ContactService _contactService;

  /// Subscription for the [ChatService.chats] changes.
  late final StreamSubscription _chatsSubscription;

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop.
  late final Worker _stateWorker;

  UserId? get me => _chatService.me;

  /// ID of the [Chat] this modal is about.
  Rx<ChatId> get chatId => _call.value.chatId;

  /// Returns the current reactive map of [ChatContact]s.
  RxObsMap<ChatContactId, RxChatContact> get contacts =>
      _contactService.contacts;

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
    super.onClose();
  }

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group with the current [Chat]-dialog members, [selectedContacts]
  /// and [selectedUsers].
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
      stage.value = ParticipantsFlowStage.addedSuccess;
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
    chat.value = (await _chatService.get(chatId.value));
    if (chat.value == null) {
      MessagePopup.error('err_unknown_chat'.l10n);
      pop();
    }
  }
}
