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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model_type_id.dart';
import 'crop_area.dart';
import 'gallery_item.dart';

part 'user_call_cover.g.dart';

/// Call cover of an [User].
///
/// Specified as relative paths on a files storage. Prepend them with a files
/// storage URL to obtain a link to the concrete image.
@HiveType(typeId: ModelTypeId.userCallCover)
class UserCallCover extends HiveObject {
  UserCallCover({
    required this.galleryItemId,
    required this.full,
    required this.vertical,
    required this.square,
    required this.original,
    this.crop,
  });

  /// ID of the [ImageGalleryItem] this [UserCallCover] is created from.
  @HiveField(0)
  final GalleryItemId galleryItemId;

  /// Path to the [original] file representing this call cover image.
  @HiveField(1)
  final String original;

  /// Path to the [full]-sized avatar image keeping the original sizes.
  @HiveField(2)
  final String full;

  /// Path to the [vertical] call cover image preview of `675px`x`900px` size.
  @HiveField(3)
  final String vertical;

  /// Path to the [square] call cover image preview of `300px`x`300px` size.
  @HiveField(4)
  final String square;

  /// [CropArea] applied to the [ImageGalleryItem] to create this
  /// [UserCallCover].
  @HiveField(5)
  final CropArea? crop;
}
