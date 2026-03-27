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

import 'drift.dart';

/// Downloaded paths of the checksums to be stored in a [Table].
@DataClassName('DownloadRow')
class Downloads extends Table {
  @override
  Set<Column> get primaryKey => {checksum};

  TextColumn get checksum => text()();
  TextColumn get path => text()();
}

/// [DriftProviderBase] for manipulating the persisted download paths.
class DownloadDriftProvider extends DriftProviderBase {
  DownloadDriftProvider(super.database);

  /// Download paths that have started the [upsert]ing, but not yet finished it.
  final Map<String, String> _cache = {};

  /// Stores the provided [path] at the [checksum] in the database.
  Future<void> upsert(String checksum, String path) async {
    _cache[checksum] = path;

    await safe((db) async {
      await db.downloads.insertOne(
        DownloadRow(checksum: checksum, path: path),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Deletes the path at the provided [checksum] from the database.
  Future<void> delete(String checksum) async {
    _cache.remove(checksum);

    await safe((db) async {
      final stmt = db.delete(db.downloads)
        ..where((e) => e.checksum.equals(checksum));
      await stmt.go();
    });
  }

  /// Returns the download paths stored in the database.
  Future<List<(String, String)>> values() async {
    final result = await safe<List<(String, String)>?>((db) async {
      final result = await db.select(db.downloads).get();
      return result.map((e) => (e.checksum, e.path)).toList();
    }, exclusive: false);

    return result ?? <(String, String)>[];
  }

  /// Returns the path at the provided [checksum] stored in the database.
  Future<String?> read(String checksum) async {
    final String? existing = _cache[checksum];
    if (existing != null) {
      return existing;
    }

    return await safe<String?>((db) async {
      final stmt = db.select(db.downloads)
        ..where((u) => u.checksum.equals(checksum));
      final DownloadRow? row = await stmt.getSingleOrNull();
      return row?.path;
    }, exclusive: false);
  }

  /// Deletes all the download paths stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.downloads).go();
    });
  }
}
