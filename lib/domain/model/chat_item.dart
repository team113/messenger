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

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../model_type_id.dart';
import '/util/new_type.dart';
import 'attachment.dart';
import 'chat.dart';
import 'chat_item_quote.dart';
import 'precise_date_time/precise_date_time.dart';
import 'sending_status.dart';
import 'user.dart';

part 'chat_item.g.dart';

/// Item posted in a [Chat] (its content).
abstract class ChatItem {
  ChatItem(
    this.id,
    this.chatId,
    this.authorId,
    this.at, {
    SendingStatus? status,
  }) : status = Rx(
            status ?? (id.isLocal ? SendingStatus.error : SendingStatus.sent));

  /// Unique ID of this [ChatItem].
  @HiveField(0)
  final ChatItemId id;

  /// ID of the [Chat] this [ChatItem] was posted in.
  @HiveField(1)
  final ChatId chatId;

  /// ID of the [User] who posted this [ChatItem].
  @HiveField(2)
  final UserId authorId;

  /// [PreciseDateTime] when this [ChatItem] was posted.
  @HiveField(3)
  PreciseDateTime at;

  /// [SendingStatus] of this [ChatItem].
  final Rx<SendingStatus> status;

  /// Returns number of microseconds since the "Unix epoch" till
  /// [PreciseDateTime] when this [ChatItem] was posted.
  String get timestamp => at.microsecondsSinceEpoch.toString();
}

/// Message in a [Chat].
@HiveType(typeId: ModelTypeId.chatMessage)
class ChatMessage extends ChatItem {
  ChatMessage(
    super.id,
    super.chatId,
    super.authorId,
    super.at, {
    super.status,
    this.repliesTo = const [],
    this.text,
    this.editedAt,
    this.attachments = const [],
  });

  /// [ChatItemQuote]s of the [ChatItem]s this [ChatMessage] replies to.
  @HiveField(5)
  final List<ChatItemQuote> repliesTo;

  /// Text of this [ChatMessage].
  @HiveField(6)
  ChatMessageText? text;

  /// [PreciseDateTime] when this [ChatMessage] was edited.
  @HiveField(7)
  PreciseDateTime? editedAt;

  /// [Attachment]s of this [ChatMessage].
  @HiveField(8)
  final List<Attachment> attachments;

  int? get donate {
    final index = text?.val.lastIndexOf('?donate=');
    if (index != null && index != -1) {
      return int.tryParse(text!.val.substring(index + 8, text!.val.length));
    }

    return null;
  }

  /// Indicates whether the [other] message shares the same [text], [repliesTo],
  /// [authorId], [chatId] and [attachments] as this [ChatMessage].
  bool isEquals(ChatMessage other) {
    return text == other.text &&
        repliesTo.every(
          (e) => other.repliesTo.any(
            (m) =>
                m.runtimeType == e.runtimeType &&
                m.at == e.at &&
                m.author == e.author &&
                m.original?.id == e.original?.id,
          ),
        ) &&
        authorId == other.authorId &&
        chatId == other.chatId &&
        attachments.every(
          (e) => other.attachments.any(
            (m) =>
                m.original.relativeRef == e.original.relativeRef &&
                m.filename == e.filename,
          ),
        );
  }
}

/// Quote of a [ChatItem] forwarded to some [Chat].
@HiveType(typeId: ModelTypeId.chatForward)
class ChatForward extends ChatItem {
  ChatForward(
    super.id,
    super.chatId,
    super.authorId,
    super.at, {
    required this.quote,
  });

  /// [ChatItemQuote] of the forwarded [ChatItem].
  ///
  /// Re-forwarding a [ChatForward] is indistinguishable from just forwarding
  /// its inner [ChatMessage] ([ChatItemQuote] depth will still be just 1).
  @HiveField(5)
  final ChatItemQuote quote;
}

/// Unique ID of a [ChatItem].
@HiveType(typeId: ModelTypeId.chatItemId)
class ChatItemId extends NewType<String> {
  const ChatItemId(String val) : super(val);

  /// Constructs a dummy [ChatItemId].
  factory ChatItemId.local() => ChatItemId('local_${const Uuid().v4()}');

  /// Indicates whether this [ChatItemId] is a dummy ID.
  bool get isLocal => val.startsWith('local_');
}

/// Text of a [ChatMessage].
@HiveType(typeId: ModelTypeId.chatMessageText)
class ChatMessageText extends NewType<String> {
  const ChatMessageText(String val) : super(val);

  /// Maximum allowed number of characters in this [ChatMessageText].
  static const int maxLength = 8192;

  /// Splits this [ChatMessageText] equally by the [maxLength] characters.
  List<ChatMessageText> split() {
    if (maxLength <= 0) {
      return [];
    }

    final List<String> chunks = [];

    int start = 0;
    int end = 1;

    while (end * maxLength <= val.length) {
      chunks.add(val.substring(maxLength * start++, maxLength * end++));
    }

    final bool isRestOfLine = val.length % maxLength != 0;
    if (isRestOfLine) {
      chunks.add(
        val.substring(
          maxLength * start,
          maxLength * start + val.length % maxLength,
        ),
      );
    }

    return chunks.map((e) => ChatMessageText(e)).toList();
  }
}
