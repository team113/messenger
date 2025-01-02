// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import 'drift.dart';

/// [ChatId] being monologs to be stored in a [Table].
@DataClassName('MonologRow')
class Monologs extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text()();
  TextColumn get chatId => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatId]s.
class MonologDriftProvider extends DriftProviderBase {
  MonologDriftProvider(super.database);

  /// [ChatId]s that have started the [upsert]ing, but not yet finished it.
  final Map<UserId, ChatId> _cache = {};

  /// Creates or updates the provided [chatId] in the database.
  Future<void> upsert(UserId userId, ChatId chatId) async {
    _cache[userId] = chatId;

    await safe((db) async {
      await db
          .into(db.monologs)
          .insert(chatId.toDb(userId), mode: InsertMode.insertOrReplace);
    }, tag: 'monolog.upsert($userId, $chatId)');
  }

  /// Returns the [ChatId] stored in the database by the provided [id], if any.
  Future<ChatId?> read(UserId id) async {
    final ChatId? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<ChatId?>((db) async {
      final stmt = db.select(db.monologs)
        ..where((u) => u.userId.equals(id.val));
      final MonologRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _MonologDb.fromDb(row);
    }, tag: 'monolog.read($id)');
  }

  /// Deletes the [ChatId] identified by the provided [id] from the database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.monologs)
        ..where((e) => e.userId.equals(id.val));
      await stmt.go();
    }, tag: 'monolog.delete($id)');
  }

  /// Deletes all the [ChatId]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.monologs).go();
    }, tag: 'monolog.clear()');
  }
}

/// Extension adding conversion methods from [MonologRow] to [ChatId].
extension _MonologDb on ChatId {
  /// Constructs a [ChatId] from the provided [MonologRow].
  static ChatId fromDb(MonologRow e) => ChatId(e.chatId);

  /// Constructs a [MonologRow] from this [ChatId].
  MonologRow toDb(UserId userId) {
    return MonologRow(userId: userId.val, chatId: val);
  }
}
