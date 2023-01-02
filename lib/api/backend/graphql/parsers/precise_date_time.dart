// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

// DateTime -> PreciseDateTime

PreciseDateTime fromGraphQLDateTimeToDartPreciseDateTime(String v) =>
    PreciseDateTime.parse(v);
String fromDartPreciseDateTimeToGraphQLDateTime(PreciseDateTime v) =>
    v.val.toUtc().toIso8601String();
List<PreciseDateTime> fromGraphQLListDateTimeToDartListPreciseDateTime(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLDateTimeToDartPreciseDateTime(e as String))
        .toList();
List<String> fromDartListPreciseDateTimeToGraphQLListDataTime(
        List<PreciseDateTime> v) =>
    v.map((e) => fromDartPreciseDateTimeToGraphQLDateTime(e)).toList();
List<PreciseDateTime>?
    fromGraphQLListNullableDateTimeToDartListNullablePreciseDateTime(
            List<Object?>? v) =>
        v
            ?.map((e) => fromGraphQLDateTimeToDartPreciseDateTime(e as String))
            .toList();
List<String>? fromDartListNullablePreciseDateTimeToGraphQLListNullableDateTime(
        List<PreciseDateTime>? v) =>
    v?.map((e) => fromDartPreciseDateTimeToGraphQLDateTime(e)).toList();

PreciseDateTime? fromGraphQLDateTimeNullableToDartPreciseDateTimeNullable(
        String? v) =>
    v == null ? null : PreciseDateTime(DateTime.parse(v));
String? fromDartPreciseDateTimeNullableToGraphQLDateTimeNullable(
        PreciseDateTime? v) =>
    v?.val.toUtc().toIso8601String();

List<PreciseDateTime?>
    fromGraphQLListDateTimeNullableToDartListPreciseDateTimeNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLDateTimeNullableToDartPreciseDateTimeNullable(
                    e as String?))
            .toList();
List<String?> fromDartListPreciseDateTimeNullableToGraphQLListDateTimeNullable(
        List<PreciseDateTime?> v) =>
    v
        .map((e) => fromDartPreciseDateTimeNullableToGraphQLDateTimeNullable(e))
        .toList();
