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

import '../model_type_id.dart';
import '/util/new_type.dart';
import 'file.dart';
import 'precise_date_time/precise_date_time.dart';

part 'gallery_item.g.dart';

/// Gallery item representing an image.
@HiveType(typeId: ModelTypeId.galleryItem)
class GalleryItem extends HiveObject {
  GalleryItem({
    required this.id,
    required this.addedAt,
    required this.original,
    required this.square,
  });

  /// Unique ID of this [GalleryItem].
  @HiveField(0)
  GalleryItemId id;

  /// [PreciseDateTime] when this [GalleryItem] was added.
  @HiveField(1)
  PreciseDateTime addedAt;

  /// Original [StorageFile] representing this [GalleryItem].
  @HiveField(2)
  ImageFile original;

  /// Square [GalleryItem]'s view [ImageFile] of `85px`x`85px` size.
  @HiveField(3)
  ImageFile square;
}

/// Unique ID of a `GalleryItem`.
@HiveType(typeId: ModelTypeId.galleryItemId)
class GalleryItemId extends NewType<String> {
  const GalleryItemId(String val) : super(val);
}
