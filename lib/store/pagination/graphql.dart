import 'dart:async';

import '/store/pagination2.dart';

class GraphQlPageProvider<U, T> implements PageProvider<U, T> {
  GraphQlPageProvider({
    required this.fetch,
  });

  final Future<Page<U, T>> Function({
    int? first,
    int? last,
    T? before,
    T? after,
  }) fetch;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    final int half = count ~/ 2;

    return await fetch(
      after: cursor,
      first: cursor == null ? count : half,
      before: cursor,
      last: cursor == null ? null : half,
    );
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
