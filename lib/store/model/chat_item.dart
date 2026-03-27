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

import '/domain/model/attachment.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/util/new_type.dart';
import 'chat_call.dart';
import 'version.dart';

part 'chat_item.g.dart';

/// Persisted in storage [ChatItem]'s [value].
abstract class DtoChatItem {
  DtoChatItem(this.value, this.cursor, this.ver);

  /// Constructs a [DtoChatItem] from the provided [json].
  factory DtoChatItem.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'DtoChatMessage' => DtoChatMessage.fromJson(json),
        'DtoChatCall' => DtoChatCall.fromJson(json),
        'DtoChatInfo' => DtoChatInfo.fromJson(json),
        'DtoChatForward' => DtoChatForward.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType']),
      };

  /// Persisted [ChatItem] model.
  ChatItem value;

  /// Cursor of a [ChatItem] this [DtoChatItem] represents.
  ChatItemsCursor? cursor;

  /// Version of a [ChatItem]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  final ChatItemVersion ver;

  @override
  int get hashCode => Object.hash(value, cursor, ver);

  @override
  bool operator ==(Object other) {
    return other is DtoChatItem &&
        cursor == other.cursor &&
        value == other.value &&
        ver == other.ver;
  }

  @override
  String toString() => '$runtimeType($value, $cursor, $ver)';

  /// Returns a [Map] representing this [DtoChatItem].
  Map<String, dynamic> toJson() => switch (runtimeType) {
    const (DtoChatMessage) => (this as DtoChatMessage).toJson(),
    const (DtoChatCall) => (this as DtoChatCall).toJson(),
    const (DtoChatInfo) => (this as DtoChatInfo).toJson(),
    const (DtoChatForward) => (this as DtoChatForward).toJson(),
    _ => throw UnimplementedError(runtimeType.toString()),
  };
}

/// Persisted in storage [ChatInfo]'s [value].
@JsonSerializable()
class DtoChatInfo extends DtoChatItem {
  DtoChatInfo(super.value, super.cursor, super.ver);

  @override
  int get hashCode => Object.hash(value, cursor, ver);

  @override
  bool operator ==(Object other) {
    return other is DtoChatInfo &&
        cursor == other.cursor &&
        value == other.value &&
        ver == other.ver;
  }

  /// Constructs a [DtoChatCall] from the provided [json].
  factory DtoChatInfo.fromJson(Map<String, dynamic> json) =>
      _$DtoChatInfoFromJson(json);

  /// Returns a [Map] representing this [DtoChatInfo].
  @override
  Map<String, dynamic> toJson() =>
      _$DtoChatInfoToJson(this)..['runtimeType'] = 'DtoChatInfo';
}

/// Persisted in storage [ChatMessage]'s [value].
@JsonSerializable()
class DtoChatMessage extends DtoChatItem {
  DtoChatMessage(super.value, super.cursor, super.ver, this.repliesToCursors);

  /// Constructs a [DtoChatMessage] in a [SendingStatus.sending] state.
  factory DtoChatMessage.sending({
    required ChatId chatId,
    required UserId me,
    ChatMessageText? text,
    List<ChatItemQuote> repliesTo = const [],
    List<Attachment> attachments = const [],
    ChatItemId? existingId,
    PreciseDateTime? existingDateTime,
  }) => DtoChatMessage(
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

  /// Constructs a [DtoChatMessage] from the provided [json].
  factory DtoChatMessage.fromJson(Map<String, dynamic> json) =>
      _$DtoChatMessageFromJson(json);

  /// Cursors of the [ChatMessage.repliesTo] list.
  List<ChatItemsCursor?>? repliesToCursors;

  @override
  int get hashCode => Object.hash(value, cursor, ver);

  @override
  bool operator ==(Object other) {
    return other is DtoChatMessage &&
        cursor == other.cursor &&
        value == other.value &&
        ver == other.ver;
  }

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

  /// Returns a [Map] representing this [DtoChatMessage].
  @override
  Map<String, dynamic> toJson() =>
      _$DtoChatMessageToJson(this)..['runtimeType'] = 'DtoChatMessage';
}

/// Persisted in storage [ChatForward]'s [value].
@JsonSerializable()
class DtoChatForward extends DtoChatItem {
  DtoChatForward(super.value, super.cursor, super.ver, this.quoteCursor);

  /// Constructs a [DtoChatForward] from the provided [json].
  factory DtoChatForward.fromJson(Map<String, dynamic> json) =>
      _$DtoChatForwardFromJson(json);

  /// Cursor of a [ChatForward.quote].
  ChatItemsCursor? quoteCursor;

  @override
  int get hashCode => Object.hash(value, cursor, ver);

  @override
  bool operator ==(Object other) {
    return other is DtoChatForward &&
        cursor == other.cursor &&
        value == other.value &&
        ver == other.ver;
  }

  /// Returns a [Map] representing this [DtoChatForward].
  @override
  Map<String, dynamic> toJson() =>
      _$DtoChatForwardToJson(this)..['runtimeType'] = 'DtoChatForward';
}

/// Persisted in storage [ChatItemQuote]'s [value].
class DtoChatItemQuote {
  DtoChatItemQuote(this.value, this.cursor);

  /// [ChatItemQuote] itself.
  final ChatItemQuote value;

  /// Cursor of a [ChatItemQuote.original].
  ChatItemsCursor? cursor;
}

/// Version of a [ChatItem]'s state.
class ChatItemVersion extends Version {
  ChatItemVersion(super.val);

  /// Constructs a [ChatItemVersion] from the provided [val].
  factory ChatItemVersion.fromJson(String val) = ChatItemVersion;

  /// Returns a [String] representing this [ChatItemVersion].
  String toJson() => val;
}

/// Cursor of a [ChatItem].
class ChatItemsCursor extends NewType<String> {
  const ChatItemsCursor(super.val);

  /// Constructs a [ChatItemsCursor] from the provided [val].
  factory ChatItemsCursor.fromJson(String val) = ChatItemsCursor;

  /// Returns a [String] representing this [ChatItemsCursor].
  String toJson() => val;
}
