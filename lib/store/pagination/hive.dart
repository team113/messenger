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
class HivePageProvider<T extends Object, C, K>
    implements PageProvider<T, C, K> {
  HivePageProvider(
    this._provider, {
    required this.getCursor,
    required this.getKey,
    this.isFirst,
    this.isLast,
    this.strategy = PaginationStrategy.fromStart,
  });

  /// Callback, called when a key of the provided [T] is required.
  final K Function(T item) getKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T? item) getCursor;

  /// Callback, called to check the provided [T] is first.
  final bool Function(T item)? isFirst;

  /// Callback, called to check the provided [T] is last.
  final bool Function(T item)? isLast;

  /// [PaginationStrategy] of [around] invoke.
  PaginationStrategy strategy;

  /// [HiveLazyProvider] to fetch the items from.
  IterableHiveProviderMixin<T, K> _provider;

  /// Sets the provided [HiveLazyProvider] as the used one.
  set provider(IterableHiveProviderMixin<T, K> value) => _provider = value;

  @override
  Future<Page<T, C>?> init(T? item, int count) => around(item, null, count);

  @override
  Future<Page<T, C>?> around(T? item, C? cursor, int count) async {
    if (_provider.keysSafe.isEmpty || item == null) {
      return null;
    }

    Iterable<dynamic>? keys;

    final K key = getKey(item);
    final Iterable<K> providerKeys = _provider.keys;
    final int initial = providerKeys.toList().indexOf(key);

    if (initial != -1) {
      if (initial < (count ~/ 2)) {
        keys = providerKeys.take(count - ((count ~/ 2) - initial));
      } else {
        keys = providerKeys.skip(initial - (count ~/ 2)).take(count);
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
  FutureOr<Page<T, C>?> after(T? item, C? cursor, int count) async {
    if (item == null) {
      return null;
    }

    final key = getKey(item);
    final index = _provider.keys.toList().indexOf(key);
    if (index != -1 && index < _provider.keys.length - 1) {
      List<T> items = [];
      for (var k in _provider.keys.skip(index + 1).take(count)) {
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
  FutureOr<Page<T, C>?> before(T? item, C? cursor, int count) async {
    if (item == null) {
      return null;
    }

    final K key = getKey(item);
    final int index = _provider.keys.toList().indexOf(key);
    if (index > 0) {
      if (index < count) {
        count = index;
      }

      List<T> items = [];
      for (var i in _provider.keys.skip(index - count).take(count)) {
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
  Page<T, C> _page(List<T> items) {
    final T? firstItem = items.firstWhereOrNull((e) => getCursor(e) != null);
    bool hasPrevious = true;

    if (firstItem != null && isFirst != null) {
      hasPrevious = !isFirst!.call(firstItem) ||
          getKey(items.first) != _provider.keys.first;
    }

    final T? lastItem = items.lastWhereOrNull((e) => getCursor(e) != null);
    bool hasNext = true;

    if (lastItem != null && isLast != null) {
      hasNext =
          !isLast!.call(lastItem) || getKey(items.last) != _provider.keys.last;
    }

    return Page(
      RxList(items.toList()),
      PageInfo(
        startCursor:
            getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
        endCursor: getCursor(lastItem),
        hasPrevious: hasPrevious,
        hasNext: hasNext,
      ),
    );
  }
}
