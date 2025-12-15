// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '/util/log.dart';
import '/util/new_type.dart';
import 'attachment.dart';
import 'chat.dart';
import 'chat_call.dart';
import 'chat_info.dart';
import 'chat_item_quote.dart';
import 'precise_date_time/precise_date_time.dart';
import 'sending_status.dart';
import 'user.dart';

part 'chat_item.g.dart';

/// Item posted in a [Chat] (its content).
abstract class ChatItem {
  ChatItem(this.id, this.chatId, this.author, this.at, {SendingStatus? status})
    : status = Rx(
        status ?? (id.isLocal ? SendingStatus.error : SendingStatus.sent),
      );

  /// Constructs a [ChatItem] from the provided [json].
  factory ChatItem.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'ChatMessage' => ChatMessage.fromJson(json),
        'ChatCall' => ChatCall.fromJson(json),
        'ChatInfo' => ChatInfo.fromJson(json),
        'ChatForward' => ChatForward.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType']),
      };

  /// Unique ID of this [ChatItem].
  final ChatItemId id;

  /// ID of the [Chat] this [ChatItem] was posted in.
  ChatId chatId;

  /// [User] who posted this [ChatItem].
  final User author;

  /// [PreciseDateTime] when this [ChatItem] was posted.
  PreciseDateTime at;

  /// [SendingStatus] of this [ChatItem].
  @JsonKey(toJson: SendingStatusJson.toJson)
  final Rx<SendingStatus> status;

  /// Returns combined [at] and [id] unique identifier of this [ChatItem].
  ///
  /// Meant to be used as a key sorted by posting [DateTime] of this [ChatItem].
  ChatItemKey get key => ChatItemKey(at, id);

  @override
  String toString() => '$runtimeType($id, $chatId)';

  /// Returns a [Map] representing this [ChatItem].
  Map<String, dynamic> toJson() => switch (runtimeType) {
    const (ChatMessage) => (this as ChatMessage).toJson(),
    const (ChatCall) => (this as ChatCall).toJson(),
    const (ChatInfo) => (this as ChatInfo).toJson(),
    const (ChatForward) => (this as ChatForward).toJson(),
    _ => throw UnimplementedError(runtimeType.toString()),
  };
}

/// Message in a [Chat].
@JsonSerializable()
class ChatMessage extends ChatItem {
  ChatMessage(
    super.id,
    super.chatId,
    super.author,
    super.at, {
    super.status,
    this.repliesTo = const [],
    this.text,
    this.editedAt,
    this.attachments = const [],
  });

  /// Constructs a [ChatMessage] from the provided [json].
  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  /// [ChatItemQuote]s of the [ChatItem]s this [ChatMessage] replies to.
  List<ChatItemQuote> repliesTo;

  /// Text of this [ChatMessage].
  ChatMessageText? text;

  /// [PreciseDateTime] when this [ChatMessage] was edited.
  PreciseDateTime? editedAt;

  /// [Attachment]s of this [ChatMessage].
  List<Attachment> attachments;

  @override
  int get hashCode => Object.hash(id, text, author, chatId, attachments);

  /// Indicates whether the [other] message shares the same [text], [repliesTo],
  /// [author], [chatId] and [attachments] as this [ChatMessage].
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
        author.id == other.author.id &&
        chatId == other.chatId &&
        attachments.every(
          (e) => other.attachments.any(
            (m) =>
                m.original.relativeRef == e.original.relativeRef &&
                m.filename == e.filename,
          ),
        );
  }

  @override
  String toString() =>
      '$runtimeType($id, $chatId, text: ${text?.obscured}, attachments: $attachments)';

  /// Returns a [Map] representing this [ChatMessage].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatMessageToJson(this)..['runtimeType'] = 'ChatMessage';

  @override
  bool operator ==(Object other) {
    return other is ChatMessage &&
        id == other.id &&
        isEquals(other) &&
        status.value == other.status.value;
  }
}

/// Quote of a [ChatItem] forwarded to some [Chat].
@JsonSerializable()
class ChatForward extends ChatItem {
  ChatForward(
    super.id,
    super.chatId,
    super.author,
    super.at, {
    required this.quote,
  });

  /// Constructs a [ChatForward] from the provided [json].
  factory ChatForward.fromJson(Map<String, dynamic> json) =>
      _$ChatForwardFromJson(json);

  /// [ChatItemQuote] of the forwarded [ChatItem].
  ///
  /// Re-forwarding a [ChatForward] is indistinguishable from just forwarding
  /// its inner [ChatMessage] ([ChatItemQuote] depth will still be just 1).
  final ChatItemQuote quote;

  /// Returns a [Map] representing this [ChatForward].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatForwardToJson(this)..['runtimeType'] = 'ChatForward';
}

/// Unique ID of a [ChatItem].
class ChatItemId extends NewType<String> {
  const ChatItemId(super.val);

  /// Constructs a dummy [ChatItemId].
  factory ChatItemId.local() => ChatItemId('local.${const Uuid().v4()}');

  /// Constructs a [ChatItemId] from the provided [val].
  factory ChatItemId.fromJson(String val) = ChatItemId;

  /// Indicates whether this [ChatItemId] is a dummy ID.
  bool get isLocal => val.startsWith('local.');

  /// Returns a [String] representing this [ChatItemId].
  String toJson() => val;
}

/// Text of a [ChatMessage].
class ChatMessageText extends NewType<String> {
  const ChatMessageText(super.val);

  /// Constructs a [ChatMessageText] from the provided [val].
  factory ChatMessageText.fromJson(String val) = ChatMessageText;

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

  /// Returns a [String] representing this [ChatMessageText].
  String toJson() => val;
}

/// Combined [at] and [id] unique identifier of a [ChatItem].
class ChatItemKey implements Comparable<ChatItemKey> {
  const ChatItemKey(this.at, this.id);

  /// Constructs a [ChatItemKey] from the provided [String].
  factory ChatItemKey.fromString(String value) {
    final List<String> split = value.split('_');

    if (split.length != 2) {
      throw const FormatException('Invalid format');
    }

    return ChatItemKey(
      PreciseDateTime.fromMicrosecondsSinceEpoch(int.parse(split[0])),
      ChatItemId(split[1]),
    );
  }

  /// Constructs a [ChatItemKey] from the provided [val].
  factory ChatItemKey.fromJson(String val) = ChatItemKey.fromString;

  /// [ChatItemId] part of this [ChatItemKey].
  final ChatItemId id;

  /// [PreciseDateTime] part of this [ChatItemKey].
  final PreciseDateTime at;

  @override
  String toString() => '${at.microsecondsSinceEpoch}_$id';

  /// Returns a [String] representing this [ChatItemKey].
  String toJson() => toString();

  @override
  bool operator ==(Object other) =>
      other is ChatItemKey && id == other.id && at == other.at;

  @override
  int compareTo(ChatItemKey other) => toString().compareTo(other.toString());

  @override
  int get hashCode => Object.hash(id, at);
}
