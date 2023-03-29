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

import '/store/pagination.dart';

/// [PageProvider] fetching items from the remote.
class GraphQlPageProvider<U, T> implements PageProvider<U, T> {
  GraphQlPageProvider({
    required this.fetch,
    this.startFromEnd = false,
  });

  /// Callback fetching items from the remote.
  final Future<Page<U, T>> Function({
    int? first,
    int? last,
    T? before,
    T? after,
  }) fetch;

  /// Indicator whether fetching should be started from the end if no cursor
  /// provided.
  bool startFromEnd;

  @override
  FutureOr<Rx<Page<U, T>>> around(U? item, T? cursor, int count) async {
    final int half = count ~/ 2;

    return (await fetch(
      after: cursor,
      first: cursor == null
          ? startFromEnd
              ? null
              : count
          : half,
      before: cursor,
      last: cursor == null
          ? startFromEnd
              ? count
              : null
          : half,
    ))
        .obs;
  }

  @override
  FutureOr<Page<U, T>?> after(U? item, T? cursor, int count) async {
    if (cursor == null) {
      return null;
    }

    return await fetch(after: cursor, first: count);
  }

  @override
  FutureOr<Page<U, T>?> before(U? item, T? cursor, int count) async {
    if (cursor == null) {
      return null;
    }

    return await fetch(before: cursor, last: count);
  }
}
