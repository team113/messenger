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

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/store/model/user.dart';
import 'common.dart';
import 'drift.dart';

/// [PreciseDateTime] acting as a timestamp lock for operations to be stored in
/// a [Table].
@DataClassName('LockRow')
class Locks extends Table {
  @override
  Set<Column> get primaryKey => {operation};

  TextColumn get operation => text()();
  IntColumn get lockedAt =>
      integer().nullable().map(const PreciseDateTimeConverter())();
}

/// [DriftProviderBase] for manipulating the persisted [PreciseDateTime]s.
class LockDriftProvider extends DriftProviderBase {
  LockDriftProvider(super.common);

  /// Creates or updates the provided [operation] in the database.
  Future<void> upsert(String operation) async {
    await safe((db) async {
      await db
          .into(db.locks)
          .insertReturning(
            LockRow(operation: operation, lockedAt: PreciseDateTime.now()),
            mode: InsertMode.insertOrReplace,
          );
    }, tag: 'lock.upsert($operation)');
  }

  /// Returns the [PreciseDateTime] stored in the database by the provided
  /// [operation], if any.
  Future<PreciseDateTime?> read(String operation) async {
    return await safe<PreciseDateTime?>(
      (db) async {
        final stmt = db.select(db.locks)
          ..where((u) => u.operation.equals(operation));
        final LockRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return row.lockedAt;
      },
      tag: 'lock.read($operation)',
      exclusive: false,
    );
  }

  /// Deletes the [operation] from the database.
  Future<void> delete(String operation) async {
    await safe((db) async {
      final stmt = db.delete(db.locks)
        ..where((e) => e.operation.equals(operation));

      await stmt.go();
    }, tag: 'lock.delete($operation)');
  }

  /// Deletes all the [DtoUser]s stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.locks).go();
    }, tag: 'lock.clear()');
  }
}
