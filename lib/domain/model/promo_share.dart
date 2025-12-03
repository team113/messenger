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

import '/util/new_type.dart';
import 'precise_date_time/precise_date_time.dart';

/// [Percentage] for each transaction that an author [User] shares with their
/// promoter [User]s.
class PromoShare {
  const PromoShare({
    required this.percentage,
    required this.addedAt,
    this.removedAt,
  });

  /// [Percentage] of this [PromoShare].
  final Percentage percentage;

  /// [PreciseDateTime] when this [PromoShare] was added.
  final PreciseDateTime addedAt;

  /// [PreciseDateTime] when this [PromoShare] was removed, if any.
  ///
  /// `null` if this [PromoShare] is not removed and is currently active.
  final PreciseDateTime? removedAt;

  @override
  bool operator ==(Object other) =>
      other is PromoShare &&
      percentage == other.percentage &&
      addedAt == other.addedAt &&
      removedAt == other.removedAt;

  @override
  int get hashCode => Object.hash(percentage, addedAt, removedAt);
}

/// Percentage value in range between 1 and 100 inclusively.
class Percentage extends NewType<String> {
  const Percentage(super.val);
}
