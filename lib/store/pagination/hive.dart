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
class HivePageProvider<U, T> implements PageProvider<U, T> {
  HivePageProvider(
    this._hiveProvider, {
    required this.getCursor,
    required this.getKey,
    this.reversed = false,
  });

  /// Callback, called when a key of the provided [item] is required.
  final dynamic Function(U item) getKey;

  /// Callback, called when a cursor of the provided [item] is required.
  final T? Function(U? item) getCursor;

  /// Indicator whether fetching should start from the end.
  bool reversed;

  /// [HiveLazyProvider] to fetch the items from.
  HiveLazyProvider _hiveProvider;

  @override
  FutureOr<Page<U, T>?> around(U? item, T? cursor, int count) async {
    if (_hiveProvider.keys.isEmpty || (item == null && cursor != null)) {
      return null;
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

    if (reversed) {
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
      PageInfo(
        startCursor:
            getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
        endCursor:
            getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
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
          startCursor:
              getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
          endCursor:
              getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
          hasPrevious: true,
          hasNext: true,
        ),
      );
    }

    return null;
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
          startCursor:
              getCursor(items.firstWhereOrNull((e) => getCursor(e) != null)),
          endCursor:
              getCursor(items.lastWhereOrNull((e) => getCursor(e) != null)),
          hasPrevious: true,
          hasNext: true,
        ),
      );
    }

    return null;
  }

  Future<void> put(Page<U, T> page) async {
    for (var item in page.edges) {
      await add(item);
    }
  }

  @override
  Future<void> add(U item) async {
    await _hiveProvider.putSafe(getKey(item), item!);
  }

  /// Updates the [_hiveProvider] with the provided [provider].
  void updateProvider(HiveLazyProvider provider) {
    _hiveProvider = provider;
  }
}
