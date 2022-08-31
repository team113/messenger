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

import '../model/user.dart';
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
    final searchResult = SearchResult.empty();
    if (num == null && name == null && login == null && link == null) {
      return searchResult;
    }

    final localUsers = RxList(
      _userRepository.users.values
          .where((_) =>
              (num != null && _.user.value.num == num) ||
              (name != null && _.user.value.name == name))
          .toList(),
    );
    searchResult.users.value = localUsers;
    searchResult.status.value =
        localUsers.isEmpty ? RxStatus.loading() : RxStatus.loadingMore();

    List<Future<void>> futures = [
      if (num != null)
        _userRepository.searchByNum(num).then(
          (usersFromRepository) {
            final result =
                _combineUsers(searchResult.users, usersFromRepository);
            searchResult.users.value = result;
          },
        ),
      if (name != null)
        _userRepository.searchByName(name).then(
          (usersFromRepository) {
            final result =
                _combineUsers(searchResult.users, usersFromRepository);
            searchResult.users.value = result;
          },
        ),
      if (login != null)
        _userRepository.searchByLogin(login).then(
          (usersFromRepository) {
            final result =
                _combineUsers(searchResult.users, usersFromRepository);
            searchResult.users.value = result;
          },
        ),
      if (link != null)
        _userRepository.searchByLink(link).then(
          (usersFromRepository) {
            final result =
                _combineUsers(searchResult.users, usersFromRepository);
            searchResult.users.value = result;
          },
        ),
    ];
    Future.wait(futures)
        .then((_) => searchResult.status.value = RxStatus.success());

    return searchResult;
  }

  /// Creates a new [List] with unique [RxUser]s by id.
  List<RxUser> _combineUsers(Iterable<RxUser> list1, Iterable<RxUser> list2) {
    HashMap<UserId, RxUser> result = HashMap();
    for (var i = 0; i < list1.length; i++) {
      final user = list1.elementAt(i);
      result[user.id] = user;
    }
    for (var i = 0; i < list2.length; i++) {
      final user = list2.elementAt(i);
      result[user.id] = user;
    }
    return result.values.toList();
  }

  /// Returns an [User] by the provided [id].
  Future<RxUser?> get(UserId id) => _userRepository.get(id);

  /// Removes [users] from the local data storage.
  Future<void> clearCached() async => await _userRepository.clearCache();
}

/// Search results.
class SearchResult {
  SearchResult({
    required this.users,
    required this.status,
  });

  SearchResult.empty()
      : users = RxList<RxUser>(),
        status = Rx(RxStatus.empty());

  /// Found users.
  final RxList<RxUser> users;

  /// Request status from backend.
  final Rx<RxStatus> status;
}
