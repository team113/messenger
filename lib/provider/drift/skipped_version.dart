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

/// Skipped [Release] version to be stored in a [Table].
@DataClassName('SkippedVersionRow')
class SkippedVersions extends Table {
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get id => integer()();
  TextColumn get skipped => text()();
}

/// [DriftProviderBase] for manipulating the persisted skipped [Release]
/// version.
class SkippedVersionDriftProvider extends DriftProviderBase {
  SkippedVersionDriftProvider(super.database);

  /// Creates or updates the provided [version] in the database.
  Future<void> upsert(String version) async {
    await safe((db) async {
      final row = SkippedVersionRow(id: 0, skipped: version);
      await db
          .into(db.skippedVersions)
          .insert(row, onConflict: DoUpdate((_) => row));
    });
  }

  /// Returns the skipped version stored in the database.
  Future<String?> read() async {
    return await safe<String?>((db) async {
      final stmt = db.select(db.skippedVersions)..where((e) => e.id.equals(0));
      final SkippedVersionRow? row = await stmt.getSingleOrNull();
      return row?.skipped;
    }, exclusive: false);
  }

  /// Deletes the skipped version stored from the database.
  Future<void> delete() async {
    await safe((db) async {
      await db.delete(db.skippedVersions).go();
    });
  }
}
