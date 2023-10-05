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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/provider/hive/base.dart';
import '/store/model/page_info.dart';
import '/store/pagination.dart';

/// [PageProvider] fetching items from the [Hive].
///
/// [HiveLazyProvider] must be initialized and disposed properly manually.
class HivePageProvider<T extends Object, C, K extends Object, S>
    implements PageProvider<T, C, K> {
  HivePageProvider(
    this._provider, {
    required this.getCursor,
    required this.getKey,
    this.sortingProvider,
    this.isFirst,
    this.isLast,
    this.strategy = PaginationStrategy.fromStart,
    this.reversed = false,
  });

  /// Callback, called when a key of the provided [T] is required.
  final K Function(T item) getKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T? item) getCursor;

  /// [IterableHiveProvider] to fetch the items keys from.
  IterableHiveProvider<K, S>? sortingProvider;

  /// Callback, called to indicate whether the provided [T] is the first.
  final bool Function(T item)? isFirst;

  /// Callback, called to indicate whether the provided [T] is the last.
  final bool Function(T item)? isLast;

  /// [PaginationStrategy] of [around] invoke.
  PaginationStrategy strategy;

  /// Indicator whether this [HivePageProvider] is reversed.
  bool reversed;

  /// [IterableHiveProvider] to fetch the items from.
  IterableHiveProvider<T, K> _provider;

  /// Sets the provided [HiveLazyProvider] as the used one.
  set provider(IterableHiveProvider<T, K> value) => _provider = value;

  @override
  Future<Page<T, C>?> init(T? item, int count) => around(item, null, count);

  @override
  Future<Page<T, C>?> around(T? item, C? cursor, int count) async {
    if (_provider.keys.isEmpty) {
      return null;
    }

    Iterable<dynamic>? keys;

    final Iterable<K> providerKeys =
        await sortingProvider?.values ?? _provider.keys;
    if (item != null) {
      final K key = getKey(item);
      final int initial = providerKeys.toList().indexOf(key);

      if (initial != -1) {
        providerKeys.around(initial, count);
      }
    }

    switch (strategy) {
      case PaginationStrategy.fromStart:
        keys ??= providerKeys.take(count);
        break;

      case PaginationStrategy.fromEnd:
        keys ??= providerKeys.skip(
          (providerKeys.length - count).clamp(0, double.maxFinite.toInt()),
        );
        break;
    }

    List<T> items = [];
    for (var k in keys) {
      final T? item = await _provider.get(k);
      if (item != null) {
        items.add(item);
      }
    }

    return _page(items);
  }

  @override
  FutureOr<Page<T, C>?> after(
    T? item,
    C? cursor,
    int count, {
    bool reversed = false,
  }) async {
    if (item == null) {
      return null;
    }

    if (this.reversed && !reversed) {
      return before(item, cursor, count, reversed: true);
    }

    final key = getKey(item);
    final Iterable<K> providerKeys =
        await sortingProvider?.values ?? _provider.keys;
    final index = providerKeys.toList().indexOf(key);
    if (index != -1 && index < providerKeys.length - 1) {
      List<T> items = [];
      for (var k in providerKeys.after(index, count)) {
        final T? item = await _provider.get(k);
        if (item != null) {
          items.add(item);
        }
      }

      return _page(items);
    }

    return null;
  }

  @override
  FutureOr<Page<T, C>?> before(
    T? item,
    C? cursor,
    int count, {
    bool reversed = false,
  }) async {
    if (item == null) {
      return null;
    }

    if (this.reversed && !reversed) {
      return after(item, cursor, count, reversed: true);
    }

    final K key = getKey(item);
    final Iterable<K> providerKeys =
        await sortingProvider?.values ?? _provider.keys;
    final int index = providerKeys.toList().indexOf(key);
    if (index > 0) {
      final List<T> items = [];
      for (var i in providerKeys.before(index, count)) {
        final T? item = await _provider.get(i);
        if (item != null) {
          items.add(item);
        }
      }

      return _page(items);
    }

    return null;
  }

  @override
  Future<void> put(T item) => _provider.put(item);

  @override
  Future<void> remove(K key) => _provider.remove(key);

  @override
  Future<void> clear() => _provider.clear();

  /// Creates a [Page] from the provided [items].
  Future<Page<T, C>> _page(List<T> items) async {
    bool hasNext = true;
    bool hasPrevious = true;

    final T? firstItem = items.firstOrNull;
    if (firstItem != null && isFirst != null) {
      hasPrevious = !isFirst!.call(firstItem) ||
          getKey(items.first) !=
              ((await sortingProvider?.values)?.first ?? _provider.keys.first);
    }

    final T? lastItem = items.lastOrNull;
    if (lastItem != null && isLast != null) {
      hasNext = !isLast!.call(lastItem) ||
          getKey(items.last) !=
              ((await sortingProvider?.values)?.last ?? _provider.keys.last);
    }

    return Page(
      reversed ? items.reversed.toList() : items,
      PageInfo(
        startCursor:
            getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
        endCursor: getCursor(lastItem),
        hasPrevious: reversed ? hasNext : hasPrevious,
        hasNext: reversed ? hasPrevious : hasNext,
      ),
    );
  }
}

/// Extension adding ability to take items around, after and before an index.
extension AroundExtension<T> on Iterable<T> {
  /// Returns the [count] items around the provided [index].
  Iterable<T> around(int index, int count) {
    if (index < (count ~/ 2)) {
      return take(count - ((count ~/ 2) - index));
    } else {
      return skip(index - (count ~/ 2)).take(count);
    }
  }

  /// Returns the [count] items after the provided [index].
  Iterable<T> after(int index, int count) {
    return skip(index + 1).take(count);
  }

  /// Returns the [count] items before the provided [index].
  Iterable<T> before(int index, int count) {
    if (index < count) {
      return take(index);
    } else {
      return skip(index - count).take(count);
    }
  }
}
