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

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '/domain/model/user.dart';
import '/util/ios_utils.dart';
import '/util/platform_utils.dart';

/// Obtains a database connection for running `drift` in a Dart VM.
QueryExecutor connect([UserId? userId]) {
  return LazyDatabase(() async {
    final Directory dbFolder;

    if (PlatformUtils.isIOS) {
      dbFolder = Directory(await IosUtils.getSharedDirectory());
    } else {
      dbFolder = await getApplicationDocumentsDirectory();
    }

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

    return NativeDatabase.createInBackground(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode = wal'),
    );
  });
}

/// Obtains an in-memory database connection for running `drift`.
QueryExecutor inMemory() {
  return NativeDatabase.memory();
}
