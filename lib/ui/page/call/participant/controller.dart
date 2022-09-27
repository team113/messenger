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
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import 'view.dart';

export 'view.dart';

/// Possible [ParticipantView] flow stage.
enum SearchFlowStage {
  search,
  participants,
}

/// Controller of the call participants modal.
class ParticipantController extends GetxController {
  ParticipantController(
    this.pop,
    this._call,
    this._chatService, {
    Rx<ChatId>? chatId,
  })  : stage = _call != null
            ? Rx(SearchFlowStage.participants)
            : Rx(SearchFlowStage.search),
        _chatId = chatId ?? _call?.value.chatId;

  /// Reactive state of the [Chat] this modal is about.
  Rx<RxChat?> chat = Rx(null);

  /// Pops the [ParticipantView] this controller is bound to.
  final Function() pop;

  /// [SearchFlowStage] of this addition modal.
  final Rx<SearchFlowStage> stage;

  /// Status of an [submit] completion.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning no [submit] is executing.
  /// - `status.isLoading`, meaning [submit] is executing.
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  /// Worker for catching the [OngoingCallState.ended] state of the call to pop.
  Worker? _stateWorker;

  /// Worker performing a [_fetchChat] on [chatId] changes.
  Worker? _chatIdWorker;

  /// The [OngoingCall] that this modal is bound to.
  final Rx<OngoingCall>? _call;

  /// ID of the [Chat] this modal is bound to.
  final Rx<ChatId>? _chatId;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Subscription for the [ChatService.chats] changes.
  StreamSubscription? _chatsSubscription;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// ID of the [Chat] this modal is bound to.
  Rx<ChatId>? get chatId => _chatId;

  @override
  void onInit() {
    if (chatId != null) {
      _chatsSubscription = _chatService.chats.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            // No-op.
            break;

          case OperationKind.removed:
            if (e.key == chatId!.value) {
              pop();
            }
            break;

          case OperationKind.updated:
            // No-op.
            break;
        }
      });

      _chatIdWorker = ever(chatId!, (_) => _fetchChat());
    }

    if (_call != null) {
      _stateWorker = ever(_call!.value.state, (state) {
        if (state == OngoingCallState.ended) {
          pop();
        }
      });
    }

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
    _chatIdWorker?.dispose();
    super.onClose();
  }

  /// Calls the provided [callback] and closes this modal or changes stage to
  /// [SearchFlowStage.participants] if bound to an [OngoingCall].
  Future<void> submit(SubmitCallback callback, List<UserId> ids) async {
    status.value = RxStatus.loading();

    try {
      await callback(ids);

      if (_call != null) {
        stage.value = SearchFlowStage.participants;
      } else {
        pop();
      }
    } finally {
      status.value = RxStatus.empty();
    }
  }

  /// Fetches the [chat].
  void _fetchChat() async {
    if (chatId != null) {
      chat.value = null;
      chat.value = (await _chatService.get(chatId!.value));
      if (chat.value == null) {
        MessagePopup.error('err_unknown_chat'.l10n);
        pop();
      }
    }
  }
}
