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

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart' show DisposableInterface;
import 'package:log_me/log_me.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import 'chat.dart';
import 'chat_item.dart';
import 'chat_member.dart';
import 'common.dart';
import 'connection/connection.dart';
import 'user.dart';

part 'drift.g.dart';

/// [DriftDatabase] storing data locally.
@DriftDatabase(
  tables: [Users, ChatItems, ChatItemViews, ChatMembers, Chats],
  queries: {
    'chatItemsAround': ''
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at <= :at AND chat_item_views.me = :me '
        'ORDER BY at DESC LIMIT :before + 1) as a '
        'UNION '
        'SELECT * FROM '
        '(SELECT * FROM chat_item_views '
        'INNER JOIN chat_items ON chat_items.id = chat_item_views.chat_item_id '
        'WHERE chat_item_views.chat_id = :chat_id AND at > :at AND chat_item_views.me = :me '
        'ORDER BY at ASC LIMIT :after) as b '
        'ORDER BY at ASC;',
  },
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? connect());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, a, b) async {
        Log.info('MigrationStrategy.onUpgrade($a, $b)', '$runtimeType');

        // TODO: Implement proper migrations.
        if (a != b) {
          for (var e in m.database.allTables) {
            await m.deleteTable(e.actualTableName);
          }
        }

        await m.createAll();
      },
      beforeOpen: (_) async {
        Log.debug('MigrationStrategy.beforeOpen()', '$runtimeType');

        await customStatement('PRAGMA foreign_keys = ON;');
        await customStatement('PRAGMA journal_mode = WAL;');
      },
    );
  }

  /// Creates all tables, triggers, views, indexes and everything else defined
  /// in the database, if they don't exist.
  Future<void> create() async {
    await createMigrator().createAll();
  }

  /// Resets everything, meaning dropping and re-creating every table.
  Future<void> reset() async {
    Log.debug('reset()', '$runtimeType');

    for (var e in allSchemaEntities) {
      if (e is TableInfo) {
        await e.deleteAll();
      } else {
        await createMigrator().drop(e);
      }
    }

    await createMigrator().createAll();
  }
}

/// [AppDatabase] provider.
final class DriftProvider extends DisposableInterface {
  /// Constructs a [DriftProvider] with the in-memory database.
  DriftProvider.memory() : db = AppDatabase(inMemory());

  /// Constructs a [DriftProvider] with the provided [db].
  DriftProvider.from(this.db);

  /// [AppDatabase] itself.
  ///
  /// `null` here means the database is closed.
  AppDatabase? db;

  @override
  void onInit() async {
    Log.debug('onInit()', '$runtimeType');
    await db?.create();
    super.onInit();
  }

  @override
  void onClose() async {
    Log.debug('onClose()', '$runtimeType');
    db = null;
    super.onClose();
  }

  /// Closes this [DriftProvider].
  @visibleForTesting
  Future<void> close() async {
    final Future<void>? future = db?.close();
    db = null;
    await future;
  }

  /// Resets the [AppDatabase] and closes this [DriftProvider].
  Future<void> reset() async {
    final Future<void>? future = db?.reset();
    db = null;
    await future;
  }
}

/// [DriftProvider] with common helper and utility methods over it.
abstract class DriftProviderBase {
  const DriftProviderBase(this._provider);

  /// [DriftProvider] itself.
  final DriftProvider _provider;

  /// Returns the [AppDatabase].
  ///
  /// `null` here means the database is closed.
  AppDatabase? get db => _provider.db;

  /// Completes the provided [action] as a transaction.
  Future<void> txn<T>(Future<T> Function() action) async {
    await db?.transaction(action);
  }

  /// Runs the [callback] through a non-closed [AppDatabase], or returns `null`.
  ///
  /// [AppDatabase] may be closed, for example, between E2E tests.
  Future<T?> safe<T>(Future<T> Function(AppDatabase db) callback) async {
    if (db == null) {
      return null;
    }

    return await callback(db!);
  }
}
