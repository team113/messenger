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

import 'package:json_annotation/json_annotation.dart';

import 'attachment.dart';
import 'chat_call.dart';
import 'chat_info.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_item_quote.g.dart';

/// Quote of a [ChatItem].
abstract class ChatItemQuote {
  const ChatItemQuote({this.original, required this.author, required this.at});

  /// Constructs a [ChatItemQuote] from the provided [ChatItem].
  factory ChatItemQuote.from(ChatItem item) {
    if (item is ChatMessage) {
      return ChatMessageQuote(
        author: item.author.id,
        at: item.at,
        attachments: item.attachments,
        text: item.text,
        original: item,
      );
    } else if (item is ChatCall) {
      return ChatCallQuote(author: item.author.id, at: item.at, original: item);
    } else if (item is ChatInfo) {
      return ChatInfoQuote(
        author: item.author.id,
        at: item.at,
        action: item.action,
        original: item,
      );
    } else if (item is ChatForward) {
      return item.quote;
    }

    throw Exception('$item is not supported to be quoted');
  }

  /// Constructs a [ChatItemQuote] from the provided [json].
  factory ChatItemQuote.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'ChatMessageQuote' => ChatMessageQuote.fromJson(json),
        'ChatCallQuote' => ChatCallQuote.fromJson(json),
        'ChatInfoQuote' => ChatInfoQuote.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType']),
      };

  /// Quoted [ChatItem].
  ///
  /// `null` if the original [ChatItem] was deleted or is unavailable for the
  /// authenticated [MyUser].
  final ChatItem? original;

  /// [User] who created the quoted [ChatItem].
  final UserId author;

  /// [PreciseDateTime] when the quoted [ChatItem] was created.
  final PreciseDateTime at;

  /// Returns a [Map] representing this [ChatItemQuote].
  Map<String, dynamic> toJson() => switch (runtimeType) {
    const (ChatMessageQuote) => (this as ChatMessageQuote).toJson(),
    const (ChatCallQuote) => (this as ChatCallQuote).toJson(),
    const (ChatInfoQuote) => (this as ChatInfoQuote).toJson(),
    _ => throw UnimplementedError(runtimeType.toString()),
  };
}

/// [ChatItemQuote] of a [ChatMessage].
@JsonSerializable()
class ChatMessageQuote extends ChatItemQuote {
  ChatMessageQuote({
    super.original,
    required super.author,
    required super.at,
    this.text,
    this.attachments = const [],
  });

  /// Constructs a [ChatMessageQuote] from the provided [json].
  factory ChatMessageQuote.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageQuoteFromJson(json);

  /// [ChatMessageText] the quoted [ChatMessage] had when this [ChatItemQuote]
  /// was made.
  final ChatMessageText? text;

  /// [Attachment]s the quoted [ChatMessage] had when this [ChatItemQuote] was
  /// made.
  final List<Attachment> attachments;

  /// Returns a [Map] representing this [ChatMessageQuote].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatMessageQuoteToJson(this)..['runtimeType'] = 'ChatMessageQuote';
}

/// [ChatItemQuote] of a [ChatCall].
@JsonSerializable()
class ChatCallQuote extends ChatItemQuote {
  ChatCallQuote({super.original, required super.author, required super.at});

  /// Constructs a [ChatCallQuote] from the provided [json].
  factory ChatCallQuote.fromJson(Map<String, dynamic> json) =>
      _$ChatCallQuoteFromJson(json);

  /// Returns a [Map] representing this [ChatCallQuote].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatCallQuoteToJson(this)..['runtimeType'] = 'ChatCallQuote';
}

/// [ChatItemQuote] of a [ChatInfo].
@JsonSerializable()
class ChatInfoQuote extends ChatItemQuote {
  ChatInfoQuote({
    super.original,
    required super.author,
    required super.at,
    required this.action,
  });

  /// Constructs a [ChatInfoQuote] from the provided [json].
  factory ChatInfoQuote.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoQuoteFromJson(json);

  /// [ChatMessageText] the quoted [ChatMessage] had when this [ChatItemQuote]
  /// was made.
  final ChatInfoAction? action;

  /// Returns a [Map] representing this [ChatInfoQuote].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatInfoQuoteToJson(this)..['runtimeType'] = 'ChatInfoQuote';
}
