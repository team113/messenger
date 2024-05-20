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
import 'model/my_user.dart';
import 'paginated.dart';
import 'pagination.dart';
import 'pagination/graphql.dart';
import 'user.dart';

typedef BlocklistPaginated
    = RxPaginatedImpl<UserId, RxUser, HiveBlocklistRecord, BlocklistCursor>;

/// [MyUser]'s blocklist repository.
class BlocklistRepository extends DisposableInterface
    implements AbstractBlocklistRepository {
  BlocklistRepository(
    this._graphQlProvider,
    this._blocklistLocal,
    this._blocklistSortingLocal,
    this._userRepository,
    this._sessionLocal,
  );

  @override
  late final BlocklistPaginated blocklist = BlocklistPaginated(
    pagination: Pagination(
      onKey: (e) => e.userId,
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
    ),
    transform: ({required HiveBlocklistRecord data, RxUser? previous}) {
      return previous ?? _userRepository.get(data.userId);
    },
  );

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Blocked [User]s local [Hive] storage.
  final BlocklistHiveProvider _blocklistLocal;

  /// [UserId]s sorted by [PreciseDateTime] representing [BlocklistRecord]s
  /// [Hive] storage.
  final BlocklistSortingHiveProvider _blocklistSortingLocal;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepository;

  /// [SessionDataHiveProvider] used to store blocked [User]s list related data.
  final SessionDataHiveProvider _sessionLocal;

  /// Puts the provided [record] to [Pagination] and [Hive].
  Future<void> put(
    HiveBlocklistRecord record, {
    bool pagination = false,
  }) async {
    Log.debug('put($record, $pagination)', '$runtimeType');
    await blocklist.put(record);
  }

  /// Removes a [User] identified by the provided [userId] from the [blocklist].
  Future<void> remove(UserId userId) {
    Log.debug('remove($userId)', '$runtimeType');
    return blocklist.remove(userId);
  }

  /// Resets this [BlocklistRepository].
  Future<void> reset() async {
    Log.debug('reset()', '$runtimeType');
    await _sessionLocal.setBlocklistSynchronized(false);
    await blocklist.clear();
    await blocklist.around();
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

    // Ensure all [users] are stored in [_userRepository].
    await Future.wait(users.map(_userRepository.put));

    return Page(
      query.edges.map((e) => e.node.toHive(cursor: e.cursor)).toList(),
      query.pageInfo.toModel((c) => BlocklistCursor(c)),
    );
  }
}
