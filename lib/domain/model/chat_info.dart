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
import 'avatar.dart';
import 'chat.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_info.g.dart';

/// Information about an action taken upon a [Chat].
@HiveType(typeId: ModelTypeId.chatInfo)
class ChatInfo extends ChatItem {
  ChatInfo(
    super.id,
    super.chatId,
    super.authorId,
    super.at, {
    required this.author,
    required this.action,
  });

  /// [User] who triggered this [ChatInfo].
  @HiveField(5)
  final User author;

  /// [ChatInfoAction] taken upon the [Chat].
  @HiveField(6)
  final ChatInfoAction action;
}

/// Possible kinds of a [ChatInfoAction].
enum ChatInfoActionKind {
  avatarUpdated,
  created,
  memberAdded,
  memberRemoved,
  nameUpdated,
}

/// Action taken upon a [Chat].
abstract class ChatInfoAction {
  const ChatInfoAction();

  /// [ChatInfoActionKind] of this event.
  ChatInfoActionKind get kind;
}

/// [ChatInfoAction] about a [ChatAvatar] being updated.
@HiveType(typeId: ModelTypeId.chatInfoActionAvatarUpdated)
class ChatInfoActionAvatarUpdated implements ChatInfoAction {
  const ChatInfoActionAvatarUpdated(this.avatar);

  /// New [ChatAvatar] of the [Chat].
  ///
  /// `null` means that the old [ChatAvatar] was removed.
  @HiveField(0)
  final ChatAvatar? avatar;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.avatarUpdated;
}

/// [ChatInfoAction] about a [Chat] being created.
@HiveType(typeId: ModelTypeId.chatInfoActionCreated)
class ChatInfoActionCreated implements ChatInfoAction {
  const ChatInfoActionCreated(this.directLinkSlug);

  /// [ChatDirectLinkSlug] used to create the [Chat], if any.
  @HiveField(0)
  final ChatDirectLinkSlug? directLinkSlug;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.created;
}

/// [ChatInfoAction] about a [ChatAvatar] being updated.
@HiveType(typeId: ModelTypeId.chatInfoActionMemberAdded)
class ChatInfoActionMemberAdded implements ChatInfoAction {
  const ChatInfoActionMemberAdded(this.user, this.directLinkSlug);

  /// [User] who became a [ChatMember].
  ///
  /// If the same as [ChatItem.authorId], then the [User] joined the [Chat] by
  /// himself.
  @HiveField(0)
  final User user;

  /// [ChatDirectLinkSlug] used by the [ChatMember] to join the [Chat], if any.
  @HiveField(1)
  final ChatDirectLinkSlug? directLinkSlug;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.memberAdded;
}

/// [ChatInfoAction] about a [ChatMember] being removed from a [Chat].
@HiveType(typeId: ModelTypeId.chatInfoActionMemberRemoved)
class ChatInfoActionMemberRemoved implements ChatInfoAction {
  const ChatInfoActionMemberRemoved(this.user);

  /// [User] who was removed from the [Chat].
  ///
  /// If the same as [ChatItem.authorId], then the [User] left the [Chat] by
  /// himself.
  @HiveField(0)
  final User user;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.memberRemoved;
}

/// [ChatInfoAction] about a [ChatName] being updated.
@HiveType(typeId: ModelTypeId.chatInfoActionNameUpdated)
class ChatInfoActionNameUpdated implements ChatInfoAction {
  const ChatInfoActionNameUpdated(this.name);

  /// New [ChatName] of the [Chat].
  ///
  /// `null` means that the old [ChatName] was removed.
  @HiveField(0)
  final ChatName? name;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.nameUpdated;
}
