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

import 'package:hive_flutter/adapters.dart';
import 'package:log_me/log_me.dart';

import '/domain/model/chat.dart';
import '/store/model/chat.dart';
import '/store/model/contact.dart';
import '/store/model/session_data.dart';
import 'base.dart';

/// [Hive] storage for a [SessionData].
class SessionDataHiveProvider extends HiveBaseProvider<SessionData> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'session_data';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters()', '$runtimeType');

    Hive.maybeRegisterAdapter(ChatContactsListVersionAdapter());
    Hive.maybeRegisterAdapter(FavoriteChatsListVersionAdapter());
    Hive.maybeRegisterAdapter(SessionDataAdapter());
  }

  /// Returns the stored [FavoriteChatsListVersion] from [Hive].
  FavoriteChatsListVersion? getFavoriteChatsListVersion() {
    Log.debug('getFavoriteChatsListVersion()', '$runtimeType');
    return getSafe(0)?.favoriteChatsListVersion;
  }

  /// Returns the stored indicator whether all favorite [Chat]s are stored
  /// locally.
  bool? getFavoriteChatsSynchronized() {
    Log.debug('getFavoriteChatsSynchronized()', '$runtimeType');
    return getSafe(0)?.favoriteChatsSynchronized;
  }

  /// Returns the stored [ChatContactsListVersion] from [Hive].
  ChatContactsListVersion? getChatContactsListVersion() {
    Log.debug('getChatContactsListVersion()', '$runtimeType');
    return getSafe(0)?.chatContactsListVersion;
  }

  /// Returns the stored [ChatContactsListVersion] from [Hive].
  bool? getFavoriteContactsSynchronized() {
    Log.debug('getFavoriteContactsSynchronized()', '$runtimeType');
    return getSafe(0)?.favoriteContactsSynchronized;
  }

  /// Returns the stored [SessionData.contactsSynchronized] from [Hive].
  bool? getContactsSynchronized() {
    Log.debug('getContactsSynchronized()', '$runtimeType');
    return getSafe(0)?.contactsSynchronized;
  }

  /// Stores a new [FavoriteChatsListVersion] to [Hive].
  Future<void> setFavoriteChatsListVersion(FavoriteChatsListVersion ver) {
    Log.debug('setChatContactsListVersion($ver)', '$runtimeType');
    return putSafe(
      0,
      (box.get(0) ?? SessionData())..favoriteChatsListVersion = ver,
    );
  }

  /// Stores a new [SessionData.favoriteChatsSynchronized] to [Hive].
  Future<void> setFavoriteChatsSynchronized(bool val) {
    Log.debug('setFavoriteChatsSynchronized($val)', '$runtimeType');
    return putSafe(
      0,
      (box.get(0) ?? SessionData())..favoriteChatsSynchronized = val,
    );
  }

  /// Stores a new [ChatContactsListVersion] to [Hive].
  Future<void> setChatContactsListVersion(ChatContactsListVersion ver) async {
    Log.debug('setChatContactsListVersion($ver)', '$runtimeType');
    await putSafe(
      0,
      (box.get(0) ?? SessionData())..chatContactsListVersion = ver,
    );
  }

  /// Returns the stored [SessionData.favoriteContactsSynchronized] from [Hive].
  Future<void> setFavoriteContactsSynchronized(bool val) async {
    Log.debug('setFavoriteContactsSynchronized($val)', '$runtimeType');
    await putSafe(
      0,
      (box.get(0) ?? SessionData())..favoriteContactsSynchronized = val,
    );
  }

  /// Returns the stored [SessionData.contactsSynchronized] from [Hive].
  Future<void> setContactsSynchronized(bool val) async {
    Log.debug('setContactsSynchronized($val)', '$runtimeType');
    await putSafe(
      0,
      (box.get(0) ?? SessionData())..contactsSynchronized = val,
    );
  }
}
