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

import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model_type_id.dart';
import '/store/model/my_user.dart';
import '/util/log.dart';
import 'base.dart';

part 'blocklist.g.dart';

/// [Hive] storage for blocked [UserId]s of the authenticated [MyUser].
class BlocklistHiveProvider extends HiveLazyProvider<HiveBlocklistRecord>
    implements IterableHiveProvider<HiveBlocklistRecord, UserId> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'blocklist';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(BlocklistCursorAdapter());
    Hive.maybeRegisterAdapter(BlocklistReasonAdapter());
    Hive.maybeRegisterAdapter(BlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(HiveBlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
  }

  @override
  Iterable<UserId> get keys => keysSafe.map((e) => UserId(e));

  @override
  Future<Iterable<HiveBlocklistRecord>> get values => valuesSafe;

  @override
  Future<void> put(HiveBlocklistRecord record) async {
    Log.trace('put($record)', '$runtimeType');
    await putSafe(record.value.userId.val, record);
  }

  @override
  Future<HiveBlocklistRecord?> get(UserId id) async {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  @override
  Future<void> remove(UserId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}

/// Persisted in [Hive] storage [BlocklistRecord]'s [value].
@HiveType(typeId: ModelTypeId.hiveBlocklistRecord)
class HiveBlocklistRecord {
  HiveBlocklistRecord(this.value, this.cursor);

  /// Persisted [BlocklistRecord] model.
  @HiveField(0)
  final BlocklistRecord value;

  /// Cursor of the [value].
  @HiveField(1)
  final BlocklistCursor? cursor;

  /// Returns the [UserId] of the [value].
  UserId get userId => value.userId;
}
