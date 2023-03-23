import 'dart:async';

import 'package:get/get.dart';

import '/provider/hive/base.dart';
import '/store/model/page_info.dart';
import '/store/pagination2.dart';

class HivePageProvider<U, T> implements PageProvider<U, T> {
  HivePageProvider(this._hiveProvider, {this.getCursor, required this.getKey});

  final dynamic Function(U item) getKey;
  final T? Function(U? item)? getCursor;
  HiveLazyProvider _hiveProvider;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    if (_hiveProvider.keys.isEmpty) {
      return Page(RxList());
    }

    Iterable<dynamic> keys = _hiveProvider.keys.take(count);
    if (item != null) {
      final key = getKey(item);
      final int initialIndex = _hiveProvider.keys.toList().indexOf(key);
      if (initialIndex != -1) {
        if (initialIndex < (count ~/ 2)) {
          keys = keys.take(count - ((count ~/ 2) - initialIndex));
        } else {
          keys = keys.skip(initialIndex - (count ~/ 2)).take(count);
        }
      }
    }

    List<U> items = [];
    for (var i in keys) {
      final U? item = await _hiveProvider.getSafe(i) as U?;
      if (item != null) {
        items.add(item);
      }
    }

    // [Hive] can't guarantee next/previous page existence based on the
    // stored values, thus `hasPrevious` and `hasNext` is always `true`.
    return Page(
      RxList(items.toList()),
      PageInfo(
        startCursor:
            items.length == count ? getCursor?.call(items.first) : null,
        endCursor: items.length == count ? getCursor?.call(items.last) : null,
        hasPrevious: true,
        hasNext: true,
      ),
    );
  }

  @override
  FutureOr<Page<U, T>?> after(U? item, T? cursor, int count) async {
    if (item == null) {
      return null;
    }

    final key = getKey(item);
    final index = _hiveProvider.keys.toList().indexOf(key);
    if (index != -1 && index < _hiveProvider.keys.length - 1) {
      List<U> items = [];
      for (var i in _hiveProvider.keys.skip(index + 1).take(count)) {
        final U? item = await _hiveProvider.getSafe(i) as U?;
        if (item != null) {
          items.add(item);
        }
      }

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
  FutureOr<Page<U, T>?> before(U? item, T? cursor, int count) async {
    if (item == null) {
      return null;
    }

    final key = getKey(item);
    final index = _hiveProvider.keys.toList().indexOf(key);
    if (index > 0) {
      if (index < count) {
        count = index;
      }

      List<U> items = [];
      for (var i in _hiveProvider.keys.skip(index - count).take(count)) {
        final U? item = await _hiveProvider.getSafe(i) as U?;
        if (item != null) {
          items.add(item);
        }
      }

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

  /// Updates the [_hiveProvider] with the provided [provider].
  void updateProvider(HiveLazyProvider provider) {
    _hiveProvider = provider;
  }
}
