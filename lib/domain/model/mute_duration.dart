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

import 'package:json_annotation/json_annotation.dart';

import 'precise_date_time/precise_date_time.dart';

part 'mute_duration.g.dart';

/// Mute duration of a [Chat] or [MyUser].
@JsonSerializable()
class MuteDuration {
  MuteDuration({this.until, this.forever});

  factory MuteDuration.forever() => MuteDuration(forever: true);

  factory MuteDuration.until(PreciseDateTime until) =>
      MuteDuration(until: until);

  /// Constructs a [MuteDuration] from the provided [json].
  factory MuteDuration.fromJson(Map<String, dynamic> json) =>
      _$MuteDurationFromJson(json);

  /// Mute duration until an exact [PreciseDateTime].
  ///
  /// Once this [PreciseDateTime] pasts (or is in the past already), it should
  /// be considered as automatically unmuted.
  PreciseDateTime? until;

  /// Forever mute duration.
  bool? forever;

  @override
  bool operator ==(Object other) =>
      other is MuteDuration && until == other.until && forever == other.forever;

  @override
  int get hashCode => Object.hash(until, forever);

  /// Returns a [Map] representing this [MuteDuration].
  Map<String, dynamic> toJson() => _$MuteDurationToJson(this);
}
