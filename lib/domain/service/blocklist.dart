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

import 'dart:async';

import 'package:get/get.dart';

import '../model/my_user.dart';
import '../model/user.dart';
import '/domain/repository/blocklist.dart';
import '/domain/repository/user.dart';
import '/util/log.dart';
import '/util/obs/rxmap.dart';
import 'disposable_service.dart';

/// Service responsible for [MyUser]'s blocklist.
class BlocklistService extends DisposableService {
  BlocklistService(this._blocklistRepo);

  /// Repository responsible for storing blocked [RxUser]s.
  final AbstractBlocklistRepository _blocklistRepo;

  /// Returns [User]s blocked by the authenticated [MyUser].
  RxObsMap<UserId, RxUser> get blocklist => _blocklistRepo.blocklist;

  /// Returns the [RxStatus] of the [blocklist] fetching.
  Rx<RxStatus> get status => _blocklistRepo.status;

  /// Indicates whether the [blocklist] have next page.
  RxBool get hasNext => _blocklistRepo.hasNext;

  /// Indicator whether a next page of the [blocklist] is loading.
  RxBool get nextLoading => _blocklistRepo.nextLoading;

  /// Returns the count of added [RxUser]s per single [next] or [around] invoke.
  int get perPage => _blocklistRepo.perPage;

  /// Fetches the initial [blocklist].
  Future<void> around() {
    Log.debug('around()', '$runtimeType');
    return _blocklistRepo.around();
  }

  /// Fetches the next [blocklist] page.
  Future<void> next() {
    Log.debug('next()', '$runtimeType');
    return _blocklistRepo.next();
  }
}
