// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import '/api/backend/schema.dart' show ChatMemberInfoAction;
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/util/obs/obs.dart';

/// Worker responsible for showing a new [Chat] message notification.
class ChatWorker extends DisposableService {
  ChatWorker(
    this._chatService,
    this._myUserService,
    this._notificationService,
  );

  /// [ChatService], used to get the [Chat]s list.
  final ChatService _chatService;

  /// [MyUserService] used to getting [MyUser.muted] status.
  final MyUserService _myUserService;

  /// [NotificationService], used to show a new [Chat] message notification.
  final NotificationService _notificationService;

  /// [Duration] indicating whether the difference between [ChatItem.at] and
  /// [DateTime.now] is small enough to show a new message notification.
  static const Duration newMessageThreshold = Duration(seconds: 30);

  /// Subscription to the [ChatService.chats] map.
  late final StreamSubscription _subscription;

  /// [Map] of [_ChatWatchData]s, used to react on the [Chat] changes.
  final Map<ChatId, _ChatWatchData> _chats = {};

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get _myUser => _myUserService.myUser;

  @override
  void onReady() {
    _chatService.chats.forEach((_, value) => _onChatAdded(value));
    _subscription = _chatService.chats.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          _onChatAdded(event.value!, true);
          break;

        case OperationKind.removed:
          _chats.remove(event.key)?.dispose();
          break;

        default:
          break;
      }
    });

    super.onReady();
  }

  @override
  void onClose() {
    _subscription.cancel();
    _chats.forEach((_, value) => value.dispose());
    super.onClose();
  }

  /// Reacts to the provided [Chat] being added and populates the [Worker] to
  /// react on its [Chat.lastItem] changes to show a notification.
  void _onChatAdded(RxChat c, [bool viaSubscription = false]) {
    // Display a new group chat notification.
    if (viaSubscription && c.chat.value.isGroup) {
      bool newChat = false;

      if (c.chat.value.lastItem is ChatMemberInfo) {
        var msg = c.chat.value.lastItem as ChatMemberInfo;
        newChat = msg.action == ChatMemberInfoAction.added &&
            msg.user.id == _chatService.me &&
            DateTime.now()
                    .difference(msg.at.val)
                    .compareTo(newMessageThreshold) <=
                -1;
      } else if (c.chat.value.lastItem == null) {
        // The chat was created just now.
        newChat = DateTime.now()
                .difference(c.chat.value.updatedAt.val)
                .compareTo(newMessageThreshold) <=
            -1;
      }

      if (newChat) {
        if (_myUser.value?.muted == null) {
          _notificationService.show(
            c.title.value,
            body: 'label_you_were_added_to_group'.l10n,
            payload: '${Routes.chat}/${c.chat.value.id}',
            icon: c.avatar.value?.original.url,
            tag: c.chat.value.id.val,
          );
        }
      }
    }

    _chats[c.chat.value.id] ??= _ChatWatchData(
      c.chat,
      onNotification: (body, tag) async {
        if (_myUser.value?.muted == null) {
          await _notificationService.show(
            c.title.value,
            body: body,
            payload: '${Routes.chat}/${c.chat.value.id}',
            icon: c.avatar.value?.original.url,
            tag: tag,
          );
        }
      },
      me: () => _chatService.me,
    );
  }
}

/// Container of data, used to show a notification on the [Chat.lastItem]
/// updates.
class _ChatWatchData {
  _ChatWatchData(
    Rx<Chat> c, {
    void Function(String, String?)? onNotification,
    UserId? Function()? me,
  }) : updatedAt = c.value.lastItem?.at ?? PreciseDateTime.now() {
    worker = ever(
      c,
      (Chat chat) {
        if (chat.lastItem != null) {
          if (chat.lastItem!.at.isAfter(updatedAt) &&
              DateTime.now()
                      .difference(chat.lastItem!.at.val)
                      .compareTo(ChatWorker.newMessageThreshold) <=
                  -1 &&
              chat.lastItem!.authorId != me?.call() &&
              chat.muted == null) {
            final StringBuffer body = StringBuffer();

            if (chat.lastItem is ChatMessage) {
              var msg = chat.lastItem as ChatMessage;
              if (msg.text != null) {
                body.write(msg.text?.val);
                if (msg.attachments.isNotEmpty) {
                  body.write('\n');
                }
              }

              if (msg.attachments.isNotEmpty) {
                body.write(
                  'label_attachments'
                      .l10nfmt({'count': msg.attachments.length}),
                );
              }
            } else if (chat.lastItem is ChatMemberInfo) {
              final ChatMemberInfo msg = chat.lastItem as ChatMemberInfo;

              switch (msg.action) {
                case ChatMemberInfoAction.created:
                  // No-op, as it shouldn't be in a notification.
                  break;

                case ChatMemberInfoAction.added:
                  body.write(
                    'label_was_added'
                        .l10nfmt({'who': '${msg.user.name ?? msg.user.num}'}),
                  );
                  break;

                case ChatMemberInfoAction.removed:
                  body.write(
                    'label_was_removed'
                        .l10nfmt({'who': '${msg.user.name ?? msg.user.num}'}),
                  );
                  break;

                case ChatMemberInfoAction.artemisUnknown:
                  body.write(msg.action.toString());
                  break;
              }
            } else if (chat.lastItem is ChatForward) {
              body.write('label_forwarded_message'.l10n);
            }

            if (body.isNotEmpty) {
              onNotification?.call(body.toString(), chat.lastItem?.id.val);
            }
          }

          updatedAt = chat.lastItem!.at;
        }
      },
    );
  }

  /// [Worker] to react on the [Chat] updates.
  late final Worker worker;

  /// [PreciseDateTime] the [Chat.lastItem] was updated at.
  PreciseDateTime updatedAt;

  /// Disposes the [worker].
  void dispose() {
    worker.dispose();
  }
}
