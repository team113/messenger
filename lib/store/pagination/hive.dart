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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/provider/hive/base.dart';
import '/store/model/page_info.dart';
import '/store/pagination.dart';
import '/util/web/web_utils.dart';

/// [PageProvider] fetching items from the [Hive].
///
/// [HiveLazyProvider] must be initialized and disposed properly manually.
class HivePageProvider<T extends Object, C, K>
    implements PageProvider<T, C, K> {
  HivePageProvider(
    this._provider, {
    required this.getCursor,
    required this.getKey,
    Iterable<K> Function(Iterable<K>)? orderBy,
    this.isFirst,
    this.isLast,
    this.strategy = PaginationStrategy.fromStart,
    this.reversed = false,
    this.readOnly = false,
  }) : orderBy = orderBy ?? _defaultOrderBy<K>;

  /// Callback, called when a key of the provided [T] is required.
  final K Function(T item) getKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T? item) getCursor;

  /// Callback, called to retrieve the order of keys the items from
  /// [IterableHiveProvider] should be sorted in.
  final Iterable<K> Function(Iterable<K>) orderBy;

  /// Callback, called to indicate whether the provided [T] is the first.
  final bool Function(T? item)? isFirst;

  /// Callback, called to indicate whether the provided [T] is the last.
  final bool Function(T? item)? isLast;

  /// [PaginationStrategy] of [around] invoke.
  final PaginationStrategy strategy;

  /// Indicator whether this [HivePageProvider] is reversed.
  final bool reversed;

  /// Indicator whether this [HivePageProvider] is read only.
  final bool readOnly;

  /// [IterableHiveProvider] to fetch the items from.
  IterableHiveProvider<T, K> _provider;

  /// Sets the provided [HiveLazyProvider] as the used one.
  set provider(IterableHiveProvider<T, K> value) => _provider = value;

  @override
  Future<Page<T, C>> init(K? key, int count) => around(key, null, count);

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    final Iterable<K> ordered = orderBy(_provider.keys);

    if (ordered.isEmpty) {
      final Page<T, C> page = Page(
        [],
        PageInfo(
          startCursor: null,
          endCursor: null,
          hasPrevious: isFirst == null ? true : !isFirst!.call(null),
          hasNext: isLast == null ? true : !isLast!.call(null),
        ),
      );

      return reversed ? page.reversed() : page;
    }

    Iterable<dynamic>? keys;
    if (key != null) {
      final int initial = ordered.toList().indexOf(key);

      if (initial != -1) {
        keys = ordered.around(initial, count);
      }
    } else {
      switch (strategy) {
        case PaginationStrategy.fromStart:
          keys = ordered.take(count);
          break;

        case PaginationStrategy.fromEnd:
          keys = ordered.skip(
            (ordered.length - count).clamp(0, double.maxFinite.toInt()),
          );
          break;
      }
    }

    List<T> items = [];
    for (var k in keys ?? []) {
      final T? item = await _provider.get(k);
      if (item != null) {
        items.add(item);
      }
    }

    return _page(items);
  }

  @override
  FutureOr<Page<T, C>?> after(
    K? key,
    C? cursor,
    int count, {
    bool reversed = false,
  }) async {
    if (key == null) {
      return null;
    }

    if (this.reversed && !reversed) {
      return before(key, cursor, count, reversed: true);
    }

    final Iterable<K> ordered = orderBy(_provider.keys);
    final index = ordered.toList().indexOf(key);
    if (index != -1 && index < ordered.length - 1) {
      List<T> items = [];
      for (var k in ordered.after(index, count)) {
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
    K? key,
    C? cursor,
    int count, {
    bool reversed = false,
  }) async {
    if (key == null) {
      return null;
    }

    if (this.reversed && !reversed) {
      return after(key, cursor, count, reversed: true);
    }

    final Iterable<K> ordered = orderBy(_provider.keys);
    final int index = ordered.toList().indexOf(key);
    if (index > 0) {
      final List<T> items = [];
      for (var i in ordered.before(index, count)) {
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
  Future<void> put(Iterable<T> items, {int Function(T, T)? compare}) async {
    // TODO: https://github.com/team113/messenger/issues/27
    // Don't write to [Hive] from popup, as [Hive] doesn't support isolate
    // synchronization, thus writes from multiple applications may lead to
    // missing events.
    if (WebUtils.isPopup || readOnly) {
      return;
    }

    for (var item in items) {
      if (compare == null) {
        return _provider.put(item);
      }

      final Iterable<K> ordered = orderBy(_provider.keys).toList();

      if (ordered.isNotEmpty) {
        final T? firstItem = await _provider.get(ordered.first);
        final T? lastItem = await _provider.get(ordered.last);

        if (firstItem != null && lastItem != null) {
          if (compare(item, lastItem) == 1) {
            if (isLast?.call(item) == true) {
              await _provider.put(item);
            }
          } else if (compare(item, firstItem) == -1) {
            if (isFirst?.call(item) == true) {
              await _provider.put(item);
            }
          } else {
            await _provider.put(item);
          }
        }
      }
    }
  }

  @override
  Future<void> remove(K key) => _provider.remove(key);

  @override
  Future<void> clear() async {
    final Iterable<K> ordered = orderBy(_provider.keys);
    if (ordered.length != _provider.keys.length) {
      for (var e in ordered) {
        await _provider.remove(e);
      }
    } else {
      await _provider.clear();
    }
  }

  /// Returns a copy of this [HivePageProvider] with the provided parameters.
  HivePageProvider<T, C, K> copyWith({bool? readOnly}) {
    return HivePageProvider(
      _provider,
      getCursor: getCursor,
      getKey: getKey,
      orderBy: orderBy,
      isFirst: isFirst,
      isLast: isLast,
      strategy: strategy,
      reversed: reversed,
      readOnly: readOnly ?? this.readOnly,
    );
  }

  /// Creates a [Page] from the provided [items].
  Page<T, C> _page(List<T> items) {
    bool hasNext = true;
    bool hasPrevious = true;

    final Iterable<K> ordered = orderBy(_provider.keys);

    final T? firstItem = items.firstOrNull;
    if (firstItem != null && isFirst != null) {
      hasPrevious =
          !isFirst!.call(firstItem) || getKey(firstItem) != ordered.first;
    }

    final T? lastItem = items.lastOrNull;
    if (lastItem != null && isLast != null) {
      hasNext = !isLast!.call(lastItem) || getKey(lastItem) != ordered.last;
    }

    final Page<T, C> page = Page(
      items,
      PageInfo(
        startCursor:
            getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
        endCursor:
            getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
        hasPrevious: hasPrevious,
        hasNext: hasNext,
      ),
    );

    return reversed ? page.reversed() : page;
  }

  /// Returns the [keys].
  ///
  /// Intended to be used as a default [orderBy].
  static Iterable<K> _defaultOrderBy<K>(Iterable<K> keys) => keys;
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
