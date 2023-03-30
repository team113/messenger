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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../model_type_id.dart';
import '/api/backend/schema.dart' show ChatKind;
import '/util/new_type.dart';
import 'avatar.dart';
import 'chat_call.dart';
import 'chat_item.dart';
import 'mute_duration.dart';
import 'my_user.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user_call_cover.dart';
import 'user.dart';

part 'chat.g.dart';

/// [Chat] is a conversation between [User]s.
@HiveType(typeId: ModelTypeId.chat)
class Chat extends HiveObject {
  Chat(
    this.id, {
    this.avatar,
    this.name,
    this.members = const [],
    this.kindIndex = 0,
    this.isHidden = false,
    this.muted,
    this.directLink,
    PreciseDateTime? createdAt,
    PreciseDateTime? updatedAt,
    this.lastReads = const [],
    PreciseDateTime? lastDelivery,
    this.lastItem,
    this.lastReadItem,
    this.unreadCount = 0,
    this.totalCount = 0,
    this.ongoingCall,
    this.favoritePosition,
  })  : createdAt = createdAt ?? PreciseDateTime.now(),
        updatedAt = updatedAt ?? PreciseDateTime.now(),
        lastDelivery = lastDelivery ?? PreciseDateTime.now();

  /// Unique ID of this [Chat].
  @HiveField(0)
  ChatId id;

  /// Avatar of this [Chat].
  @HiveField(1)
  ChatAvatar? avatar;

  /// Name of this [Chat].
  ///
  /// Only [Chat]-group can have a name.
  @HiveField(2)
  ChatName? name;

  /// [ChatMember]s of this [Chat].
  @HiveField(3)
  List<ChatMember> members;

  /// Kind of this [Chat].
  @HiveField(4)
  int kindIndex;

  ChatKind get kind => ChatKind.values[kindIndex];
  set kind(ChatKind chatKind) {
    kindIndex = chatKind.index;
  }

  /// Indicator whether this [Chat] is hidden by the authenticated [MyUser].
  @HiveField(5)
  bool isHidden;

  /// Mute condition of this [Chat] for the authenticated [MyUser].
  ///
  /// Muted [Chat] implies that its events don't produce sounds and
  /// notifications on a client side. This, however, has nothing to do with a
  /// server and is the responsibility to be satisfied by a client side.
  ///
  /// Note, that [Chat.muted] doesn't correlate with [MyUser.muted]. Muted
  /// [Chat] of unmuted [MyUser] (and unmuted [Chat] of muted [MyUser]) should
  /// not produce any sounds.
  @HiveField(6)
  MuteDuration? muted;

  /// [ChatDirectLink] to this [Chat].
  @HiveField(7)
  ChatDirectLink? directLink;

  /// [PreciseDateTime] when this [Chat] was created.
  @HiveField(8)
  PreciseDateTime createdAt;

  /// [PreciseDateTime] when the last [ChatItem] was posted.
  @HiveField(9)
  PreciseDateTime updatedAt;

  /// List of this [Chat]'s members which have read it, along with the
  /// corresponding [LastChatRead]s.
  @HiveField(10)
  List<LastChatRead> lastReads;

  /// [PreciseDateTime] when the last [ChatItem] posted by the authenticated
  /// [MyUser] was delivered.
  @HiveField(11)
  PreciseDateTime lastDelivery;

  /// Last [ChatItem] posted in this [Chat].
  ///
  /// If [Chat] has no visible [ChatItem]s for the authenticated [MyUser], then
  /// it's `null`.
  @HiveField(12)
  ChatItem? lastItem;

  /// Last [ChatItem] read by the authenticated [MyUser] in this [Chat].
  ///
  /// If [Chat] hasn't been read yet, or has no visible [ChatItem]s for the
  /// authenticated [MyUser], then it's `null`.
  @HiveField(13)
  ChatItem? lastReadItem;

  /// Count of [ChatItem]s unread by the authenticated [MyUser] in this [Chat].
  @HiveField(14)
  int unreadCount;

  /// Count of [ChatItem]s visible to the authenticated [MyUser] in this [Chat].
  @HiveField(15)
  int totalCount;

  /// Current ongoing [ChatCall] of this [Chat], if any.
  @HiveField(16)
  ChatCall? ongoingCall;

  /// Position of this [Chat] in the favorites list of the authenticated
  /// [MyUser].
  @HiveField(17)
  ChatFavoritePosition? favoritePosition;

  /// Indicates whether this [Chat] is a monolog.
  bool get isMonolog => kind == ChatKind.monolog;

  /// Indicates whether this [Chat] is a dialog.
  bool get isDialog => kind == ChatKind.dialog;

  /// Indicates whether this [Chat] is a group.
  bool get isGroup => kind == ChatKind.group;

  /// Returns an [UserAvatar] of this [Chat].
  UserAvatar? getUserAvatar(UserId? me) {
    switch (kind) {
      case ChatKind.monolog:
        return members.firstOrNull?.user.avatar;
      case ChatKind.dialog:
        return members.firstWhereOrNull((e) => e.user.id != me)?.user.avatar;
      case ChatKind.group:
      case ChatKind.artemisUnknown:
        return null;
    }
  }

  /// Returns an [User] identified by its [id].
  User? getUser(UserId id) =>
      members.firstWhereOrNull((e) => e.user.id == id)?.user;

  /// Returns an [UserCallCover] of this [Chat].
  UserCallCover? getCallCover(UserId? me) {
    switch (kind) {
      case ChatKind.monolog:
        return members.firstOrNull?.user.callCover;
      case ChatKind.dialog:
        return members.firstWhereOrNull((e) => e.user.id != me)?.user.callCover;
      case ChatKind.group:
      case ChatKind.artemisUnknown:
        return null;
    }
  }

  /// Indicates whether the provided [ChatItem] was read by some [User] other
  /// than [me].
  bool isRead(ChatItem item, UserId? me, [List<ChatMember>? members]) {
    if (members != null) {
      final Iterable<ChatMember> membersWithoutMe =
          members.where((e) => e.user.id != me);

      if (membersWithoutMe.isNotEmpty) {
        final PreciseDateTime firstJoinedAt =
            membersWithoutMe.fold<PreciseDateTime>(
          membersWithoutMe.first.joinedAt,
          (at, member) => member.joinedAt.isBefore(at) ? member.joinedAt : at,
        );

        if (item.at.isBefore(firstJoinedAt)) {
          return true;
        }
      }
    }

    return lastReads.firstWhereOrNull(
            (e) => !e.at.isBefore(item.at) && e.memberId != me) !=
        null;
  }

  /// Indicates whether the provided [ChatItem] was read by the given [user].
  bool isReadBy(ChatItem item, UserId? user) {
    return lastReads
            .firstWhereOrNull((e) => e.memberId == user)
            ?.at
            .isBefore(item.at) ==
        false;
  }
}

/// Member of a [Chat].
@HiveType(typeId: ModelTypeId.chatMember)
class ChatMember {
  ChatMember(this.user, this.joinedAt);

  /// [User] represented by this [ChatMember].
  @HiveField(0)
  User user;

  /// [PreciseDateTime] when the [User] became a [ChatMember].
  @HiveField(1)
  final PreciseDateTime joinedAt;
}

/// [PreciseDateTime] of when a [Chat] was read last time by a [User].
@HiveType(typeId: ModelTypeId.lastChatRead)
class LastChatRead {
  LastChatRead(this.memberId, this.at);

  /// ID of the [User] who read the [Chat].
  @HiveField(0)
  final UserId memberId;

  /// [PreciseDateTime] when the [Chat] was read last time.
  @HiveField(1)
  PreciseDateTime at;
}

/// Unique ID of a [Chat].
@HiveType(typeId: ModelTypeId.chatId)
class ChatId extends NewType<String> {
  const ChatId(super.val);

  /// Constructs a dummy [ChatId].
  factory ChatId.local(UserId id) => ChatId('local_${id.val}');

  /// Indicates whether this [ChatId] is a dummy ID.
  bool get isLocal => val.startsWith('local_');

  /// Returns [UserId] part of this [ChatId] if [isLocal].
  UserId get userId => isLocal
      ? UserId(val.replaceFirst('local_', ''))
      : throw Exception('ChatId is not local');
}

/// Name of a [Chat].
///
/// Only [Chat]-group can have a name.
@HiveType(typeId: ModelTypeId.chatName)
class ChatName extends NewType<String> {
  const ChatName._(String val) : super(val);

  ChatName(String val) : super(val) {
    if (!_regExp.hasMatch(val)) {
      throw const FormatException('Does not match validation RegExp');
    }
  }

  /// Creates a [ChatName] without any validation.
  const factory ChatName.unchecked(String val) = ChatName._;

  /// Regular expression for a [ChatName] validation.
  static final RegExp _regExp = RegExp(r'^[^\s].{0,98}[^\s]$');
}

/// Position of this [Chat] in the favorites list of the authenticated [MyUser].
@HiveType(typeId: ModelTypeId.chatFavoritePosition)
class ChatFavoritePosition extends NewType<double>
    implements Comparable<ChatFavoritePosition> {
  const ChatFavoritePosition(double val) : super(val);

  factory ChatFavoritePosition.parse(String val) =>
      ChatFavoritePosition(double.parse(val));

  @override
  int compareTo(ChatFavoritePosition other) => val.compareTo(other.val);
}
