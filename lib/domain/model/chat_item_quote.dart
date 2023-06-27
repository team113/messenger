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

import 'package:hive/hive.dart';

import '../model_type_id.dart';
import 'attachment.dart';
import 'chat_call.dart';
import 'chat_info.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_item_quote.g.dart';

/// Quote of a [ChatItem].
abstract class ChatItemQuote {
  const ChatItemQuote({
    this.original,
    required this.author,
    required this.at,
  });

  /// Constructs a [ChatItemQuote] from the provided [ChatItem].
  factory ChatItemQuote.from(ChatItem item) {
    if (item is ChatMessage) {
      return ChatMessageQuote(
        author: item.authorId,
        at: item.at,
        attachments: item.attachments,
        text: item.text,
        original: item,
      );
    } else if (item is ChatCall) {
      return ChatCallQuote(
        author: item.authorId,
        at: item.at,
        original: item,
      );
    } else if (item is ChatInfo) {
      return ChatInfoQuote(
        author: item.authorId,
        at: item.at,
        action: item.action,
        original: item,
      );
    } else if (item is ChatForward) {
      return item.quote;
    }

    throw Exception('$item is not supported to be quoted');
  }

  /// Quoted [ChatItem].
  ///
  /// `null` if the original [ChatItem] was deleted or is unavailable for the
  /// authenticated [MyUser].
  @HiveField(0)
  final ChatItem? original;

  /// [User] who created the quoted [ChatItem].
  @HiveField(1)
  final UserId author;

  /// [PreciseDateTime] when the quoted [ChatItem] was created.
  @HiveField(2)
  final PreciseDateTime at;
}

/// [ChatItemQuote] of a [ChatMessage].
@HiveType(typeId: ModelTypeId.chatMessageQuote)
class ChatMessageQuote extends ChatItemQuote {
  ChatMessageQuote({
    super.original,
    required super.author,
    required super.at,
    this.text,
    this.attachments = const [],
  });

  /// [ChatMessageText] the quoted [ChatMessage] had when this [ChatItemQuote]
  /// was made.
  @HiveField(3)
  final ChatMessageText? text;

  /// [Attachment]s the quoted [ChatMessage] had when this [ChatItemQuote] was
  /// made.
  @HiveField(4)
  final List<Attachment> attachments;
}

/// [ChatItemQuote] of a [ChatCall].
@HiveType(typeId: ModelTypeId.chatCallQuote)
class ChatCallQuote extends ChatItemQuote {
  ChatCallQuote({
    super.original,
    required super.author,
    required super.at,
  });
}

/// [ChatItemQuote] of a [ChatInfo].
@HiveType(typeId: ModelTypeId.chatInfoQuote)
class ChatInfoQuote extends ChatItemQuote {
  ChatInfoQuote({
    super.original,
    required super.author,
    required super.at,
    required this.action,
  });

  /// [ChatMessageText] the quoted [ChatMessage] had when this [ChatItemQuote]
  /// was made.
  @HiveField(3)
  final ChatInfoAction? action;
}
