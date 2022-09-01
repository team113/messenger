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

import 'dart:async';

import 'package:get/get.dart';

import '../repository/user.dart';
import '/domain/model/user.dart';
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
  SearchResult search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) {
    final SearchResult searchResult = SearchResult();
    if (num == null && name == null && login == null && link == null) {
      return searchResult;
    }

    final List<RxUser> users = _userRepository.users.values
        .where((u) =>
            (num != null && u.user.value.num == num) ||
            (name != null && u.user.value.name == name))
        .toList();

    searchResult.users.value = users;
    searchResult.status.value =
        users.isEmpty ? RxStatus.loading() : RxStatus.loadingMore();

    FutureOr<List<RxUser>> add(List<RxUser> u) {
      Set<RxUser> users = searchResult.users.toSet()..addAll(u);
      searchResult.users.value = users.toList();
      return searchResult.users;
    }

    List<Future<List<RxUser>>> futures = [
      if (num != null) _userRepository.searchByNum(num).then(add),
      if (name != null) _userRepository.searchByName(name).then(add),
      if (login != null) _userRepository.searchByLogin(login).then(add),
      if (link != null) _userRepository.searchByLink(link).then(add),
    ];

    Future.wait(futures)
        .then((_) => searchResult.status.value = RxStatus.success());

    return searchResult;
  }

  /// Returns an [User] by the provided [id].
  Future<RxUser?> get(UserId id) => _userRepository.get(id);

  /// Removes [users] from the local data storage.
  Future<void> clearCached() async => await _userRepository.clearCache();
}

/// Result of an [UserService.search] query.
class SearchResult {
  /// Found [RxUser]s themselves.
  final RxList<RxUser> users = RxList<RxUser>();

  /// Reactive [RxStatus] of this [SearchResult].
  final Rx<RxStatus> status = Rx(RxStatus.empty());
}
