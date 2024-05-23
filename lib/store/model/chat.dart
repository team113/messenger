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

import '/domain/model/chat.dart';
import '/domain/model_type_id.dart';
import '/util/new_type.dart';
import 'chat_item.dart';
import 'version.dart';

part 'chat.g.dart';

/// Persisted in [Hive] storage [Chat]'s [value].
@HiveType(typeId: ModelTypeId.dtoChat)
class DtoChat extends HiveObject {
  DtoChat(
    this.value,
    this.ver,
    this.lastItemCursor,
    this.lastReadItemCursor,
    this.recentCursor,
    this.favoriteCursor,
  );

  /// Persisted [Chat] model.
  @HiveField(0)
  Chat value;

  /// Version of this [Chat]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(1)
  ChatVersion ver;

  /// Cursor of a [Chat.lastItem].
  @HiveField(2)
  ChatItemsCursor? lastItemCursor;

  /// Cursor of a [Chat.lastReadItem].
  @HiveField(3)
  ChatItemsCursor? lastReadItemCursor;

  /// Cursor of the [value] when paginating through recent [Chat]s.
  @HiveField(4)
  RecentChatsCursor? recentCursor;

  /// Cursor of the [value] when paginating through favorite [Chat]s.
  @HiveField(5)
  FavoriteChatsCursor? favoriteCursor;

  /// Returns the [ChatId] of the [value].
  ChatId get id => value.id;

  @override
  String toString() =>
      '$runtimeType($value, $ver, $lastItemCursor, $lastReadItemCursor, $recentCursor, $favoriteCursor)';
}

/// Version of a [Chat]'s state.
@HiveType(typeId: ModelTypeId.chatVersion)
class ChatVersion extends Version {
  ChatVersion(super.val);
}

/// Cursor used for recent [Chat]s pagination.
@HiveType(typeId: ModelTypeId.recentChatsCursor)
class RecentChatsCursor extends NewType<String> {
  RecentChatsCursor(super.val);
}

/// Cursor used for favorite [Chat]s pagination.
@HiveType(typeId: ModelTypeId.favoriteChatsCursor)
class FavoriteChatsCursor extends NewType<String> {
  FavoriteChatsCursor(super.val);
}

/// Version of a favorite [Chat]s list.
@HiveType(typeId: ModelTypeId.favoriteChatsListVersion)
class FavoriteChatsListVersion extends Version {
  FavoriteChatsListVersion(super.val);
}

/// Cursor of a [ChatMember].
@HiveType(typeId: ModelTypeId.chatMembersCursor)
class ChatMembersCursor extends NewType<String> {
  ChatMembersCursor(super.val);
}
