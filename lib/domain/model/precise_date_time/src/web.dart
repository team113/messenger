// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';
import '/util/new_type.dart';

/// [DateTime] considering the microseconds on any platform, including Web.
class PreciseDateTime extends NewType<DateTime>
    implements Comparable<PreciseDateTime> {
  PreciseDateTime(DateTime val, {this.microsecond = 0}) : super(val);

  /// Microseconds of this [PreciseDateTime].
  ///
  /// Stored independently from [DateTime], since on Web its microseconds are
  /// ignored.
  final int microsecond;

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
  int get microsecondsSinceEpoch => val.microsecondsSinceEpoch + microsecond;

  @override
  int compareTo(PreciseDateTime other) {
    if (val == other.val) {
      return microsecond.compareTo(other.microsecond);
    }
    return val.compareTo(other.val);
  }

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
  bool isBefore(PreciseDateTime other) {
    if (val == other.val) {
      return microsecond < other.microsecond;
    }
    return val.isBefore(other.val);
  }

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
  bool isAfter(PreciseDateTime other) {
    if (val == other.val) {
      return microsecond > other.microsecond;
    }
    return val.isAfter(other.val);
  }

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
  PreciseDateTime add(Duration duration) => PreciseDateTime(
        val.add(duration),
        microsecond: microsecond +
            (duration.inMicroseconds - duration.inMilliseconds * 1000),
      );

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
  PreciseDateTime subtract(Duration duration) => PreciseDateTime(
        val.subtract(duration),
        microsecond: microsecond -
            (duration.inMicroseconds - duration.inMilliseconds * 1000),
      );

  /// Constructs a [PreciseDateTime] instance with current date and time in the
  /// local time zone.
  ///
  /// ```dart
  /// final now = PreciseDateTime.now();
  /// ```
  static PreciseDateTime now() => PreciseDateTime(DateTime.now());

  /// Returns this [PreciseDateTime] value in the UTC time zone.
  PreciseDateTime toUtc() =>
      PreciseDateTime(val.toUtc(), microsecond: microsecond);

  /// Constructs a new [PreciseDateTime] instance based on [formattedString].
  ///
  /// The function parses a subset of ISO 8601, which includes the subset
  /// accepted by RFC 3339.
  ///
  /// This includes the output of [toString], which will be parsed back into a
  /// [PreciseDateTime] object with the same time as the original.
  ///
  /// Examples of accepted strings:
  ///
  /// * `"2012-02-27 13:27:00,123456Z"`
  /// * `'2022-06-03T12:38:34.366158Z'`
  /// * `'2022-06-03T12:38:34.366Z'`
  /// * `'2022-06-03T12:38:34.366000Z'`
  /// * `'2022-06-03T12:38:35Z'`
  ///
  static PreciseDateTime parse(String formattedString) {
    if (formattedString.contains('.')) {
      var split = formattedString.split('.');
      if (split[1].length != 7) {
        split[1] = '${split[1].replaceFirst('Z', '').padRight(6, '0')}Z';
      }

      int microseconds =
          int.tryParse(split[1].substring(3).replaceFirst('Z', '')) ?? 0;
      split[1] = '${split[1].substring(0, 3)}Z';
      return PreciseDateTime(
        DateTime.parse(split.join('.')),
        microsecond: microseconds,
      );
    }

    return PreciseDateTime(DateTime.parse(formattedString));
  }

  @override
  String toString() {
    final formattedString = val.toString();
    var split = formattedString.split('.');
    if (microsecond > 0) {
      split[1] = split[1].replaceFirst('Z', '');
      String microsecondsStr = microsecond.toString().padLeft(3, '0');
      if (microsecondsStr.length < 3) {
        microsecondsStr =
            microsecondsStr.padLeft(3 - microsecondsStr.length, '0');
      }

      split[1] = split[1].substring(0, 3) + microsecondsStr;
      var result = '${split.join('.')}Z';
      return result;
    }

    return formattedString;
  }
}

/// [Hive] adapter for a [PreciseDateTime].
class PreciseDateTimeAdapter extends TypeAdapter<PreciseDateTime> {
  @override
  final typeId = ModelTypeId.preciseDateTime;

  @override
  PreciseDateTime read(BinaryReader reader) => PreciseDateTime(
        DateTime.fromMillisecondsSinceEpoch(reader.readInt(), isUtc: true),
        microsecond: reader.readInt(),
      );

  @override
  void write(BinaryWriter writer, PreciseDateTime obj) {
    writer.writeInt(obj.val.millisecondsSinceEpoch);
    writer.writeInt(obj.microsecond);
  }
}
