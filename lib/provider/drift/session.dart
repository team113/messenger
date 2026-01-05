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

import '/domain/model/session.dart';
import '/util/obs/obs.dart';
import 'common.dart';
import 'drift.dart';

/// [Session]s to be stored in a [Table].
@DataClassName('SessionRow')
class Sessions extends Table {
  @override
  Set<Column> get primaryKey => {id};

  TextColumn get id => text()();
  TextColumn get ip => text()();
  TextColumn get userAgent => text()();
  IntColumn get lastActivatedAt =>
      integer().map(const PreciseDateTimeConverter())();
}

/// [DriftProviderBase] for manipulating the persisted [Session].
class SessionDriftProvider extends DriftProviderBaseWithScope {
  SessionDriftProvider(super.database, super.scoped);

  /// Creates or updates the provided [session] in the database.
  Future<Session> upsert(Session session) async {
    final result = await safe((db) async {
      final Session stored = _SessionDb.fromDb(
        await db
            .into(db.sessions)
            .insertReturning(
              session.toDb(),
              onConflict: DoUpdate((_) => session.toDb()),
            ),
      );

      return stored;
    });

    return result ?? session;
  }

  /// Inserts the provided [sessions] to the database.
  Future<void> upsertBulk(List<Session> sessions) async {
    for (var session in sessions) {
      await upsert(session);
    }
  }

  /// Returns the [Session] stored in the database by the provided [id], if any.
  Future<Session?> read(SessionId id) async {
    return await safe<Session?>((db) async {
      final stmt = db.select(db.sessions)..where((u) => u.id.equals(id.val));
      final SessionRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _SessionDb.fromDb(row);
    }, exclusive: false);
  }

  /// Deletes the [Session] identified by the provided [id] from the database.
  Future<void> delete(SessionId id) async {
    await safe((db) async {
      final stmt = db.delete(db.sessions)..where((e) => e.id.equals(id.val));
      await stmt.go();
    });
  }

  /// Deletes all the [Session]s stored in the database.
  Future<void> clear() async {
    await safe((db) async {
      await db.delete(db.sessions).go();
    });
  }

  /// Returns the [Stream] of [Session]s stored.
  Stream<List<MapChangeNotification<SessionId, Session>>> watch() {
    return stream((db) {
      final stmt = db.select(db.sessions);
      stmt.orderBy([(u) => OrderingTerm.desc(u.lastActivatedAt)]);
      return stmt
          .watch()
          .map((rows) => {for (var e in rows.map(_SessionDb.fromDb)) e.id: e})
          .changes();
    });
  }
}

/// Extension adding conversion methods from [SessionRow] to [Session].
extension _SessionDb on Session {
  /// Constructs a [Session] from the provided [SessionRow].
  static Session fromDb(SessionRow e) {
    return Session(
      id: SessionId(e.id),
      ip: IpAddress(e.ip),
      userAgent: UserAgent(e.userAgent),
      lastActivatedAt: e.lastActivatedAt,
    );
  }

  /// Constructs a [SessionRow] from this [Session].
  SessionRow toDb() {
    return SessionRow(
      id: id.val,
      ip: ip.val,
      userAgent: userAgent.val,
      lastActivatedAt: lastActivatedAt,
    );
  }
}
