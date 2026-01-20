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

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/blocklist.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/util/log.dart';
import 'disposable_service.dart';

/// Service responsible for [MyUser]'s blocklist.
class BlocklistService extends Dependency {
  BlocklistService(this._blocklistRepo);

  /// Repository responsible for storing blocked [RxUser]s.
  final AbstractBlocklistRepository _blocklistRepo;

  /// Returns [User]s blocked by the authenticated [MyUser].
  Paginated<UserId, RxUser> get blocklist => _blocklistRepo.blocklist;

  /// Total [BlocklistRecord]s count in the blocklist of the currently
  /// authenticated [MyUser].
  RxInt get count => _blocklistRepo.count;

  /// Returns the [RxStatus] of the [blocklist] fetching.
  Rx<RxStatus> get status => _blocklistRepo.blocklist.status;

  /// Indicates whether the [blocklist] have next page.
  RxBool get hasNext => _blocklistRepo.blocklist.hasNext;

  /// Indicator whether a next page of the [blocklist] is loading.
  RxBool get nextLoading => _blocklistRepo.blocklist.nextLoading;

  /// Returns the count of added [RxUser]s per single [next] or [around] invoke.
  int get perPage => _blocklistRepo.blocklist.perPage;

  /// Fetches the initial [blocklist].
  Future<void> around() async {
    Log.debug('around()', '$runtimeType');

    await _blocklistRepo.blocklist.clear();
    await _blocklistRepo.blocklist.around();
  }

  /// Fetches the next [blocklist] page.
  Future<void> next() {
    Log.debug('next()', '$runtimeType');
    return _blocklistRepo.blocklist.next();
  }
}
