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
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        AddChatMemberException,
        RedialChatCallMemberException,
        RemoveChatMemberException;
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of an [AddChatMemberView].
class AddChatMemberController extends GetxController {
  AddChatMemberController(
    this.chatId,
    this._chatService,
    this._callService, {
    this.pop,
  });

  /// ID of the [Chat] to add [ChatMember]s to.
  final ChatId chatId;

  /// Reactive [RxChat] this modal is about.
  Rx<RxChat?> chat = Rx(null);

  /// Callback, called when an [AddChatMemberView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// Status of an [addMembers] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [addMembers] is executing.
  /// - `status.isLoading`, meaning [addMembers] is executing.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Worker performing a [_fetchChat] on the [chatId] changes.
  Worker? _chatWorker;

  /// [Chat]s service adding members to the [chat].
  final ChatService _chatService;

  /// [CallService] transforming the [_call] into a group-call.
  final CallService _callService;

  /// Subscription for the [ChatService.chats] changes.
  StreamSubscription? _chatsSubscription;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    _chatsSubscription = _chatService.chats.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          // No-op.
          break;

        case OperationKind.removed:
          if (e.key == chatId) {
            pop?.call();
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
    _chatsSubscription?.cancel();
    _chatWorker?.dispose();
    super.onClose();
  }

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember(UserId userId) async {
    try {
      await _chatService.removeChatMember(chatId, userId);
      if (userId == me) {
        pop?.call();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Adds the [User]s identified by the provided [UserId]s to this [chat].
  Future<void> addMembers(List<UserId> ids) async {
    status.value = RxStatus.loading();

    try {
      List<Future> futures =
          ids.map((e) => _chatService.addChatMember(chatId, e)).toList();

      await Future.wait(futures);

      pop?.call();
    } on AddChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      status.value = RxStatus.empty();
    }
  }

  /// Redials by specified [UserId] who left or declined the ongoing [ChatCall].
  Future<void> redialChatCallMember(UserId memberId) async {
    // MessagePopup.success('label_participant_redial_successfully'.l10n);

    try {
      await _callService.redialChatCallMember(chatId, memberId);
    } on RedialChatCallMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Fetches the [chat].
  void _fetchChat() async {
    chat.value = null;
    chat.value = await _chatService.get(chatId);
    if (chat.value == null) {
      MessagePopup.error('err_unknown_chat'.l10n);
      pop?.call();
    }
  }
}
