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
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/util/backoff.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import 'model/page_info.dart';

/// [Page]s maintainer utility of the provided [T] values with the specified [K]
/// key identifying those items and their [C] cursor.
class Pagination<T, C, K> {
  Pagination({
    this.perPage = 50,
    required this.provider,
    required this.onKey,
    this.compare,
    this.fulfilled = _returnsTrue,
  });

  /// Items per [Page] to fetch.
  final int perPage;

  /// Items fetched from the [provider] ordered by their [T] values.
  ///
  /// Use [compare] to describe the order.
  late final SortedObsMap<K, T> items = SortedObsMap(compare);

  /// [PageProvider] providing the [items].
  final PageProvider<T, C, K> provider;

  /// Indicator whether the [items] have next page.
  final RxBool hasNext = RxBool(true);

  /// Indicator whether the [items] have previous page.
  final RxBool hasPrevious = RxBool(true);

  /// Indicator whether the [next] page of [items] is being fetched.
  final RxBool nextLoading = RxBool(false);

  /// Indicator whether the [previous] page of [items] is being fetched.
  final RxBool previousLoading = RxBool(false);

  /// Callback, called when a key of type [K] identifying the provided [T] item
  /// is required.
  final K Function(T) onKey;

  /// Callback, comparing the provided [T] items to order them in the [items].
  final int Function(T, T)? compare;

  /// Callback, indicating whether the provided page is considered as fulfilled
  /// the request.
  final bool Function(Iterable<T>) fulfilled;

  /// Cursor of the first item in the [items] list.
  @visibleForTesting
  C? startCursor;

  /// Cursor of the last item in the [items] list.
  @visibleForTesting
  C? endCursor;

  /// [Mutex] guarding synchronized access to the [init] and [around].
  final Mutex _guard = Mutex();

  /// [Mutex] guarding synchronized access to the [next].
  final Mutex _nextGuard = Mutex();

  /// [Mutex] guarding synchronized access to the [previous].
  final Mutex _previousGuard = Mutex();

  /// [Mutex] guarding synchronized access to the [put] and [remove].
  final Mutex _itemsGuard = Mutex();

  /// [CancelToken] for cancelling [init], [around], [next] and [previous]
  /// query.
  final CancelToken _cancelToken = CancelToken();

  /// Indicator whether this [Pagination] has been disposed.
  bool _disposed = false;

  /// Returns a [Stream] of changes of the [items].
  Stream<MapChangeNotification<K, T>> get changes => items.changes;

  /// Indicator whether this [Pagination] is empty.
  bool get isEmpty => items.isEmpty && hasNext.isTrue && hasPrevious.isTrue;

  /// Disposes this [Pagination].
  void dispose() {
    Log.debug('dispose()', '$runtimeType');

    provider.dispose();
    _cancelToken.cancel();
    _disposed = true;
  }

  /// Resets this [Pagination] to its initial state.
  Future<void> clear() {
    Log.debug('clear()', '$runtimeType');

    items.clear();
    hasNext.value = true;
    hasPrevious.value = true;
    startCursor = null;
    endCursor = null;
    return provider.clear();
  }

  /// Fetches the initial [Page] of [items].
  Future<void> init(K? key) {
    if (_disposed) {
      return Future.value();
    }

    return _guard.protect(() async {
      if (!isEmpty) {
        return;
      }

      try {
        final Page<T, C>? page = await Backoff.run(
          () => provider.init(key, perPage),
          cancel: _cancelToken,
        );
        Log.debug(
          'init(key: $key)... \n'
              '\tFetched ${page?.edges.length} items\n'
              '\tstartCursor: ${page?.info.startCursor}\n'
              '\tendCursor: ${page?.info.endCursor}\n'
              '\thasPrevious: ${page?.info.hasPrevious}\n'
              '\thasNext: ${page?.info.hasNext}',
          '$runtimeType',
        );

        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }

        startCursor = page?.info.startCursor;
        endCursor = page?.info.endCursor;
        hasNext.value = page?.info.hasNext ?? hasNext.value;
        hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
        Log.debug('init(key: $key)... done', '$runtimeType');
      } catch (e) {
        if (e is! OperationCanceledException) {
          rethrow;
        }
      }
    });
  }

  /// Fetches the [Page] around the provided [key] or [cursor].
  ///
  /// If neither [key] nor [cursor] is provided, then fetches the first [Page].
  Future<Page<T, C>?> around({K? key, C? cursor}) {
    if (_disposed) {
      return Future.value(null);
    }

    final bool locked = _guard.isLocked;

    return _guard.protect(() async {
      if ((locked && !isEmpty) || _disposed) {
        return null;
      }

      Log.debug('around(key: $key, cursor: $cursor)...', '$runtimeType');

      try {
        final Page<T, C>? page = await Backoff.run(
          () => provider.around(key, cursor, perPage),
          cancel: _cancelToken,
        );

        Log.debug(
          'around(key: $key, cursor: $cursor)... \n'
              '\tFetched ${page?.edges.length} items\n'
              '\tstartCursor: ${page?.info.startCursor}\n'
              '\tendCursor: ${page?.info.endCursor}\n'
              '\thasPrevious: ${page?.info.hasPrevious}\n'
              '\thasNext: ${page?.info.hasNext}',
          '$runtimeType',
        );

        for (var e in page?.edges ?? []) {
          items[onKey(e)] = e;
        }

        startCursor = page?.info.startCursor;
        endCursor = page?.info.endCursor;
        hasNext.value = page?.info.hasNext ?? hasNext.value;
        hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
        Log.debug('around(key: $key, cursor: $cursor)... done', '$runtimeType');

        return page;
      } catch (e) {
        if (e is! OperationCanceledException) {
          rethrow;
        }
      }

      return null;
    });
  }

  /// Fetches a next page of the [items].
  Future<void> next() async {
    if (_disposed) {
      return Future.value();
    }

    final bool locked = _nextGuard.isLocked;

    return _nextGuard.protect(() async {
      if (locked || _disposed) {
        return;
      }

      await _repeatUntilFulfilled(() async {
        Log.debug('next()...', '$runtimeType');

        if (hasNext.isTrue && nextLoading.isFalse) {
          nextLoading.value = true;

          try {
            if (items.isNotEmpty) {
              try {
                final Page<T, C>? page = await Backoff.run(
                  () => provider.after(onKey(items.last), endCursor, perPage),
                  cancel: _cancelToken,
                );
                Log.debug(
                  'next()... fetched ${page?.edges.length} items',
                  '$runtimeType',
                );

                final int before = items.length;
                for (var e in page?.edges ?? []) {
                  items[onKey(e)] = e;
                }

                endCursor = page?.info.endCursor ?? endCursor;
                hasNext.value = page?.info.hasNext ?? hasNext.value;
                Log.debug('next()... done', '$runtimeType');

                return page?.edges
                    .skip(before)
                    .take(max(0, items.length - before));
              } catch (e) {
                if (e is! OperationCanceledException) {
                  rethrow;
                }
              }
            } else {
              await around();
            }
          } finally {
            nextLoading.value = false;
          }
        }

        return null;
      });
    });
  }

  /// Fetches a previous page of the [items].
  Future<void> previous() async {
    if (_disposed) {
      return Future.value();
    }

    final bool locked = _previousGuard.isLocked;

    return _previousGuard.protect(() async {
      if (locked || _disposed) {
        return;
      }

      await _repeatUntilFulfilled(() async {
        Log.debug('previous()...', '$runtimeType');

        if (hasPrevious.isTrue && previousLoading.isFalse) {
          previousLoading.value = true;

          try {
            if (items.isNotEmpty) {
              try {
                final Page<T, C>? page = await Backoff.run(
                  () =>
                      provider.before(onKey(items.first), startCursor, perPage),
                  cancel: _cancelToken,
                );
                Log.debug(
                  'previous()... fetched ${page?.edges.length} items',
                  '$runtimeType',
                );

                final int before = items.length;
                for (var e in page?.edges ?? []) {
                  items[onKey(e)] = e;
                }

                startCursor = page?.info.startCursor ?? startCursor;
                hasPrevious.value = page?.info.hasPrevious ?? hasPrevious.value;
                Log.debug('previous()... done', '$runtimeType');

                return page?.edges.take(max(0, items.length - before));
              } catch (e) {
                if (e is! OperationCanceledException) {
                  rethrow;
                }
              }
            } else {
              Log.debug(
                'previous()... propagated to `around` due to items being empty',
                '$runtimeType',
              );
              await around();
            }
          } finally {
            previousLoading.value = false;
          }
        } else {
          Log.debug(
            'previous()... canceled due to `hasPrevious` being `true` ($hasPrevious) or `previousLoading` being false ($previousLoading)',
            '$runtimeType',
          );
        }

        return null;
      });
    });
  }

  /// Adds the provided [item] to the [items].
  ///
  /// [item] will be added if it is within the bounds of the stored [items].
  ///
  /// If [store] is `false`, then the [item] will be only added to the [items]
  /// and won't be put to the [provider].
  Future<void> put(
    T item, {
    bool ignoreBounds = false,
    bool store = true,
  }) async {
    if (_disposed) {
      return;
    }

    Log.debug('put($item)', '$runtimeType');

    // Bypasses the bounds check.
    //
    // Intended to be used to forcefully add items, e.g. when items are
    // migrating from one source to another.
    bool put = ignoreBounds;

    if (!put) {
      await _itemsGuard.protect(() async {
        // Wait for [items] fetching before putting a new one.
        await _guard.protect(() async => null);
        await _nextGuard.protect(() async => null);
        await _previousGuard.protect(() async => null);

        if (items.isEmpty) {
          put = hasNext.isFalse && hasPrevious.isFalse;
        } else if (compare?.call(item, items.last) == 1) {
          put = hasNext.isFalse;
        } else if (compare?.call(item, items.first) == -1) {
          put = hasPrevious.isFalse;
        } else {
          put = true;
        }
      });
    }

    if (put) {
      items[onKey(item)] = item;
    }

    if (store) {
      await provider.put([item], compare: put ? null : compare);
    }
  }

  /// Removes the item with the provided [key] from the [items] and [provider].
  ///
  ///
  /// If [store] is `false`, then the [key] will be only removed from the
  /// [items] and won't be removed from the [provider].
  Future<void> remove(K key, {bool store = true}) async {
    Log.debug('remove($key)', '$runtimeType');

    if (_disposed) {
      return Future.value();
    }

    await _itemsGuard.protect(() async {
      items.remove(key);
    });

    if (store) {
      await provider.remove(key);
    }
  }

  /// Repeats the provided [callback] until the [Page] it returns fulfills the
  /// [fulfilled] condition.
  ///
  /// [delay] may be provided to add delay between the invokes of [callback].
  Future<void> _repeatUntilFulfilled(
    Future<Iterable<T>?> Function() callback, {
    Duration delay = Duration.zero,
  }) async {
    bool done = false;

    while (!done) {
      final Iterable<T>? items = await callback();
      done = items == null || fulfilled(items.take(perPage)) || items.isEmpty;

      if (!done) {
        Log.debug(
          '_repeatUntilFulfilled(${items.length}) -> repeating',
          '$runtimeType',
        );

        if (delay != Duration.zero) {
          await Future.delayed(delay);
        }
      }
    }
  }

  /// Returns `true`.
  static bool _returnsTrue<T, C>(_) => true;
}

/// List of [T] items along with their [PageInfo] containing the [C] cursor.
class Page<T, C> {
  Page(this.edges, this.info);

  /// Reactive [RxStatus] of the [Page] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the page is not fetched.
  /// - `status.isLoading`, meaning the [edges] are being fetched.
  /// - `status.isLoadingMore`, meaning some [edges] were fetched from local
  ///   storage.
  /// - `status.isSuccess`, meaning the [edges] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.success());

  /// List of the fetched items.
  final List<T> edges;

  /// [PageInfo] of this [Page].
  PageInfo<C> info;

  /// Returns a new [Page] with reversed [info].
  Page<T, C> reversed() {
    return Page(
      List.from(edges.reversed),
      PageInfo(
        hasNext: info.hasPrevious,
        hasPrevious: info.hasNext,
        startCursor: info.endCursor,
        endCursor: info.startCursor,
      ),
    );
  }
}

/// Utility providing the [Page]s.
abstract class PageProvider<T, C, K> {
  /// Initializes this [PageProvider], loading initial [Page], if any.
  Future<Page<T, C>?> init(K? key, int count);

  /// Disposes this [PageProvider], freeing any resources it might've occupied.
  void dispose() {
    // No-op.
  }

  /// Fetches the [Page] around the provided [key] or [cursor].
  ///
  /// If neither [key] nor [cursor] is provided, then fetches the first [Page].
  FutureOr<Page<T, C>?> around(K? key, C? cursor, int count);

  /// Fetches the [Page] after the provided [key] or [cursor].
  FutureOr<Page<T, C>?> after(K? key, C? cursor, int count);

  /// Fetches the [Page] before the provided [key] or [cursor].
  FutureOr<Page<T, C>?> before(K? key, C? cursor, int count);

  /// Adds the provided [items] to this [PageProvider].
  Future<void> put(Iterable<T> items, {int Function(T, T)? compare});

  /// Removes the item specified by its [key] from this [PageProvider].
  Future<void> remove(K key);

  /// Clears this [PageProvider].
  Future<void> clear();
}

/// [PageProvider] page fetching strategy.
enum PaginationStrategy {
  /// [Page]s fetching starts from the beginning of the available window.
  fromStart,

  /// [Page]s fetching starts from the end of the available window.
  fromEnd,
}
