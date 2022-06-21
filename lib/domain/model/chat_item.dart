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

import 'package:hive/hive.dart';

import '../model_type_id.dart';
import '/api/backend/schema.dart' show ChatItemQuoteInput, ChatMemberInfoAction;
import '/util/new_type.dart';
import 'attachment.dart';
import 'chat.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_item.g.dart';

/// Item posted in a [Chat] (its content).
abstract class ChatItem {
  ChatItem(this.id, this.chatId, this.authorId, this.at);

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

  /// Returns number of microseconds since the "Unix epoch" till
  /// [PreciseDateTime] when this [ChatItem] was posted.
  String get timestamp => at.microsecondsSinceEpoch.toString();
}

/// Information about an action taken upon a [ChatMember].
@HiveType(typeId: ModelTypeId.chatMemberInfo)
class ChatMemberInfo extends ChatItem {
  ChatMemberInfo(
    ChatItemId id,
    ChatId chatId,
    UserId authorId,
    PreciseDateTime at, {
    required this.user,
    required this.actionIndex,
  }) : super(id, chatId, authorId, at);

  /// [User] this [ChatMemberInfo] is about.
  @HiveField(5)
  final User user;

  /// Action taken upon the [ChatMember].
  @HiveField(6)
  final int actionIndex;

  ChatMemberInfoAction get action => ChatMemberInfoAction.values[actionIndex];
}

/// Message in a [Chat].
@HiveType(typeId: ModelTypeId.chatMessage)
class ChatMessage extends ChatItem {
  ChatMessage(
    ChatItemId id,
    ChatId chatId,
    UserId authorId,
    PreciseDateTime at, {
    this.repliesTo,
    this.text,
    this.editedAt,
    this.attachments = const [],
  }) : super(id, chatId, authorId, at);

  /// Quote of the [ChatItem] this [ChatMessage] replies to.
  @HiveField(5)
  ChatItem? repliesTo;

  /// Text of this [ChatMessage].
  @HiveField(6)
  ChatMessageText? text;

  /// ID of the [Chat] this [ChatItem] was posted in.
  @HiveField(7)
  PreciseDateTime? editedAt;

  /// [Attachment]s of this [ChatMessage].
  @HiveField(8)
  List<Attachment> attachments;
}

/// Quote of a [ChatItem] forwarded to some [Chat].
@HiveType(typeId: ModelTypeId.chatForward)
class ChatForward extends ChatItem {
  ChatForward(
    ChatItemId id,
    ChatId chatId,
    UserId authorId,
    PreciseDateTime at, {
    this.item,
  }) : super(id, chatId, authorId, at);

  /// Forwarded [ChatItem].
  @HiveField(5)
  ChatItem? item;
}

/// Unique ID of a [ChatItem].
@HiveType(typeId: ModelTypeId.chatItemId)
class ChatItemId extends NewType<String> {
  const ChatItemId(String val) : super(val);
}

/// Text of a [ChatMessage].
@HiveType(typeId: ModelTypeId.chatMessageText)
class ChatMessageText extends NewType<String> {
  const ChatMessageText(String val) : super(val);
}

/// Quote of the [ChatItem] to be forwarded.
class ChatItemQuote {
  ChatItemQuote({
    required this.item,
    required this.withText,
    required this.attachments,
  });

  /// ID of the [ChatItem] to be forwarded.
  final ChatItem item;

  /// Indicator whether a forward should contain the full [ChatMessageText] of
  /// the original [ChatItem] (if it contains any).
  final bool withText;

  /// IDs of the [ChatItem]'s Attachments to be forwarded.
  ///
  /// If no [Attachment]s are provided, then [ChatForward] will only contain a
  /// [ChatMessageText].
  final List<AttachmentId> attachments;

  /// Returns [ChatItemQuoteInput].
  ChatItemQuoteInput get quote => ChatItemQuoteInput(
        id: item.id,
        attachments: attachments,
        withText: withText,
      );
}
