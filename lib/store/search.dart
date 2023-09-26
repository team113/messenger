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

import 'package:get/get.dart';

import '/domain/repository/search.dart';
import '/util/obs/obs.dart';
import 'pagination.dart';

/// Implementation of a [SearchResult].
class SearchResultImpl<K extends Comparable, T, C>
    implements SearchResult<K, T> {
  SearchResultImpl({
    this.pagination,
    List<FutureOr<Map<K, T>>> initial = const [],
  }) {
    final List<Map<K, T>> items = [];
    final List<Future> futures = [];

    for (var f in initial) {
      if (f is Future<Map<K, T>>) {
        futures.add(f..then(this.items.addAll));
      } else {
        items.add(f);
      }
    }

    this.items.value = items.fold({}, (p, e) => p..addAll(e));

    if (pagination != null) {
      _paginationSubscription = pagination!.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
            this.items[event.key!] = event.value as T;
            break;

          case OperationKind.removed:
          case OperationKind.updated:
            // No-op.
            break;
        }
      });

      futures.add(pagination!.around());
    }

    if (futures.isEmpty) {
      status.value = RxStatus.success();
    } else {
      if (items.isNotEmpty) {
        status.value = RxStatus.loadingMore();
      } else {
        status.value = RxStatus.loading();
      }

      Future.wait(futures)
          .whenComplete(() => status.value = RxStatus.success());
    }
  }

  @override
  final RxMap<K, T> items = RxMap<K, T>();

  @override
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Pagination fetching [items].
  final Pagination<T, C, K>? pagination;

  /// [StreamSubscription] to the [Pagination.changes].
  StreamSubscription? _paginationSubscription;

  @override
  RxBool get hasNext => pagination?.hasNext ?? RxBool(false);

  @override
  RxBool get nextLoading => pagination?.nextLoading ?? RxBool(false);

  @override
  void dispose() {
    _paginationSubscription?.cancel();
  }

  @override
  Future<void> next() async {
    if (pagination != null && nextLoading.isFalse) {
      if (status.value.isSuccess) {
        status.value = RxStatus.loadingMore();
      }

      // TODO: Probably shouldn't do that in the store.
      int length = items.length;
      for (int i = 0; i < 10; i++) {
        await pagination!.next();

        if (length != items.length || hasNext.isFalse) {
          break;
        }
      }

      status.value = RxStatus.success();
    }
  }
}
