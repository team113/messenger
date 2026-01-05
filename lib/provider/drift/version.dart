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

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/remote.dart';
import 'package:mutex/mutex.dart';

import '/domain/model/user.dart';
import '/store/model/blocklist.dart';
import '/store/model/chat.dart';
import '/store/model/contact.dart';
import '/store/model/session_data.dart';
import '/store/model/session.dart';
import '/util/new_type.dart';
import 'drift.dart';

/// [SessionData] to be stored in a [Table].
@DataClassName('VersionRow')
class Versions extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text()();
  TextColumn get favoriteChatsListVersion => text().nullable()();
  BoolColumn get favoriteChatsSynchronized => boolean().nullable()();
  TextColumn get chatContactsListVersion => text().nullable()();
  BoolColumn get favoriteContactsSynchronized => boolean().nullable()();
  BoolColumn get contactsSynchronized => boolean().nullable()();
  BoolColumn get blocklistSynchronized => boolean().nullable()();
  TextColumn get sessionsListVersion => text().nullable()();
  TextColumn get blocklistVersion => text().nullable()();
  IntColumn get blocklistCount => integer().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [SessionData].
class VersionDriftProvider extends DriftProviderBase {
  VersionDriftProvider(super.database);

  /// [SessionData]s stored in the database and accessible synchronously.
  ///
  /// __Note__, that this field only should be used, if [init] was invoked
  /// before any operations with the database, or otherwise it may contain
  /// incomplete data.
  final Map<UserId, SessionData> data = {};

  /// [Mutex] guarding [init].
  final Mutex _guard = Mutex();

  /// Indicator whether [init] has been completed.
  bool _initialized = false;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  /// Pre-initializes the [data], so that it is accessible synchronously.
  Future<void> init() async {
    await _guard.protect(() async {
      if (_initialized) {
        return;
      }

      final result = await safe((db) async {
        final stmt = await db.select(db.versions).get();
        return stmt
            .map((e) => (UserId(e.userId), _SessionDataDb.fromDb(e)))
            .toList();
      }, exclusive: false);

      for (var e in result ?? <(UserId, SessionData)>[]) {
        data[e.$1] = e.$2;
      }

      _initialized = true;
    });
  }

  /// Creates or updates the provided [data] in the database.
  Future<SessionData> upsert(
    UserId userId, {
    NewType<FavoriteChatsListVersion?>? favoriteChatsListVersion,
    NewType<bool?>? favoriteChatsSynchronized,
    NewType<ChatContactsListVersion?>? chatContactsListVersion,
    NewType<bool?>? favoriteContactsSynchronized,
    NewType<bool?>? contactsSynchronized,
    NewType<bool?>? blocklistSynchronized,
    NewType<SessionsListVersion?>? sessionsListVersion,
    NewType<BlocklistVersion?>? blocklistVersion,
    NewType<int?>? blocklistCount,
  }) async {
    final SessionData? existing = data[userId];
    final SessionData session = (existing ?? SessionData()).replaceWith(
      favoriteChatsListVersion: favoriteChatsListVersion,
      favoriteChatsSynchronized: favoriteChatsSynchronized,
      chatContactsListVersion: chatContactsListVersion,
      favoriteContactsSynchronized: favoriteContactsSynchronized,
      contactsSynchronized: contactsSynchronized,
      blocklistSynchronized: blocklistSynchronized,
      sessionsListVersion: sessionsListVersion,
      blocklistVersion: blocklistVersion,
      blocklistCount: blocklistCount,
    );

    data[userId] = session;

    final result = await safe((db) async {
      try {
        return _SessionDataDb.fromDb(
          await db
              .into(db.versions)
              .insertReturning(session.toDb(userId), mode: InsertMode.replace),
        );
      } on DriftRemoteException {
        // Upsert may fail during E2E tests due to rapid database resetting and
        // creating.
        return null;
      }
    });

    return result ?? session;
  }

  /// Returns the [SessionData] stored in the database by the provided [id], if
  /// any.
  Future<SessionData?> read(UserId id) async {
    final SessionData? existing = data[id];
    if (existing != null) {
      return existing;
    }

    return await safe<SessionData?>((db) async {
      final stmt = db.select(db.versions)
        ..where((u) => u.userId.equals(id.val));
      final VersionRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _SessionDataDb.fromDb(row);
    }, exclusive: false);
  }

  /// Deletes the [SessionData] identified by the provided [id] from the
  /// database.
  Future<void> delete(UserId id) async {
    data.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.versions)
        ..where((e) => e.userId.equals(id.val));
      await stmt.go();
    });
  }

  /// Deletes all the [SessionData]s stored in the database.
  Future<void> clear() async {
    data.clear();

    await safe((db) async {
      await db.delete(db.versions).go();
    });
  }
}

/// Extension adding conversion methods from [VersionRow] to [SessionData].
extension _SessionDataDb on SessionData {
  /// Constructs a [SessionData] from the provided [VersionRow].
  static SessionData fromDb(VersionRow e) {
    return SessionData(
      favoriteChatsListVersion: e.favoriteChatsListVersion == null
          ? null
          : FavoriteChatsListVersion(e.favoriteChatsListVersion!),
      favoriteChatsSynchronized: e.favoriteChatsSynchronized,
      chatContactsListVersion: e.chatContactsListVersion == null
          ? null
          : ChatContactsListVersion(e.chatContactsListVersion!),
      favoriteContactsSynchronized: e.favoriteContactsSynchronized,
      contactsSynchronized: e.contactsSynchronized,
      blocklistSynchronized: e.blocklistSynchronized,
      sessionsListVersion: e.sessionsListVersion == null
          ? null
          : SessionsListVersion(e.sessionsListVersion!),
      blocklistVersion: e.blocklistVersion == null
          ? null
          : BlocklistVersion(e.blocklistVersion!),
      blocklistCount: e.blocklistCount,
    );
  }

  /// Constructs a [VersionRow] from this [SessionData].
  VersionRow toDb(UserId userId) {
    return VersionRow(
      userId: userId.val,
      favoriteChatsListVersion: favoriteChatsListVersion?.val,
      favoriteChatsSynchronized: favoriteChatsSynchronized,
      chatContactsListVersion: chatContactsListVersion?.val,
      favoriteContactsSynchronized: favoriteContactsSynchronized,
      contactsSynchronized: contactsSynchronized,
      blocklistSynchronized: blocklistSynchronized,
      sessionsListVersion: sessionsListVersion?.val,
      blocklistVersion: blocklistVersion?.val,
      blocklistCount: blocklistCount,
    );
  }
}
