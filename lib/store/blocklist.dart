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
import 'package:hive/hive.dart';
import 'package:messenger/domain/repository/blocklist.dart';

import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/blocklist.dart';
import '/provider/hive/user.dart';
import '/util/obs/obs.dart';
import 'model/my_user.dart';
import 'pagination.dart';
import 'pagination/graphql.dart';
import 'user.dart';

/// [MyUser]'s blocklist repository.
class BlocklistRepository implements AbstractBlocklistRepository {
  BlocklistRepository(
    this._graphQlProvider,
    this._blocklistLocal,
    this._userRepo,
  );

  @override
  final RxMap<UserId, RxUser> blocklist = RxMap<UserId, RxUser>();

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Blocked [User]s local [Hive] storage.
  final BlocklistHiveProvider _blocklistLocal;

  /// [User]s repository, used to put the fetched [MyUser] into it.
  final UserRepository _userRepo;

  /// [BlocklistHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// [Pagination] loading [blocklist] with pagination.
  late final Pagination<HiveUser, BlocklistCursor, UserId> _pagination;

  /// Subscription to the [Pagination.items] changes.
  StreamSubscription? _paginationSubscription;

  @override
  RxBool get hasNext => _pagination.hasNext;

  @override
  RxBool get nextLoading => _pagination.nextLoading;

  @override
  Future<void> init() async {
    _initLocalSubscription();

    _pagination = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) => _fetchBlocklist(
          after: after,
          before: before,
          first: first,
          last: last,
        ),
      ),
    );

    _paginationSubscription = _pagination.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          _add(event.key!);
          break;

        case OperationKind.removed:
          remove(event.key!);
          break;
      }
    });

    _pagination.around();
  }

  @override
  void dispose() {
    _localSubscription?.cancel();
    _paginationSubscription?.cancel();
    _pagination.dispose();
  }

  @override
  Future<void> next() => _pagination.next();

  /// Removes a [User] identified by the provided [userId] from the [blocklist].
  Future<void> remove(UserId userId) => _blocklistLocal.remove(userId);

  /// Puts the provided [HiveUser] into this [BlocklistRepository].
  Future<void> put(HiveUser user) => _pagination.put(user);

  /// Resets this [BlocklistRepository].
  Future<void> reset() async {
    await _pagination.clear();
    await _pagination.around();
  }

  /// Fetches blocked [User]s with pagination.
  Future<Page<HiveUser, BlocklistCursor>> _fetchBlocklist({
    int? first,
    BlocklistCursor? after,
    int? last,
    BlocklistCursor? before,
  }) async {
    final query = await _graphQlProvider.getBlocklist(
      first: first,
      after: after,
      last: last,
      before: before,
    );

    final users = RxList(query.edges.map((e) => e.node.user.toHive()).toList());
    users.forEach(_userRepo.put);

    return Page(
      users,
      query.pageInfo.toModel((c) => BlocklistCursor(c)),
    );
  }

  /// Adds the [User] with the specified [userId] to the [blocklist].
  Future<void> _add(UserId userId) async {
    final RxUser? user = blocklist[userId];
    if (user == null) {
      final RxUser? user = await _userRepo.get(userId);
      if (user != null) {
        blocklist[userId] = user;
      }
    }
  }

  /// Initializes [BlocklistHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_blocklistLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      final BoxEvent event = _localSubscription!.current;
      final UserId userId = UserId(event.key);
      if (event.deleted) {
        blocklist.remove(userId);
      } else {
        await _add(userId);
      }
    }
  }
}
