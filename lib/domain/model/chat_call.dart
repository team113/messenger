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
import '/api/backend/schema.dart';
import '/util/new_type.dart';
import 'chat_item.dart';
import 'chat.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_call.g.dart';

/// Call in a [Chat].
@HiveType(typeId: ModelTypeId.chatCall)
class ChatCall extends ChatItem {
  ChatCall(
    super.id,
    super.chatId,
    super.authorId,
    super.at, {
    required this.caller,
    required this.members,
    required this.withVideo,
    this.conversationStartedAt,
    this.finishReasonIndex,
    this.finishedAt,
    this.joinLink,
    this.dialed,
  });

  /// [User] who started this [ChatCall].
  @HiveField(5)
  final User? caller;

  /// Indicator whether this [ChatCall] is intended to start with video.
  @HiveField(6)
  final bool withVideo;

  /// [ChatCallMember]s of this [ChatCall].
  @HiveField(7)
  List<ChatCallMember> members;

  /// Link for joining this [ChatCall]'s room on a media server.
  @HiveField(8)
  ChatCallRoomJoinLink? joinLink;

  /// [PreciseDateTime] when the actual conversation in this [ChatCall] was
  /// started (after ringing had been finished).
  @HiveField(9)
  PreciseDateTime? conversationStartedAt;

  /// [PreciseDateTime] when this [ChatCall] was finished.
  @HiveField(10)
  PreciseDateTime? finishedAt;

  /// Reason of why this [ChatCall] was finished.
  @HiveField(11)
  int? finishReasonIndex;

  ChatCallFinishReason? get finishReason => finishReasonIndex == null
      ? null
      : ChatCallFinishReason.values[finishReasonIndex!];
  set finishReason(ChatCallFinishReason? reason) {
    finishReasonIndex = reason?.index;
  }

  /// [ChatMember]s being dialed by this [ChatCall] at the moment.
  ///
  /// To understand whether the authenticated [MyUser] is dialed by this
  /// [ChatCall] at the moment, check whether the
  /// [ChatMembersDialedConcrete.members] contain him or the
  /// [ChatMembersDialedAll.answeredMembers] do not while the [dialed] is not
  /// `null`.
  @HiveField(12)
  final ChatMembersDialed? dialed;
}

/// Member of a [ChatCall].
@HiveType(typeId: ModelTypeId.chatCallMember)
class ChatCallMember {
  ChatCallMember({
    required this.user,
    required this.handRaised,
    required this.joinedAt,
  });

  /// [User] representing this [ChatCallMember].
  @HiveField(0)
  final User user;

  /// Indicator whether this [ChatCallMember] raised a hand.
  @HiveField(1)
  bool handRaised;

  /// [PreciseDateTime] when this [ChatCallMember] joined the [ChatCall].
  @HiveField(2)
  final PreciseDateTime joinedAt;
}

/// One-time secret credentials to authenticate a [ChatCall] with on a media
/// server.
@HiveType(typeId: ModelTypeId.chatCallCredentials)
class ChatCallCredentials extends HiveObject {
  ChatCallCredentials(this.val);

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
}

/// Link for joining a [ChatCall] room on a media server.
@HiveType(typeId: ModelTypeId.chatCallRoomJoinLink)
class ChatCallRoomJoinLink extends NewType<String> {
  const ChatCallRoomJoinLink(String val) : super(val);
}

/// ID of the device the authenticated [MyUser] starts a [ChatCall] from.
@HiveType(typeId: ModelTypeId.chatCallDeviceId)
class ChatCallDeviceId extends NewType<String> {
  const ChatCallDeviceId(String val) : super(val);
}

/// [ChatMember]s being dialed by a [ChatCall].
abstract class ChatMembersDialed {
  const ChatMembersDialed();
}

/// Information about all [ChatMember]s of a [Chat] being dialed (or redialed)
/// by a [ChatCall].
@HiveType(typeId: ModelTypeId.chatMembersDialedAll)
class ChatMembersDialedAll implements ChatMembersDialed {
  const ChatMembersDialedAll(this.answeredMembers);

  /// [ChatMember]s who answered (joined or declined) the [ChatCall] already, so
  /// are not dialed anymore.
  @HiveField(0)
  final List<ChatMember> answeredMembers;
}

/// Information about concrete [ChatMember]s of a [Chat] being dialed (or
/// redialed) by a [ChatCall].
@HiveType(typeId: ModelTypeId.chatMembersDialedConcrete)
class ChatMembersDialedConcrete implements ChatMembersDialed {
  const ChatMembersDialedConcrete(this.members);

  /// Concrete [ChatMember]s who are dialed (or redialed) by the [ChatCall].
  ///
  /// Guaranteed to be non-empty.
  @HiveField(0)
  final List<ChatMember> members;
}
