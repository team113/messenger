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
import 'package:drift/remote.dart' show DriftRemoteException;

import '/domain/model/chat.dart';
import 'drift.dart';

/// [ChatId] being monologs to be stored in a [Table].
@DataClassName('MonologRow')
class Monologs extends Table {
  @override
  Set<Column> get primaryKey => {identifier};

  TextColumn get identifier => text()();
  TextColumn get chatId => text()();
}

/// Possible [MonologDriftProvider] stored [ChatId].
enum MonologKind { support, notes }

/// [DriftProviderBase] for manipulating the persisted [ChatId]s.
class MonologDriftProvider extends DriftProviderBaseWithScope {
  MonologDriftProvider(super.common, super.scoped);

  /// [ChatId]s that have started the [upsert]ing, but not yet finished it.
  final Map<String, ChatId> _cache = {};

  /// Creates or updates the provided [chatId] in the database.
  Future<void> upsert(MonologKind kind, ChatId chatId) async {
    _cache[kind.name] = chatId;

    await safe((db) async {
      await db
          .into(db.monologs)
          .insert(chatId.toDb(kind), mode: InsertMode.insertOrReplace);
    }, tag: 'monolog.upsert(${kind.name}, $chatId)');
  }

  /// Returns the [ChatId] stored in the database by the provided [kind], if
  /// any.
  Future<ChatId?> read(MonologKind kind) async {
    final ChatId? existing = _cache[kind.name];
    if (existing != null) {
      return existing;
    }

    return await safe<ChatId?>((db) async {
      try {
        final stmt = db.select(db.monologs)
          ..where((u) => u.identifier.equals(kind.name));
        final MonologRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _MonologDb.fromDb(row);
      } on DriftRemoteException {
        // Upsert may fail during E2E tests due to rapid database resetting and
        // creating.
        return null;
      }
    }, tag: 'monolog.read(${kind.name})');
  }

  /// Deletes the [ChatId] identified by the provided [kind] from the database.
  Future<void> delete(MonologKind kind) async {
    _cache.remove(kind.name);

    await safe((db) async {
      final stmt = db.delete(db.monologs)
        ..where((e) => e.identifier.equals(kind.name));
      await stmt.go();
    }, tag: 'monolog.delete(${kind.name})');
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
  MonologRow toDb(MonologKind kind) {
    return MonologRow(identifier: kind.name, chatId: val);
  }
}
