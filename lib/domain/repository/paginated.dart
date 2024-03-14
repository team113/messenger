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

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '/util/obs/obs.dart';

/// Paginated view of [T] items.
abstract class Paginated<K, T> {
  Paginated({this.onDispose});

  /// Paginated [T] items themselves.
  final RxSortedObsMap<K, T> items = RxSortedObsMap<K, T>();

  /// Reactive [RxStatus] of [items] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the query is not yet started.
  /// - `status.isLoading`, meaning the [items] are being fetched.
  /// - `status.isLoadingMore`, meaning some [items] were fetched from local
  ///   storage.
  /// - `status.isSuccess`, meaning the [items] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Callback, called when this [Paginated] is disposed.
  final void Function()? onDispose;

  /// [StreamController] for [updates] of this [Paginated].
  ///
  /// Behaves like a reference counter: when [updates] are listened to, this
  /// invokes [ensureInitialized], and when [updates] aren't listened,
  /// [dispose]s this [Paginated].
  late final StreamController<void> _controller = StreamController.broadcast(
    onListen: ensureInitialized,
    onCancel: dispose,
  );

  /// Indicates whether the [items] have next page.
  RxBool get hasNext;

  /// Indicates whether the [items] have previous page.
  RxBool get hasPrevious;

  /// Indicates whether the [next] page of [items] is being fetched.
  RxBool get nextLoading;

  /// Indicates whether the [previous] page of [items] is being fetched.
  RxBool get previousLoading;

  /// Initializes this [Paginated] while the returned [Stream] is listened and
  /// disposes when canceled.
  Stream<void> get updates => _controller.stream;

  /// Returns the [Iterable] of [T] items kept in [items].
  Iterable<T> get values => items.values;

  /// Returns count of [T] items kept in [items].
  int get length => items.length;

  /// Returns count of [T] items fetched with each page.
  int get perPage;

  /// Ensures this [Paginated] is initialized.
  Future<void> ensureInitialized();

  /// Disposes this [Paginated].
  @mustCallSuper
  @protected
  void dispose() {
    _controller.close();
    onDispose?.call();
  }

  /// Fetches the initial page of the [items].
  Future<void> around() async {
    await ensureInitialized();
  }

  /// Fetches next page of the [items].
  Future<void> next();

  /// Fetches previous page of the [items].
  Future<void> previous();
}
