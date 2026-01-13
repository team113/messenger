// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import '/store/model/blocklist.dart';
import '/store/model/my_user.dart';
import 'common.dart';
import 'drift.dart';

/// [BlocklistRecord] to be stored in a [Table].
@DataClassName('BlocklistRow')
class Blocklist extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text()();
  TextColumn get reason => text().nullable()();
  IntColumn get at => integer().map(const PreciseDateTimeConverter())();
  TextColumn get cursor => text().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [BlocklistRecord]s.
class BlocklistDriftProvider extends DriftProviderBaseWithScope
    with IdentityAware {
  BlocklistDriftProvider(super.common, super.scoped);

  /// [DtoBlocklistRecord]s that have started the [upsert]ing, but not yet
  /// finished it.
  final Map<UserId, DtoBlocklistRecord> _cache = {};

  @override
  int get order => IdentityAware.providerOrder;

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  /// Creates or updates the provided [records] in the database.
  Future<Iterable<DtoBlocklistRecord>> upsertBulk(
    Iterable<DtoBlocklistRecord> records,
  ) async {
    await safe((db) async {
      await db.batch((batch) {
        for (var record in records) {
          final BlocklistRow row = record.toDb();
          batch.insert(db.blocklist, row, onConflict: DoUpdate((_) => row));
        }
      });
    }, tag: 'blocklist.upsertBulk(${records.length} items)');

    return records;
  }

  /// Creates or updates the provided [record] in the database.
  Future<DtoBlocklistRecord> upsert(DtoBlocklistRecord record) async {
    _cache[record.userId] = record;

    final result = await safe((db) async {
      final DtoBlocklistRecord stored = _BlocklistDb.fromDb(
        await db
            .into(db.blocklist)
            .insertReturning(record.toDb(), mode: InsertMode.insertOrReplace),
      );

      return stored;
    }, tag: 'blocklist.upsert(record)');

    _cache.remove(record.userId);

    return result ?? record;
  }

  /// Returns the [DtoBlocklistRecord] stored in the database by the provided
  /// [id], if any.
  Future<DtoBlocklistRecord?> read(UserId id) async {
    final DtoBlocklistRecord? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoBlocklistRecord?>(
      (db) async {
        final stmt = db.select(db.blocklist)
          ..where((u) => u.userId.equals(id.val));
        final BlocklistRow? row = await stmt.getSingleOrNull();

        if (row == null) {
          return null;
        }

        return _BlocklistDb.fromDb(row);
      },
      tag: 'blocklist.read($id)',
      exclusive: false,
    );
  }

  /// Deletes the [DtoBlocklistRecord] identified by the provided [id] from the
  /// database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.blocklist)
        ..where((e) => e.userId.equals(id.val));
      await stmt.go();
    }, tag: 'blocklist.delete($id)');
  }

  /// Deletes all the [DtoBlocklistRecord]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.blocklist).go();
    }, tag: 'blocklist.clear()');
  }

  /// Returns the recent [DtoBlocklistRecord]s being in a historical view order.
  Future<List<DtoBlocklistRecord>> records({int? limit}) async {
    final result = await safe(
      (db) async {
        final stmt = db.select(db.blocklist);

        stmt.orderBy([(u) => OrderingTerm.desc(u.at)]);

        if (limit != null) {
          stmt.limit(limit);
        }

        return (await stmt.get()).map(_BlocklistDb.fromDb).toList();
      },
      tag: 'blocklist.records(limit: $limit)',
      exclusive: false,
    );

    return result ?? [];
  }
}

/// Extension adding conversion methods from [BlocklistRow] to
/// [DtoBlocklistRecord].
extension _BlocklistDb on DtoBlocklistRecord {
  /// Constructs a [DtoBlocklistRecord] from the provided [BlocklistRow].
  static DtoBlocklistRecord fromDb(BlocklistRow e) {
    return DtoBlocklistRecord(
      BlocklistRecord(
        userId: UserId(e.userId),
        reason: e.reason == null ? null : BlocklistReason.unchecked(e.reason!),
        at: e.at,
      ),
      e.cursor == null ? null : BlocklistCursor(e.cursor!),
    );
  }

  /// Constructs a [BlocklistRow] from this [DtoBlocklistRecord].
  BlocklistRow toDb() {
    return BlocklistRow(
      userId: value.userId.val,
      reason: value.reason?.val,
      at: value.at,
      cursor: cursor?.val,
    );
  }
}
