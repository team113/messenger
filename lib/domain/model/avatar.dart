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

  /// Path to the [full]-sized avatar image keeping the original sizes.
  @HiveField(0)
  final String full;

  /// Path to the [big] avatar image preview of `70px`x`70px` size.
  @HiveField(1)
  final String big;

  /// Path to the [medium] avatar image preview of `46px`x`46px` size.
  @HiveField(2)
  final String medium;

  /// Path to the [small] avatar image preview of `25px`x`25px` size.
  @HiveField(3)
  final String small;

  /// Path to the [original] file representing this avatar image.
  @HiveField(4)
  final String original;

  /// [CropArea] applied to this [Avatar].
  @HiveField(5)
  final CropArea? crop;
}

/// [Avatar] of an [User].
@HiveType(typeId: ModelTypeId.userAvatar)
class UserAvatar extends Avatar {
  UserAvatar({
    required this.galleryItemId,
    required String full,
    required String big,
    required String medium,
    required String small,
    required String original,
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
    required String full,
    required String big,
    required String medium,
    required String small,
    required String original,
    CropArea? crop,
  }) : super(full, big, medium, small, original, crop);
}
