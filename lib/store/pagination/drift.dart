// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
    this.watchUpdates = _defaultWatchUpdates,
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
  }) : assert(fetch != null || watch != null);

  /// Callback, called when a [K] of the provided [T] is required.
  final K Function(T) onKey;

  /// Callback, called when a cursor of the provided [T] is required.
  final C? Function(T?) onCursor;

  /// Callback, called when the [after] and [before] amounts of [T] items
  /// [around] the provided [K] are required.
  ///
  /// Only meaningful, if [watch] isn't provided, or otherwise it will be used
  /// instead.
  final FutureOr<List<T>> Function({
    required int after,
    required int before,
    K? around,
  })?
  fetch;

  /// Callback, called when [Stream] of the [T] items [around] the provided [K]
  /// are required.
  ///
  /// Intended to be used to watch SQL queries being changed.
  final FutureOr<Stream<List<T>>> Function({
    int? after,
    int? before,
    K? around,
  })?
  watch;

  /// Callback, comparing the provided items when they update during [watch] to
  /// determine whether the [onAdded] should be invoked.
  final bool Function(T a, T b) watchUpdates;

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
  final bool? Function(T, int)? isFirst;

  /// Callback, called to indicate whether the provided [T] is the last.
  ///
  /// `null` returned means that the [T] shouldn't participant in such test.
  final bool? Function(T, int)? isLast;

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

  /// [Completer] of [_page]s used to dispose non-completed ones in [dispose].
  final List<Completer<List<T>>> _completers = [];

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

  /// [T] items already fired during the [_watchSubscription], so a diff can be
  /// constructed from the [watch] invokes.
  List<T> _items = [];

  /// [Mutex] guarding the synchronized access to the [_page].
  final Mutex _guard = Mutex();

  /// [Timer] invoking a [fetch], if any, when [watch] takes too much time to
  /// complete.
  Timer? _timeoutTimer;

  /// Returns the last item from the [_list], for which [isFirst] is `true`.
  T? get _first =>
      _list.lastWhereOrNull((e) => isFirst?.call(e, _list.length) == true);

  /// Returns the first item from the [_list], for which [isLast] is `true`.
  T? get _last =>
      _list.firstWhereOrNull((e) => isLast?.call(e, _list.length) == true);

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

    _ensureLimits();

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
    _timeoutTimer?.cancel();
    _watchSubscription?.cancel();

    for (var e in _completers) {
      if (!e.isCompleted) {
        e.complete([]);
      }
    }
  }

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    _reset(around: key, count: count);

    final int edgesBefore = _list.length;
    final List<T> edges = await _page();
    final bool fulfilled =
        fulfilledWhenNone ||
        (_hasFirst && _hasLast) ||
        edges.length - edgesBefore >= count ~/ 2;

    Log.debug(
      'around($key, $count) -> $fulfilled(${edges.length}) cuz ($fulfilledWhenNone || ($_hasFirst && $_hasLast) || ${edges.length} - $edgesBefore >= ${count ~/ 2}), hasNext: ${!_hasLast}, hasPrevious: ${!_hasFirst}',
      '$runtimeType',
    );

    _ensureLimits();

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
    // [_after] can be `null`, when there's no limit above the page.
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

    _ensureLimits();

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
    // [_before] can be `null`, when there's no below the page above.
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

    _ensureLimits();

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
    _reset();
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
  }

  /// Returns the [T] items [fetch]ed.
  Future<List<T>> _page() async {
    return await _guard.protect(() async {
      if (watch != null) {
        final stream = await watch!(
          after: _after,
          before: _before,
          around: _around,
        );

        final Completer<List<T>> completer;
        _completers.add(completer = Completer());

        void handle(List<T> items) {
          for (var e in items) {
            final K key = onKey(e);
            final T? item = _items.firstWhereOrNull((m) => onKey(m) == key);

            if (item == null) {
              if (!_accounted.contains((OperationKind.added, key))) {
                onAdded?.call(e);
              }
            } else if (watchUpdates(e, item)) {
              _accounted.remove((OperationKind.removed, key));
              onAdded?.call(e);
            }
          }

          // `drift` emits `[]` when new [Chat] is created, so this check
          // ignores those events.
          if (items.isNotEmpty) {
            for (var e in _items) {
              final K key = onKey(e);
              final T? item = items.firstWhereOrNull((m) => onKey(m) == key);

              if (item == null) {
                if (!_accounted.contains((OperationKind.removed, key))) {
                  _accounted.remove((OperationKind.added, key));
                  onRemoved?.call(e);
                }
              }
            }
          }

          _items = List.from(items.toList(growable: false), growable: false);

          if (!completer.isCompleted) {
            completer.complete(
              items.isEmpty ? _items.toList() : items.toList(),
            );
            _completers.remove(completer);
          }
        }

        _watchSubscription?.cancel();
        _watchSubscription = stream.listen(handle);

        _timeoutTimer?.cancel();
        _timeoutTimer = Timer(const Duration(seconds: 1), () async {
          if (!completer.isCompleted) {
            if (fetch != null) {
              handle(
                await fetch!(
                  after: _after ?? 50,
                  before: _before ?? 50,
                  around: _around,
                ),
              );
            } else {
              handle([]);
            }
          }
        });

        _list = await completer.future;
      } else if (fetch != null) {
        _list = await fetch!(
          after: _after ?? 50,
          before: _before ?? 50,
          around: _around,
        );
      }

      return _list;
    });
  }

  /// Checks whether the current [_list] contain [_first] or [_last] items, so
  /// the [watch]/[fetch] can be promoted to being unlimited for top or bottom.
  void _ensureLimits() {
    bool refetch = false;

    if (_before != null) {
      final T? first = _first;
      if (first != null || _items.isEmpty) {
        _before = null;
        refetch = true;
      }
    }

    if (_after != null) {
      final T? last = _last;
      if (last != null || _items.isEmpty) {
        _after = null;
        refetch = true;
      }
    }

    if (refetch) {
      _page();
    }
  }

  /// Adds the [key] with its [op] to the [_accounted].
  void _account(OperationKind op, K key) {
    _accounted.add((OperationKind.added, key));
    if (_accounted.length > 128) {
      _accounted.removeAt(0);
    }
  }

  /// Indicates whether [a] isn't equal to [b].
  static bool _defaultWatchUpdates(dynamic a, dynamic b) => a != b;
}
