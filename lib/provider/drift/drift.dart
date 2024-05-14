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
import 'package:log_me/log_me.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import 'common.dart';
import 'connection/connection.dart';
import 'user.dart';

part 'drift.g.dart';

@DriftDatabase(tables: [Users])
class DriftProvider extends _$DriftProvider {
  DriftProvider([QueryExecutor? e]) : super(e ?? connect());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, a, b) async {
        Log.debug('onUpgrade($a, $b)', 'MigrationStrategy');

        // TODO: Implement proper migrations.
        if (a != b) {
          for (var e in m.database.allTables) {
            await m.deleteTable(e.actualTableName);
          }
        }

        await m.createAll();
      },
      beforeOpen: (_) async {
        Log.debug('beforeOpen()', 'MigrationStrategy');
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

class DriftProviderBase {
  DriftProviderBase(this.db);

  final DriftProvider db;

  Future<void> txn<T>(Future<T> Function() action) async {
    await db.transaction(action);
  }
}
