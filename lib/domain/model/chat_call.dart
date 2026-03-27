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

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';

import '/api/backend/schema.dart';
import '/util/new_type.dart';
import 'chat.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_call.g.dart';

/// Call in a [Chat].
@JsonSerializable()
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
    this.dialed,
  });

  /// Constructs a [ChatCall] from the provided [json].
  factory ChatCall.fromJson(Map<String, dynamic> json) =>
      _$ChatCallFromJson(json);

  /// Indicator whether this [ChatCall] is intended to start with video.
  final bool withVideo;

  /// [ChatCallMember]s of this [ChatCall].
  List<ChatCallMember> members;

  /// [PreciseDateTime] when the actual conversation in this [ChatCall] was
  /// started (after ringing had been finished).
  PreciseDateTime? conversationStartedAt;

  /// [PreciseDateTime] when this [ChatCall] was finished.
  PreciseDateTime? finishedAt;

  /// Reason of why this [ChatCall] was finished.
  int? finishReasonIndex;

  /// [ChatMember]s being dialed by this [ChatCall] at the moment.
  ///
  /// To understand whether the authenticated [MyUser] is dialed by this
  /// [ChatCall] at the moment, check whether the
  /// [ChatMembersDialedConcrete.members] contain him or the
  /// [ChatMembersDialedAll.answeredMembers] do not while the [dialed] is not
  /// `null`.
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
  Map<String, dynamic> toJson() =>
      _$ChatCallToJson(this)..['runtimeType'] = 'ChatCall';

  @override
  bool operator ==(Object other) {
    return other is ChatCall &&
        id == other.id &&
        chatId == other.chatId &&
        author.id == other.author.id &&
        at == other.at &&
        const ListEquality().equals(members, other.members) &&
        withVideo == other.withVideo &&
        conversationStartedAt == other.conversationStartedAt &&
        finishReasonIndex == other.finishReasonIndex &&
        finishedAt == other.finishedAt &&
        dialed == other.dialed;
  }

  @override
  int get hashCode => Object.hash(
    id,
    chatId,
    author.id,
    at,
    members,
    withVideo,
    conversationStartedAt,
    finishReasonIndex,
    finishedAt,
    dialed,
  );
}

/// Member of a [ChatCall].
@JsonSerializable()
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
  final User user;

  /// Indicator whether this [ChatCallMember] raised a hand.
  bool handRaised;

  /// [PreciseDateTime] when this [ChatCallMember] joined the [ChatCall].
  final PreciseDateTime joinedAt;

  /// Returns a [Map] representing this [ChatCallMember].
  Map<String, dynamic> toJson() => _$ChatCallMemberToJson(this);

  @override
  bool operator ==(Object other) {
    return other is ChatCallMember &&
        user.id == other.user.id &&
        handRaised == other.handRaised &&
        joinedAt == other.joinedAt;
  }

  @override
  int get hashCode => Object.hash(user, handRaised, joinedAt);
}

/// One-time secret credentials to authenticate a [ChatCall] with on a media
/// server.
class ChatCallCredentials {
  ChatCallCredentials(this.val);

  /// Constructs the [ChatCallCredentials] from the provided [val].
  factory ChatCallCredentials.fromJson(String val) = ChatCallCredentials;

  /// Actual value of these [ChatCallCredentials].
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
class ChatCallRoomJoinLink extends NewType<String> {
  const ChatCallRoomJoinLink(super.val);

  /// Constructs a [ChatCallRoomJoinLink] from the provided [val].
  factory ChatCallRoomJoinLink.fromJson(String val) = ChatCallRoomJoinLink;

  /// Returns a [String] representing this [ChatCallRoomJoinLink].
  String toJson() => val;
}

/// ID of the device the authenticated [MyUser] starts a [ChatCall] from.
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
        'ChatMembersDialedConcrete' => ChatMembersDialedConcrete.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType']),
      };

  /// Returns a [Map] representing this [ChatMembersDialed].
  Map<String, dynamic> toJson() => switch (runtimeType) {
    const (ChatMembersDialedAll) => (this as ChatMembersDialedAll).toJson(),
    const (ChatMembersDialedConcrete) =>
      (this as ChatMembersDialedConcrete).toJson(),
    _ => throw UnimplementedError(runtimeType.toString()),
  };
}

/// Information about all [ChatMember]s of a [Chat] being dialed (or redialed)
/// by a [ChatCall].
@JsonSerializable()
class ChatMembersDialedAll implements ChatMembersDialed {
  const ChatMembersDialedAll(this.answeredMembers);

  /// Constructs a [ChatMembersDialedAll] from the provided [json].
  factory ChatMembersDialedAll.fromJson(Map<String, dynamic> json) =>
      _$ChatMembersDialedAllFromJson(json);

  /// [ChatMember]s who answered (joined or declined) the [ChatCall] already, so
  /// are not dialed anymore.
  final List<ChatMember> answeredMembers;

  /// Returns a [Map] representing this [ChatMembersDialedAll].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatMembersDialedAllToJson(this)
        ..['runtimeType'] = 'ChatMembersDialedAll';

  @override
  bool operator ==(Object other) {
    return other is ChatMembersDialedAll &&
        const ListEquality().equals(answeredMembers, other.answeredMembers);
  }

  @override
  int get hashCode => answeredMembers.hashCode;
}

/// Information about concrete [ChatMember]s of a [Chat] being dialed (or
/// redialed) by a [ChatCall].
@JsonSerializable()
class ChatMembersDialedConcrete implements ChatMembersDialed {
  const ChatMembersDialedConcrete(this.members);

  /// Constructs a [ChatMembersDialedConcrete] from the provided [json].
  factory ChatMembersDialedConcrete.fromJson(Map<String, dynamic> json) =>
      _$ChatMembersDialedConcreteFromJson(json);

  /// Concrete [ChatMember]s who are dialed (or redialed) by the [ChatCall].
  ///
  /// Guaranteed to be non-empty.
  final List<ChatMember> members;

  /// Returns a [Map] representing this [ChatMembersDialedConcrete].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatMembersDialedConcreteToJson(this)
        ..['runtimeType'] = 'ChatMembersDialedConcrete';

  @override
  bool operator ==(Object other) {
    return other is ChatMembersDialedConcrete &&
        const ListEquality().equals(members, other.members);
  }

  @override
  int get hashCode => members.hashCode;
}
