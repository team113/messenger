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

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:log_me/log_me.dart';

/// Obtains a database connection for running `drift` on the web.
QueryExecutor connect() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'my_app_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );

    Log.info('Using ${result.chosenImplementation} for `drift` backend.');

    if (result.missingFeatures.isNotEmpty) {
      Log.warning(
        'Browser misses the following features in order for `drift` to be as performant as possible: ${result.missingFeatures}',
      );
    }

    return result.resolvedExecutor;
  }));
}
