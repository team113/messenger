// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:hive/hive.dart';

import '../model_type_id.dart';
import 'precise_date_time/precise_date_time.dart';

part 'mute_duration.g.dart';

/// Mute duration of a [Chat] or [MyUser].
@HiveType(typeId: ModelTypeId.muteDuration)
class MuteDuration {
  /// Mute duration until an exact [PreciseDateTime].
  ///
  /// Once this [PreciseDateTime] pasts (or is in the past already), it should
  /// be considered as automatically unmuted.
  @HiveField(0)
  PreciseDateTime? until;

  /// Forever mute duration.
  @HiveField(1)
  bool? forever;

  @HiveField(2)
  MuteDuration({
    this.until,
    this.forever,
  });

  factory MuteDuration.forever() => MuteDuration(forever: true);

  factory MuteDuration.until(PreciseDateTime until) =>
      MuteDuration(until: until);
}
