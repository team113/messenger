// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';

import '/api/backend/schema.graphql.dart' show AddChatMemberErrorCode;
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart' show AddChatMemberException;
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of an [AddChatMemberView].
class AddChatMemberController extends GetxController {
  AddChatMemberController(
    this.chatId,
    this._chatService,
    this._userService, {
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

  /// [Chat]s service adding members to the [chat].
  final ChatService _chatService;

  /// [UserService] fetching [User]s to display in [MessagePopup]s.
  final UserService _userService;

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
    super.onClose();
  }

  /// Adds the [User]s identified by the provided [UserId]s to this [chat].
  Future<void> addMembers(List<UserId> ids) async {
    status.value = RxStatus.loading();

    pop?.call();

    try {
      final Iterable<Future> futures = ids.map(
        (userId) => _chatService
            .addChatMember(chatId, userId)
            .onError<AddChatMemberException>((_, _) async {
              final FutureOr<RxUser?> userOrFuture = _userService.get(userId);
              final User? user =
                  (userOrFuture is RxUser? ? userOrFuture : await userOrFuture)
                      ?.user
                      .value;

              if (user != null) {
                MessagePopup.error(
                  'err_blocked_by'.l10nfmt({
                    'user': '${user.name ?? user.num}',
                  }),
                );
              }
            }, test: (e) => e.code == AddChatMemberErrorCode.blocked),
      );

      await Future.wait(futures);
    } on AddChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      status.value = RxStatus.empty();
    }
  }

  /// Fetches the [chat], or [pop]s, if it's `null`.
  Future<void> _fetchChat() async {
    chat.value = null;

    final FutureOr<RxChat?> fetched = _chatService.get(chatId);
    chat.value = fetched is RxChat? ? fetched : await fetched;

    if (chat.value == null) {
      MessagePopup.error('label_unknown_page'.l10n);
      pop?.call();
    }
  }
}
