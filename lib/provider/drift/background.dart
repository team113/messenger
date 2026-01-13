// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
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

import 'package:async/async.dart';
import 'package:drift/drift.dart';

import '/domain/model/user.dart';
import '/domain/service/disposable_service.dart';
import '/store/model/background.dart';
import 'drift.dart';

/// [DtoBackground] to be stored in a [Table].
@DataClassName('BackgroundRow')
class Background extends Table {
  @override
  Set<Column> get primaryKey => {userId};

  TextColumn get userId => text()();
  BlobColumn get data => blob()();
}

/// [DriftProviderBase] for manipulating the persisted [DtoBackground].
class BackgroundDriftProvider extends DriftProviderBase with IdentityAware {
  BackgroundDriftProvider(super.database);

  /// [StreamController] emitting [DtoBackground]s in [watch].
  final Map<UserId, StreamController<DtoBackground?>> _controllers = {};

  /// [DtoBackground]s that have started the [upsert]ing, but not yet finished
  /// it.
  final Map<UserId, DtoBackground> _cache = {};

  @override
  int get order => IdentityAware.providerOrder;

  @override
  void onIdentityChanged(UserId me) {
    _cache.clear();
  }

  /// Creates or updates the provided [background] in the database.
  Future<DtoBackground> upsert(UserId userId, DtoBackground background) async {
    _cache[userId] = background;

    final result = await safe((db) async {
      final DtoBackground stored = _BackgroundDb.fromDb(
        await db
            .into(db.background)
            .insertReturning(
              background.toDb(userId),
              mode: InsertMode.insertOrReplace,
            ),
      );

      _controllers[userId]?.add(stored);

      return stored;
    });

    return result ?? background;
  }

  /// Returns the [DtoBackground] stored in the database by the provided [id],
  /// if any.
  Future<DtoBackground?> read(UserId id) async {
    final DtoBackground? existing = _cache[id];
    if (existing != null) {
      return existing;
    }

    return await safe<DtoBackground?>((db) async {
      final stmt = db.select(db.background)
        ..where((u) => u.userId.equals(id.val));
      final BackgroundRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _BackgroundDb.fromDb(row);
    }, exclusive: false);
  }

  /// Deletes the [DtoBackground] identified by the provided [id] from the
  /// database.
  Future<void> delete(UserId id) async {
    _cache.remove(id);

    await safe((db) async {
      final stmt = db.delete(db.background)
        ..where((e) => e.userId.equals(id.val));
      await stmt.go();

      _controllers[id]?.add(null);
    });
  }

  /// Deletes all the [DtoBackground]s stored in the database.
  Future<void> clear() async {
    _cache.clear();

    await safe((db) async {
      await db.delete(db.background).go();
    });
  }

  /// Returns the [Stream] of real-time changes happening with the
  /// [DtoBackground] identified by the provided [id].
  Stream<DtoBackground?> watch(UserId id) {
    return stream((db) {
      final stmt = db.select(db.background)
        ..where((u) => u.userId.equals(id.val));

      StreamController<DtoBackground?>? controller = _controllers[id];
      if (controller == null) {
        controller = StreamController<DtoBackground?>.broadcast(sync: true);
        _controllers[id] = controller;
      }

      return StreamGroup.merge([
        controller.stream,
        stmt.watch().map(
          (e) => e.isEmpty ? null : _BackgroundDb.fromDb(e.first),
        ),
      ]);
    });
  }
}

/// Extension adding conversion methods from [BackgroundRow] to [DtoBackground].
extension _BackgroundDb on DtoBackground {
  /// Constructs a [DtoBackground] from the provided [BackgroundRow].
  static DtoBackground fromDb(BackgroundRow e) {
    return DtoBackground(e.data);
  }

  /// Constructs a [BackgroundRow] from this [DtoBackground].
  BackgroundRow toDb(UserId userId) {
    return BackgroundRow(userId: userId.val, data: bytes);
  }
}
