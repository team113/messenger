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
import 'package:log_me/log_me.dart';

import '/store/chat_rx.dart';
import '/store/model/page_info.dart';
import '/store/pagination.dart';
import '/util/obs/obs.dart';

/// [PageProvider] fetching items from the [ScopedDriftProvider].
class DriftPageProvider<T, C, K> extends PageProvider<T, C, K> {
  DriftPageProvider({
    required this.onKey,
    required this.onCursor,
    this.fetch,
    this.watch,
    this.add,
    this.delete,
    this.reset,
    this.isFirst,
    this.isLast,
    this.onNone,
    this.compare,
    this.fulfilledWhenNone = false,
    this.onAdded,
    this.onRemoved,
  });

  /// Callback, called when a [K] of the provided [T] is required.
  final K Function(T) onKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T?) onCursor;

  // Use [Stream]s here?
  /// Callback, called when the [after] and [before] amounts of [T] items
  /// [around] the provided [K] are required.
  final FutureOr<List<T>> Function({
    required int after,
    required int before,
    K? around,
  })? fetch;

  final FutureOr<Stream<List<MapChangeNotification<K, T>>>> Function({
    required int after,
    required int before,
    K? around,
  })? watch;

  /// Callback, called when the provided [T] items should be persisted.
  final Future<void> Function(Iterable<T> items, {bool toView})? add;

  /// Callback, called when the provided [key] was invoked during [init].
  final Future<void> Function(K key)? onNone;

  /// Callback, called when an item at the [key] should be deleted.
  final Future<void> Function(K key)? delete;

  /// Callback, called when this provider should clear all its data.
  final Future<void> Function()? reset;

  /// Callback, called to indicate whether the provided [T] is the first.
  ///
  /// `null` returned means that the [T] shouldn't participant in such test.
  final bool? Function(T)? isFirst;

  /// Callback, called to indicate whether the provided [T] is the last.
  ///
  /// `null` returned means that the [T] shouldn't participant in such test.
  final bool? Function(T)? isLast;

  /// Callback, called to compare the provided [T] items.
  final int Function(T, T)? compare;

  /// Callback, called when the provided [T] item is added via [watch].
  final void Function(T)? onAdded;

  /// Callback, called when the provided [T] item is removed via [watch].
  final void Function(T)? onRemoved;

  /// Indicator whether the zero-item responses should be considered fulfilled.
  final bool fulfilledWhenNone;

  /// Internal [List] of [T] items retrieved from the [fetch].
  List<T> _list = [];

  /// Count of [T] items requested after the [_around].
  int _after = 0;

  /// Count of [T] items requested before the [_around].
  int _before = 0;

  /// Key [K], around which the [_list] should be [fetch]ed.
  K? _around;

  /// [K]eys accounted during [put] and [remove], so that those keys aren't
  /// fired again when [watch] fires items.
  final Set<K> _accounted = {};

  /// Subscription to [watch].
  StreamSubscription? _watchSubscription;

  /// Indicates whether the [_list] contain an item identified as the first.
  bool get _hasFirst =>
      _list.lastWhereOrNull((e) => isFirst?.call(e) == true) != null;

  /// Indicates whether the [_list] contain an item identified as the last.
  bool get _hasLast =>
      _list.firstWhereOrNull((e) => isLast?.call(e) == true) != null;

  /// Returns the last non-`null` [C] cursor from the [_list].
  C? get _lastCursor =>
      onCursor(_list.lastWhereOrNull((e) => onCursor(e) != null));

  /// Returns the first non-`null` [C] cursor from the [_list].
  C? get _firstCursor =>
      onCursor(_list.firstWhereOrNull((e) => onCursor(e) != null));

  @override
  Future<Page<T, C>> init(K? key, int count) async {
    _reset(around: key, count: count);

    final List<T> edges = await _page();

    Log.debug(
      'init($key, $count) -> (${edges.length}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    if (edges.isEmpty && key != null) {
      try {
        await onNone?.call(key);
      } catch (e) {
        Log.warning('Failed to `onNone`: $e', '$runtimeType');
      }
    }

    return Page(
      edges,
      PageInfo(
        hasNext: !_hasLast,
        hasPrevious: !_hasFirst,
        startCursor: _firstCursor,
        endCursor: _lastCursor,
      ),
    );
  }

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    _reset(around: key, count: count);

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool fulfilled = fulfilledWhenNone ||
        (_hasFirst && _hasLast) ||
        edges.length - edgesBefore >= count ~/ 2;

    Log.debug(
      'around($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    final bool zeroed = fulfilledWhenNone && edges.isEmpty;

    return Page(
      fulfilled ? edges : [],
      PageInfo(
        hasNext: !_hasLast && !zeroed,
        hasPrevious: !_hasFirst && !zeroed,
        startCursor: _firstCursor,
        endCursor: _lastCursor,
      ),
    );
  }

  @override
  Future<Page<T, C>> after(K? key, C? cursor, int count) async {
    _after += count;

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool fulfilled =
        fulfilledWhenNone || _hasLast || edges.length - edgesBefore >= count;

    Log.debug(
      'after($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    return Page(
      fulfilled ? edges : [],
      PageInfo(
        hasNext: !_hasLast,
        hasPrevious: !_hasFirst,
        startCursor: _firstCursor,
        endCursor: _lastCursor,
      ),
    );
  }

  @override
  Future<Page<T, C>> before(K? key, C? cursor, int count) async {
    _before += count;

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool fulfilled =
        fulfilledWhenNone || _hasFirst || edges.length - edgesBefore >= count;

    Log.debug(
      'before($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    return Page(
      fulfilled ? edges : [],
      PageInfo(
        hasNext: !_hasLast,
        hasPrevious: !_hasFirst,
        startCursor: _firstCursor,
        endCursor: _lastCursor,
      ),
    );
  }

  @override
  Future<void> put(Iterable<T> items, {int Function(T, T)? compare}) async {
    final bool toView = compare == null;

    for (var item in items) {
      _accounted.add(onKey(item));
    }

    if (toView) {
      for (var item in items) {
        final int i = _list.indexWhere((e) => onKey(e) == onKey(item));
        if (i != -1) {
          _list[i] = item;
        } else {
          _list.insertAfter(item, (e) => this.compare?.call(e, item) == 1);
        }
      }
    }

    await add?.call(items, toView: toView);
  }

  @override
  Future<void> remove(K key) async {
    _accounted.add(key);
    await delete?.call(key);
  }

  @override
  Future<void> clear() async {
    _accounted.clear();
    await reset?.call();
  }

  /// Resets all the values to be [around].
  void _reset({K? around, int count = 50}) {
    _list.clear();
    _after = count ~/ 2;
    _before = count ~/ 2;
    _around = around;
  }

  /// Returns the [T] items [fetch]ed.
  Future<List<T>> _page() async {
    if (fetch != null) {
      _list = await fetch!(after: _after, before: _before, around: _around);
    } else if (watch != null) {
      final stream = await watch!(
        after: _after,
        before: _before,
        around: _around,
      );

      final Completer<List<T>> completer = Completer();

      _watchSubscription?.cancel();
      _watchSubscription = stream.listen(
        (e) {
          if (!completer.isCompleted) {
            completer.complete(e.map((m) => m.value!).toList());
          } else {
            for (var m in e) {
              final key = onKey(m.value as T);

              switch (m.op) {
                case OperationKind.added:
                  if (!_accounted.remove(key)) {
                    _accounted.add(key);
                    onAdded?.call(m.value as T);
                  }
                  break;

                case OperationKind.removed:
                  onRemoved?.call(m.value as T);
                  break;

                case OperationKind.updated:
                  if (!_accounted.remove(key)) {
                    _accounted.add(key);
                    onAdded?.call(m.value as T);
                  }
                  break;
              }
            }
          }
        },
      );

      _list = await completer.future;
    }

    return _list;
  }
}
