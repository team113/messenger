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

import 'package:http/http.dart';

/// Parser of GraphQL's Upload to Dart's MultipartFile.

MultipartFile fromGraphQLUploadToDartMultipartFile(MultipartFile file) => file;
MultipartFile fromDartMultipartFileToGraphQLUpload(MultipartFile file) => file;

List<MultipartFile> fromGraphQLListUploadToDartListMultipartFile(
        List<MultipartFile> file) =>
    file;
List<MultipartFile> fromDartListMultipartFileToGraphQLListUpload(
        List<MultipartFile> file) =>
    file;

List<MultipartFile>?
    fromGraphQLListNullableUploadToDartListNullableMultipartFile(
            List<MultipartFile>? file) =>
        file;
List<MultipartFile>?
    fromDartListNullableMultipartFileToGraphQLListNullableUpload(
            List<MultipartFile>? file) =>
        file;

MultipartFile? fromGraphQLUploadNullableToDartMultipartFileNullable(
        MultipartFile? file) =>
    file;
MultipartFile? fromDartMultipartFileNullableToGraphQLUploadNullable(
        MultipartFile? file) =>
    file;

List<MultipartFile?>?
    fromDartListNullableMultipartFileNullableToGraphQLListNullableUploadNullable(
            List<MultipartFile?>? file) =>
        file;
List<MultipartFile?>?
    fromGraphQLListNullableUploadNullableToDartListNullableMultipartFileNullable(
            List<MultipartFile?>? file) =>
        file;

List<MultipartFile?>
    fromGraphQLListUploadNullableToDartListMultipartFileNullable(
            List<MultipartFile?> file) =>
        file;
List<MultipartFile?>
    fromDartListMultipartFileNullableToGraphQLListUploadNullable(
            List<MultipartFile?> file) =>
        file;
