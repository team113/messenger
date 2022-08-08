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

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/provider/gql/exceptions.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of the forward messages modal.
class ChatForwardController extends GetxController {
  ChatForwardController(
    this._chatService,
    this.fromId,
    this.forwardItem,
  );

  /// Reactive list of sorted [Chat]s.
  late final RxList<RxChat> chats;

  /// Selected chats to forward messages.
  final RxList<ChatId> selectedChats = RxList<ChatId>([]);

  /// Id of [Chat] from messages will forward.
  final ChatId fromId;

  /// Map of forwarded items.
  final ChatItemQuote forwardItem;

  /// State of a send forwarded messages field.
  late final TextFieldState sendForward;

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    chats = RxList<RxChat>(_chatService.chats.values.toList());
    _sortChats();

    sendForward = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) async {
        s.status.value = RxStatus.loading();
        s.editable.value = false;

        try {
          var futures = selectedChats.map(
            (e) => _chatService.forwardChatItem(
              fromId,
              e,
              forwardItem,
              text: s.text == '' ? null : ChatMessageText(s.text),
            ),
          );

          Future.wait(futures);
        } on ForwardChatItemsException catch (e) {
          MessagePopup.error(e);
        } catch (e) {
          MessagePopup.error(e);
          rethrow;
        } finally {
          s.unsubmit();
        }
      },
    );

    super.onInit();
  }

  /// Sorts the [chats] by the [Chat.updatedAt] and [Chat.currentCall] values.
  void _sortChats() {
    chats.sort((a, b) {
      if (a.chat.value.currentCall != null &&
          b.chat.value.currentCall == null) {
        return -1;
      } else if (a.chat.value.currentCall == null &&
          b.chat.value.currentCall != null) {
        return 1;
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });
  }
}
