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

import '/domain/model/precise_date_time/precise_date_time.dart';
import 'common.dart';
import 'drift.dart';

/// [PreciseDateTime]s associated with a [String] IDs to be stored in a [Table].
@DataClassName('CallKitCallRow')
class CallKitCalls extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  IntColumn get at => integer().map(const PreciseDateTimeConverter())();
}

/// [DriftProviderBase] for manipulating the persisted [PreciseDateTime]s.
class CallKitCallsDriftProvider extends DriftProviderBase {
  CallKitCallsDriftProvider(super.common);

  /// Creates or updates the provided [at] in the database.
  Future<void> upsert(String id, PreciseDateTime at) async {
    await safe((db) async {
      final CallKitCallRow stored = await db
          .into(db.callKitCalls)
          .insertReturning(
            CallKitCallRow(id: id, at: at),
            mode: InsertMode.insertOrReplace,
          );

      return stored.at;
    });
  }

  /// Returns the [PreciseDateTime] stored in the database by the provided [id],
  /// if any.
  Future<PreciseDateTime?> read(String id) async {
    return await safe<PreciseDateTime?>((db) async {
      final stmt = db.select(db.callKitCalls)..where((u) => u.id.equals(id));
      final CallKitCallRow? row = await stmt.getSingleOrNull();
      return row?.at;
    });
  }

  /// Deletes the [PreciseDateTime] identified by the provided [id] from the
  /// database.
  Future<void> delete(String id) async {
    await safe((db) async {
      final stmt = db.delete(db.callKitCalls)..where((e) => e.id.equals(id));
      await stmt.go();
    });
  }

  /// Deletes all the [PreciseDateTime]s stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.callKitCalls).go();
    });
  }
}
