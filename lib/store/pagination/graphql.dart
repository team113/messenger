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
class GraphQlPageProvider<U, T> implements PageProvider<U, T> {
  GraphQlPageProvider({required this.fetch, this.reversed = false});

  /// Indicator whether this [GraphQlPageProvider] is reversed.
  final bool reversed;

  /// Callback fetching items from the remote.
  final Future<Page<U, T>> Function({
    int? first,
    int? last,
    T? before,
    T? after,
  }) fetch;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    final int half = count ~/ 2;

    final Page<U, T> page = await fetch(
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
  FutureOr<Page<U, T>?> after(U? item, T? cursor, int count) async {
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
  FutureOr<Page<U, T>?> before(U? item, T? cursor, int count) async {
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
  Future<void> put(U item) async {
    // No-op.
  }
}
