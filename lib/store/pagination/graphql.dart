// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
class GraphQlPageProvider<T, C, K> implements PageProvider<T, C, K> {
  GraphQlPageProvider({required this.fetch, this.reversed = false});

  /// Indicator whether this [GraphQlPageProvider] is reversed.
  final bool reversed;

  /// Callback fetching items from the remote.
  final Future<Page<T, C>> Function({
    int? first,
    int? last,
    C? before,
    C? after,
  })
  fetch;

  @override
  Future<Page<T, C>?> init(K? key, int count) async {
    return null;
  }

  @override
  void dispose() {
    // No-op.
  }

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    final int half = count ~/ 2;

    final Page<T, C> page = await fetch(
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
  Future<Page<T, C>> after(K? key, C? cursor, int count) async {
    if (reversed) {
      return (await fetch(before: cursor, last: count)).reversed();
    } else {
      return fetch(after: cursor, first: count);
    }
  }

  @override
  Future<Page<T, C>> before(K? key, C? cursor, int count) async {
    if (reversed) {
      return (await fetch(after: cursor, first: count)).reversed();
    } else {
      return fetch(before: cursor, last: count);
    }
  }

  @override
  Future<void> put(
    Iterable<T> items, {
    bool ignoreBounds = false,
    int Function(T, T)? compare,
  }) async {
    // No-op.
  }

  @override
  Future<void> remove(K key) async {
    // No-op.
  }

  @override
  Future<void> clear() async {
    // No-op.
  }
}
