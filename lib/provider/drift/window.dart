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

import '/store/model/window_preferences.dart';
import 'drift.dart';

/// [WindowPreferences] to be stored in a [Table].
@DataClassName('WindowRectangleRow')
class WindowRectangles extends Table {
  @override
  Set<Column> get primaryKey => {id};

  IntColumn get id => integer()();
  RealColumn get width => real().nullable()();
  RealColumn get height => real().nullable()();
  RealColumn get dx => real().nullable()();
  RealColumn get dy => real().nullable()();
}

/// [DriftProviderBase] for manipulating the persisted [WindowPreferences].
class WindowRectDriftProvider extends DriftProviderBase {
  WindowRectDriftProvider(super.database);

  /// [WindowPreferences] stored in the database.
  WindowPreferences? _prefs;

  /// [Mutex] guarding [init].
  final Mutex _guard = Mutex();

  /// Indicator whether [init] has been completed.
  bool _initialized = false;

  @override
  void onInit() {
    init();
    super.onInit();
  }

  /// Pre-initializes the [_prefs], so that they are accessible synchronously.
  Future<void> init() async {
    await _guard.protect(() async {
      if (_initialized) {
        return;
      }

      _prefs = await read();

      _initialized = true;
    });
  }

  /// Creates or updates the provided [prefs] in the database.
  Future<void> upsert(WindowPreferences prefs) async {
    await safe((db) async {
      await db
          .into(db.windowRectangles)
          .insertReturning(
            prefs.toDb(),
            onConflict: DoUpdate((_) => prefs.toDb()),
          );
    });
  }

  /// Returns the [WindowPreferences] stored in the database.
  Future<WindowPreferences?> read() async {
    if (_prefs != null) {
      return _prefs;
    }

    return await safe<WindowPreferences?>((db) async {
      final stmt = db.select(db.windowRectangles)..where((u) => u.id.equals(0));
      final WindowRectangleRow? row = await stmt.getSingleOrNull();

      if (row == null) {
        return null;
      }

      return _prefs = _WindowPreferencesDb.fromDb(row);
    }, exclusive: false);
  }

  /// Deletes the stored [WindowPreferences] from the database.
  Future<void> delete() async {
    await safe((db) async {
      await db.delete(db.versions).go();
    });
  }
}

/// Extension adding conversion methods from [WindowRectangleRow] to
/// [WindowPreferences].
extension _WindowPreferencesDb on WindowPreferences {
  /// Constructs a [WindowPreferences] from the provided [WindowRectangleRow].
  static WindowPreferences fromDb(WindowRectangleRow e) {
    return WindowPreferences(
      width: e.width,
      height: e.height,
      dx: e.dx,
      dy: e.dy,
    );
  }

  /// Constructs a [WindowRectangleRow] from this [WindowPreferences].
  WindowRectangleRow toDb() {
    return WindowRectangleRow(
      id: 0,
      width: width,
      height: height,
      dx: dx,
      dy: dy,
    );
  }
}
