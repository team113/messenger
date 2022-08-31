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

import 'dart:collection';

import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
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

  @override
  void onInit() {
    _userRepository.init();
    super.onInit();
  }

  @override
  void onClose() {
    _userRepository.dispose();
    super.onClose();
  }

  /// Searches [User]s by the given criteria.
  Future<List<RxUser>> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) async {
    if (num == null && name == null && login == null && link == null) {
      return [];
    }

    HashMap<UserId, RxUser> result = HashMap();

    List<Future<List<RxUser>>> futures = [
      if (num != null) _userRepository.searchByNum(num),
      if (name != null) _userRepository.searchByName(name),
      if (login != null) _userRepository.searchByLogin(login),
      if (link != null) _userRepository.searchByLink(link),
    ];

    // TODO: Don't wait for all request to finish, but display results as they
    //       are ready.
    (await Future.wait(futures)).expand((e) => e).forEach((user) {
      result[user.id] = user;
    });

    return result.values.toList();
  }

  /// Returns an [User] by the provided [id].
  Future<RxUser?> get(UserId id) => _userRepository.get(id);

  /// Removes [users] from the local data storage.
  Future<void> clearCached() async => await _userRepository.clearCache();
}
