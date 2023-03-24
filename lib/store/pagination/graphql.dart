import 'dart:async';

import 'package:get/get.dart';

import '/store/pagination.dart';

/// [PageProvider] fetching items from the remote.
class GraphQlPageProvider<U, T> implements PageProvider<U, T> {
  GraphQlPageProvider({
    required this.fetch,
  });

  /// Callback fetching items from the remote.
  final Future<Page<U, T>> Function({
    int? first,
    int? last,
    T? before,
    T? after,
  }) fetch;

  @override
  FutureOr<Rx<Page<U, T>>> around(U? item, T? cursor, int count) async {
    final int half = count ~/ 2;

    return (await fetch(
      after: cursor,
      first: cursor == null ? count : half,
      before: cursor,
      last: cursor == null ? null : half,
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
