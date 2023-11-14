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

import '/domain/model/chat.dart';
import '/store/model/chat.dart';
import '/store/model/favorite_chats_data.dart';
import 'base.dart';

/// [Hive] storage for a [FavoriteChatsData].
class FavoriteChatsDataHiveProvider
    extends HiveBaseProvider<FavoriteChatsData> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'favorite_chats_data';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(FavoriteChatsDataAdapter());
    Hive.maybeRegisterAdapter(FavoriteChatsListVersionAdapter());
  }

  /// Returns the stored [FavoriteChatsListVersion] from [Hive].
  FavoriteChatsListVersion? getFavoriteChatsListVersion() =>
      getSafe(0)?.favoriteChatsListVersion;

  /// Returns the stored indicator whether all favorite [Chat]s are stored
  /// locally.
  bool? getFavoriteChatsFetched() => getSafe(0)?.favoriteChatsFetched;

  /// Stores a new [FavoriteChatsListVersion] to [Hive].
  Future<void> setFavoriteChatsListVersion(FavoriteChatsListVersion ver) =>
      putSafe(
        0,
        (box.get(0) ?? FavoriteChatsData())..favoriteChatsListVersion = ver,
      );

  /// Stores a new [FavoriteChatsData.favoriteChatsFetched] to [Hive].
  Future<void> setFavoriteChatsFetched(bool val) => putSafe(
        0,
        (box.get(0) ?? FavoriteChatsData())..favoriteChatsFetched = val,
      );
}
