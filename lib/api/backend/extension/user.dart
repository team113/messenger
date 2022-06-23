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

import '../schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/provider/hive/user.dart';

/// Extension adding models construction from an [UserMixin].
extension UserConversion on UserMixin {
  /// Constructs a new [User] from this [UserMixin].
  User toModel() => User(
        id,
        this.num,
        name: name,
        bio: bio,
        avatar: avatar == null
            ? null
            : UserAvatar(
                galleryItemId: avatar!.galleryItemId,
                full: avatar!.full,
                big: avatar!.big,
                medium: avatar!.medium,
                small: avatar!.small,
                original: avatar!.original,
              ),
        callCover: callCover == null
            ? null
            : UserCallCover(
                galleryItemId: callCover!.galleryItemId,
                full: callCover!.full,
                vertical: callCover!.vertical,
                square: callCover!.square,
                original: callCover!.original,
              ),
        gallery: gallery.nodes.map((e) {
          var imageData = e as UserMixin$Gallery$Nodes$ImageGalleryItem;
          return ImageGalleryItem(
            original: Original(imageData.original),
            square: Square(imageData.square),
            id: imageData.id,
            addedAt: imageData.addedAt,
          );
        }).toList(),
        mutualContactsCount: mutualContactsCount,
        online: online?.$$typename == 'UserOnline',
        lastSeenAt: online?.$$typename == 'UserOffline'
            ? (online as UserMixin$Online$UserOffline).lastSeenAt
            : null,
        dialog: dialog == null ? null : Chat(dialog!.id),
        presenceIndex: presence.index,
        status: status,
        isDeleted: isDeleted,
        isBlacklisted: isBlacklisted.blacklisted,
      );

  /// Constructs a new [HiveUser] from this [UserMixin].
  HiveUser toHive() => HiveUser(toModel(), ver, isBlacklisted.ver);
}

/// Extension adding models construction from an [ImageGalleryItem].
extension ImageGalleryItemConversion on ImageGalleryItemMixin {
  /// Constructs a new [ImageGalleryItem] from this [ImageGalleryItemMixin].
  ImageGalleryItem toModel() => ImageGalleryItem(
        addedAt: addedAt,
        id: id,
        original: Original(original),
        square: Square(square),
      );
}

extension UserAvatarConversion on UserAvatarMixin {
  UserAvatar toModel() => UserAvatar(
      full: full,
      original: original,
      galleryItemId: galleryItemId,
      big: big,
      medium: medium,
      small: small,
      crop: crop != null
          ? CropArea(
              topLeft: CropPoint(
                x: crop!.topLeft.x,
                y: crop!.topLeft.y,
              ),
              bottomRight: CropPoint(
                x: crop!.bottomRight.x,
                y: crop!.bottomRight.y,
              ),
              angle: crop?.angle,
            )
          : null);
}

extension UserCallCoverConversion on UserCallCoverMixin {
  UserCallCover toModel() => UserCallCover(
      galleryItemId: galleryItemId,
      full: full,
      original: original,
      vertical: vertical,
      square: square,
      crop: crop != null
          ? CropArea(
              topLeft: CropPoint(
                x: crop!.topLeft.x,
                y: crop!.topLeft.y,
              ),
              bottomRight: CropPoint(
                x: crop!.bottomRight.x,
                y: crop!.bottomRight.y,
              ),
              angle: crop?.angle,
            )
          : null);
}
