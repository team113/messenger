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

import '/domain/model/cache_info.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import 'common.dart';
import 'drift.dart';

/// Checksums to be stored in a [Table].
@DataClassName('CacheRow')
class Cache extends Table {
  @override
  Set<Column> get primaryKey => {checksum};

  TextColumn get checksum => text()();
}

/// [CacheInfo] to be stored in a [Table].
@DataClassName('CacheSummaryRow')
class CacheSummary extends Table {
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get id => integer()();
  IntColumn get size => integer().withDefault(const Constant(0))();
  IntColumn get modified =>
      integer().map(const PreciseDateTimeConverter()).nullable()();
  IntColumn get maxSize => integer().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [CacheInfo].
class CacheDriftProvider extends DriftProviderBase {
  CacheDriftProvider(super.database);

  /// Stores the provided [checksums] in the database.
  Future<void> register(List<String> checksums) async {
    await safe((db) async {
      await db.batch((batch) {
        for (var e in checksums) {
          batch.insert(
            db.cache,
            CacheRow(checksum: e),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    });
  }

  /// Deletes the [checksums] from the database.
  Future<void> unregister(List<String> checksums) async {
    await safe((db) async {
      final stmt = db.delete(db.cache)
        ..where((e) => e.checksum.isIn(checksums));
      await stmt.go();
    });
  }

  /// Returns the checksums stored in the database.
  Future<List<String>> checksums() async {
    final result = await safe<List<String>?>((db) async {
      final result = await db.select(db.cache).get();
      return result.map((e) => e.checksum).toList();
    });

    return result ?? [];
  }

  /// Creates, updates or deletes the provided [info] in the database.
  Future<void> upsert(CacheInfo? info) async {
    await safe((db) async {
      if (info == null) {
        await db.delete(db.cacheSummary).go();
      } else {
        await db
            .into(db.cacheSummary)
            .insert(info.toDb(), mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Returns the [CacheInfo] stored in the database.
  Future<CacheInfo?> read() async {
    return await safe<CacheInfo?>((db) async {
      final stmt = db.select(db.cacheSummary)..where((u) => u.id.equals(0));
      final CacheSummaryRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _CacheInfoDb.fromDb(row);
    });
  }

  /// Deletes all the checksums and [CacheInfo] stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.cache).go();
      await db.delete(db.cacheSummary).go();
    });
  }

  /// Returns the [Stream] of real-time changes happening with the [CacheInfo].
  Stream<CacheInfo?> watch() {
    if (db == null) {
      return const Stream.empty();
    }

    final stmt = db!.select(db!.cacheSummary)..where((u) => u.id.equals(0));

    return stmt.watchSingleOrNull().map(
      (e) => e == null ? null : _CacheInfoDb.fromDb(e),
    );
  }
}

/// Extension adding conversion methods from [CacheSummaryRow] to [CacheInfo].
extension _CacheInfoDb on CacheInfo {
  /// Constructs a [CacheInfo] from the provided [CacheSummaryRow].
  static CacheInfo fromDb(CacheSummaryRow e) {
    return CacheInfo(
      size: e.size,
      modified: e.modified?.val,
      maxSize: e.maxSize,
    );
  }

  /// Constructs a [CacheSummaryRow] from this [CacheInfo].
  CacheSummaryRow toDb() {
    return CacheSummaryRow(
      id: 0,
      size: size,
      modified: modified == null ? null : PreciseDateTime(modified!),
      maxSize: maxSize,
    );
  }
}
