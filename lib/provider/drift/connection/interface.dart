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

import 'package:drift/drift.dart';

import '/domain/model/user.dart';

/// Obtains a database connection for running `drift`.
QueryExecutor connect([UserId? userId]) {
  throw UnsupportedError('`drift` isn\'t supported on this platform.');
}

/// Obtains an in-memory database connection for running `drift`.
QueryExecutor inMemory() {
  throw UnsupportedError(
    'In-memory database isn\'t supported on this platform.',
  );
}

/// Clears any database related files from the filesystem.
Future<void> clearDb() {
  throw UnsupportedError(
    'Database clearing isn\'t supported on this platform.',
  );
}
