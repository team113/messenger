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
import '/store/model/link.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// DirectLinkSlug

DirectLinkSlug fromGraphQLDirectLinkSlugToDartDirectLinkSlug(String v) =>
    DirectLinkSlug.unchecked(v);
String fromDartDirectLinkSlugToGraphQLDirectLinkSlug(DirectLinkSlug v) => v.val;
List<DirectLinkSlug> fromGraphQLListDirectLinkSlugToDartListDirectLinkSlug(
  List<Object?> v,
) => v
    .map((e) => fromGraphQLDirectLinkSlugToDartDirectLinkSlug(e as String))
    .toList();
List<String> fromDartListDirectLinkSlugToGraphQLListDirectLinkSlug(
  List<DirectLinkSlug> v,
) => v.map((e) => fromDartDirectLinkSlugToGraphQLDirectLinkSlug(e)).toList();
List<DirectLinkSlug>?
fromGraphQLListNullableDirectLinkSlugToDartListNullableDirectLinkSlug(
  List<Object?>? v,
) => v
    ?.map((e) => fromGraphQLDirectLinkSlugToDartDirectLinkSlug(e as String))
    .toList();
List<String>?
fromDartListNullableDirectLinkSlugToGraphQLListNullableDirectLinkSlug(
  List<DirectLinkSlug>? v,
) => v?.map((e) => fromDartDirectLinkSlugToGraphQLDirectLinkSlug(e)).toList();

DirectLinkSlug? fromGraphQLDirectLinkSlugNullableToDartDirectLinkSlugNullable(
  String? v,
) => v == null ? null : DirectLinkSlug.unchecked(v);
String? fromDartDirectLinkSlugNullableToGraphQLDirectLinkSlugNullable(
  DirectLinkSlug? v,
) => v?.val;
List<DirectLinkSlug?>
fromGraphQLListDirectLinkSlugNullableToDartListDirectLinkSlugNullable(
  List<Object?> v,
) => v
    .map(
      (e) => fromGraphQLDirectLinkSlugNullableToDartDirectLinkSlugNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>
fromDartListDirectLinkSlugNullableToGraphQLListDirectLinkSlugNullable(
  List<DirectLinkSlug?> v,
) => v
    .map(
      (e) => fromDartDirectLinkSlugNullableToGraphQLDirectLinkSlugNullable(e),
    )
    .toList();
List<DirectLinkSlug?>?
fromGraphQLListNullableDirectLinkSlugNullableToDartListNullableDirectLinkSlugNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLDirectLinkSlugNullableToDartDirectLinkSlugNullable(
        e as String?,
      ),
    )
    .toList();
List<String?>?
fromDartListNullableDirectLinkSlugNullableToGraphQLListNullableDirectLinkSlugNullable(
  List<DirectLinkSlug?>? v,
) => v
    ?.map(
      (e) => fromDartDirectLinkSlugNullableToGraphQLDirectLinkSlugNullable(e),
    )
    .toList();

// DirectLinkVersion

DirectLinkVersion fromGraphQLDirectLinkVersionToDartDirectLinkVersion(
  String v,
) => DirectLinkVersion(v);
String fromDartDirectLinkVersionToGraphQLDirectLinkVersion(
  DirectLinkVersion v,
) => v.toString();
List<DirectLinkVersion>
fromGraphQLListDirectLinkVersionToDartListDirectLinkVersion(List<Object?> v) =>
    v
        .map(
          (e) =>
              fromGraphQLDirectLinkVersionToDartDirectLinkVersion(e as String),
        )
        .toList();
List<String> fromDartListDirectLinkVersionToGraphQLListDirectLinkVersion(
  List<DirectLinkVersion> v,
) => v
    .map((e) => fromDartDirectLinkVersionToGraphQLDirectLinkVersion(e))
    .toList();
List<DirectLinkVersion>?
fromGraphQLListNullableDirectLinkVersionToDartListNullableDirectLinkVersion(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLDirectLinkVersionToDartDirectLinkVersion(e as String),
    )
    .toList();
List<String>?
fromDartListNullableDirectLinkVersionToGraphQLListNullableDirectLinkVersion(
  List<DirectLinkVersion>? v,
) => v
    ?.map((e) => fromDartDirectLinkVersionToGraphQLDirectLinkVersion(e))
    .toList();

DirectLinkVersion?
fromGraphQLDirectLinkVersionNullableToDartDirectLinkVersionNullable(
  String? v,
) => v == null ? null : DirectLinkVersion(v);
String? fromDartDirectLinkVersionNullableToGraphQLDirectLinkVersionNullable(
  DirectLinkVersion? v,
) => v?.toString();
List<DirectLinkVersion?>
fromGraphQLListDirectLinkVersionNullableToDartListDirectLinkVersionNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLDirectLinkVersionNullableToDartDirectLinkVersionNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListDirectLinkVersionNullableToGraphQLListDirectLinkVersionNullable(
  List<DirectLinkVersion?> v,
) => v
    .map(
      (e) =>
          fromDartDirectLinkVersionNullableToGraphQLDirectLinkVersionNullable(
            e,
          ),
    )
    .toList();
List<DirectLinkVersion?>?
fromGraphQLListNullableDirectLinkVersionNullableToDartListNullableDirectLinkVersionNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLDirectLinkVersionNullableToDartDirectLinkVersionNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableDirectLinkVersionNullableToGraphQLListNullableDirectLinkVersionNullable(
  List<DirectLinkVersion?>? v,
) => v
    ?.map(
      (e) =>
          fromDartDirectLinkVersionNullableToGraphQLDirectLinkVersionNullable(
            e,
          ),
    )
    .toList();

// DirectLinksCursor

DirectLinksCursor fromGraphQLDirectLinksCursorToDartDirectLinksCursor(
  String v,
) => DirectLinksCursor(v);
String fromDartDirectLinksCursorToGraphQLDirectLinksCursor(
  DirectLinksCursor v,
) => v.toString();
List<DirectLinksCursor>
fromGraphQLListDirectLinksCursorToDartListDirectLinksCursor(List<Object?> v) =>
    v
        .map(
          (e) =>
              fromGraphQLDirectLinksCursorToDartDirectLinksCursor(e as String),
        )
        .toList();
List<String> fromDartListDirectLinksCursorToGraphQLListDirectLinksCursor(
  List<DirectLinksCursor> v,
) => v
    .map((e) => fromDartDirectLinksCursorToGraphQLDirectLinksCursor(e))
    .toList();
List<DirectLinksCursor>?
fromGraphQLListNullableDirectLinksCursorToDartListNullableDirectLinksCursor(
  List<Object?>? v,
) => v
    ?.map(
      (e) => fromGraphQLDirectLinksCursorToDartDirectLinksCursor(e as String),
    )
    .toList();
List<String>?
fromDartListNullableDirectLinksCursorToGraphQLListNullableDirectLinksCursor(
  List<DirectLinksCursor>? v,
) => v
    ?.map((e) => fromDartDirectLinksCursorToGraphQLDirectLinksCursor(e))
    .toList();

DirectLinksCursor?
fromGraphQLDirectLinksCursorNullableToDartDirectLinksCursorNullable(
  String? v,
) => v == null ? null : DirectLinksCursor(v);
String? fromDartDirectLinksCursorNullableToGraphQLDirectLinksCursorNullable(
  DirectLinksCursor? v,
) => v?.toString();
List<DirectLinksCursor?>
fromGraphQLListDirectLinksCursorNullableToDartListDirectLinksCursorNullable(
  List<Object?> v,
) => v
    .map(
      (e) =>
          fromGraphQLDirectLinksCursorNullableToDartDirectLinksCursorNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>
fromDartListDirectLinksCursorNullableToGraphQLListDirectLinksCursorNullable(
  List<DirectLinksCursor?> v,
) => v
    .map(
      (e) =>
          fromDartDirectLinksCursorNullableToGraphQLDirectLinksCursorNullable(
            e,
          ),
    )
    .toList();
List<DirectLinksCursor?>?
fromGraphQLListNullableDirectLinksCursorNullableToDartListNullableDirectLinksCursorNullable(
  List<Object?>? v,
) => v
    ?.map(
      (e) =>
          fromGraphQLDirectLinksCursorNullableToDartDirectLinksCursorNullable(
            e as String?,
          ),
    )
    .toList();
List<String?>?
fromDartListNullableDirectLinksCursorNullableToGraphQLListNullableDirectLinksCursorNullable(
  List<DirectLinksCursor?>? v,
) => v
    ?.map(
      (e) =>
          fromDartDirectLinksCursorNullableToGraphQLDirectLinksCursorNullable(
            e,
          ),
    )
    .toList();
