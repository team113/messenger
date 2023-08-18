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

import 'package:hive/hive.dart';

import '/provider/hive/base.dart';
import '/store/pagination.dart';
import 'graphql.dart';
import 'hive.dart';

/// [HivePageProvider] and [GraphQlPageProvider] providers combined.
class HiveGraphQlPageProvider<T, C> implements PageProvider<T, C> {
  HiveGraphQlPageProvider({
    required this.hiveProvider,
    required this.graphQlProvider,
  });

  /// [HivePageProvider] fetching elements from the [Hive].
  final HivePageProvider<T, C> hiveProvider;

  /// [GraphQlPageProvider] fetching elements from the remote.
  final GraphQlPageProvider<T, C> graphQlProvider;

  @override
  FutureOr<Page<T, C>?> around(T? item, C? cursor, int count) async {
    final cached = await hiveProvider.around(item, cursor, count);

    if (cached != null && cached.edges.isNotEmpty) {
      return cached;
    }

    final remote = await graphQlProvider.around(item, cursor, count);
    for (T e in remote.edges) {
      hiveProvider.put(e);
    }

    return remote;
  }

  @override
  FutureOr<Page<T, C>?> after(T? item, C? cursor, int count) async {
    final cached = await hiveProvider.after(item, cursor, count);

    if (cached != null && cached.edges.isNotEmpty) {
      return cached;
    }

    final remote = await graphQlProvider.after(item, cursor, count);
    if (remote != null) {
      for (T e in remote.edges) {
        await hiveProvider.put(e);
      }
    }

    return remote;
  }

  @override
  FutureOr<Page<T, C>?> before(T? item, C? cursor, int count) async {
    final cached = await hiveProvider.before(item, cursor, count);

    if (cached != null && cached.edges.isNotEmpty) {
      return cached;
    }

    final remote = await graphQlProvider.before(item, cursor, count);
    if (remote != null) {
      for (T e in remote.edges) {
        await hiveProvider.put(e);
      }
    }

    return remote;
  }

  @override
  Future<void> put(T item) => hiveProvider.put(item);

  @override
  Future<void> remove(String key) => hiveProvider.remove(key);

  /// Updates the provider in the [hiveProvider] with the provided [provider].
  void updateHiveProvider(HiveLazyProvider provider) =>
      hiveProvider.updateProvider(provider);

  @override
  Future<void> clear() => hiveProvider.clear();
}
