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

import 'package:get/get.dart';

import '/domain/model/chat_item.dart';
import '../domain/repository/paginated.dart';
import '/provider/hive/chat_item.dart';
import '/store/model/chat_item.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import 'pagination.dart';

/// Implementation of a [Paginated].
class PaginatedImpl<K extends Comparable, T, C> extends Paginated<K, T> {
  PaginatedImpl({
    this.pagination,
    this.initial = const [],
    super.onDispose,
  });

  /// Pagination fetching [items].
  final Pagination<T, C, K>? pagination;

  /// Initial [T] items to put inside the [items].
  final List<FutureOr<Map<K, T>>> initial;

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

        _futures.add(pagination!.around());
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

/// Implementation of a [Paginated] for [ChatItem]s.
class MessagesPaginated extends Paginated<ChatItemKey, Rx<ChatItem>> {
  MessagesPaginated({
    required this.pagination,
    this.initialKey,
    this.initialCursor,
    super.onDispose,
  });

  /// Pagination fetching [items].
  final Pagination<HiveChatItem, ChatItemsCursor, ChatItemKey> pagination;

  /// [ChatItemKey] to fetch [items] around.
  final ChatItemKey? initialKey;

  /// [ChatItemsCursor] to fetch [items] around.
  final ChatItemsCursor? initialCursor;

  /// [Future]s loading the initial [items].
  final List<Future> _futures = [];

  /// [StreamSubscription] to the [Pagination.changes].
  StreamSubscription? _paginationSubscription;

  @override
  RxBool get hasNext => pagination.hasNext;

  @override
  RxBool get hasPrevious => pagination.hasPrevious;

  @override
  RxBool get nextLoading => pagination.nextLoading;

  @override
  RxBool get previousLoading => pagination.previousLoading;

  @override
  Future<void> ensureInitialized() async {
    Log.debug('ensureInitialized()', '$runtimeType');

    if (_futures.isEmpty) {
      _paginationSubscription = pagination.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
          case OperationKind.updated:
            if (items.containsKey(event.key!)) {
              items[event.key!]!.value = event.value!.value;
            } else {
              items[event.key!] = Rx(event.value!.value);
            }
            break;

          case OperationKind.removed:
            items.remove(event.key);
            break;
        }
      });

      _futures.add(pagination.around(key: initialKey, cursor: initialCursor));

      await Future.wait(_futures);
      status.value = RxStatus.success();
    } else {
      await Future.wait(_futures);
    }
  }

  @override
  void dispose() {
    Log.debug('dispose()', '$runtimeType');

    pagination.dispose();
    _paginationSubscription?.cancel();
    super.dispose();
  }

  @override
  Future<void> next() async {
    Log.debug('next()', '$runtimeType');

    if (nextLoading.isFalse) {
      await pagination.next();
    }
  }

  @override
  Future<void> previous() async {
    Log.debug('previous()', '$runtimeType');

    if (previousLoading.isFalse) {
      await pagination.previous();
    }
  }
}
