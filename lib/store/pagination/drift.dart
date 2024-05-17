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

import 'package:log_me/log_me.dart';

import '/store/model/page_info.dart';
import '/store/pagination.dart';
import '/util/obs/obs.dart';

class DriftPageProvider<T, C, K> extends PageProvider<T, C, K> {
  DriftPageProvider({
    required this.onKey,
    required this.onCursor,
    required this.fetch,
    this.add,
    this.delete,
    this.reset,
    this.isFirst,
    this.isLast,
    this.onNone,
  });

  final K Function(T) onKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T?) onCursor;

  final FutureOr<List<T>> Function({
    required int after,
    required int before,
    K? around,
  }) fetch;

  final Future<void> Function(Iterable<T> items)? add;
  final Future<void> Function(K key)? onNone;
  final Future<void> Function(K key)? delete;
  final Future<void> Function()? reset;

  /// Callback, called to indicate whether the provided [T] is the first.
  final bool Function(T? item)? isFirst;

  /// Callback, called to indicate whether the provided [T] is the last.
  final bool Function(T? item)? isLast;

  List<T> _list = [];
  int _after = 0;
  int _before = 0;
  K? _around;

  StreamSubscription? _subscription;

  @override
  Future<void> dispose() async {
    _subscription?.cancel();
  }

  @override
  Future<Page<T, C>> init(K? key, int count) async {
    _reset(around: key, count: count);

    final List<T> edges = await _page();
    final bool hasFirst = isLast?.call(edges.firstOrNull) == true;
    final bool hasLast = isFirst?.call(edges.lastOrNull) == true;

    Log.info(
      'init($key, $count) -> (${edges.length}), hasNext: ${!hasFirst}, hasPrevious: ${!hasLast}',
    );

    print(
      'edges: ${isLast?.call(edges.firstOrNull) == true}, ${isLast?.call(edges.lastOrNull) == true}, ${isFirst?.call(edges.firstOrNull) == true}, ${isFirst?.call(edges.lastOrNull) == true}',
    );

    if (edges.isEmpty && key != null) {
      await onNone?.call(key);
    }

    return Page(
      edges,
      PageInfo(
        hasNext: !hasFirst,
        hasPrevious: !hasLast,
        startCursor: onCursor(edges.lastOrNull),
        endCursor: onCursor(edges.firstOrNull),
      ),
    );
  }

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    _reset(around: key, count: count);

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool hasFirst = isLast?.call(edges.firstOrNull) == true;
    final bool hasLast = isFirst?.call(edges.lastOrNull) == true;
    final bool fulfilled = edges.length - edgesBefore >= count;

    Log.info(
      'around($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!hasFirst}, hasPrevious: ${!hasLast}',
    );

    return Page(
      fulfilled ? edges : [],
      PageInfo(
        hasNext: !hasFirst,
        hasPrevious: !hasLast,
        startCursor: onCursor(edges.lastOrNull),
        endCursor: onCursor(edges.firstOrNull),
      ),
    );
  }

  @override
  Future<Page<T, C>> after(K? key, C? cursor, int count) async {
    _after += count;

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool hasFirst = isLast?.call(edges.firstOrNull) == true;
    final bool hasLast = isFirst?.call(edges.lastOrNull) == true;
    final bool fulfilled = hasFirst || edges.length - edgesBefore >= count;

    Log.info(
      'after($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!hasFirst}, hasPrevious: ${!hasLast}',
    );

    print(
      'edges: ${isLast?.call(edges.firstOrNull) == true}, ${isLast?.call(edges.lastOrNull) == true}, ${isFirst?.call(edges.firstOrNull) == true}, ${isFirst?.call(edges.lastOrNull) == true}',
    );

    return Page(
      fulfilled ? edges : [],
      PageInfo(
        hasNext: !hasFirst,
        hasPrevious: !hasLast,
        startCursor: onCursor(edges.lastOrNull),
        endCursor: onCursor(edges.firstOrNull),
      ),
    );
  }

  @override
  Future<Page<T, C>> before(K? key, C? cursor, int count) async {
    _before += count;

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool hasFirst = isLast?.call(edges.firstOrNull) == true;
    final bool hasLast = isFirst?.call(edges.lastOrNull) == true;
    final bool fulfilled = hasLast || edges.length - edgesBefore >= count;

    Log.info(
      'before($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!hasFirst}, hasPrevious: ${!hasLast}',
    );

    print(
      'edges: ${isLast?.call(edges.firstOrNull) == true}, ${isLast?.call(edges.lastOrNull) == true}, ${isFirst?.call(edges.firstOrNull) == true}, ${isFirst?.call(edges.lastOrNull) == true}',
    );

    return Page(
      fulfilled ? edges : [],
      PageInfo(
        hasNext: !hasFirst,
        hasPrevious: !hasLast,
        startCursor: onCursor(edges.lastOrNull),
        endCursor: onCursor(edges.firstOrNull),
      ),
    );
  }

  @override
  Future<void> put(Iterable<T> items, {int Function(T, T)? compare}) async {
    _after += 1;
    await add?.call(items);
  }

  @override
  Future<void> remove(K key) async {
    await delete?.call(key);
  }

  @override
  Future<void> clear() async {
    await reset?.call();
  }

  void _reset({K? around, int count = 50}) {
    _subscription?.cancel();
    _list.clear();
    _after = count ~/ 2;
    _before = count ~/ 2;
    _around = around;
  }

  Future<List<T>> _page() async {
    _list = await fetch(after: _after, before: _before, around: _around);
    return _list;

    // final Completer completer = Completer();

    // _subscription?.cancel();

    // final futureOrStream =
    //     fetch(after: _after, before: _before, around: _around);
    // final stream =
    //     futureOrStream is Future ? await futureOrStream : futureOrStream;

    // _subscription = stream.listen((e) {
    //   Log.debug(
    //     '_page(after: $_after, before: $_before) fired: ${e.length}',
    //     '$runtimeType',
    //   );

    //   if (!completer.isCompleted) {
    //     completer.complete();
    //   }

    //   for (var o in e) {
    //     switch (o.op) {
    //       case OperationKind.added:
    //       case OperationKind.updated:
    //         final int i = _list.indexWhere((m) => onKey(m) == o.key);
    //         if (i == -1) {
    //           _list.add(o.value as T);
    //         } else {
    //           _list[i] = o.value as T;
    //         }
    //         break;

    //       case OperationKind.removed:
    //         _list.removeWhere((m) => onKey(m) == o.key);
    //         break;
    //     }
    //   }
    // });

    // await completer.future;

    // return _list;
  }
}
