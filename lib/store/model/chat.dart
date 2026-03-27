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

import '/domain/model/chat.dart';
import '/util/new_type.dart';
import 'chat_item.dart';
import 'version.dart';

/// Persisted in storage [Chat]'s [value].
class DtoChat {
  DtoChat(
    this.value,
    this.ver,
    this.lastItemCursor,
    this.lastReadItemCursor,
    this.recentCursor,
    this.favoriteCursor,
  );

  /// Persisted [Chat] model.
  Chat value;

  /// Version of this [Chat]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  ChatVersion ver;

  /// Cursor of a [Chat.lastItem].
  ChatItemsCursor? lastItemCursor;

  /// Cursor of a [Chat.lastReadItem].
  ChatItemsCursor? lastReadItemCursor;

  /// Cursor of the [value] when paginating through recent [Chat]s.
  RecentChatsCursor? recentCursor;

  /// Cursor of the [value] when paginating through favorite [Chat]s.
  FavoriteChatsCursor? favoriteCursor;

  /// Returns the [ChatId] of the [value].
  ChatId get id => value.id;

  @override
  String toString() =>
      '$runtimeType($value, $ver, $lastItemCursor, $lastReadItemCursor, $recentCursor, $favoriteCursor)';

  @override
  bool operator ==(Object other) {
    return other is DtoChat &&
        value == other.value &&
        ver == other.ver &&
        lastItemCursor == other.lastItemCursor &&
        lastReadItemCursor == other.lastReadItemCursor &&
        recentCursor == other.recentCursor &&
        favoriteCursor == other.favoriteCursor;
  }

  @override
  int get hashCode => Object.hash(
    value,
    ver,
    lastItemCursor,
    lastReadItemCursor,
    recentCursor,
    favoriteCursor,
  );
}

/// Version of a [Chat]'s state.
class ChatVersion extends Version {
  ChatVersion(super.val);
}

/// Cursor used for recent [Chat]s pagination.
class RecentChatsCursor extends NewType<String> {
  RecentChatsCursor(super.val);
}

/// Cursor used for favorite [Chat]s pagination.
class FavoriteChatsCursor extends NewType<String> {
  FavoriteChatsCursor(super.val);
}

/// Version of a favorite [Chat]s list.
class FavoriteChatsListVersion extends Version {
  FavoriteChatsListVersion(super.val);
}

/// Cursor of a [ChatMember].
class ChatMembersCursor extends NewType<String> {
  ChatMembersCursor(super.val);
}
