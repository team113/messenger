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

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:log_me/log_me.dart';
import 'package:sqlite3/wasm.dart';

import '/domain/model/user.dart';
import '/util/web/web.dart';

/// Obtains a database connection for running `drift` on the web.
QueryExecutor connect([UserId? userId]) {
  return DatabaseConnection.delayed(
    Future(() async {
      final String dbName = userId?.val ?? 'common';

      // TODO: Uncomment, when [WasmStorageImplementation.opfsLocks] doesn't throw
      //       file I/O errors in Chromium browsers.
      // final result = await WasmDatabase.open(
      //   databaseName: dbName,
      //   sqlite3Uri: Uri.parse('sqlite3.wasm'),
      //   driftWorkerUri: Uri.parse('drift_worker.js'),
      // );
      //
      // Log.info('Using ${result.chosenImplementation} for `drift` backend.');
      //
      // if (result.missingFeatures.isNotEmpty) {
      //   Log.warning(
      //     'Browser misses the following features in order for `drift` to be as performant as possible: ${result.missingFeatures}',
      //   );
      // }
      //
      // return result.resolvedExecutor;

      final WasmProbeResult probed = await WasmDatabase.probe(
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
        databaseName: dbName,
      );

      final List<WasmStorageImplementation> available = probed.availableStorages
          .toList();

      if (!WebUtils.isSafari && !WebUtils.isFirefox) {
        available.remove(WasmStorageImplementation.opfsLocks);
      }

      checkExisting:
      for (final (location, name) in probed.existingDatabases) {
        if (name == dbName) {
          final implementationsForStorage = switch (location) {
            WebStorageApi.indexedDb => const [
              WasmStorageImplementation.sharedIndexedDb,
              WasmStorageImplementation.unsafeIndexedDb,
            ],
            WebStorageApi.opfs => const [
              WasmStorageImplementation.opfsShared,
              WasmStorageImplementation.opfsLocks,
            ],
          };

          // If any of the implementations for this location is still available,
          // we want to use it instead of another location.
          if (implementationsForStorage.any(available.contains)) {
            available.removeWhere(
              (i) => !implementationsForStorage.contains(i),
            );
            break checkExisting;
          }
        }
      }

      // Enum values are ordered by preferability, so just pick the best option
      // left.
      available.sortBy<num>((element) => element.index);

      final best = available.firstOrNull ?? WasmStorageImplementation.inMemory;
      final DatabaseConnection connection = await probed.open(best, dbName);

      Log.info('Using $best for `drift` backend.');

      if (probed.missingFeatures.isNotEmpty) {
        Log.warning(
          'Browser misses the following features in order for `drift` to be as performant as possible: ${probed.missingFeatures}',
        );
      }

      return connection;
    }),
  );
}

/// Obtains an in-memory database connection for running `drift`.
QueryExecutor inMemory() {
  return LazyDatabase(() async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('/sqlite3.wasm'));
    sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
    return WasmDatabase.inMemory(sqlite3);
  });
}

/// Clears any database related files from the filesystem.
Future<void> clearDb() async {
  await WebUtils.cleanIndexedDb();
}
