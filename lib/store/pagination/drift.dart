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
import 'package:mutex/mutex.dart';

import '../../domain/model/chat_item.dart';
import '../model/chat_item.dart';
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
    this.top,
    this.bottom,
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

  final FutureOr<Stream<List<T>>> Function({
    int? after,
    int? before,
    K? around,
  })? watch;

  final Stream<List<MapChangeNotification<K, T>>> Function(
    T item,
  )? top;

  final Stream<List<MapChangeNotification<K, T>>> Function(
    T item,
  )? bottom;

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
  int? _after = 0;

  /// Count of [T] items requested before the [_around].
  int? _before = 0;

  /// Key [K], around which the [_list] should be [fetch]ed.
  K? _around;

  /// [K]eys accounted during [put] and [remove], so that those keys aren't
  /// fired again when [watch] fires items.
  final List<(OperationKind, K)> _accounted = [];

  /// Subscription to [watch].
  StreamSubscription? _watchSubscription;

  StreamSubscription? _topSubscription;

  StreamSubscription? _bottomSubscription;

  List<T> _items = [];

  T? get _first => _list.lastWhereOrNull((e) => isFirst?.call(e) == true);

  T? get _last => _list.firstWhereOrNull((e) => isLast?.call(e) == true);

  /// Indicates whether the [_list] contain an item identified as the first.
  bool get _hasFirst => _first != null;

  /// Indicates whether the [_list] contain an item identified as the last.
  bool get _hasLast => _last != null;

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

    _ensureWatchers();

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
  void dispose() {
    _watchSubscription?.cancel();
    _topSubscription?.cancel();
    _bottomSubscription?.cancel();
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

    _ensureWatchers();

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
    if (_after != null) {
      _after = _after! + count;
    }

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool fulfilled =
        fulfilledWhenNone || _hasLast || edges.length - edgesBefore >= count;

    Log.debug(
      'after($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    _ensureWatchers();

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
    if (_before != null) {
      _before = _before! + count;
    }

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool fulfilled =
        fulfilledWhenNone || _hasFirst || edges.length - edgesBefore >= count;

    Log.debug(
      'before($key, $count) -> $fulfilled(${edges.length}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    _ensureWatchers();

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
      _account(OperationKind.added, onKey(item));
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

      if (_after != null) {
        _after = _after! + items.length;
      }

      _page();
    }

    await add?.call(items, toView: toView);
  }

  @override
  Future<void> remove(K key) async {
    _account(OperationKind.removed, key);
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

    _watchSubscription?.cancel();
    _topSubscription?.cancel();
    _bottomSubscription?.cancel();
  }

  final Mutex _guard = Mutex();

  /// Returns the [T] items [fetch]ed.
  Future<List<T>> _page() async {
    return await _guard.protect(() async {
      if (fetch != null) {
        _list = await fetch!(
          after: _after ?? 50,
          before: _before ?? 50,
          around: _around,
        );
      } else if (watch != null) {
        print('===== querying $_before/$_after items...');

        final stream = await watch!(
          after: _after,
          before: _before,
          around: _around,
        );

        final Completer<List<T>> completer = Completer();

        _watchSubscription?.cancel();
        _watchSubscription = stream.listen(
          (items) {
            if (items is List<DtoChatItem>) {
              print(
                  '=============== ${(items as List<DtoChatItem>).map((e) => e is DtoChatMessage ? '${(e.value as ChatMessage).text}' : '${e.value.runtimeType}').toList()}');
            }

            for (var e in items) {
              final K key = onKey(e);
              final T? item = _items.firstWhereOrNull((m) => onKey(m) == key);

              if (item == null) {
                if (!_accounted.contains((OperationKind.added, key))) {
                  onAdded?.call(e);
                }
              } else if (e != item) {
                onAdded?.call(e);
              }
            }

            for (var e in _items) {
              final K key = onKey(e);
              final T? item = items.firstWhereOrNull((m) => onKey(m) == key);

              if (item == null) {
                if (!_accounted.contains((OperationKind.removed, key))) {
                  onRemoved?.call(e);
                }
              }
            }

            _items = List.from(items);

            if (!completer.isCompleted) {
              completer.complete(items);
            }

            // if (!completer.isCompleted) {
            //   completer.complete(e.map((m) => m.value!).toList());
            // } else {
            //   for (var m in e) {
            //     final K key = m.key as K;

            //     switch (m.op) {
            //       case OperationKind.added:
            //         Log.info('[${m.op}] $key');

            //         if (!_accounted.contains((m.op, key))) {
            //           onAdded?.call(m.value as T);
            //         }
            //         break;

            //       case OperationKind.removed:
            //         if (!_accounted.contains((m.op, key))) {
            //           onRemoved?.call(m.value as T);
            //         }
            //         break;

            //       case OperationKind.updated:
            //         final K key = m.key as K;
            //         Log.info('[${m.op}] $key');

            //         if (!_accounted.contains((m.op, key))) {
            //           onAdded?.call(m.value as T);
            //         }
            //         break;
            //     }
            //   }
            // }
          },
        );

        _list = await completer.future;
      }

      return _list;
    });
  }

  void _ensureWatchers() {
    if (_before != null) {
      final T? first = _first;
      if (first != null) {
        print('===== first detected, switching to before-less...');
        _before = null;
        _page();
      }
    }

    if (_after != null) {
      final T? last = _last;
      if (last != null) {
        print('===== last detected, switching to after-less...');
        _after = null;
        _page();
      }
    }

    if (top != null && _topSubscription == null) {
      final T? first = _first;

      if (first != null) {
        _topSubscription?.cancel();
        _topSubscription = top!(first).listen((items) {
          for (var e in items) {
            final K key = e.key as K;

            switch (e.op) {
              case OperationKind.added:
                if (!_accounted.contains((e.op, key))) {
                  onAdded?.call(e.value as T);
                }
                break;

              case OperationKind.removed:
                onRemoved?.call(e.value as T);
                break;

              case OperationKind.updated:
                final K key = e.key as K;
                Log.info('[${e.op}] $key');

                if (!_accounted.contains((e.op, key))) {
                  onAdded?.call(e.value as T);
                }
                break;
            }
          }
        });
      }
    }

    if (bottom != null && _bottomSubscription == null) {
      final T? last = _last;

      if (last != null) {
        _bottomSubscription?.cancel();
        _bottomSubscription = bottom!(last).listen((items) {
          for (var e in items) {
            final K key = e.key as K;

            switch (e.op) {
              case OperationKind.added:
                if (!_accounted.contains((e.op, key))) {
                  onAdded?.call(e.value as T);
                }
                break;

              case OperationKind.removed:
                onRemoved?.call(e.value as T);
                break;

              case OperationKind.updated:
                final K key = e.key as K;
                Log.info('[${e.op}] $key');

                if (!_accounted.contains((e.op, key))) {
                  onAdded?.call(e.value as T);
                }
                break;
            }
          }
        });
      }
    }
  }

  void _account(OperationKind op, K key) {
    _accounted.add((OperationKind.added, key));
    if (_accounted.length > 128) {
      _accounted.removeAt(0);
    }
  }
}
