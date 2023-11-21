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

import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/blocklist.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/blocklist.dart';
import '/provider/hive/user.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
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
  final RxObsMap<UserId, RxUser> blocklist = RxObsMap<UserId, RxUser>();

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
    Log.debug('init()', '$runtimeType');

    _initLocalSubscription();

    _pagination = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) => _blocklist(
          after: after,
          before: before,
          first: first,
          last: last,
        ),
      ),
      compare: (a, b) {
        if (a.value.isBlocked == null || b.value.isBlocked == null) {
          return 0;
        }

        return b.value.isBlocked!.at.compareTo(a.value.isBlocked!.at);
      },
    );

    _paginationSubscription = _pagination.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          put(event.value!, pagination: true);
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
    Log.debug('dispose()', '$runtimeType');

    _localSubscription?.cancel();
    _paginationSubscription?.cancel();
    _pagination.dispose();
  }

  @override
  Future<void> next() {
    Log.debug('next()', '$runtimeType');
    return _pagination.next();
  }

  /// Puts the provided [user] to [Pagination] and [Hive].
  Future<void> put(HiveUser user, {bool pagination = false}) async {
    Log.debug('put($user, $pagination)', '$runtimeType');

    // [pagination] is `true`, if the [chat] is received from [Pagination],
    // thus otherwise we should try putting it to it.
    if (!pagination) {
      await _pagination.put(user);
    } else {
      _add(user.value.id);

      // TODO: https://github.com/team113/messenger/issues/27
      // Don't write to [Hive] from popup, as [Hive] doesn't support isolate
      // synchronization, thus writes from multiple applications may lead to
      // missing events.
      if (!WebUtils.isPopup) {
        await _blocklistLocal.put(user.value.id);
      }
    }
  }

  /// Removes a [User] identified by the provided [userId] from the [blocklist].
  Future<void> remove(UserId userId) {
    Log.debug('remove($userId)', '$runtimeType');
    return _blocklistLocal.remove(userId);
  }

  /// Resets this [BlocklistRepository].
  Future<void> reset() async {
    Log.debug('reset()', '$runtimeType');
    await _pagination.clear();
    await _pagination.around();
  }

  /// Fetches blocked [User]s with pagination.
  Future<Page<HiveUser, BlocklistCursor>> _blocklist({
    int? first,
    BlocklistCursor? after,
    int? last,
    BlocklistCursor? before,
  }) async {
    Log.debug('_blocklist($first, $after, $last, $before)', '$runtimeType');

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
    Log.debug('_add($userId)', '$runtimeType');

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
    Log.debug('_initLocalSubscription()', '$runtimeType');

    _localSubscription = StreamIterator(_blocklistLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      final BoxEvent event = _localSubscription!.current;
      final UserId userId = UserId(event.key);
      if (event.deleted) {
        blocklist.remove(userId);
      } else {
        if (blocklist[userId] == null) {
          await _add(userId);
        }
      }
    }
  }
}
