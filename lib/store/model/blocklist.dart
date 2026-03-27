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

import '/domain/model/user.dart';
import 'my_user.dart';
import 'version.dart';

/// Persisted in storage [BlocklistRecord]'s [value].
class DtoBlocklistRecord implements Comparable<DtoBlocklistRecord> {
  DtoBlocklistRecord(this.value, this.cursor);

  /// Persisted [BlocklistRecord] model.
  final BlocklistRecord value;

  /// Cursor of the [value].
  final BlocklistCursor? cursor;

  /// Returns the [UserId] of the [value].
  UserId get userId => value.userId;

  @override
  int compareTo(DtoBlocklistRecord other) {
    final result = value.at.compareTo(other.value.at);
    if (result == 0) {
      return userId.val.compareTo(other.userId.val);
    }

    return result;
  }
}

/// Version of [MyUser]'s [BlocklistRecord]s list.
class BlocklistVersion extends Version {
  BlocklistVersion(super.val);
}
