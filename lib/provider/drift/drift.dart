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
