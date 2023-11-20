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

    Hive.maybeRegisterAdapter(SessionDataAdapter());
    Hive.maybeRegisterAdapter(FavoriteChatsListVersionAdapter());
    Hive.maybeRegisterAdapter(ChatContactsListVersionAdapter());
  }

  /// Returns the stored [FavoriteChatsListVersion] from [Hive].
  FavoriteChatsListVersion? getFavoriteChatsListVersion() {
    Log.debug('getFavoriteChatsListVersion()', '$runtimeType');
    return getSafe(0)?.favoriteChatsListVersion;
  }

  /// Returns the stored indicator whether all favorite [Chat]s are stored
  /// locally.
  bool? getFavoriteChatsFetched() {
    Log.debug('getFavoriteChatsFetched()', '$runtimeType');
    return getSafe(0)?.favoriteChatsFetched;
  }

  /// Returns the stored [ChatContactsListVersion] from [Hive].
  ChatContactsListVersion? getChatContactsListVersion() {
    Log.debug('getChatContactsListVersion()', '$runtimeType');
    return getSafe(0)?.chatContactsListVersion;
  }

  /// Stores a new [FavoriteChatsListVersion] to [Hive].
  Future<void> setFavoriteChatsListVersion(FavoriteChatsListVersion ver) {
    Log.debug('setChatContactsListVersion($ver)', '$runtimeType');
    return putSafe(
        0, (box.get(0) ?? SessionData())..favoriteChatsListVersion = ver);
  }

  /// Stores a new [SessionData.favoriteChatsFetched] to [Hive].
  Future<void> setFavoriteChatsFetched(bool val) {
    Log.debug('setFavoriteChatsFetched($val)', '$runtimeType');
    return putSafe(
      0,
      (box.get(0) ?? SessionData())..favoriteChatsFetched = val,
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
}
