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

import 'package:get/get.dart';

import '/domain/model/chat_item.dart';
import '../domain/repository/paginated.dart';
import '/store/model/chat_item.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import 'pagination.dart';

/// Implementation of a [Paginated].
class PaginatedImpl<K, T, V, C> extends Paginated<K, T> {
  PaginatedImpl({
    this.pagination,
    this.initial = const [],
    this.initialKey,
    this.initialCursor,
    super.onDispose,
  });

  /// Pagination fetching [items].
  final Pagination<V, C, K>? pagination;

  /// Initial [T] items to put inside the [items].
  final List<FutureOr<Map<K, T>>> initial;

  /// [ChatItemKey] to fetch [items] around.
  final K? initialKey;

  /// [ChatItemsCursor] to fetch [items] around.
  final C? initialCursor;

  /// [Future]s loading the initial [items].
  final List<Future> _futures = [];

  /// [StreamSubscription] to the [Pagination.changes].
  StreamSubscription? _paginationSubscription;

  @override
  RxBool get hasNext => pagination?.hasNext ?? RxBool(false);

  @override
  RxBool get hasPrevious => pagination?.hasPrevious ?? RxBool(false);

  @override
  RxBool get nextLoading => pagination?.nextLoading ?? RxBool(false);

  @override
  RxBool get previousLoading => pagination?.previousLoading ?? RxBool(false);

  @override
  int get perPage => pagination?.perPage ?? 0;

  @override
  Future<void> ensureInitialized() async {
    Log.debug('ensureInitialized()', '$runtimeType');

    if (_futures.isEmpty && !status.value.isSuccess) {
      for (var f in initial) {
        if (f is Future<Map<K, T>>) {
          _futures.add(f..then(items.addAll));
        } else {
          items.addAll(f);
        }
      }

      if (pagination != null) {
        _paginationSubscription = pagination!.changes.listen((event) {
          switch (event.op) {
            case OperationKind.added:
            case OperationKind.updated:
              items[event.key!] = event.value as T;
              break;

            case OperationKind.removed:
              items.remove(event.key);
              break;
          }
        });

        _futures.add(
          pagination!.around(key: initialKey, cursor: initialCursor),
        );
      }

      if (_futures.isEmpty) {
        status.value = RxStatus.success();
      } else {
        if (items.isNotEmpty) {
          status.value = RxStatus.loadingMore();
        } else {
          status.value = RxStatus.loading();
        }

        await Future.wait(_futures);
        status.value = RxStatus.success();
      }
    } else {
      await Future.wait(_futures);
    }
  }

  @override
  void dispose() {
    Log.debug('dispose()', '$runtimeType');

    _paginationSubscription?.cancel();
    pagination?.dispose();
    super.dispose();
  }

  @override
  Future<void> clear() async {
    await pagination?.clear();
  }

  @override
  Future<void> next() async {
    Log.debug('next()', '$runtimeType');

    if (pagination != null && nextLoading.isFalse) {
      if (status.value.isSuccess) {
        status.value = RxStatus.loadingMore();
      }

      // TODO: Probably shouldn't do that in the store.
      int length = items.length;
      for (int i = 0; i < 10 && hasNext.isTrue; i++) {
        await pagination!.next();

        if (length != items.length || hasNext.isFalse) {
          break;
        }
      }

      status.value = RxStatus.success();
    }
  }

  @override
  Future<void> previous() async {
    Log.debug('previous()', '$runtimeType');

    if (pagination != null && previousLoading.isFalse) {
      if (status.value.isSuccess) {
        status.value = RxStatus.loadingMore();
      }

      // TODO: Probably shouldn't do that in the store.
      int length = items.length;
      for (int i = 0; i < 10 && hasPrevious.isTrue; i++) {
        await pagination!.previous();

        if (length != items.length || hasPrevious.isFalse) {
          break;
        }
      }

      status.value = RxStatus.success();
    }
  }
}

/// Implementation of a [Paginated] transforming [V] from [Pagination] to [T]
/// value.
class RxPaginatedImpl<K, T, V, C> extends PaginatedImpl<K, T, V, C> {
  RxPaginatedImpl({
    required this.transform,
    required Pagination<V, C, K> super.pagination,
    super.initial,
    super.initialKey,
    super.initialCursor,
    super.onDispose,
  }) {
    // TODO: Replace completely with bug-free [_apply]ing of items right away.
    _paginationSubscription = pagination!.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          await _apply(event.key as K, event.value as V);
          break;

        case OperationKind.removed:
          items.remove(event.key);
          break;
      }
    });
  }

  /// Callback, called to transform the [V] to [T].
  final FutureOr<T?> Function({T? previous, required V data}) transform;

  /// Returns the raw count of [V] items kept in [pagination].
  ///
  /// Note, that this count may __not__ be equal to [length], as [transform] is
  /// applied to every item in [pagination] before appending to the [items],
  /// which may take some time.
  int get rawLength => pagination!.items.length;

  @override
  Future<void> ensureInitialized() async {
    Log.debug('ensureInitialized()', '$runtimeType');

    if (_futures.isEmpty && !status.value.isSuccess) {
      for (var f in initial) {
        if (f is Future<Map<K, T>>) {
          _futures.add(f..then(items.addAll));
        } else {
          items.addAll(f);
        }
      }

      await Future.wait(_futures);
      status.value = RxStatus.success();
      _futures.clear();
    } else {
      await Future.wait(_futures);
    }
  }

  @override
  Future<void> around() async {
    Log.debug('around()', '$runtimeType');

    if (!status.value.isSuccess) {
      await ensureInitialized();
    } else if (items.isNotEmpty) {
      await clear();
    }

    final Page<V, C>? page = await pagination?.around(
      key: initialKey,
      cursor: initialCursor,
    );

    if (page != null) {
      for (var e in page.edges) {
        await _apply(pagination!.onKey(e), e);
      }
    }
  }

  @override
  Future<void> next() async {
    Log.debug('next()', '$runtimeType');

    if (!status.value.isSuccess) {
      await ensureInitialized();
    }

    if (nextLoading.isFalse) {
      await pagination?.next();
    }
  }

  @override
  Future<void> previous() async {
    Log.debug('previous()', '$runtimeType');

    if (!status.value.isSuccess) {
      await ensureInitialized();
    }

    if (previousLoading.isFalse) {
      await pagination?.previous();
    }
  }

  /// Puts the provided [item] to the [pagination].
  Future<void> put(V item, {bool ignoreBounds = false}) async {
    await pagination?.put(item, ignoreBounds: ignoreBounds);
  }

  /// Removes the item with the provided [key] from the [pagination].
  Future<void> remove(K key) async {
    await pagination?.remove(key);
  }

  @override
  Future<void> clear() async {
    items.clear();
    await pagination?.clear();
    status.value = RxStatus.empty();
  }

  /// Applies [transform] to the [value] item with its [key].
  FutureOr<void> _apply(K key, V value) {
    final FutureOr<T?> itemOrFuture = transform(
      previous: items[key],
      data: value,
    );

    if (itemOrFuture is T?) {
      if (itemOrFuture != null) {
        items[key] = itemOrFuture;
      }
    } else {
      return Future(() async {
        final item = await itemOrFuture;
        if (item != null) {
          items[key] = item;
        }
      });
    }
  }
}
