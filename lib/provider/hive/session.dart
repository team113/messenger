// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/store/model/chat.dart';
import '/store/model/contact.dart';
import '/store/model/session_data.dart';
import 'base.dart';

// TODO: Encrypt stored data.
/// [Hive] storage for a [SessionData].
class SessionDataHiveProvider extends HiveBaseProvider<SessionData> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch(key: 0);

  @override
  String get boxName => 'session_data';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(AccessTokenAdapter());
    Hive.maybeRegisterAdapter(ChatContactsListVersionAdapter());
    Hive.maybeRegisterAdapter(CredentialsAdapter());
    Hive.maybeRegisterAdapter(FavoriteChatsListVersionAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(RememberedSessionAdapter());
    Hive.maybeRegisterAdapter(RememberTokenAdapter());
    Hive.maybeRegisterAdapter(SessionAdapter());
    Hive.maybeRegisterAdapter(SessionDataAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
    // Hive.maybeRegisterAdapter(WindowPreferencesAdapter());
  }

  /// Returns the stored [Credentials] from [Hive].
  Credentials? getCredentials() => getSafe(0)?.credentials;

  /// Returns the stored [ChatContactsListVersion] from [Hive].
  ChatContactsListVersion? getChatContactsListVersion() =>
      getSafe(0)?.chatContactsListVersion;

  /// Returns the stored [FavoriteChatsListVersion] from [Hive].
  FavoriteChatsListVersion? getFavoriteChatsListVersion() =>
      getSafe(0)?.favoriteChatsListVersion;

  /// Returns the stored [FavoriteChatsListVersion] from [Hive].
  // WindowPreferences? getWindowPreferences() => getSafe(0)?.windowPreferences;

  /// Stores new [Credentials] to [Hive].
  Future<void> setCredentials(Credentials credentials) =>
      putSafe(0, (box.get(0) ?? SessionData())..credentials = credentials);

  /// Stores a new [ChatContactsListVersion] to [Hive].
  Future<void> setChatContactsListVersion(ChatContactsListVersion ver) =>
      putSafe(0, (box.get(0) ?? SessionData())..chatContactsListVersion = ver);

  /// Stores a new [FavoriteChatsListVersion] to [Hive].
  Future<void> setFavoriteChatsListVersion(FavoriteChatsListVersion ver) =>
      putSafe(0, (box.get(0) ?? SessionData())..favoriteChatsListVersion = ver);

  /// Stores a new [FavoriteChatsListVersion] to [Hive].
  // Future<void> setWindowPreferences(WindowPreferences prefs) async {
  //   print('set window preferences');
  //   await putSafe(0, (box.get(0) ?? SessionData())..windowPreferences = prefs);
  // }
}
