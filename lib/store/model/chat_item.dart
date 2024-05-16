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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'version.dart';

part 'chat_item.g.dart';

/// Persisted in [Hive] storage [ChatItem]'s [value].
abstract class DtoChatItem extends HiveObject {
  DtoChatItem(this.value, this.cursor, this.ver);

  /// Persisted [ChatItem] model.
  @HiveField(0)
  ChatItem value;

  /// Cursor of a [ChatItem] this [DtoChatItem] represents.
  @HiveField(1)
  ChatItemsCursor? cursor;

  /// Version of a [ChatItem]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(2)
  final ChatItemVersion ver;

  @override
  String toString() => '$runtimeType($value, $cursor, $ver)';
}

/// Persisted in [Hive] storage [ChatInfo]'s [value].
@HiveType(typeId: ModelTypeId.dtoChatInfo)
class DtoChatInfo extends DtoChatItem {
  DtoChatInfo(super.value, super.cursor, super.ver);
}

/// Persisted in [Hive] storage [ChatMessage]'s [value].
@HiveType(typeId: ModelTypeId.dtoChatMessage)
class DtoChatMessage extends DtoChatItem {
  DtoChatMessage(
    super.value,
    super.cursor,
    super.ver,
    this.repliesToCursors,
  );

  /// Constructs a [DtoChatMessage] in a [SendingStatus.sending] state.
  factory DtoChatMessage.sending({
    required ChatId chatId,
    required UserId me,
    ChatMessageText? text,
    List<ChatItemQuote> repliesTo = const [],
    List<Attachment> attachments = const [],
    ChatItemId? existingId,
    PreciseDateTime? existingDateTime,
  }) =>
      DtoChatMessage(
        ChatMessage(
          existingId ?? ChatItemId.local(),
          chatId,
          User(me, UserNum('1234123412341234')),
          existingDateTime ?? PreciseDateTime.now(),
          text: text,
          repliesTo: repliesTo,
          attachments: attachments,
          status: SendingStatus.sending,
        ),
        null,
        ChatItemVersion('0'),
        [],
      );

  /// Cursors of the [ChatMessage.repliesTo] list.
  @HiveField(3)
  List<ChatItemsCursor?>? repliesToCursors;

  /// Returns a copy of this [DtoChatMessage] with the provided parameters.
  DtoChatMessage copyWith({
    ChatItem? value,
    ChatItemsCursor? cursor,
    ChatItemVersion? ver,
    List<ChatItemsCursor?>? repliesToCursors,
  }) {
    return DtoChatMessage(
      value ?? this.value,
      cursor ?? this.cursor,
      ver ?? this.ver,
      repliesToCursors ?? this.repliesToCursors,
    );
  }
}

/// Persisted in [Hive] storage [ChatForward]'s [value].
@HiveType(typeId: ModelTypeId.dtoChatForward)
class DtoChatForward extends DtoChatItem {
  DtoChatForward(
    super.value,
    super.cursor,
    super.ver,
    this.quoteCursor,
  );

  /// Cursor of a [ChatForward.quote].
  @HiveField(3)
  ChatItemsCursor? quoteCursor;
}

/// Persisted in [Hive] storage [ChatItemQuote]'s [value].
class DtoChatItemQuote {
  DtoChatItemQuote(this.value, this.cursor);

  /// [ChatItemQuote] itself.
  @HiveField(0)
  final ChatItemQuote value;

  /// Cursor of a [ChatItemQuote.original].
  @HiveField(1)
  ChatItemsCursor? cursor;
}

/// Version of a [ChatItem]'s state.
@HiveType(typeId: ModelTypeId.chatItemVersion)
class ChatItemVersion extends Version {
  ChatItemVersion(super.val);
}

/// Cursor of a [ChatItem].
@HiveType(typeId: ModelTypeId.chatItemsCursor)
class ChatItemsCursor extends NewType<String> {
  const ChatItemsCursor(super.val);
}
