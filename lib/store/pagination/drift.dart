import 'dart:async';

import 'package:log_me/log_me.dart';

import '/store/model/page_info.dart';
import '/store/pagination.dart';
import '/util/obs/obs.dart';

class DriftPageProvider<T, C, K> extends PageProvider<T, C, K> {
  DriftPageProvider({
    required this.onKey,
    required this.fetch,
    this.add,
    this.delete,
    this.reset,
  });

  final K Function(T) onKey;

  final Stream<List<MapChangeNotification<K, T>>> Function({
    required int limit,
    required int offset,
  }) fetch;

  final Future<void> Function(T item)? add;
  final Future<void> Function(K key)? delete;
  final Future<void> Function()? reset;

  int offset = 0;
  int limit = 0;

  final RxObsList<T> list = RxObsList();

  StreamSubscription? _subscription;

  @override
  Future<void> dispose() async {
    _subscription?.cancel();
  }

  @override
  Future<Page<T, C>> init(K? key, int count) async {
    Log.info('init($key, $count)');

    offset = 0;
    limit = count;

    final int edgesBefore = list.length;
    final RxObsList<T> edges = await _page();

    return Page(
      edges,
      PageInfo(
        hasNext: edges.length - edgesBefore < count,
        hasPrevious: true,
      ),
    );
  }

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    Log.info('around($key, $count)');

    offset = 0;
    limit = count;

    return Page(
      await _page(),
      PageInfo(
        hasPrevious: true,
        hasNext: true,
      ),
    );
  }

  @override
  Future<Page<T, C>> after(K? key, C? cursor, int count) async {
    Log.info('after($key, $count)');

    limit += count * 2;
    offset += count; // ??

    final int edgesBefore = list.length;
    final RxObsList<T> edges = await _page();

    return Page(
      edges,
      PageInfo(
        hasNext:
            edges.length != edgesBefore && edges.length - edgesBefore < count,
        hasPrevious: true,
      ),
    );
  }

  @override
  Future<Page<T, C>> before(K? key, C? cursor, int count) async {
    Log.info('before($key, $count)');

    limit += count;

    final int edgesBefore = list.length;
    final RxObsList<T> edges = await _page();

    return Page(
      edges,
      PageInfo(
        hasNext: true,
        hasPrevious:
            edges.length != edgesBefore && edges.length - edgesBefore >= count,
      ),
    );
  }

  @override
  Future<void> put(T item, {int Function(T, T)? compare}) async {
    limit += 1;
    await add?.call(item);
  }

  @override
  Future<void> remove(K key) async {
    limit -= 1;
    await delete?.call(key);
  }

  @override
  Future<void> clear() async {
    await reset?.call();
  }

  Future<RxObsList<T>> _page() async {
    final Completer completer = Completer();

    _subscription?.cancel();
    _subscription = fetch(limit: limit, offset: offset).listen((e) {
      Log.debug(
        '_page(limit: $limit, offset: $offset) fired: ${e.length}',
        '$runtimeType',
      );

      if (!completer.isCompleted) {
        completer.complete();
      }

      for (var o in e) {
        switch (o.op) {
          case OperationKind.added:
          case OperationKind.updated:
            final int i = list.indexWhere((m) => onKey(m) == o.key);
            if (i == -1) {
              list.add(o.value as T);
            } else {
              list[i] = o.value as T;
            }
            break;

          case OperationKind.removed:
            list.removeWhere((m) => onKey(m) == o.key);
            break;
        }
      }
    });

    await completer.future;

    return list;
  }
}
