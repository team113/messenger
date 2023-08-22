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
import 'package:mutex/mutex.dart';

import '/provider/hive/base.dart';
import '/store/model/page_info.dart';
import '/store/pagination.dart';

/// [PageProvider] fetching items from the [Hive].
///
/// [HiveLazyProvider] must be initialized and disposed properly manually.
class HivePageProvider<T, C> implements PageProvider<T, C> {
  HivePageProvider(
    this._provider, {
    required this.getCursor,
    required this.getKey,
    this.isLast,
    this.reversed = false,
  });

  /// Callback, called when a key of the provided [T] is required.
  final String Function(T item) getKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T? item) getCursor;

  /// Callback, called to check the provided [T] is last.
  final bool Function(T item)? isLast;

  /// Indicator whether fetching should start from the end.
  bool reversed;

  /// [HiveLazyProvider] to fetch the items from.
  HiveLazyProvider _provider;

  /// Guard used to guarantee synchronous access to the [_provider].
  final Mutex _guard = Mutex();

  /// Sets the provided [HiveLazyProvider] as the used one.
  set provider(HiveLazyProvider value) => _provider = value;

  @override
  Future<Page<T, C>?> init(T? item, int count) => around(item, null, count);

  @override
  Future<Page<T, C>?> around(T? item, C? cursor, int count) {
    return _guard.protect(() async {
      if (_provider.keysSafe.isEmpty || item == null) {
        return null;
      }

      Iterable<dynamic>? keys;
      final key = getKey(item);
      final int initialIndex = _provider.keysSafe.toList().indexOf(key);
      if (initialIndex != -1) {
        if (initialIndex < (count ~/ 2)) {
          keys = _provider.keysSafe.take(count - ((count ~/ 2) - initialIndex));
        } else {
          keys =
              _provider.keysSafe.skip(initialIndex - (count ~/ 2)).take(count);
        }
      }

      if (reversed) {
        keys ??= _provider.keysSafe.toList().reversed.take(count);
      } else {
        keys ??= _provider.keysSafe.take(count);
      }

      List<T> items = [];
      for (var i in keys) {
        final T? item = await _provider.getSafe(i) as T?;
        if (item != null) {
          items.add(item);
        }
      }

      return _page(items);
    });
  }

  @override
  FutureOr<Page<T, C>?> after(T? item, C? cursor, int count) async {
    return _guard.protect(() async {
      if (item == null) {
        return null;
      }

      final key = getKey(item);
      final index = _provider.keysSafe.toList().indexOf(key);
      if (index != -1 && index < _provider.keysSafe.length - 1) {
        List<T> items = [];
        for (var i in _provider.keysSafe.skip(index + 1).take(count)) {
          final T? item = await _provider.getSafe(i) as T?;
          if (item != null) {
            items.add(item);
          }
        }

        return _page(items);
      }

      return null;
    });
  }

  @override
  FutureOr<Page<T, C>?> before(T? item, C? cursor, int count) async {
    return _guard.protect(() async {
      if (item == null) {
        return null;
      }

      final key = getKey(item);
      final index = _provider.keysSafe.toList().indexOf(key);
      if (index > 0) {
        if (index < count) {
          count = index;
        }

        List<T> items = [];
        for (var i in _provider.keysSafe.skip(index - count).take(count)) {
          final T? item = await _provider.getSafe(i) as T?;
          if (item != null) {
            items.add(item);
          }
        }

        return _page(items);
      }

      return null;
    });
  }

  @override
  Future<void> put(T item) =>
      _guard.protect(() => _provider.putSafe(getKey(item), item!));

  @override
  Future<void> remove(String key) =>
      _guard.protect(() => _provider.deleteSafe(key));

  @override
  Future<void> clear() => _guard.protect(() => _provider.clear());

  /// Creates a [Page] from the provided [items].
  Page<T, C> _page(List<T> items) {
    final T? lastItem = items.lastWhereOrNull((e) => getCursor(e) != null);
    bool hasNext = true;
    if (lastItem != null && isLast != null) {
      hasNext = !isLast!.call(lastItem) &&
          getKey(items.last) == _provider.keysSafe.last;
    }

    // [Hive] can't guarantee previous page existence based on the stored
    // values, thus `hasPrevious` is always `true`.
    return Page(
      RxList(items.toList()),
      PageInfo(
        startCursor:
            getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
        endCursor: getCursor(lastItem),
        hasPrevious: true,
        hasNext: hasNext,
      ),
    );
  }
}
