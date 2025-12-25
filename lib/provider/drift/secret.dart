// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/session.dart';
import '/domain/model/user.dart';
import 'drift.dart';

/// [UserId] with their [RefreshTokenSecretInput] and [AccessTokenSecretInput]
/// to be stored in a [Table].
@DataClassName('RefreshSecretRow')
class RefreshSecrets extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text()();
  TextColumn get refresh => text()();
  TextColumn get access => text()();
}

/// [DriftProviderBase] for manipulating the persisted [RefreshSessionSecrets].
class RefreshSecretDriftProvider extends DriftProviderBase {
  RefreshSecretDriftProvider(super.common);

  /// Retrieves the [RefreshSessionSecrets], if those are present, or generates
  /// and writes to the database the new secrets.
  Future<RefreshSessionSecrets> getOrCreate(UserId userId) async {
    final result = await safe((db) async {
      return await db.transaction(() async {
        final stmt = db.select(db.refreshSecrets)
          ..where((e) => e.userId.equals(userId.val));
        final existing = await stmt.getSingleOrNull();

        if (existing != null) {
          return _RefreshSessionSecretsDb.fromDb(existing);
        }

        final secrets = RefreshSessionSecrets.generate().toDb(userId);
        final row = await db
            .into(db.refreshSecrets)
            .insertReturning(
              secrets,
              mode: InsertMode.insert,
              onConflict: DoUpdate((_) => secrets),
            );

        return _RefreshSessionSecretsDb.fromDb(row);
      });
    }, tag: 'refresh_secrets.getOrCreate($userId)');

    return result ?? RefreshSessionSecrets.generate();
  }

  /// Deletes the secrets associated with the provided [userId].
  Future<void> delete(UserId userId) async {
    await safe((db) async {
      final stmt = db.delete(db.refreshSecrets)
        ..where((e) => e.userId.equals(userId.val));
      await stmt.go();
    }, tag: 'refresh_secrets.delete($userId)');
  }

  /// Deletes all the secrets stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.refreshSecrets).go();
    }, tag: 'refresh_secrets.clear()');
  }
}

/// Extension adding conversion methods from [RefreshSecretRow] to
/// [RefreshSessionSecrets].
extension _RefreshSessionSecretsDb on RefreshSessionSecrets {
  /// Constructs the [RefreshSessionSecrets] from the provided
  /// [RefreshSecretRow].
  static RefreshSessionSecrets fromDb(RefreshSecretRow e) {
    return RefreshSessionSecrets(
      RefreshTokenSecretInput(e.refresh),
      AccessTokenSecretInput(e.access),
    );
  }

  /// Constructs a [RefreshSecretRow] from this [RefreshSecretRow].
  RefreshSecretRow toDb(UserId userId) {
    return RefreshSecretRow(
      userId: userId.val,
      access: access.val,
      refresh: refresh.val,
    );
  }
}
