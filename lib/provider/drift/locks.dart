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
import 'package:uuid/uuid.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/util/new_type.dart';
import 'common.dart';
import 'drift.dart';

/// [PreciseDateTime] acting as a timestamp lock for operations to be stored in
/// a [Table].
@DataClassName('LockRow')
class Locks extends Table {
  @override
  Set<Column> get primaryKey => {operation};

  TextColumn get operation => text()();
  TextColumn get holder => text()();
  IntColumn get lockedAt =>
      integer().nullable().map(const PreciseDateTimeConverter())();
}

/// [DriftProviderBase] for manipulating the persisted [PreciseDateTime]s.
class LockDriftProvider extends DriftProviderBase {
  LockDriftProvider(super.common);

  /// Acquires a lock for the provided [operation] and returns a
  /// [LockIdentifier] holding it.
  ///
  /// [ttl] is the time to live for the lock, after which it will be
  /// automatically released.
  ///
  /// [retryPeriod] is the time to wait before retrying to acquire the lock, if
  /// it is already held by another operation.
  ///
  /// This method will keep retrying until the lock is acquired or this
  /// [LockDriftProvider] is closed.
  Future<LockIdentifier> acquire(
    String operation, {
    Duration ttl = const Duration(seconds: 30),
    Duration retryPeriod = const Duration(milliseconds: 200),
  }) async {
    final LockIdentifier holder = LockIdentifier.generate();

    bool acquired = false;

    while (!acquired && !isClosed) {
      await safe((db) async {
        final lock = LockRow(
          operation: operation,
          holder: holder.val,
          lockedAt: PreciseDateTime.now(),
        );

        final row = await db
            .into(db.locks)
            .insertReturningOrNull(
              lock,
              onConflict: DoUpdate(
                (_) => lock,
                where: (e) =>
                    e.operation.equals(operation) &
                    // TODO: Check whether this accounts `NULL` values.
                    e.lockedAt.isSmallerOrEqualValue(
                      (lock.lockedAt!).subtract(ttl).microsecondsSinceEpoch,
                    ),
              ),
              mode: InsertMode.insertOrRollback,
            );

        acquired = row?.holder == holder.val;
      }, tag: 'lock.acquire($operation)');

      if (!acquired) {
        await Future.delayed(retryPeriod);
      }
    }

    return holder;
  }

  /// Releases a lock with the provided [identifier] from the database.
  Future<void> release(LockIdentifier identifier) async {
    await safe((db) async {
      final stmt = db.delete(db.locks)
        ..where((e) => e.holder.equals(identifier.val));

      await stmt.go();
    }, tag: 'lock.release($identifier)');
  }

  /// Deletes all the locks stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.locks).go();
    }, tag: 'lock.clear()');
  }
}

/// Unique identifier for a lock operation.
class LockIdentifier extends NewType<String> {
  const LockIdentifier._(super.val);

  /// Creates a new [LockIdentifier] with a random value.
  factory LockIdentifier.generate() {
    return LockIdentifier._(const Uuid().v4());
  }
}
