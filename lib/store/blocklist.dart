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
import 'package:hive/hive.dart';

import '/api/backend/extension/my_user.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/blocklist.dart';
import '/domain/repository/user.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/blocklist.dart';
import '/provider/hive/blocklist_sorting.dart';
import '/provider/hive/session_data.dart';
import '/store/pagination/hive.dart';
import '/store/pagination/hive_graphql.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
import 'model/my_user.dart';
import 'pagination.dart';
import 'pagination/graphql.dart';
import 'user.dart';

/// [MyUser]'s blocklist repository.
class BlocklistRepository extends DisposableInterface
    implements AbstractBlocklistRepository {
  BlocklistRepository(
    this._graphQlProvider,
    this._blocklistLocal,
    this._blocklistSortingLocal,
    this._userRepo,
    this._sessionLocal,
  );

  @override
  final RxObsMap<UserId, RxUser> blocklist = RxObsMap<UserId, RxUser>();

  @override
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.loading());

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Blocked [User]s local [Hive] storage.
  final BlocklistHiveProvider _blocklistLocal;

  /// [UserId]s sorted by [PreciseDateTime] representing [BlocklistRecord]s
  /// [Hive] storage.
  final BlocklistSortingHiveProvider _blocklistSortingLocal;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepo;

  /// [SessionDataHiveProvider] used to store blocked [User]s list related data.
  final SessionDataHiveProvider _sessionLocal;

  /// [BlocklistHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// [Pagination] loading [blocklist] with pagination.
  late final Pagination<HiveBlocklistRecord, BlocklistCursor, UserId>
      _pagination;

  /// Subscription to the [Pagination.items] changes.
  StreamSubscription? _paginationSubscription;

  @override
  RxBool get hasNext => _pagination.hasNext;

  @override
  RxBool get nextLoading => _pagination.nextLoading;

  @override
  int get perPage => _pagination.perPage;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    _initLocalSubscription();
    _initRemotePagination();

    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _localSubscription?.cancel();
    _paginationSubscription?.cancel();
    _pagination.dispose();

    super.onClose();
  }

  @override
  Future<void> around() async {
    Log.debug('around()', '$runtimeType');

    if (status.value.isSuccess) {
      return;
    }

    await _pagination.around();

    status.value = RxStatus.success();
  }

  @override
  Future<void> next() {
    Log.debug('next()', '$runtimeType');
    return _pagination.next();
  }

  /// Puts the provided [record] to [Pagination] and [Hive].
  Future<void> put(
    HiveBlocklistRecord record, {
    bool pagination = false,
  }) async {
    Log.debug('put($record, $pagination)', '$runtimeType');

    // [pagination] is `true`, if the [user] is received from [Pagination],
    // thus otherwise we should try putting it to it.
    if (!pagination) {
      await _pagination.put(record);
    } else {
      await Future.wait([
        _add(record.value.userId),

        // TODO: https://github.com/team113/messenger/issues/27
        // Don't write to [Hive] from popup, as [Hive] doesn't support isolate
        // synchronization, thus writes from multiple applications may lead to
        // missing events.
        if (!WebUtils.isPopup) _blocklistLocal.put(record),
      ]);
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
    await _sessionLocal.setBlocklistSynchronized(false);
    await _pagination.clear();
    await _pagination.around();
  }

  /// Fetches blocked [User]s with pagination.
  Future<Page<HiveBlocklistRecord, BlocklistCursor>> _blocklist({
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

    final users = RxList(query.edges.map((e) => e.node.user.toDto()).toList());

    // Ensure all [users] are stored in [_userRepo].
    await Future.wait(users.map(_userRepo.put));

    return Page(
      query.edges.map((e) => e.node.toHive(cursor: e.cursor)).toList(),
      query.pageInfo.toModel((c) => BlocklistCursor(c)),
    );
  }

  /// Adds the [User] with the specified [userId] to the [blocklist].
  Future<void> _add(UserId userId) async {
    Log.debug('_add($userId)', '$runtimeType');

    final RxUser? user = blocklist[userId];
    if (user == null) {
      final FutureOr<RxUser?> userOrFuture = _userRepo.get(userId);

      if (userOrFuture is RxUser?) {
        if (userOrFuture != null) {
          blocklist[userId] = userOrFuture;
        }
      } else {
        final user = await userOrFuture;
        if (user != null) {
          blocklist[userId] = user;
        }
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
        _blocklistSortingLocal.remove(userId);
      } else {
        _blocklistSortingLocal.put(event.value.value.at, userId);
      }
    }
  }

  /// Initializes the [_pagination].
  void _initRemotePagination() {
    Log.debug('_initRemotePagination()', '$runtimeType');

    _pagination = Pagination(
      onKey: (e) => e.value.userId,
      perPage: 15,
      provider: HiveGraphQlPageProvider(
        hiveProvider: HivePageProvider(
          _blocklistLocal,
          getCursor: (e) => e?.cursor,
          getKey: (e) => e.value.userId,
          orderBy: (_) => _blocklistSortingLocal.values,
          isFirst: (_) => _sessionLocal.getBlocklistSynchronized() == true,
          isLast: (_) => _sessionLocal.getBlocklistSynchronized() == true,
          reversed: true,
          strategy: PaginationStrategy.fromEnd,
        ),
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) async {
            final Page<HiveBlocklistRecord, BlocklistCursor> page =
                await _blocklist(
              after: after,
              before: before,
              first: first,
              last: last,
            );

            if (page.info.hasNext == false) {
              _sessionLocal.setBlocklistSynchronized(true);
            }

            return page;
          },
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    );

    _paginationSubscription = _pagination.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          await put(event.value!, pagination: true);
          break;

        case OperationKind.removed:
          await remove(event.key!);
          break;
      }
    });
  }
}
