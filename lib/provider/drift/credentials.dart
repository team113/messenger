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
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mutex/mutex.dart';

import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import 'drift.dart';

/// [Credentials] to be stored in a [Table].
@DataClassName('TokenRow')
class Tokens extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text()();
  TextColumn get credentials => text()();
}

/// [DriftProviderBase] for manipulating the persisted [Credentials].
class CredentialsDriftProvider extends DriftProviderBase {
  CredentialsDriftProvider(super.database);

  /// [Credentials] stored in the database and accessible synchronously.
  ///
  /// __Note__, that this field only should be used, if [init] was invoked
  /// before any operations with the database, or otherwise it may contain
  /// incomplete data.
  final Map<UserId, Credentials> data = {};

  /// [Mutex] guarding [init].
  final Mutex _guard = Mutex();

  /// Indicator whether [init] has been completed.
  bool _initialized = false;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  /// Pre-initializes the [data], so that it is accessible synchronously.
  Future<void> init() async {
    await _guard.protect(() async {
      if (_initialized) {
        return;
      }

      for (var e in await all()) {
        data[e.userId] = e;
      }

      _initialized = true;
    });
  }

  /// Returns all the [Credentials] stored in the database.
  Future<List<Credentials>> all() async {
    final result = await safe((db) async {
      final stmt = await db.select(db.tokens).get();
      return stmt
          .map((c) {
            try {
              return _CredentialsDb.fromDb(c);
            } catch (e) {
              Log.error('Unable to decode `Credentials`: $e', '$runtimeType');
              Log.error(
                'The credentials stored are: `${c.credentials}`',
                '$runtimeType',
              );
              return null;
            }
          })
          .nonNulls
          .toList();
    }, exclusive: false);

    return result ?? [];
  }

  /// Creates or updates the provided [creds] in the database.
  Future<Credentials> upsert(Credentials creds) async {
    data[creds.userId] = creds;

    final result = await safe<Credentials?>((db) async {
      final Credentials stored = _CredentialsDb.fromDb(
        await db
            .into(db.tokens)
            .insertReturning(
              creds.toDb(),
              onConflict: DoUpdate((_) => creds.toDb()),
            ),
      );

      return stored;
    });

    return result ?? creds;
  }

  /// Returns the [Credentials] stored in the database by the provided [id], if
  /// any.
  Future<Credentials?> read(UserId id, {bool refresh = false}) async {
    final Credentials? existing = data[id];
    if (existing != null && !refresh) {
      return existing;
    }

    final result = await safe<Credentials?>((db) async {
      final stmt = db.select(db.tokens)..where((u) => u.userId.equals(id.val));
      final TokenRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _CredentialsDb.fromDb(row);
    }, exclusive: false);

    if (result == null) {
      return null;
    }

    return data[id] = result;
  }

  /// Deletes the [Credentials] identified by the provided [id] from the
  /// database.
  Future<void> delete(UserId id) async {
    data.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.tokens)..where((e) => e.userId.equals(id.val));
      await stmt.go();
    });
  }

  /// Deletes all the [Credentials]s stored in the database.
  Future<void> clear() async {
    data.clear();

    await safe((db) async {
      await db.delete(db.tokens).go();
    });
  }

  /// Returns the [Stream] of real-time changes happening with the
  /// [Credentials].
  Stream<List<MapChangeNotification<UserId, Credentials?>>> watch() {
    return stream((db) {
      final stmt = db.select(db.tokens);
      return stmt
          .watch()
          .map((rows) => rows.map(_CredentialsDb.fromDb).toList())
          .map((i) => {for (var e in i) e.userId: e})
          .changes();
    });
  }
}

/// Extension adding conversion methods from [TokenRow] to [Credentials].
extension _CredentialsDb on Credentials {
  /// Constructs the [Credentials] from the provided [TokenRow].
  static Credentials fromDb(TokenRow e) {
    return Credentials.fromJson(jsonDecode(e.credentials));
  }

  /// Constructs a [TokenRow] from these [Credentials].
  TokenRow toDb() {
    return TokenRow(userId: userId.val, credentials: jsonEncode(toJson()));
  }
}
