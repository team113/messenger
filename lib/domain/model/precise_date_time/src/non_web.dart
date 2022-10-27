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

import '/domain/model_type_id.dart';
import '/util/new_type.dart';

/// [DateTime] considering the microseconds on any platform, including Web.
class PreciseDateTime extends NewType<DateTime>
    implements Comparable<PreciseDateTime> {
  PreciseDateTime(DateTime val, {int microsecond = 0}) : super(val);

  /// Returns the number of microseconds since the "Unix epoch"
  /// 1970-01-01T00:00:00Z (UTC).
  ///
  /// This value is independent of the time zone.
  ///
  /// This value is at most 8,640,000,000,000,000,000us (100,000,000 days) from
  /// the Unix epoch.
  /// In other words: `microsecondsSinceEpoch.abs() <= 8640000000000000000`.
  ///
  /// Note that this value does not fit into 53 bits (the size of a IEEE
  /// double).
  int get microsecondsSinceEpoch => val.microsecondsSinceEpoch;

  @override
  int compareTo(PreciseDateTime other) => val.compareTo(other.val);

  /// Returns `true` if this [PreciseDateTime] occurs before [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in the
  /// local time zone.
  ///
  /// ```dart
  /// final now = PreciseDateTime.now();
  /// final earlier = now.subtract(const Duration(seconds: 5));
  /// print(earlier.isBefore(now)); // true
  /// print(!now.isBefore(now)); // true
  ///
  /// // This relation stays the same, even when changing timezones.
  /// print(earlier.isBefore(now.toUtc())); // true
  /// print(earlier.toUtc().isBefore(now)); // true
  ///
  /// print(!now.toUtc().isBefore(now)); // true
  /// print(!now.isBefore(now.toUtc())); // true
  /// ```
  bool isBefore(PreciseDateTime other) => val.isBefore(other.val);

  /// Returns `true` if this [PreciseDateTime] occurs after [other].
  ///
  /// The comparison is independent of whether the time is in UTC or in the
  /// local time zone.
  ///
  /// ```dart
  /// final now = PreciseDateTime.now();
  /// final later = now.add(const Duration(seconds: 5));
  /// print(later.isAfter(now)); // true
  /// print(!now.isBefore(now)); // true
  ///
  /// // This relation stays the same, even when changing timezones.
  /// print(later.isAfter(now.toUtc())); // true
  /// print(later.toUtc().isAfter(now)); // true
  ///
  /// print(!now.toUtc().isAfter(now)); // true
  /// print(!now.isAfter(now.toUtc())); // true
  /// ```
  bool isAfter(PreciseDateTime other) => val.isAfter(other.val);

  /// Returns a new [PreciseDateTime] instance with [duration] added.
  ///
  /// ```dart
  /// final today = PreciseDateTime.now();
  /// final fiftyDaysFromNow = today.add(const Duration(days: 50));
  /// ```
  ///
  /// Notice that the duration being added is actually 50 * 24 * 60 * 60
  /// seconds. If the resulting [PreciseDateTime] has a different daylight
  /// saving offset than this [PreciseDateTime], then the result won't have the
  /// same time-of-day as this, and may not even hit the calendar date 50 days
  /// later.
  ///
  /// Be careful when working with dates in local time.
  PreciseDateTime add(Duration duration) => PreciseDateTime(val.add(duration));

  /// Returns a new [PreciseDateTime] instance with [duration] subtracted from
  /// this [PreciseDateTime].
  ///
  /// ```dart
  /// final today = PreciseDateTime.now();
  /// final fiftyDaysAgo = today.subtract(const Duration(days: 50));
  /// ```
  ///
  /// Notice that the duration being added is actually 50 * 24 * 60 * 60
  /// seconds. If the resulting [PreciseDateTime] has a different daylight
  /// saving offset than this [PreciseDateTime], then the result won't have the
  /// same time-of-day as this, and may not even hit the calendar date 50 days
  /// later.
  ///
  /// Be careful when working with dates in local time.
  PreciseDateTime subtract(Duration duration) =>
      PreciseDateTime(val.subtract(duration));

  /// Constructs a [PreciseDateTime] instance with current date and time in the
  /// local time zone.
  ///
  /// ```dart
  /// final now = PreciseDateTime.now();
  /// ```
  static PreciseDateTime now() => PreciseDateTime(DateTime.now());

  /// Returns this [PreciseDateTime] value in the UTC time zone.
  PreciseDateTime toUtc() => PreciseDateTime(val.toUtc());

  /// Constructs a new [PreciseDateTime] instance based on [formattedString].
  ///
  /// Throws a [FormatException] if the input string cannot be parsed.
  ///
  /// The function parses a subset of ISO 8601, which includes the subset
  /// accepted by RFC 3339.
  ///
  /// The accepted inputs are currently:
  ///
  /// * A date: A signed four-to-six digit year, two digit month and
  ///   two digit day, optionally separated by `-` characters.
  ///   Examples: "19700101", "-0004-12-24", "81030-04-01".
  /// * An optional time part, separated from the date by either `T` or a space.
  ///   The time part is a two digit hour,
  ///   then optionally a two digit minutes value,
  ///   then optionally a two digit seconds value, and
  ///   then optionally a '.' or ',' followed by at least a one digit
  ///   second fraction.
  ///   The minutes and seconds may be separated from the previous parts by a
  ///   ':'.
  ///   Examples: "12", "12:30:24.124", "12:30:24,124", "123010.50".
  /// * An optional time-zone offset part,
  ///   possibly separated from the previous by a space.
  ///   The time zone is either 'z' or 'Z', or it is a signed two digit hour
  ///   part and an optional two digit minute part. The sign must be either
  ///   "+" or "-", and cannot be omitted.
  ///   The minutes may be separated from the hours by a ':'.
  ///   Examples: "Z", "-10", "+01:30", "+1130".
  ///
  /// This includes the output of [toString], which will be parsed back into a
  /// [PreciseDateTime] object with the same time as the original.
  ///
  /// The result is always in either local time or UTC. If a time zone offset
  /// other than UTC is specified, the time is converted to the equivalent UTC
  /// time.
  ///
  /// Examples of accepted strings:
  ///
  /// * `"2012-02-27"`
  /// * `"2012-02-27 13:27:00"`
  /// * `"2012-02-27 13:27:00.123456789z"`
  /// * `"2012-02-27 13:27:00,123456789z"`
  /// * `"20120227 13:27:00"`
  /// * `"20120227T132700"`
  /// * `"20120227"`
  /// * `"+20120227"`
  /// * `"2012-02-27T14Z"`
  /// * `"2012-02-27T14+00:00"`
  /// * `"-123450101 00:00:00 Z"`: in the year -12345.
  /// * `"2002-02-27T14:00:00-0500"`: Same as `"2002-02-27T19:00:00Z"`
  ///
  /// This method accepts out-of-range component values and interprets them as
  /// overflows into the next larger component.
  ///
  /// For example, "2020-01-42" will be parsed as 2020-02-11, because the last
  /// valid date in that month is 2020-01-31, so 42 days is interpreted as 31
  /// days of that month plus 11 days into the next month.
  static PreciseDateTime parse(String formattedString) =>
      PreciseDateTime(DateTime.parse(formattedString));
}

/// [Hive] adapter for a [PreciseDateTime].
class PreciseDateTimeAdapter extends TypeAdapter<PreciseDateTime> {
  @override
  final typeId = ModelTypeId.preciseDateTime;

  @override
  PreciseDateTime read(BinaryReader reader) => PreciseDateTime(
        DateTime.fromMicrosecondsSinceEpoch(reader.readInt()),
      );

  @override
  void write(BinaryWriter writer, PreciseDateTime obj) {
    writer.writeInt(obj.microsecondsSinceEpoch);
  }
}
