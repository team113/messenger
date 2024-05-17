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

import 'package:hive/hive.dart';

import '/provider/hive/base.dart';
import '/store/pagination.dart';
import 'graphql.dart';
import 'hive.dart';

/// [HivePageProvider] and [GraphQlPageProvider] providers combined.
class HiveGraphQlPageProvider<T extends Object, C, K>
    implements PageProvider<T, C, K> {
  const HiveGraphQlPageProvider({
    required this.hiveProvider,
    required this.graphQlProvider,
  });

  /// [HivePageProvider] fetching elements from the [Hive].
  final HivePageProvider<T, C, K> hiveProvider;

  /// [GraphQlPageProvider] fetching elements from the remote.
  final GraphQlPageProvider<T, C, K> graphQlProvider;

  /// Makes the [hiveProvider] to use the provided [HiveLazyProvider].
  set hive(IterableHiveProvider<T, K> provider) =>
      hiveProvider.provider = provider;

  @override
  Future<Page<T, C>> init(K? key, int count) => hiveProvider.init(key, count);

  @override
  Future<Page<T, C>> around(K? key, C? cursor, int count) async {
    final Page<T, C> cached = await hiveProvider.around(key, cursor, count);

    if (cached.edges.length >= count ||
        !cached.info.hasNext ||
        !cached.info.hasPrevious) {
      return cached;
    }

    final Page<T, C> remote = await graphQlProvider.around(key, cursor, count);

    await hiveProvider.put(remote.edges);

    return remote;
  }

  @override
  Future<Page<T, C>> after(K? key, C? cursor, int count) async {
    final Page<T, C>? cached = await hiveProvider.after(key, cursor, count);

    if (cached != null && cached.edges.isNotEmpty) {
      return cached;
    }

    final Page<T, C> remote = await graphQlProvider.after(key, cursor, count);

    await hiveProvider.put(remote.edges);

    return remote;
  }

  @override
  Future<Page<T, C>> before(K? key, C? cursor, int count) async {
    final Page<T, C>? cached = await hiveProvider.before(key, cursor, count);

    if (cached != null && cached.edges.isNotEmpty) {
      return cached;
    }

    final Page<T, C> remote = await graphQlProvider.before(key, cursor, count);

    await hiveProvider.put(remote.edges);

    return remote;
  }

  @override
  Future<void> put(Iterable<T> items, {int Function(T, T)? compare}) =>
      hiveProvider.put(items, compare: compare);

  @override
  Future<void> remove(K key) => hiveProvider.remove(key);

  @override
  Future<void> clear() => hiveProvider.clear();
}
