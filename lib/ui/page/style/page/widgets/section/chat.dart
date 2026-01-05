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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../common/cat.dart';
import '../widget/headline.dart';
import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/file.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/chat_forward.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/page/chat/widget/notes_block.dart';
import '/ui/page/home/page/chat/widget/time_label.dart';
import '/ui/page/home/page/chat/widget/unread_label.dart';

/// [Routes.style] chat section.
class ChatSection {
  /// Returns the [Widget]s of this [ChatSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    // Returns a [ChatMessage] built locally with the provided parameters.
    ChatItem message({
      bool fromMe = true,
      SendingStatus status = SendingStatus.sent,
      String? text = 'Lorem ipsum',
      List<String> attachments = const [],
      List<ChatItemQuote> repliesTo = const [],
    }) {
      final NativeFile image = NativeFile(
        name: 'Image',
        size: 2,
        bytes: CatImage.bytes,
        dimensions: CatImage.size,
      );

      return ChatMessage(
        ChatItemId.local(),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        text: text == null ? null : ChatMessageText(text),
        attachments: attachments.map((e) {
          if (e == 'file') {
            return FileAttachment(
              id: AttachmentId.local(),
              original: PlainFile(relativeRef: '', size: 12300000),
              filename: 'Document.pdf',
            );
          } else {
            return LocalAttachment(image, status: SendingStatus.sent);
          }
        }).toList(),
        status: status,
        repliesTo: repliesTo,
      );
    }

    // Returns a [ChatInfo] built locally with the provided parameters.
    ChatItem info(ChatInfoAction action, {bool fromMe = true}) {
      return ChatInfo(
        ChatItemId.local(),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        action: action,
      );
    }

    // Returns a [ChatCall] built locally with the provided parameters.
    ChatItem call({
      bool fromMe = true,
      bool withVideo = false,
      bool started = false,
      int? finishReasonIndex,
    }) {
      return ChatCall(
        const ChatItemId('dwd'),
        ChatId.local(const UserId('me')),
        User(UserId(fromMe ? 'me' : '0'), UserNum('1234123412341234')),
        PreciseDateTime.now(),
        withVideo: withVideo,
        members: [],
        conversationStartedAt: started
            ? PreciseDateTime.now().subtract(const Duration(hours: 1))
            : null,
        finishReasonIndex: finishReasonIndex,
        finishedAt: finishReasonIndex == null ? null : PreciseDateTime.now(),
      );
    }

    // Returns a [ChatItemWidget] with the provided [ChatItem].
    Widget chatItem(
      ChatItem v, {
      bool delivered = false,
      bool read = false,
      ChatKind kind = ChatKind.dialog,
    }) {
      return ChatItemWidget(
        item: Rx(v),
        chat: Rx(
          Chat(
            ChatId.local(const UserId('me')),
            kindIndex: kind.index,
            lastDelivery: delivered
                ? null
                : PreciseDateTime.fromMicrosecondsSinceEpoch(0),
            lastReads: [
              if (read)
                LastChatRead(
                  const UserId('fqw'),
                  PreciseDateTime(DateTime(15000)),
                ),
            ],
          ),
        ),
        selectable: true,
        me: const UserId('me'),
        reads: [
          if (read)
            LastChatRead(const UserId('fqw'), PreciseDateTime(DateTime(15000))),
        ],
      );
    }

    /// Returns a [ChatForwardWidget] with the provided [ChatItem]s as forwards.
    Widget chatForward(
      List<ChatItem> v, {
      ChatItem? note,
      bool delivered = false,
      bool read = false,
      bool fromMe = true,
      ChatKind kind = ChatKind.dialog,
    }) {
      return ChatForwardWidget(
        forwards: RxList(
          v
              .map(
                (e) => Rx(
                  ChatForward(
                    e.id,
                    e.chatId,
                    e.author,
                    e.at,
                    quote: ChatItemQuote.from(e),
                  ),
                ),
              )
              .toList(),
        ),
        authorId: fromMe ? const UserId('me') : const UserId('0'),
        note: Rx(note == null ? null : Rx(note)),
        chat: Rx(
          Chat(
            ChatId.local(const UserId('me')),
            kindIndex: kind.index,
            lastDelivery: delivered
                ? null
                : PreciseDateTime.fromMicrosecondsSinceEpoch(0),
            lastReads: [
              if (read)
                LastChatRead(
                  const UserId('fqw'),
                  PreciseDateTime(DateTime(15000)),
                ),
            ],
          ),
        ),
        me: const UserId('me'),
        reads: [
          if (read)
            LastChatRead(const UserId('fqw'), PreciseDateTime(DateTime(15000))),
        ],
      );
    }

    return [
      Headline(
        headline: 'TimeLabelWidget',
        background: style.colors.onBackgroundOpacity7,
        child: Column(
          children: [
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(minutes: 10)),
            ),
            TimeLabelWidget(DateTime.now().subtract(const Duration(days: 1))),
            TimeLabelWidget(DateTime.now().subtract(const Duration(days: 7))),
            TimeLabelWidget(DateTime.now().subtract(const Duration(days: 64))),
            TimeLabelWidget(
              DateTime.now().subtract(const Duration(days: 365 * 4)),
            ),
          ],
        ),
      ),
      Headline(
        headline: 'UnreadLabel',
        background: style.colors.onBackgroundOpacity7,
        child: const Column(children: [UnreadLabel(123)]),
      ),
      Headline(
        headline: 'ChatItemWidget',
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
        background: style.colors.onBackgroundOpacity7,
        child: Column(
          children: [
            chatItem(
              message(
                status: SendingStatus.sending,
                text: 'Sending message...',
              ),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.error, text: 'Error'),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent, text: 'Sent message'),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent, text: 'Delivered message'),
              kind: ChatKind.dialog,
              delivered: true,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(status: SendingStatus.sent, text: 'Read message'),
              kind: ChatKind.dialog,
              read: true,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Received message',
                fromMe: false,
              ),
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Replies.
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Sent reply',
                fromMe: true,
                repliesTo: [
                  ChatMessageQuote(
                    author: const UserId('me'),
                    at: PreciseDateTime.now(),
                    text: const ChatMessageText('Replied message'),
                  ),
                ],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Received reply',
                fromMe: false,
                repliesTo: [
                  ChatMessageQuote(
                    author: const UserId('me'),
                    at: PreciseDateTime.now(),
                    text: const ChatMessageText('Replied message'),
                  ),
                ],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Image attachments.
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: true,
                attachments: ['image'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: false,
                attachments: ['image'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // File attachments.
            chatItem(
              message(
                status: SendingStatus.sent,
                text: 'Message with file attachment',
                fromMe: true,
                attachments: ['file'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: false,
                attachments: ['file'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Images attachments.
            chatItem(
              message(
                status: SendingStatus.sent,
                fromMe: true,
                attachments: [
                  'file',
                  'file',
                  'image',
                  'image',
                  'image',
                  'image',
                  'image',
                ],
                text: 'Message with file and image attachments',
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),
            chatItem(
              message(
                status: SendingStatus.sent,
                text: null,
                fromMe: false,
                attachments: ['file', 'file', 'image', 'image', 'image'],
              ),
              read: true,
              kind: ChatKind.dialog,
            ),
            const SizedBox(height: 8),

            // Info.
            const SizedBox(height: 8),
            chatItem(info(const ChatInfoActionCreated(null))),
            const SizedBox(height: 8),
            chatItem(
              info(
                ChatInfoActionMemberAdded(
                  User(
                    const UserId('me'),
                    UserNum('1234123412341234'),
                    name: UserName('added'),
                  ),
                  null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            chatItem(
              info(
                ChatInfoActionMemberAdded(
                  User(
                    const UserId('me'),
                    UserNum('1234123412341234'),
                    name: UserName('User'),
                  ),
                  null,
                ),
                fromMe: false,
              ),
            ),
            const SizedBox(height: 8),

            // Call.
            chatItem(call(withVideo: true), read: true),
            const SizedBox(height: 8),
            chatItem(call(withVideo: true, fromMe: false), read: true),
            const SizedBox(height: 8),
            chatItem(call(started: true), read: true),
            const SizedBox(height: 8),
            chatItem(call(started: true, fromMe: false), read: true),
            const SizedBox(height: 8),
            chatItem(call(finishReasonIndex: 2, started: true), read: true),
            const SizedBox(height: 8),
            chatItem(
              call(finishReasonIndex: 2, started: true, fromMe: false),
              read: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      Headline(
        headline: 'ChatForwardWidget',
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
        background: style.colors.onBackgroundOpacity7,
        child: Column(
          children: [
            const SizedBox(height: 32),
            chatForward(
              [message(text: 'Forwarded message')],
              read: true,
              note: message(text: 'Comment'),
            ),
            const SizedBox(height: 8),
            chatForward(
              [message(text: 'Forwarded message')],
              read: true,
              fromMe: false,
              note: message(text: 'Comment'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      Headline(
        headline: 'NotesBlock',
        background: style.colors.onBackgroundOpacity7,
        child: const Column(children: [NotesBlock()]),
      ),
    ];
  }
}
