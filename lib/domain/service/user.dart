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
import '/domain/repository/user.dart';
import '/store/model/user.dart';
import '/store/pagination.dart';
import '/store/pagination/graphql.dart';
import '/util/obs/obs.dart';
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
  SearchResult<RxUser> search({
    UserNum? num,
    UserName? name,
    UserLogin? login,
    ChatDirectLinkSlug? link,
  }) {
    Pagination<RxUser, UsersCursor, UserId>? pagination;
    if (name != null) {
      pagination = Pagination(
        provider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) {
            return _userRepository.searchByName(
              name,
              after: after,
              first: first,
            );
          },
        ),
        onKey: (RxUser u) => u.id,
      );
    }
    final SearchResult<RxUser> searchResult =
        SearchResult(pagination: pagination);

    if (num == null && name == null && login == null && link == null) {
      return searchResult;
    }

    final List<RxUser> users = _userRepository.users.values
        .where((u) =>
            (num != null && u.user.value.num == num) ||
            (name != null && u.user.value.name?.val.contains(name.val) == true))
        .toList();

    searchResult.items.value = users;
    searchResult.status.value =
        users.isEmpty ? RxStatus.loading() : RxStatus.loadingMore();

    void add(List<RxUser> u) {
      Set<RxUser> users = searchResult.items.toSet()..addAll(u);
      searchResult.items.value = users.toList();
    }

    List<Future> futures = [
      if (num != null) _userRepository.searchByNum(num).then(add),
      if (name != null) searchResult.pagination!.around(),
      if (login != null) _userRepository.searchByLogin(login).then(add),
      if (link != null) _userRepository.searchByLink(link).then(add),
    ];

    if (name != null) {
      futures.add(pagination!.around());
    }

    Future.wait(futures)
        .then((_) => searchResult.status.value = RxStatus.success());

    return searchResult;
  }

  /// Returns an [User] by the provided [id].
  Future<RxUser?> get(UserId id) => _userRepository.get(id);

  /// Blacklists the specified [User] for the authenticated [MyUser].
  Future<void> blockUser(UserId id, BlocklistReason? reason) =>
      _userRepository.blockUser(id, reason);

  /// Removes the specified [User] from the blacklist of the authenticated
  /// [MyUser].
  Future<void> unblockUser(UserId id) => _userRepository.unblockUser(id);

  /// Removes [users] from the local data storage.
  Future<void> clearCached() async => await _userRepository.clearCache();
}

/// Result of a search query.
class SearchResult<T> {
  SearchResult({this.pagination}) {
    if (pagination != null) {
      _paginationSubscription = pagination!.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
            items.add(event.value as T);
            break;

          case OperationKind.removed:
          case OperationKind.updated:
            // No-op.
            break;
        }
      });
    }
  }

  /// Found [RxUser]s themselves.
  final RxList<T> items = RxList<T>();

  /// Reactive [RxStatus] of [items] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the query is not yet started.
  /// - `status.isLoading`, meaning the [items] are being fetched.
  /// - `status.isLoadingMore`, meaning some [items] were fetched from local
  ///   storage.
  /// - `status.isSuccess`, meaning the [items] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Pagination fetching [items].
  final Pagination<T, dynamic, dynamic>? pagination;

  /// [StreamSubscription] to the [Pagination.changes].
  StreamSubscription? _paginationSubscription;

  /// Indicator whether the [items] have next page.
  RxBool get hasNext => pagination?.hasNext ?? RxBool(false);

  /// Indicator whether the [next] page of [items] is being fetched.
  RxBool get nextLoading => pagination?.nextLoading ?? RxBool(false);

  /// Disposes this [SearchResult].
  void dispose() {
    _paginationSubscription?.cancel();
  }

  /// Fetches next page of the [items].
  Future<void> next() async {
    if (pagination != null) {
      status.value = RxStatus.loadingMore();
      await pagination!.next();
      status.value = RxStatus.success();
    }
  }
}
