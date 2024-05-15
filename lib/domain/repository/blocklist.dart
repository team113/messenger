// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/util/obs/obs.dart';

/// [MyUser]'s blocklist repository interface.
abstract class AbstractBlocklistRepository {
  /// Returns [User]s blocked by the authenticated [MyUser].
  RxObsMap<UserId, RxUser> get blocklist;

  /// Returns the initialization [RxStatus] of this repository and its
  /// [blocklist].
  Rx<RxStatus> get status;

  /// Indicates whether the [blocklist] have next page.
  RxBool get hasNext;

  /// Indicator whether a next page of the [blocklist] is loading.
  RxBool get nextLoading;

  /// Returns the count of added [RxUser]s per single [next] or [around] invoke.
  int get perPage;

  /// Fetches the initial [blocklist] page.
  Future<void> around();

  /// Fetches the next [blocklist] page.
  Future<void> next();
}
