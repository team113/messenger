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

import 'package:get/get.dart';

/// Result of a search query.
abstract class SearchResult<K extends Comparable, T> {
  /// Found [T] items themselves.
  final RxMap<K, T> items = RxMap<K, T>();

  /// Reactive [RxStatus] of [items] being fetched.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning the query is not yet started.
  /// - `status.isLoading`, meaning the [items] are being fetched.
  /// - `status.isLoadingMore`, meaning some [items] were fetched from local
  ///   storage.
  /// - `status.isSuccess`, meaning the [items] were successfully fetched.
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// Indicator whether the [items] have next page.
  RxBool get hasNext;

  /// Indicator whether the [next] page of [items] is being fetched.
  RxBool get nextLoading;

  /// Disposes this [SearchResult].
  void dispose();

  /// Fetches next page of the [items].
  Future<void> next();
}
