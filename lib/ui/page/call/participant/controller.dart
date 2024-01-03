// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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

import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart'
    show
        AddChatMemberException,
        RedialChatCallMemberException,
        RemoveChatCallMemberException,
        RemoveChatMemberException,
        TransformDialogCallIntoGroupCallException;
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'view.dart';

export 'view.dart';

/// Possible [ParticipantView] flow stage.
enum ParticipantsFlowStage {
  search,
  participants,
}

/// Controller of a [ParticipantView].
class ParticipantController extends GetxController {
  ParticipantController(
    this._call,
    this._chatService,
    this._callService, {
    this.pop,
  });

  /// Reactive [RxChat] this modal is about.
  Rx<RxChat?> chat = Rx(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Callback, called when a [ParticipantView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// [ParticipantsFlowStage] currently being displayed.
  final Rx<ParticipantsFlowStage> stage =
      Rx(ParticipantsFlowStage.participants);

  /// Status of a [addMembers] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [addMembers] is executing.
  /// - `status.isLoading`, meaning [addMembers] is executing.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Worker for catching the [OngoingCallState.ended] state of the [_call] to
  /// [pop] the view.
  Worker? _stateWorker;

  /// Worker performing a [_fetchChat] on the [chatId] changes.
  Worker? _chatWorker;

  /// [OngoingCall] this modal is bound to.
  final Rx<OngoingCall> _call;

  /// [Chat]s service adding members to the [chat].
  final ChatService _chatService;

  /// [CallService] transforming the [_call] into a group-call.
  final CallService _callService;

  /// Subscription for the [ChatService.chats] changes.
  StreamSubscription? _chatsSubscription;

  /// Returns an ID of the [Chat] this modal is bound to.
  Rx<ChatId> get chatId => _call.value.chatId;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.add(_onBack, ifNotYetIntercepted: true);
    }

    _chatsSubscription = _chatService.chats.changes.listen((e) {
      switch (e.op) {
        case OperationKind.added:
          // No-op.
          break;

        case OperationKind.removed:
          if (e.key == chatId.value) {
            pop?.call();
          }
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _chatWorker = ever(chatId, (_) => _fetchChat());
    _stateWorker = ever(_call.value.state, (state) {
      if (state == OngoingCallState.ended) {
        pop?.call();
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
    _stateWorker?.dispose();
    _chatWorker?.dispose();

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      BackButtonInterceptor.remove(_onBack);
    }

    super.onClose();
  }

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember(UserId userId) async {
    try {
      await _chatService.removeChatMember(chatId.value, userId);
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Removes the specified [User] from the [_call].
  Future<void> removeChatCallMember(UserId userId) async {
    try {
      await _callService.removeChatCallMember(chatId.value, userId);
    } on RemoveChatCallMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Adds the [User]s identified by the provided [UserId]s to this [chat].
  ///
  /// If this [chat] is a dialog, then transforms the [_call] into a
  /// [Chat]-group call.
  Future<void> addMembers(List<UserId> ids) async {
    status.value = RxStatus.loading();

    try {
      if (chat.value?.chat.value.isGroup ?? true) {
        List<Future> futures = ids
            .map((e) => _chatService.addChatMember(chatId.value, e))
            .toList();

        await Future.wait(futures);
      } else {
        await _callService.transformDialogCallIntoGroupCall(chatId.value, ids);
      }

      stage.value = ParticipantsFlowStage.participants;
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

  /// Redials by specified [UserId] who left or declined the ongoing [ChatCall].
  Future<void> redialChatCallMember(UserId memberId) async {
    try {
      await _callService.redialChatCallMember(chatId.value, memberId);
    } on RedialChatCallMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Fetches the [chat], or [pop]s, if it's `null`.
  Future<void> _fetchChat() async {
    chat.value = null;
    final FutureOr<RxChat?> fetched = _chatService.get(chatId.value);
    chat.value = fetched is RxChat? ? fetched : await fetched;

    if (chat.value == null) {
      MessagePopup.error('err_unknown_chat'.l10n);
      pop?.call();
    }
  }

  /// Invokes [pop].
  ///
  /// Intended to be used as a [BackButtonInterceptor] callback, thus returns
  /// `true` to intercept back button.
  bool _onBack(bool _, RouteInfo __) {
    pop?.call();
    return true;
  }
}
