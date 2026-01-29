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
import '/store/model/chat.dart';
import '/store/model/contact.dart';
import '/util/new_type.dart';
import 'blocklist.dart';
import 'session.dart';

/// [Session] relative preferences.
class SessionData {
  SessionData({
    this.favoriteChatsListVersion,
    this.favoriteChatsSynchronized,
    this.chatContactsListVersion,
    this.favoriteContactsSynchronized,
    this.contactsSynchronized,
    this.blocklistSynchronized,
    this.sessionsListVersion,
    this.blocklistVersion,
    this.blocklistCount,
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

  /// Persisted [SessionsListVersion] data.
  SessionsListVersion? sessionsListVersion;

  /// Persisted [BlocklistVersion] data.
  BlocklistVersion? blocklistVersion;

  /// Persisted total count of [BlocklistRecord]s in the blocklist of [MyUser].
  int? blocklistCount;

  /// Returns a copy of this [SessionData] replaced with the [NewType]s
  /// provided.
  SessionData replaceWith({
    NewType<FavoriteChatsListVersion?>? favoriteChatsListVersion,
    NewType<bool?>? favoriteChatsSynchronized,
    NewType<ChatContactsListVersion?>? chatContactsListVersion,
    NewType<bool?>? favoriteContactsSynchronized,
    NewType<bool?>? contactsSynchronized,
    NewType<bool?>? blocklistSynchronized,
    NewType<SessionsListVersion?>? sessionsListVersion,
    NewType<BlocklistVersion?>? blocklistVersion,
    NewType<int?>? blocklistCount,
  }) {
    return SessionData(
      favoriteChatsListVersion: favoriteChatsListVersion == null
          ? this.favoriteChatsListVersion
          : favoriteChatsListVersion.val,
      favoriteChatsSynchronized: favoriteChatsSynchronized == null
          ? this.favoriteChatsSynchronized
          : favoriteChatsSynchronized.val,
      chatContactsListVersion: chatContactsListVersion == null
          ? this.chatContactsListVersion
          : chatContactsListVersion.val,
      favoriteContactsSynchronized: favoriteContactsSynchronized == null
          ? this.favoriteContactsSynchronized
          : favoriteContactsSynchronized.val,
      contactsSynchronized: contactsSynchronized == null
          ? this.contactsSynchronized
          : contactsSynchronized.val,
      blocklistSynchronized: blocklistSynchronized == null
          ? this.blocklistSynchronized
          : blocklistSynchronized.val,
      sessionsListVersion: sessionsListVersion == null
          ? this.sessionsListVersion
          : sessionsListVersion.val,
      blocklistVersion: blocklistVersion == null
          ? this.blocklistVersion
          : blocklistVersion.val,
      blocklistCount: blocklistCount == null
          ? this.blocklistCount
          : blocklistCount.val,
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
    SessionsListVersion? sessionsListVersion,
    BlocklistVersion? blocklistVersion,
    int? blocklistCount,
  }) {
    return SessionData(
      favoriteChatsListVersion:
          favoriteChatsListVersion ?? this.favoriteChatsListVersion,
      favoriteChatsSynchronized:
          favoriteChatsSynchronized ?? this.favoriteChatsSynchronized,
      chatContactsListVersion:
          chatContactsListVersion ?? this.chatContactsListVersion,
      favoriteContactsSynchronized:
          favoriteContactsSynchronized ?? this.favoriteContactsSynchronized,
      contactsSynchronized: contactsSynchronized ?? this.contactsSynchronized,
      blocklistSynchronized:
          blocklistSynchronized ?? this.blocklistSynchronized,
      sessionsListVersion: sessionsListVersion ?? this.sessionsListVersion,
      blocklistVersion: blocklistVersion ?? this.blocklistVersion,
      blocklistCount: blocklistCount ?? this.blocklistCount,
    );
  }

  @override
  String toString() {
    return 'SessionData(favoriteChatsListVersion: $favoriteChatsListVersion, favoriteChatsSynchronized: $favoriteChatsSynchronized, chatContactsListVersion: $chatContactsListVersion, favoriteContactsSynchronized: $favoriteContactsSynchronized, contactsSynchronized: $contactsSynchronized, blocklistSynchronized: $blocklistSynchronized, sessionsListVersion: $sessionsListVersion, blocklistVersion: $blocklistVersion, blocklistCount: $blocklistCount)';
  }
}
