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

import '/store/pagination.dart';

/// [PageProvider] fetching items from the remote in a GraphQL style.
class GraphQlPageProvider<T, K> implements PageProvider<T, K> {
  GraphQlPageProvider({required this.fetch, this.reversed = false});

  /// Indicator whether this [GraphQlPageProvider] is reversed.
  final bool reversed;

  /// Callback fetching items from the remote.
  final Future<Page<T, K>> Function({
    int? first,
    int? last,
    K? before,
    K? after,
  }) fetch;

  @override
  FutureOr<Page<T, K>> around(T? item, K? cursor, int count) async {
    final int half = count ~/ 2;

    final Page<T, K> page = await fetch(
      after: cursor,
      last: cursor == null
          ? reversed
              ? count
              : null
          : half,
      before: cursor,
      first: cursor == null
          ? reversed
              ? null
              : count
          : half,
    );

    return reversed ? page.reversed() : page;
  }

  @override
  FutureOr<Page<T, K>?> after(T? item, K? cursor, int count) async {
    if (cursor == null) {
      return null;
    }

    if (reversed) {
      return (await fetch(before: cursor, last: count)).reversed();
    } else {
      return fetch(after: cursor, first: count);
    }
  }

  @override
  FutureOr<Page<T, K>?> before(T? item, K? cursor, int count) async {
    if (cursor == null) {
      return null;
    }

    if (reversed) {
      return (await fetch(after: cursor, first: count)).reversed();
    } else {
      return fetch(before: cursor, last: count);
    }
  }

  @override
  Future<void> put(T item) async {
    // No-op.
  }

  @override
  Future<void> remove(String key) async {
    // No-op.
  }

  @override
  Future<void> clear() async {
    // No-op.
  }
}
