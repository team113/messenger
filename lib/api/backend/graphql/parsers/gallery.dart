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

import '/domain/model/gallery_item.dart';

// ignore: todo
// TODO: Change List<Object?> to List<String>.
// Needs https://github.com/google/json_serializable.dart/issues/806

// GalleryItemId

GalleryItemId fromGraphQLGalleryItemIdToDartGalleryItemId(String v) =>
    GalleryItemId(v);
String fromDartGalleryItemIdToGraphQLGalleryItemId(GalleryItemId v) => v.val;
List<GalleryItemId> fromGraphQLListGalleryItemIdToDartListGalleryItemId(
        List<Object?> v) =>
    v
        .map((e) => fromGraphQLGalleryItemIdToDartGalleryItemId(e as String))
        .toList();
List<String> fromDartListGalleryItemIdToGraphQLListGalleryItemId(
        List<GalleryItemId> v) =>
    v.map((e) => fromDartGalleryItemIdToGraphQLGalleryItemId(e)).toList();
List<GalleryItemId>?
    fromGraphQLListNullableGalleryItemIdToDartListNullableGalleryItemId(
            List<Object?>? v) =>
        v
            ?.map(
                (e) => fromGraphQLGalleryItemIdToDartGalleryItemId(e as String))
            .toList();
List<String>?
    fromDartListNullableGalleryItemIdToGraphQLListNullableGalleryItemId(
            List<GalleryItemId>? v) =>
        v?.map((e) => fromDartGalleryItemIdToGraphQLGalleryItemId(e)).toList();

GalleryItemId? fromGraphQLGalleryItemIdNullableToDartGalleryItemIdNullable(
        String? v) =>
    v == null ? null : GalleryItemId(v);
String? fromDartGalleryItemIdNullableToGraphQLGalleryItemIdNullable(
        GalleryItemId? v) =>
    v?.val;
List<GalleryItemId?>
    fromGraphQLListGalleryItemIdNullableToDartListGalleryItemIdNullable(
            List<Object?> v) =>
        v
            .map((e) =>
                fromGraphQLGalleryItemIdNullableToDartGalleryItemIdNullable(
                    e as String?))
            .toList();
List<String?>
    fromDartListGalleryItemIdNullableToGraphQLListGalleryItemIdNullable(
            List<GalleryItemId?> v) =>
        v
            .map((e) =>
                fromDartGalleryItemIdNullableToGraphQLGalleryItemIdNullable(e))
            .toList();
List<GalleryItemId?>?
    fromGraphQLListNullableGalleryItemIdNullableToDartListNullableGalleryItemIdNullable(
            List<Object?>? v) =>
        v
            ?.map((e) =>
                fromGraphQLGalleryItemIdNullableToDartGalleryItemIdNullable(
                    e as String?))
            .toList();
List<String?>?
    fromDartListNullableGalleryItemIdNullableToGraphQLListNullableGalleryItemIdNullable(
            List<GalleryItemId?>? v) =>
        v
            ?.map((e) =>
                fromDartGalleryItemIdNullableToGraphQLGalleryItemIdNullable(e))
            .toList();
