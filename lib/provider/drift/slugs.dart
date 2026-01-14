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
import '/util/log.dart';
import 'drift.dart';

/// [ChatDirectLinkSlug] stored as an affiliate of this application.
@DataClassName('SlugRow')
class Slugs extends Table {
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get id => integer()();
  TextColumn get slug => text()();
}

/// [DriftProviderBase] for manipulating the persisted [ChatDirectLinkSlug]s.
class SlugDriftProvider extends DriftProviderBase {
  SlugDriftProvider(super.common);

  /// Creates or updates the provided [slug] in the database.
  Future<void> upsert(ChatDirectLinkSlug slug) async {
    Log.debug('upsert($slug)', '$runtimeType');

    await safe((db) async {
      await db
          .into(db.slugs)
          .insert(
            SlugRow(id: 0, slug: slug.val),
            mode: InsertMode.insertOrReplace,
          );
    }, tag: 'slugs.upsert()');
  }

  /// Returns the [ChatDirectLinkSlug] stored in the database, if any.
  Future<ChatDirectLinkSlug?> read() async {
    Log.debug('read()', '$runtimeType');

    return await safe<ChatDirectLinkSlug?>((db) async {
      final stmt = db.select(db.slugs)..where((u) => u.id.equals(0));
      final SlugRow? row = await stmt.getSingleOrNull();
      Log.debug('read() -> $row', '$runtimeType');

      if (row == null) {
        return null;
      }

      return ChatDirectLinkSlug.unchecked(row.slug);
    }, tag: 'slugs.read()');
  }

  /// Deletes the stored [ChatDirectLinkSlug] from the database.
  Future<void> delete() async {
    Log.debug('delete()', '$runtimeType');

    await safe(
      (db) async => await db.delete(db.slugs).go(),
      tag: 'slugs.delete()',
    );
  }
}
