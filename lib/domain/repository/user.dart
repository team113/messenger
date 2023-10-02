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

import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/user.dart';
import 'chat.dart';
import 'search.dart';

/// [User]s repository interface.
abstract class AbstractUserRepository {
  /// Returns reactive map of [User]s.
  RxMap<UserId, RxUser> get users;

  /// Indicates whether this repository was initialized and [users] can be
  /// used.
  RxBool get isReady;

  /// Initializes this repository.
  Future<void> init();

  /// Disposes this repository.
  void dispose();

  /// Clears the stored [users].
  Future<void> clearCache();

  /// Searches [User]s by the given criteria.
  SearchResult<UserId, RxUser> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  });

  /// Returns an [User] by the provided [id].
  Future<RxUser?> get(UserId id);

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

  /// Returns the [User.id] of this [RxUser].
  UserId get id => user.value.id;

  /// States that this [user] should get its updates.
  void listenUpdates();

  /// States that updates of this [user] are no longer required.
  void stopUpdates();
}
