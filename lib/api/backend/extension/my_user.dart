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
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/provider/hive/my_user.dart';
import 'user.dart';

/// Extension adding models construction from a [MyUserMixin].
extension MyUserConversion on MyUserMixin {
  /// Constructs a new [MyUser] from this [MyUserMixin].
  MyUser toModel() => MyUser(
        id: id,
        num: this.num,
        online: online.$$typename == 'UserOnline',
        login: login,
        name: name,
        bio: bio,
        hasPassword: hasPassword,
        unreadChatsCount: unreadChatsCount,
        chatDirectLink: chatDirectLink != null
            ? ChatDirectLink(
                slug: chatDirectLink!.slug,
                usageCount: chatDirectLink!.usageCount,
              )
            : null,
        avatar: avatar?.toModel(),
        gallery: gallery.nodes.map((e) => e.toModel()).toList(),
        status: status,
        presenceIndex: presence.index,
        emails: MyUserEmails(
          confirmed: emails.confirmed,
          unconfirmed: emails.unconfirmed,
        ),
        phones: MyUserPhones(
          confirmed: phones.confirmed,
          unconfirmed: phones.unconfirmed,
        ),
        muted: muted != null
            ? muted!.$$typename == 'MuteForeverDuration'
                ? MuteDuration.forever()
                : MuteDuration.until(
                    (muted! as MyUserMixin$Muted$MuteUntilDuration).until)
            : null,
      );

  /// Constructs a new [HiveMyUser] from this [MyUserMixin].
  HiveMyUser toHive() => HiveMyUser(toModel(), ver);
}

/// Extension adding models construction from
/// [MyUserEventsVersionedMixin$Events$EventUserGalleryItemAdded$GalleryItem].
extension EventMyUserGalleryItemAdded$GalleryItemConversion
    on MyUserEventsVersionedMixin$Events$EventUserGalleryItemAdded$GalleryItem {
  /// Constructs a new [ImageGalleryItem] from this
  /// [MyUserEventsVersionedMixin$Events$EventUserGalleryItemAdded$GalleryItem].
  ImageGalleryItem toModel() => (this as ImageGalleryItemMixin).toModel();
}

/// Extension adding models construction from [MyUserMixin$Gallery$Nodes].
extension MyUserMixinGalleryNodesConversion on MyUserMixin$Gallery$Nodes {
  /// Constructs a new [ImageGalleryItem] from this [MyUserMixin$Gallery$Nodes].
  ImageGalleryItem toModel() => (this as ImageGalleryItemMixin).toModel();
}
