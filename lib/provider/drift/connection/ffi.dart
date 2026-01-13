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

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:log_me/log_me.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '/config.dart';
import '/domain/model/user.dart';
import '/provider/drift/interceptor/log.dart';
import '/util/ios_utils.dart';
import '/util/platform_utils.dart';

/// Obtains a database connection for running `drift` in a Dart VM.
QueryExecutor connect([UserId? userId]) {
  return LazyDatabase(() async {
    final Directory dbFolder;

    if (PlatformUtils.isIOS) {
      dbFolder = Directory(await IosUtils.getSharedDirectory());
    } else {
      dbFolder = await PlatformUtils.libraryDirectory;
    }

    Log.debug(
      'connect() -> `drift` will place its files to `${dbFolder.path}`.',
    );

    final File file = File(
      p.join(dbFolder.path, '${userId?.val ?? 'common'}.sqlite'),
    );

    // Workaround limitations on old Android versions.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    // Make `sqlite3` pick a more suitable location for temporary files - the
    // one from the system may be inaccessible due to sandboxing.
    final String cache = (await getTemporaryDirectory()).path;

    // We can't access `/tmp` on Android, which `sqlite3` would try by default.
    // Explicitly tell it about the correct temporary directory.
    sqlite3.tempDirectory = cache;

    final connection = NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode = wal'),
    );

    if (!Config.logDatabase) {
      return connection;
    }

    return connection.interceptWith(LogInterceptor());
  });
}

/// Obtains an in-memory database connection for running `drift`.
QueryExecutor inMemory() {
  return NativeDatabase.memory();
}

/// Clears any database related files from the filesystem.
Future<void> clearDb() async {
  final Directory dbFolder;

  if (PlatformUtils.isIOS) {
    dbFolder = Directory(await IosUtils.getSharedDirectory());
  } else {
    dbFolder = await PlatformUtils.libraryDirectory;
  }

  await for (FileSystemEntity entity in dbFolder.list()) {
    if (entity is File) {
      if (entity.path.endsWith('.sqlite') ||
          entity.path.endsWith('.sqlite-shm') ||
          entity.path.endsWith('.sqlite-wal')) {
        await entity.delete();
      }
    }
  }
}
