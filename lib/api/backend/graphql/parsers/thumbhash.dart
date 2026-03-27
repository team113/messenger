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

import '/domain/model/file.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// ThumbHash

ThumbHash fromGraphQLThumbHashToDartThumbHash(String v) => ThumbHash(v);
String fromDartThumbHashToGraphQLThumbHash(ThumbHash v) => v.val;
List<ThumbHash> fromGraphQLListThumbHashToDartListThumbHash(List<Object?> v) =>
    v.map((e) => fromGraphQLThumbHashToDartThumbHash(e as String)).toList();
List<String> fromDartListThumbHashToGraphQLListThumbHash(List<ThumbHash> v) =>
    v.map((e) => fromDartThumbHashToGraphQLThumbHash(e)).toList();
List<ThumbHash>? fromGraphQLListNullableThumbHashToDartListNullableThumbHash(
  List<Object?>? v,
) => v?.map((e) => fromGraphQLThumbHashToDartThumbHash(e as String)).toList();
List<String>? fromDartListNullableThumbHashToGraphQLListNullableThumbHash(
  List<ThumbHash>? v,
) => v?.map((e) => fromDartThumbHashToGraphQLThumbHash(e)).toList();

ThumbHash? fromGraphQLThumbHashNullableToDartThumbHashNullable(String? v) =>
    v == null ? null : ThumbHash(v);
String? fromDartThumbHashNullableToGraphQLThumbHashNullable(ThumbHash? v) =>
    v?.val;
List<ThumbHash?> fromGraphQLListThumbHashNullableToDartListThumbHashNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLThumbHashNullableToDartThumbHashNullable(e as String?),
    )
    .toList();
List<String?> fromDartListThumbHashNullableToGraphQLListThumbHashNullable(
  List<ThumbHash?> v,
) => v
    .map((e) => fromDartThumbHashNullableToGraphQLThumbHashNullable(e))
    .toList();
List<ThumbHash?>?
fromGraphQLListNullableThumbHashNullableToDartListNullableThumbHashNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLThumbHashNullableToDartThumbHashNullable(e as String?),
    )
    .toList();
List<String?>?
fromDartListNullableThumbHashNullableToGraphQLListNullableThumbHashNullable(
  List<ThumbHash?>? v,
) => v
    ?.map((e) => fromDartThumbHashNullableToGraphQLThumbHashNullable(e))
    .toList();
