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

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';

/// Persisted in storage [IpGeoLocation]'s [value].
class DtoIpGeoLocation {
  const DtoIpGeoLocation(this.value, this.updatedAt, {this.language});

  /// Persisted [IpGeoLocation] model.
  final IpGeoLocation value;

  /// [PreciseDateTime] when the [value] was persisted.
  final PreciseDateTime updatedAt;

  /// Language this [value] is on.
  final String? language;

  @override
  String toString() => '$runtimeType($value, $updatedAt, $language)';
}
