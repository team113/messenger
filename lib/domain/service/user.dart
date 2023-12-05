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
import '/domain/repository/search.dart';
import '/domain/repository/user.dart';
import '/util/log.dart';
import 'disposable_service.dart';

/// Service responsible for [User]s related functionality.
class UserService extends DisposableService {
  UserService(this._userRepository);

  /// Repository to fetch [User]s from.
  final AbstractUserRepository _userRepository;

  /// Changes to `true` once the underlying data storage is initialized and
  /// [users] value is fetched.
  RxBool get isReady => _userRepository.isReady;

  /// Returns the current reactive map of [User]s.
  RxMap<UserId, RxUser> get users => _userRepository.users;

  /// Searches [User]s by the given criteria.
  SearchResult<UserId, RxUser> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) {
    Log.debug('search($num, $name, $login, $link)', '$runtimeType');

    return _userRepository.search(
      num: num,
      name: name,
      login: login,
      link: link,
    );
  }

  /// Returns an [User] by the provided [id].
  FutureOr<RxUser?> get(UserId id) async {
    Log.debug('get($id)', '$runtimeType');

    final FutureOr<RxUser?> user = _userRepository.get(id);
    return user is RxUser? ? user : await user;
  }

  /// Blacklists the specified [User] for the authenticated [MyUser].
  Future<void> blockUser(UserId id, BlocklistReason? reason) async {
    Log.debug('blockUser($id, $reason)', '$runtimeType');
    await _userRepository.blockUser(id, reason);
  }

  /// Removes the specified [User] from the blacklist of the authenticated
  /// [MyUser].
  Future<void> unblockUser(UserId id) async {
    Log.debug('unblockUser($id)', '$runtimeType');
    await _userRepository.unblockUser(id);
  }

  /// Removes [users] from the local data storage.
  Future<void> clearCached() async {
    Log.debug('clearCached()', '$runtimeType');
    await _userRepository.clearCache();
  }
}
