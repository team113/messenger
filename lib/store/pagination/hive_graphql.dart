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
class HiveGraphQlPageProvider<U, T> implements PageProvider<U, T> {
  HiveGraphQlPageProvider(this._hiveProvider, this._graphQlProvider);

  /// [HivePageProvider] fetching elements from the [Hive].
  final HivePageProvider<U, T> _hiveProvider;

  /// [GraphQlPageProvider] fetching elements from the remote.
  final GraphQlPageProvider<U, T> _graphQlProvider;

  /// Indicator whether [around] is executing.
  bool _aroundFetching = false;

  /// Indicator whether [after] is executing.
  bool _afterFetching = false;

  /// Indicator whether [before] is executing.
  bool _beforeFetching = false;

  @override
  FutureOr<Page<U, T>?> around(U? item, T? cursor, int count) async {
    if (_aroundFetching) {
      return null;
    }

    _aroundFetching = true;
    final cached = await _hiveProvider.around(item, cursor, count);

    if (cached != null && cached.edges.length >= count) {
      _aroundFetching = false;
      return cached;
    }

    final remote = await _graphQlProvider.around(item, cursor, count);
    await _hiveProvider.put(remote);

    _aroundFetching = false;
    return remote;
  }

  @override
  FutureOr<Page<U, T>?> after(U? item, T? cursor, int count) async {
    if (_afterFetching) {
      return null;
    }

    _afterFetching = true;
    final cached = await _hiveProvider.after(item, cursor, count);

    if (cached != null && cached.edges.length >= count) {
      _afterFetching = false;
      return cached;
    }

    final remote = await _graphQlProvider.after(item, cursor, count);
    if (remote != null) {
      await _hiveProvider.put(remote);
    }

    _afterFetching = false;
    return remote;
  }

  @override
  FutureOr<Page<U, T>?> before(U? item, T? cursor, int count) async {
    if (_beforeFetching) {
      return null;
    }

    _beforeFetching = true;
    final cached = await _hiveProvider.before(item, cursor, count);

    if (cached != null && cached.edges.length >= count) {
      _beforeFetching = false;
      return cached;
    }

    final remote = await _graphQlProvider.before(item, cursor, count);
    if (remote != null) {
      await _hiveProvider.put(remote);
    }

    _beforeFetching = false;
    return remote;
  }

  @override
  Future<void> add(U item) async {
    await _hiveProvider.add(item);
  }

  /// Updates the provider in the [_hiveProvider] with the provided [provider].
  void updateHiveProvider(HiveLazyProvider provider) {
    _hiveProvider.updateProvider(provider);
  }
}
