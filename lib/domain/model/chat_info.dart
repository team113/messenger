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
import 'avatar.dart';
import 'chat.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

part 'chat_info.g.dart';

/// Information about an action taken upon a [Chat].
@HiveType(typeId: ModelTypeId.chatInfo)
@JsonSerializable()
class ChatInfo extends ChatItem {
  ChatInfo(
    super.id,
    super.chatId,
    super.author,
    super.at, {
    required this.action,
  });

  /// Constructs a [ChatInfo] from the provided [json].
  factory ChatInfo.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoFromJson(json);

  /// [ChatInfoAction] taken upon the [Chat].
  @HiveField(5)
  final ChatInfoAction action;

  /// Returns a [Map] representing this [ChatInfo].
  @override
  Map<String, dynamic> toJson() =>
      _$ChatInfoToJson(this)..['runtimeType'] = 'ChatInfo';
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

  /// Constructs a [ChatInfoAction] from the provided [json].
  factory ChatInfoAction.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'ChatInfoActionAvatarUpdated' =>
          ChatInfoActionAvatarUpdated.fromJson(json),
        'ChatInfoActionCreated' => ChatInfoActionCreated.fromJson(json),
        'ChatInfoActionMemberAdded' => ChatInfoActionMemberAdded.fromJson(json),
        'ChatInfoActionMemberRemoved' =>
          ChatInfoActionMemberRemoved.fromJson(json),
        'ChatInfoActionNameUpdated' => ChatInfoActionNameUpdated.fromJson(json),
        _ => throw UnimplementedError(json['runtimeType'])
      };

  /// [ChatInfoActionKind] of this event.
  ChatInfoActionKind get kind;

  /// Returns a [Map] representing this [ChatInfoAction].
  Map<String, dynamic> toJson() => switch (runtimeType) {
        const (ChatInfoActionAvatarUpdated) =>
          (this as ChatInfoActionAvatarUpdated).toJson(),
        const (ChatInfoActionCreated) =>
          (this as ChatInfoActionCreated).toJson(),
        const (ChatInfoActionMemberAdded) =>
          (this as ChatInfoActionMemberAdded).toJson(),
        const (ChatInfoActionMemberRemoved) =>
          (this as ChatInfoActionMemberRemoved).toJson(),
        const (ChatInfoActionNameUpdated) =>
          (this as ChatInfoActionNameUpdated).toJson(),
        _ => throw UnimplementedError(runtimeType.toString()),
      };
}

/// [ChatInfoAction] about a [ChatAvatar] being updated.
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatInfoActionAvatarUpdated)
class ChatInfoActionAvatarUpdated implements ChatInfoAction {
  const ChatInfoActionAvatarUpdated(this.avatar);

  /// Constructs a [ChatInfoActionAvatarUpdated] from the provided [json].
  factory ChatInfoActionAvatarUpdated.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoActionAvatarUpdatedFromJson(json);

  /// New [ChatAvatar] of the [Chat].
  ///
  /// `null` means that the old [ChatAvatar] was removed.
  @HiveField(0)
  final ChatAvatar? avatar;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.avatarUpdated;

  /// Returns a [Map] representing this [ChatInfoActionAvatarUpdated].
  @override
  Map<String, dynamic> toJson() => _$ChatInfoActionAvatarUpdatedToJson(this)
    ..['runtimeType'] = 'ChatInfoActionAvatarUpdated';
}

/// [ChatInfoAction] about a [Chat] being created.
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatInfoActionCreated)
class ChatInfoActionCreated implements ChatInfoAction {
  const ChatInfoActionCreated(this.directLinkSlug);

  /// Constructs a [ChatInfoActionCreated] from the provided [json].
  factory ChatInfoActionCreated.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoActionCreatedFromJson(json);

  /// [ChatDirectLinkSlug] used to create the [Chat], if any.
  @HiveField(0)
  final ChatDirectLinkSlug? directLinkSlug;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.created;

  /// Returns a [Map] representing this [ChatInfoActionCreated].
  @override
  Map<String, dynamic> toJson() => _$ChatInfoActionCreatedToJson(this)
    ..['runtimeType'] = 'ChatInfoActionCreated';
}

/// [ChatInfoAction] about a [ChatAvatar] being updated.
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatInfoActionMemberAdded)
class ChatInfoActionMemberAdded implements ChatInfoAction {
  const ChatInfoActionMemberAdded(this.user, this.directLinkSlug);

  /// Constructs a [ChatInfoActionMemberAdded] from the provided [json].
  factory ChatInfoActionMemberAdded.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoActionMemberAddedFromJson(json);

  /// [User] who became a [ChatMember].
  ///
  /// If the same as [ChatItem.author], then the [User] joined the [Chat] by
  /// himself.
  @HiveField(0)
  final User user;

  /// [ChatDirectLinkSlug] used by the [ChatMember] to join the [Chat], if any.
  @HiveField(1)
  final ChatDirectLinkSlug? directLinkSlug;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.memberAdded;

  /// Returns a [Map] representing this [ChatInfoActionMemberAdded].
  @override
  Map<String, dynamic> toJson() => _$ChatInfoActionMemberAddedToJson(this)
    ..['runtimeType'] = 'ChatInfoActionMemberAdded';
}

/// [ChatInfoAction] about a [ChatMember] being removed from a [Chat].
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatInfoActionMemberRemoved)
class ChatInfoActionMemberRemoved implements ChatInfoAction {
  const ChatInfoActionMemberRemoved(this.user);

  /// Constructs a [ChatInfoActionMemberRemoved] from the provided [json].
  factory ChatInfoActionMemberRemoved.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoActionMemberRemovedFromJson(json);

  /// [User] who was removed from the [Chat].
  ///
  /// If the same as [ChatItem.author], then the [User] left the [Chat] by
  /// himself.
  @HiveField(0)
  final User user;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.memberRemoved;

  /// Returns a [Map] representing this [ChatInfoActionMemberRemoved].
  @override
  Map<String, dynamic> toJson() => _$ChatInfoActionMemberRemovedToJson(this)
    ..['runtimeType'] = 'ChatInfoActionMemberRemoved';
}

/// [ChatInfoAction] about a [ChatName] being updated.
@JsonSerializable()
@HiveType(typeId: ModelTypeId.chatInfoActionNameUpdated)
class ChatInfoActionNameUpdated implements ChatInfoAction {
  const ChatInfoActionNameUpdated(this.name);

  /// Constructs a [ChatInfoActionNameUpdated] from the provided [json].
  factory ChatInfoActionNameUpdated.fromJson(Map<String, dynamic> json) =>
      _$ChatInfoActionNameUpdatedFromJson(json);

  /// New [ChatName] of the [Chat].
  ///
  /// `null` means that the old [ChatName] was removed.
  @HiveField(0)
  final ChatName? name;

  @override
  ChatInfoActionKind get kind => ChatInfoActionKind.nameUpdated;

  /// Returns a [Map] representing this [ChatInfoActionNameUpdated].
  @override
  Map<String, dynamic> toJson() => _$ChatInfoActionNameUpdatedToJson(this)
    ..['runtimeType'] = 'ChatInfoActionNameUpdated';
}
