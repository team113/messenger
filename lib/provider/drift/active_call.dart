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

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import 'drift.dart';

/// [ChatCall]s being active right now to be stored in a [Table].
@DataClassName('ActiveCallRow')
class ActiveCalls extends Table {
  @override
  Set<Column> get primaryKey => {chatId};

  TextColumn get chatId => text()();
  TextColumn get data => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatCall]s.
class ActiveCallDriftProvider extends DriftProviderBaseWithScope {
  ActiveCallDriftProvider(super.common, super.scoped);

  /// [ActiveCall] that have started the [upsert]ing, but not yet finished it.
  final Map<ChatId, ActiveCall> _cache = {};

  /// Creates or updates the provided [call] in the database.
  Future<void> upsert(ActiveCall call) async {
    _cache[call.chatId] = call;

    await safe((db) async {
      await db.into(db.activeCalls).insertReturning(
            call.toDb(),
            mode: InsertMode.insertOrReplace,
          );
    });

    _cache.remove(call.chatId);
  }

  /// Returns the [ActiveCall] stored in the database by the provided
  /// [id], if any.
  Future<ActiveCall?> read(ChatId id) async {
    final ActiveCall? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<ActiveCall?>((db) async {
      final stmt = db.select(db.activeCalls);
      stmt.where((u) => u.chatId.equals(id.val));

      final ActiveCallRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _ActiveCallDb.fromDb(row);
    });
  }

  /// Deletes the [ActiveCall] identified by the provided [id] from the
  /// database.
  Future<void> delete(ChatId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.activeCalls)
        ..where((e) => e.chatId.equals(id.val));
      await stmt.go();
    });
  }

  /// Deletes all the [ActiveCall]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.callCredentials).go();
    });
  }
}

/// Extension adding conversion methods from [ActiveCallRow] to
/// [ActiveCall].
extension _ActiveCallDb on ActiveCall {
  /// Constructs a [ActiveCall] from the provided [ActiveCallRow].
  static ActiveCall fromDb(ActiveCallRow e) {
    return ActiveCall.fromJson(jsonDecode(e.data));
  }

  /// Constructs a [ActiveCallRow] from this [ActiveCall].
  ActiveCallRow toDb() {
    return ActiveCallRow(chatId: chatId.val, data: jsonEncode(toJson()));
  }
}
