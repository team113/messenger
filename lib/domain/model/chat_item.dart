// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';
import 'dart:ui';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:messenger/l10n/l10n.dart';
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
    this.author,
    this.at, {
    SendingStatus? status,
  }) : status = Rx(
          status ?? (id.isLocal ? SendingStatus.error : SendingStatus.sent),
        );

  /// Unique ID of this [ChatItem].
  @HiveField(0)
  final ChatItemId id;

  /// ID of the [Chat] this [ChatItem] was posted in.
  @HiveField(1)
  ChatId chatId;

  /// [User] who posted this [ChatItem].
  @HiveField(2)
  final User author;

  /// [PreciseDateTime] when this [ChatItem] was posted.
  @HiveField(3)
  PreciseDateTime at;

  /// [SendingStatus] of this [ChatItem].
  final Rx<SendingStatus> status;

  /// Returns combined [at] and [id] unique identifier of this [ChatItem].
  ///
  /// Meant to be used as a key sorted by posting [DateTime] of this [ChatItem].
  ChatItemKey get key => ChatItemKey(at, id);

  bool get isCommand {
    if (this is! ChatMessage) {
      return false;
    }

    final msg = this as ChatMessage;
    return msg.text?.val.startsWith('/') == true;
  }

  @override
  String toString() => '$runtimeType($id, $chatId)';
}

/// Message in a [Chat].
@HiveType(typeId: ModelTypeId.chatMessage)
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

  /// [ChatItemQuote]s of the [ChatItem]s this [ChatMessage] replies to.
  @HiveField(5)
  List<ChatItemQuote> repliesTo;

  /// Text of this [ChatMessage].
  @HiveField(6)
  ChatMessageText? text;

  /// [PreciseDateTime] when this [ChatMessage] was edited.
  @HiveField(7)
  PreciseDateTime? editedAt;

  /// [Attachment]s of this [ChatMessage].
  @HiveField(8)
  List<Attachment> attachments;

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
}

/// Quote of a [ChatItem] forwarded to some [Chat].
@HiveType(typeId: ModelTypeId.chatForward)
class ChatForward extends ChatItem {
  ChatForward(
    super.id,
    super.chatId,
    super.author,
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
  const ChatItemId(super.val);

  /// Constructs a dummy [ChatItemId].
  factory ChatItemId.local() => ChatItemId('local.${const Uuid().v4()}');

  /// Indicates whether this [ChatItemId] is a dummy ID.
  bool get isLocal => val.startsWith('local.');
}

class ChatBotText {
  const ChatBotText({
    this.title,
    this.text,
    this.actions = const [],
  });

  final String? title;
  final String? text;
  final List<BotAction> actions;

  Map<String, dynamic> toMap() {
    return {
      if (title != null) 'title': title,
      if (text != null) 'text': text,
      if (actions.isNotEmpty)
        'actions':
            actions.map((e) => {'text': e.text, 'command': e.command}).toList(),
    };
  }
}

/// Text of a [ChatMessage].
@HiveType(typeId: ModelTypeId.chatMessageText)
class ChatMessageText extends NewType<String> {
  const ChatMessageText(super.val);

  factory ChatMessageText.bot({
    String? title,
    Map<Locale, ChatBotText> localized = const {},
    ChatBotText? text,
  }) {
    return ChatMessageText(
      '[@bot]${jsonEncode(
        {
          for (var e in localized.entries) ...{
            e.key.toLanguageTag(): e.value.toMap(),
          },
          ...text?.toMap() ?? {},
        },
      )}',
    );
  }

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

  /// [ChatItemId] part of this [ChatItemKey].
  final ChatItemId id;

  /// [PreciseDateTime] part of this [ChatItemKey].
  final PreciseDateTime at;

  @override
  String toString() => '${at.microsecondsSinceEpoch}_$id';

  @override
  bool operator ==(Object other) =>
      other is ChatItemKey && id == other.id && at == other.at;

  @override
  int compareTo(ChatItemKey other) => toString().compareTo(other.toString());

  @override
  int get hashCode => Object.hash(id, at);
}

/// Command in a [Chat].
class ChatCommand extends ChatItem {
  ChatCommand(
    super.id,
    super.chatId,
    super.author,
    super.at, {
    super.status,
    this.repliesTo,
    this.text,
  });

  @HiveField(5)
  ChatItemQuote? repliesTo;

  @HiveField(6)
  ChatMessageText? text;
}

/// Command in a [Chat].
class BotInfo extends ChatItem {
  BotInfo(
    super.id,
    super.chatId,
    super.author,
    super.at, {
    super.status,
    this.repliesTo,
    required this.title,
    this.text,
    this.actions,
  });

  static BotInfo? parse(ChatMessage msg) {
    if (msg.text?.val.startsWith('[@bot]') ?? false) {
      Map<String, dynamic>? decoded;

      try {
        decoded = jsonDecode(msg.text!.val.substring('[@bot]'.length));
      } catch (_) {
        // No-op.
      }

      if (decoded != null) {
        final title = decoded[L10n.chosen.value!.toString()]?['title'] ??
            decoded['title'];
        final text =
            decoded[L10n.chosen.value!.toString()]?['text'] ?? decoded['text'];
        final actions = decoded[L10n.chosen.value!.toString()]?['actions'] ??
            decoded['actions'];

        return BotInfo(
          msg.id,
          msg.chatId,
          msg.author,
          msg.at,
          text: text == null ? null : ChatMessageText(text),
          repliesTo: msg.repliesTo.firstOrNull,
          actions: (actions as List?)?.map((e) {
            return BotAction(text: e['text'], command: e['command']);
          }).toList(),
          title: title ?? 'Bot',
        );
      }
    }

    return null;
  }

  @HiveField(5)
  ChatItemQuote? repliesTo;

  @HiveField(6)
  ChatMessageText? text;

  @HiveField(7)
  List<BotAction>? actions;

  @HiveField(8)
  String title;
}

class BotAction {
  const BotAction({
    required this.text,
    required this.command,
  });

  @HiveField(0)
  final String text;

  @HiveField(1)
  final String command;
}
