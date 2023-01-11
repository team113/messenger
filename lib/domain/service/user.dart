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
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import 'auth.dart';
import 'disposable_service.dart';

/// Service responsible for [User]s related functionality.
class UserService extends DisposableService {
  UserService(this._authService, this._userRepository, this._chatRepository);

  /// Repository to fetch [User]s from.
  final AbstractUserRepository _userRepository;

  /// Repository to listen [AbstractChatRepository.chats].
  final AbstractChatRepository _chatRepository;

  /// [AuthService] to get an authorized user.
  final AuthService _authService;

  /// Subscription for the listening changes of [AbstractChatRepository.chats].
  late final StreamSubscription _chatsSubscription;

  /// Changes to `true` once the underlying data storage is initialized and
  /// [users] value is fetched.
  RxBool get isReady => _userRepository.isReady;

  /// Returns the current reactive map of [User]s.
  RxMap<UserId, RxUser> get users => _userRepository.users;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  @override
  void onInit() {
    _userRepository.init();
    _chatsSubscription = _chatRepository.chats.changes.listen((e) {
      if (e.value?.chat.value.isDialog == true) {
        UserId userId = e.value!.chat.value.members
            .firstWhere((e) => e.user.id != me)
            .user
            .id;
        _userRepository.users[userId]?.updateDialog(e.value);
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    _chatsSubscription.cancel();
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
            (name != null && u.user.value.name?.val.contains(name.val) == true))
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

  /// Blacklists the specified [User] for the authenticated [MyUser].
  Future<void> blacklistUser(UserId id) => _userRepository.blacklistUser(id);

  /// Removes the specified [User] from the blacklist of the authenticated
  /// [MyUser].
  Future<void> unblacklistUser(UserId id) =>
      _userRepository.unblacklistUser(id);

  /// Removes [users] from the local data storage.
  Future<void> clearCached() async => await _userRepository.clearCache();
}

/// Result of a [UserService.search] query.
class SearchResult {
  /// Found [RxUser]s themselves.
  final RxList<RxUser> users = RxList<RxUser>();

  /// Reactive [RxStatus] of [users] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the query is not yet started.
  /// - `status.isLoading`, meaning the [users] are being fetched.
  /// - `status.isLoadingMore`, meaning some [users] were fetched from local
  ///   storage.
  /// - `status.isSuccess`, meaning the [users] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.empty());
}
