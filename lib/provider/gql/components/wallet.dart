// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:graphql/client.dart';

import '../base.dart';
import '/api/backend/schema.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/store/model/operation.dart';
import '/util/log.dart';

/// [MyUser]'s purse related functionality.
mixin WalletGraphQlMixin {
  GraphQlClient get client;

  AccessTokenSecret? get token;

  /// Returns [Operation]s filtered by the provided criteria.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Sorting
  ///
  /// The returned [Operation]s are sorted by their [OperationNum] in descending
  /// order.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] counts at the same time,
  /// provided that [after] and [before] cursors are equal. In such case the
  /// returned page will include the [Operation] pointed by the cursor and the
  /// requested count of [Operation]s preceding and following it.
  ///
  /// If it's desired to receive the [Operation], pointed by the cursor, without
  /// querying in both directions, one can specify [first] or [last] count as 0.
  ///
  /// If no arguments are provided, then [first] parameter will be considered as
  /// 50.
  ///
  /// [after] and [before] cursors are only meaningful once other non-pagination
  /// arguments remain the same between queries. Trying to query a page of some
  /// filtered entries with a cursor pointing to a page of totally different
  /// filtered entries is nonsense and will produce an invalid result (usually
  /// returning nothing).
  Future<Operations$Query$Operations> operations({
    int? first,
    OperationsCursor? after,
    int? last,
    OperationsCursor? before,
  }) async {
    Log.debug('operations($first, $after, $last, $before)', '$runtimeType');

    final variables = OperationsArguments(
      origin: OperationOrigin.purse,
      pagination: OperationsPagination(
        first: first,
        after: after,
        last: last,
        before: before,
      ),
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'Operations',
        document: OperationsQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return Operations$Query.fromJson(result.data!).operations;
  }
}
