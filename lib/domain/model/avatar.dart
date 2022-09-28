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
import 'crop_area.dart';
import 'file.dart';
import 'gallery_item.dart';

part 'avatar.g.dart';

/// Image representing a particular [User] or a [Chat].
///
/// Specified as relative paths on a files storage. Prepend them with a files
/// storage URL to obtain a link to the concrete image.
abstract class Avatar {
  Avatar(
    this.full,
    this.big,
    this.medium,
    this.small,
    this.original,
    this.crop,
  );

  /// Full-sized [UserAvatar]'s image [StorageFile], keeping the original sizes.
  @HiveField(0)
  final StorageFile full;

  /// Big [UserAvatar]'s view image [StorageFile] of `70px`x`70px` size.
  @HiveField(1)
  final StorageFile big;

  /// Medium [UserAvatar]'s view image [StorageFile] of `46px`x`46px` size.
  @HiveField(2)
  final StorageFile medium;

  /// Small [UserAvatar]'s view image [StorageFile] of `25px`x`25px` size.
  @HiveField(3)
  final StorageFile small;

  /// Original image [StorageFile] representing this [UserAvatar].
  @HiveField(4)
  final StorageFile original;

  /// [CropArea] applied to this [Avatar].
  @HiveField(5)
  final CropArea? crop;
}

/// [Avatar] of an [User].
@HiveType(typeId: ModelTypeId.userAvatar)
class UserAvatar extends Avatar {
  UserAvatar({
    required this.galleryItemId,
    required StorageFile full,
    required StorageFile big,
    required StorageFile medium,
    required StorageFile small,
    required StorageFile original,
    CropArea? crop,
  }) : super(full, big, medium, small, original, crop);

  /// ID of the `GalleryItem` this [UserAvatar] is created from.
  @HiveField(6)
  final GalleryItemId galleryItemId;
}

/// [Avatar] of a [Chat].
@HiveType(typeId: ModelTypeId.chatAvatar)
class ChatAvatar extends Avatar {
  ChatAvatar({
    required StorageFile full,
    required StorageFile big,
    required StorageFile medium,
    required StorageFile small,
    required StorageFile original,
    CropArea? crop,
  }) : super(full, big, medium, small, original, crop);
}
