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

import '/api/backend/schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/user.dart';
import 'file.dart';
import 'my_user.dart';

/// Extension adding models construction from an [UserMixin].
extension UserConversion on UserMixin {
  /// Constructs a new [User] from this [UserMixin].
  User toModel() => User(
    id,
    this.num,
    name: name,
    bio: bio,
    avatar: avatar?.toModel(),
    callCover: callCover?.toModel(),
    online: online?.$$typename == 'UserOnline',
    lastSeenAt: online?.$$typename == 'UserOffline'
        ? (online as UserMixin$Online$UserOffline).lastSeenAt
        : null,
    dialog: dialog?.id,
    presenceIndex: presence?.index,
    status: status,
    isDeleted: isDeleted,
    isBlocked: isBlocked.record?.toModel(id),
    welcomeMessage: welcomeMessage?.toModel(),
  );

  /// Constructs a new [DtoUser] from this [UserMixin].
  DtoUser toDto() => DtoUser(toModel(), ver, isBlocked.ver);
}

/// Extension adding models construction from a
/// [UserMixin$IsBlocked$Record].
extension BlocklistRecordConversion on UserMixin$IsBlocked$Record {
  /// Constructs a new [BlocklistRecord] from this
  /// [UserMixin$IsBlocked$Record].
  BlocklistRecord toModel(UserId id) =>
      BlocklistRecord(userId: id, reason: reason, at: at);
}

/// Extension adding models construction from an [UserAvatarMixin].
extension UserAvatarConversion on UserAvatarMixin {
  /// Constructs a new [UserAvatar] from this [UserAvatarMixin].
  UserAvatar toModel() => UserAvatar(
    full: full.toModel(),
    original: original.toModel(),
    big: big.toModel(),
    medium: medium.toModel(),
    small: small.toModel(),
    crop: crop != null
        ? CropArea(
            topLeft: CropPoint(x: crop!.topLeft.x, y: crop!.topLeft.y),
            bottomRight: CropPoint(
              x: crop!.bottomRight.x,
              y: crop!.bottomRight.y,
            ),
            angle: crop?.angle,
          )
        : null,
  );
}

/// Extension adding models construction from an [UserCallCoverMixin].
extension UserCallCoverConversion on UserCallCoverMixin {
  /// Constructs a new [UserCallCover] from this [UserCallCoverMixin].
  UserCallCover toModel() => UserCallCover(
    full: full.toModel(),
    original: original.toModel(),
    vertical: vertical.toModel(),
    square: square.toModel(),
    crop: crop != null
        ? CropArea(
            topLeft: CropPoint(x: crop!.topLeft.x, y: crop!.topLeft.y),
            bottomRight: CropPoint(
              x: crop!.bottomRight.x,
              y: crop!.bottomRight.y,
            ),
            angle: crop?.angle,
          )
        : null,
  );
}
