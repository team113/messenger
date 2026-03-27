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
import 'package:mutex/mutex.dart';

import '/domain/model/user.dart';
import 'drift.dart';

/// [UserId] of the currently active [MyUser] to be stored in a [Table].
@DataClassName('AccountRow')
class Accounts extends Table {
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get id => integer()();
  TextColumn get userId => text()();
}

/// [DriftProviderBase] for manipulating the persisted [UserId] of the active
/// [MyUser].
class AccountDriftProvider extends DriftProviderBase {
  AccountDriftProvider(super.database);

  /// [UserId] of the active [MyUser] stored in the database.
  UserId? _userId;

  /// [Mutex] guarding [init].
  final Mutex _guard = Mutex();

  /// Indicator whether [init] has been completed.
  bool _initialized = false;

  /// Returns the [UserId] of the active [MyUser] stored in the database.
  ///
  /// __Note__, that this field should be used afterwards the [init] is invoked,
  /// as otherwise it may contain outdated data.
  UserId? get userId => _userId;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  /// Pre-initializes the [_userId], so that it is accessible synchronously.
  Future<void> init() async {
    await _guard.protect(() async {
      if (_initialized) {
        return;
      }

      _userId = await read();

      _initialized = true;
    });
  }

  /// Creates or updates the provided [userId] in the database.
  Future<void> upsert(UserId userId) async {
    _userId = userId;

    await safe((db) async {
      await db
          .into(db.accounts)
          .insert(
            AccountRow(id: 0, userId: userId.val),
            mode: InsertMode.insertOrReplace,
          );
    }, tag: 'account.upsert($userId)');
  }

  /// Returns the currently active [UserId] account stored in the database.
  Future<UserId?> read() async {
    return await safe<UserId?>((db) async {
      final stmt = db.select(db.accounts)..where((e) => e.id.equals(0));
      final AccountRow? row = await stmt.getSingleOrNull();
      _userId = row == null ? null : UserId(row.userId);

      return _userId;
    }, tag: 'account.read()');
  }

  /// Deletes the currently active [UserId] account stored in the database.
  Future<void> delete() async {
    _userId = null;

    await safe((db) async {
      await db.delete(db.accounts).go();
    }, tag: 'account.delete()');
  }

  /// Deletes the currently active [UserId] account stored in the database.
  Future<void> clear() => delete();
}
