import 'dart:async';

import '/store/pagination2.dart';

class GraphQlPageProvider<U, T, K> implements PageProvider<U, T> {
  GraphQlPageProvider({
    required this.fetch,
    required this.transform,
  });

  final Future<K> Function({
    int? first,
    int? last,
    T? before,
    T? after,
  }) fetch;

  final Page<U, T> Function(K) transform;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    final int half = count ~/ 2;

    return transform(
      await fetch(
        after: cursor,
        first: cursor == null ? count : half,
        before: cursor,
        last: cursor == null ? null : half,
      ),
    );
  }

  @override
  FutureOr<Page<U, T>> after(Page<U, T> page, int count) async {
    return transform(
      await fetch(after: page.info?.endCursor, first: count),
    );
  }

  @override
  FutureOr<Page<U, T>> before(Page<U, T> page, int count) async {
    return transform(
      await fetch(before: page.info?.startCursor, last: count),
    );
  }
}
