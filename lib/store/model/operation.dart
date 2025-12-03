// Copyright © 2025 Ideas Networks Solutions S.A.,
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

import '/domain/model/operation.dart';
import '/util/new_type.dart';
import 'version.dart';

/// Persisted in storage [Operation]'s [value].
class DtoOperation implements Comparable<DtoOperation> {
  DtoOperation(this.value, this.version, {this.cursor});

  /// Persisted [Operation] model.
  final Operation value;

  /// Version of the [value].
  final OperationVersion version;

  /// Cursor of the [value].
  final OperationsCursor? cursor;

  /// Returns the [OperationId] of the [value].
  OperationId get id => value.id;

  @override
  int compareTo(DtoOperation other) {
    final result = value.createdAt.compareTo(other.value.createdAt);
    if (result == 0) {
      return id.val.compareTo(other.id.val);
    }

    return result;
  }
}

/// Version of the [Operation]'s state.
class OperationVersion extends Version {
  OperationVersion(super.val);
}

/// Cursor of [Operation]s.
class OperationsCursor extends NewType<String> {
  OperationsCursor(super.val);
}
