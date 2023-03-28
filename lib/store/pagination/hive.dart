import 'dart:async';

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/provider/hive/base.dart';
import '/store/model/page_info.dart';
import '/store/pagination.dart';

/// [PageProvider] fetching items from the [Hive].
class HivePageProvider<U, T> implements PageProvider<U, T> {
  HivePageProvider(
    this._hiveProvider, {
    required this.getCursor,
    required this.getKey,
    this.startFromEnd = false,
  });

  /// Callback returning key of an item.
  final dynamic Function(U item) getKey;

  /// Callback returning cursor of an item.
  final T? Function(U? item) getCursor;

  /// Indicator whether fetching should be started from the end if no item
  /// provided.
  bool startFromEnd;

  /// [HiveLazyProvider] items fetching from.
  HiveLazyProvider _hiveProvider;

  @override
  FutureOr<Rx<Page<U, T>>> around(U? item, T? cursor, int count) async {
    if (_hiveProvider.keys.isEmpty || (item == null && cursor != null)) {
      return Page<U, T>(RxList()).obs;
    }

    Iterable<dynamic>? keys;

    if (item != null) {
      final key = getKey(item);
      final int initialIndex = _hiveProvider.keys.toList().indexOf(key);
      if (initialIndex != -1) {
        if (initialIndex < (count ~/ 2)) {
          keys = _hiveProvider.keys.take(count - ((count ~/ 2) - initialIndex));
        } else {
          keys =
              _hiveProvider.keys.skip(initialIndex - (count ~/ 2)).take(count);
        }
      }
    }

    if (startFromEnd) {
      keys ??= _hiveProvider.keys.toList().reversed.take(count);
    } else {
      keys ??= _hiveProvider.keys.take(count);
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
      info: PageInfo(
        startCursor:
            getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
        endCursor:
            getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
        hasPrevious: true,
        hasNext: true,
      ),
      finalResult: items.length == count,
    ).obs;
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
        info: PageInfo(
          startCursor:
              getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
          endCursor:
              getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
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
        info: PageInfo(
          startCursor:
              getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
          endCursor:
              getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
          hasPrevious: true,
          hasNext: true,
        ),
      );
    }

    return Page(RxList());
  }

  /// Updates the [_hiveProvider] with the provided [provider].
  void updateProvider(HiveLazyProvider provider) {
    _hiveProvider = provider;
  }
}
