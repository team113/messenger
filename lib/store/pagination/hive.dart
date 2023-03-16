import 'dart:async';
import 'dart:math';

import 'package:get/get.dart';

import '/provider/hive/base.dart';
import '/store/model/page_info.dart';
import '/store/pagination2.dart';

class HivePageProvider<U, T> implements PageProvider<U, T> {
  HivePageProvider(this._hiveProvider, {this.getCursor, required this.getKey});

  final dynamic Function(U item) getKey;
  final T? Function(U? item)? getCursor;
  final HiveLazyProvider _hiveProvider;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    if (item == null && cursor == null) {
      final bool fullPage = count <= _hiveProvider.keys.length;

      List<U> items = [];
      for (var i in _hiveProvider.keys
          .skip(max(0, _hiveProvider.keys.length - count))
          .take(count)) {
        final U? item = await _hiveProvider.getSafe(i) as U?;
        if (item != null) {
          items.add(item);
        }
      }

      items = items.reversed.toList();

      // [Hive] can't guarantee next/previous page existence based on the
      // stored values, thus `hasPrevious` and `hasNext` is always `true`.
      return Page(
        RxList(items.toList()),
        PageInfo(
          startCursor: fullPage ? getCursor?.call(items.first) : null,
          endCursor: fullPage ? getCursor?.call(items.last) : null,
          hasPrevious: true,
          hasNext: true,
        ),
      );
    }

    return Page(RxList());
  }

  @override
  FutureOr<Page<U, T>> after(Page<U, T> page, int count) async {
    final key = getKey(page.edges.last);
    final index = _hiveProvider.keys.toList().indexOf(key);
    if (index != -1 && index + 1 >= count) {
      List<U> items = [];
      for (var i in _hiveProvider.keys.skip(index - count).take(count)) {
        final U? item = await _hiveProvider.getSafe(i) as U?;
        if (item != null) {
          items.add(item);
        }
      }

      items = items.reversed.toList();

      // [Hive] can't guarantee next/previous page existence based on the
      // stored values, thus `hasPrevious` and `hasNext` is always `true`.
      return Page(
        RxList(items.toList()),
        PageInfo(
          startCursor: getCursor?.call(items.first),
          endCursor: getCursor?.call(items.last),
          hasPrevious: true,
          hasNext: true,
        ),
      );
    }

    return Page(RxList());
  }

  @override
  FutureOr<Page<U, T>> before(Page<U, T> page, int count) async {
    final key = getKey(page.edges.first);
    final index = _hiveProvider.keys.toList().indexOf(key);
    if (index != -1 && index + count + 1 < _hiveProvider.keys.length) {
      List<U> items = [];
      for (var i in _hiveProvider.keys.skip(index + 1).take(count)) {
        final U? item = await _hiveProvider.getSafe(i) as U?;
        if (item != null) {
          items.add(item);
        }
      }

      items = items.reversed.toList();

      // [Hive] can't guarantee next/previous page existence based on the
      // stored values, thus `hasPrevious` and `hasNext` is always `true`.
      return Page(
        RxList(items.toList()),
        PageInfo(
          startCursor: getCursor?.call(items.first),
          endCursor: getCursor?.call(items.last),
          hasPrevious: true,
          hasNext: true,
        ),
      );
    }

    return Page(RxList());
  }

  Future<void> put(Page<U, T> page) async {
    for (var item in page.edges) {
      await _hiveProvider.putSafe(getKey(item), item!);
    }
  }
}
