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

import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/contact.dart';
import 'chat.dart';
import 'paginated.dart';

/// [User]s repository interface.
abstract class AbstractUserRepository {
  /// Returns reactive map of [User]s.
  RxMap<UserId, RxUser> get users;

  /// Searches [User]s by the given criteria.
  Paginated<UserId, RxUser> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  });

  /// Returns an [User] by the provided [id].
  FutureOr<RxUser?> get(UserId id);

  /// Blocks the specified [User] for the authenticated [MyUser].
  Future<void> blockUser(UserId id, BlocklistReason? reason);

  /// Removes the specified [User] from the blocklist of the authenticated
  /// [MyUser].
  Future<void> unblockUser(UserId id);
}

/// Unified reactive [User] entity.
abstract class RxUser {
  /// Returns reactive value of the [User] this [RxUser] represents.
  Rx<User> get user;

  /// Returns reactive value of the [RxChat]-dialog with this [RxUser].
  Rx<RxChat?> get dialog;

  /// Returns reactive [User.lastSeenAt] value.
  Rx<PreciseDateTime?> get lastSeen;

  /// Returns reactive [RxChatContact] linked to this [RxUser].
  ///
  /// `null` means this [RxUser] is not in the address book of the authenticated
  /// [MyUser].
  Rx<RxChatContact?> get contact;

  /// Returns the [User.id] of this [RxUser].
  UserId get id => user.value.id;

  /// Listens to the updates of this [RxUser] while the returned [Stream] is
  /// listened to.
  Stream<void> get updates;
}
