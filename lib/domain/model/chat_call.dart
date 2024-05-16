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
import 'package:json_annotation/json_annotation.dart';

import '../model_type_id.dart';
import '/api/backend/schema.dart';
import '/util/new_type.dart';
import 'chat.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_call.g.dart';

/// Call in a [Chat].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatCall)
class ChatCall extends ChatItem {
  ChatCall(
    super.id,
    super.chatId,
    super.author,
    super.at, {
    required this.members,
    required this.withVideo,
    this.conversationStartedAt,
    this.finishReasonIndex,
    this.finishedAt,
    this.joinLink,
    this.dialed,
  });

  /// Constructs a [ChatCall] from the provided [json].
  factory ChatCall.fromJson(Map<String, dynamic> json) =>
      _$ChatCallFromJson(json);

  /// Indicator whether this [ChatCall] is intended to start with video.
  @HiveField(5)
  final bool withVideo;

  /// [ChatCallMember]s of this [ChatCall].
  @HiveField(6)
  List<ChatCallMember> members;

  /// Link for joining this [ChatCall]'s room on a media server.
  @HiveField(7)
  ChatCallRoomJoinLink? joinLink;

  /// [PreciseDateTime] when the actual conversation in this [ChatCall] was
  /// started (after ringing had been finished).
  @HiveField(8)
  PreciseDateTime? conversationStartedAt;

  /// [PreciseDateTime] when this [ChatCall] was finished.
  @HiveField(9)
  PreciseDateTime? finishedAt;

  /// Reason of why this [ChatCall] was finished.
  @HiveField(10)
  int? finishReasonIndex;

  /// [ChatMember]s being dialed by this [ChatCall] at the moment.
  ///
  /// To understand whether the authenticated [MyUser] is dialed by this
  /// [ChatCall] at the moment, check whether the
  /// [ChatMembersDialedConcrete.members] contain him or the
  /// [ChatMembersDialedAll.answeredMembers] do not while the [dialed] is not
  /// `null`.
  @HiveField(11)
  ChatMembersDialed? dialed;

  /// Returns the [ChatCallFinishReason] this [ChatCall] finished with, if any.
  ChatCallFinishReason? get finishReason => finishReasonIndex == null
      ? null
      : ChatCallFinishReason.values[finishReasonIndex!];

  /// Sets the [ChatCallFinishReason] of this [ChatCall] to the [reason].
  set finishReason(ChatCallFinishReason? reason) {
    finishReasonIndex = reason?.index;
  }

  /// Returns a [Map] representing this [ChatCall].
  @override
  Map<String, dynamic> toJson() => _$ChatCallToJson(this);
}

/// Member of a [ChatCall].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatCallMember)
class ChatCallMember {
  ChatCallMember({
    required this.user,
    required this.handRaised,
    required this.joinedAt,
  });

  /// Constructs a [ChatCallMember] from the provided [json].
  factory ChatCallMember.fromJson(Map<String, dynamic> json) =>
      _$ChatCallMemberFromJson(json);

  /// [User] representing this [ChatCallMember].
  @HiveField(0)
  final User user;

  /// Indicator whether this [ChatCallMember] raised a hand.
  @HiveField(1)
  bool handRaised;

  /// [PreciseDateTime] when this [ChatCallMember] joined the [ChatCall].
  @HiveField(2)
  final PreciseDateTime joinedAt;

  /// Returns a [Map] representing this [ChatCallMember].
  Map<String, dynamic> toJson() => _$ChatCallMemberToJson(this);
}

/// One-time secret credentials to authenticate a [ChatCall] with on a media
/// server.
@HiveType(typeId: ModelTypeId.chatCallCredentials)
class ChatCallCredentials extends HiveObject {
  ChatCallCredentials(this.val);

  /// Constructs the [ChatCallCredentials] from the provided [val].
  factory ChatCallCredentials.fromJson(String val) = ChatCallCredentials;

  /// Actual value of these [ChatCallCredentials].
  @HiveField(0)
  final String val;

  @override
  int get hashCode => val.hashCode;

  @override
  String toString() => val.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatCallCredentials && val == other.val;

  /// Returns a copy of these [ChatCallCredentials] with the given [val].
  ChatCallCredentials copyWith({String? val}) =>
      ChatCallCredentials(val ?? this.val);

  /// Returns a [String] representing these [ChatCallCredentials].
  String toJson() => val;
}

/// Link for joining a [ChatCall] room on a media server.
@HiveType(typeId: ModelTypeId.chatCallRoomJoinLink)
class ChatCallRoomJoinLink extends NewType<String> {
  const ChatCallRoomJoinLink(super.val);

  /// Constructs a [ChatCallRoomJoinLink] from the provided [val].
  factory ChatCallRoomJoinLink.fromJson(String val) = ChatCallRoomJoinLink;

  /// Returns a [String] representing this [ChatCallRoomJoinLink].
  String toJson() => val;
}

/// ID of the device the authenticated [MyUser] starts a [ChatCall] from.
@HiveType(typeId: ModelTypeId.chatCallDeviceId)
class ChatCallDeviceId extends NewType<String> {
  const ChatCallDeviceId(super.val);

  /// Constructs a [ChatCallDeviceId] from the provided [val].
  factory ChatCallDeviceId.fromJson(String val) = ChatCallDeviceId;

  /// Returns a [String] representing this [ChatCallDeviceId].
  String toJson() => val;
}

/// [ChatMember]s being dialed by a [ChatCall].
abstract class ChatMembersDialed {
  const ChatMembersDialed();

  /// Constructs a [ChatMembersDialed] from the provided [json].
  factory ChatMembersDialed.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'ChatMembersDialedAll' => ChatMembersDialedAll.fromJson(json),
        'ChatMembersDialedAll' => ChatMembersDialedAll.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType'])
      };

  /// Returns a [Map] representing this [ChatMembersDialed].
  Map<String, dynamic> toJson() => switch (runtimeType) {
        const (ChatMembersDialedAll) => (this as ChatMembersDialedAll).toJson(),
        const (ChatMembersDialedAll) => (this as ChatMembersDialedAll).toJson(),
        _ => throw UnimplementedError(runtimeType.toString()),
      };
}

/// Information about all [ChatMember]s of a [Chat] being dialed (or redialed)
/// by a [ChatCall].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatMembersDialedAll)
class ChatMembersDialedAll implements ChatMembersDialed {
  const ChatMembersDialedAll(this.answeredMembers);

  /// Constructs a [ChatMembersDialedAll] from the provided [json].
  factory ChatMembersDialedAll.fromJson(Map<String, dynamic> json) =>
      _$ChatMembersDialedAllFromJson(json);

  /// [ChatMember]s who answered (joined or declined) the [ChatCall] already, so
  /// are not dialed anymore.
  @HiveField(0)
  final List<ChatMember> answeredMembers;

  /// Returns a [Map] representing this [ChatMembersDialedAll].
  @override
  Map<String, dynamic> toJson() => _$ChatMembersDialedAllToJson(this)
    ..['runtimeType'] = 'ChatMembersDialedAll';
}

/// Information about concrete [ChatMember]s of a [Chat] being dialed (or
/// redialed) by a [ChatCall].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatMembersDialedConcrete)
class ChatMembersDialedConcrete implements ChatMembersDialed {
  const ChatMembersDialedConcrete(this.members);

  /// Constructs a [ChatMembersDialedConcrete] from the provided [json].
  factory ChatMembersDialedConcrete.fromJson(Map<String, dynamic> json) =>
      _$ChatMembersDialedConcreteFromJson(json);

  /// Concrete [ChatMember]s who are dialed (or redialed) by the [ChatCall].
  ///
  /// Guaranteed to be non-empty.
  @HiveField(0)
  final List<ChatMember> members;

  /// Returns a [Map] representing this [ChatMembersDialedConcrete].
  @override
  Map<String, dynamic> toJson() => _$ChatMembersDialedConcreteToJson(this)
    ..['runtimeType'] = 'ChatMembersDialedConcrete';
}
