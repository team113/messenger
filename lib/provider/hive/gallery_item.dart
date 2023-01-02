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

import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/file.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import 'base.dart';

/// [Hive] storage for [ImageGalleryItem].
class GalleryItemHiveProvider extends HiveBaseProvider<ImageGalleryItem> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'gallery_item';

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(GalleryItemIdAdapter());
    Hive.maybeRegisterAdapter(ImageGalleryItemAdapter());
    Hive.maybeRegisterAdapter(StorageFileAdapter());
  }

  /// Puts the provided [ImageGalleryItem] to [Hive].
  Future<void> put(ImageGalleryItem item) => putSafe(item.id.val, item);

  /// Removes an [ImageGalleryItem] from [Hive] by its [id].
  Future<void> remove(GalleryItemId id) => deleteSafe(id.val);
}
