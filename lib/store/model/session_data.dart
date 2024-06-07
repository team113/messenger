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

import '/domain/model/chat.dart';
import '/store/model/chat.dart';
import '/store/model/contact.dart';

/// [Session] relative preferences.
class SessionData {
  SessionData({
    this.favoriteChatsListVersion,
    this.favoriteChatsSynchronized,
    this.chatContactsListVersion,
    this.favoriteContactsSynchronized,
    this.contactsSynchronized,
    this.blocklistSynchronized,
  });

  /// Persisted [FavoriteChatsListVersion] data.
  FavoriteChatsListVersion? favoriteChatsListVersion;

  /// Persisted indicator whether all favorite [Chat]s are synchronized with the
  /// remote, meaning no queries should be made.
  bool? favoriteChatsSynchronized;

  /// Persisted [ChatContactsListVersion] data.
  ChatContactsListVersion? chatContactsListVersion;

  /// Persisted indicator whether all favorite [ChatContact]s are synchronized
  /// with the remote, meaning no queries should be made.
  bool? favoriteContactsSynchronized;

  /// Persisted indicator whether all [ChatContact]s are synchronized with the
  /// remote, meaning no queries should be made.
  bool? contactsSynchronized;

  /// Persisted indicator whether all blocked [User]s are synchronized with the
  /// remote, meaning no queries should be made.
  bool? blocklistSynchronized;

  /// Returns a copy of this [SessionData] from the [other].
  SessionData copyFrom(SessionData other) {
    return copyWith(
      favoriteChatsListVersion: other.favoriteChatsListVersion,
      favoriteChatsSynchronized: other.favoriteChatsSynchronized,
      chatContactsListVersion: other.chatContactsListVersion,
      favoriteContactsSynchronized: other.favoriteContactsSynchronized,
      contactsSynchronized: other.contactsSynchronized,
      blocklistSynchronized: other.blocklistSynchronized,
    );
  }

  /// Returns a copy of this [SessionData].
  SessionData copyWith({
    FavoriteChatsListVersion? favoriteChatsListVersion,
    bool? favoriteChatsSynchronized,
    ChatContactsListVersion? chatContactsListVersion,
    bool? favoriteContactsSynchronized,
    bool? contactsSynchronized,
    bool? blocklistSynchronized,
  }) {
    return SessionData(
      favoriteChatsListVersion:
          this.favoriteChatsListVersion ?? favoriteChatsListVersion,
      favoriteChatsSynchronized:
          this.favoriteChatsSynchronized ?? favoriteChatsSynchronized,
      chatContactsListVersion:
          this.chatContactsListVersion ?? chatContactsListVersion,
      favoriteContactsSynchronized:
          this.favoriteContactsSynchronized ?? favoriteContactsSynchronized,
      contactsSynchronized: this.contactsSynchronized ?? contactsSynchronized,
      blocklistSynchronized:
          this.blocklistSynchronized ?? blocklistSynchronized,
    );
  }
}
