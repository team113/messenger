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

import '/domain/model/link.dart';
import '/util/new_type.dart';
import 'version.dart';

/// Persisted in storage [DirectLink]'s [value].
class DtoDirectLink {
  DtoDirectLink(this.value, this.ver, this.cursor);

  /// Persisted [DirectLink] model.
  DirectLink value;

  /// Version of this [DirectLink]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  DirectLinkVersion ver;

  /// Cursor of a [value].
  DirectLinksCursor? cursor;

  @override
  String toString() => '$runtimeType($value, $ver)';
}

/// Version of a [DirectLink]'s state.
class DirectLinkVersion extends Version {
  DirectLinkVersion(super.val);
}

/// Cursor of a list of [DirectLink]s.
class DirectLinksCursor extends NewType<String> {
  DirectLinksCursor(super.val);
}
