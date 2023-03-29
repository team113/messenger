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
import 'package:hive/hive.dart';

import '/domain/model/chat_item.dart';
import '/provider/hive/base.dart';
import '/provider/hive/chat_item.dart';
import '/store/pagination.dart';
import 'graphql.dart';
import 'hive.dart';

String consoleList<U>(Iterable<U>? items) {
  return '${items?.map((m) {
    if (m is HiveChatMessage) {
      return '${(m.value as ChatMessage).text}';
    }
    return '$m';
  })}';
}

/// Combined [PageProvider] from the [HivePageProvider] and
/// [GraphQlPageProvider].
class HiveGraphQlPageProvider<U, T> implements PageProvider<U, T> {
  HiveGraphQlPageProvider(this._hiveProvider, this._graphQlProvider);

  /// [HivePageProvider] fetching elements from the [Hive].
  final HivePageProvider<U, T> _hiveProvider;

  /// [GraphQlPageProvider] fetching elements from the remote.
  final GraphQlPageProvider<U, T> _graphQlProvider;

  /// Indicator whether [after] is executing.
  bool _afterFetching = false;

  /// Indicator whether [before] is executing.
  bool _beforeFetching = false;

  @override
  FutureOr<Rx<Page<U, T>>> around(U? item, T? cursor, int count) async {
    print('\n[AROUND] Request begun');
    final cached = await _hiveProvider.around(item, cursor, count);
    print(
      '[AROUND] Cached page: [${consoleList(cached.value.edges)}], ${cached.value.info?.startCursor} to ${cached.value.info?.endCursor}, hasPrevious: ${cached.value.info?.hasPrevious}, hasNext: ${cached.value.info?.hasNext}',
    );
    if (cached.value.info != null) {
      if (cached.value.edges.length < count) {
        print('[AROUND] Request ongoing with CACHED response');

        Future(() async {
          final remote = await _graphQlProvider.around(item, cursor, count);
          cached.value.edges = remote.value.edges;
          cached.value.info = remote.value.info;
          cached.refresh();
          print(
            '[AROUND] OFFLOADED Remote page: [${consoleList(remote.value.edges)}], ${remote.value.info?.startCursor} to ${remote.value.info?.endCursor}, hasPrevious: ${remote.value.info?.hasPrevious}, hasNext: ${remote.value.info?.hasNext}',
          );
        });

        return cached;
      } else {
        print('[AROUND] Request done with CACHED response');
        return cached;
      }
    }

    print('[AROUND] Requesting REMOTE...');
    final remote = await _graphQlProvider.around(item, cursor, count);
    print(
      '[AROUND] Remote page: [${consoleList(remote.value.edges)}], ${remote.value.info?.startCursor} to ${remote.value.info?.endCursor}, hasPrevious: ${remote.value.info?.hasPrevious}, hasNext: ${remote.value.info?.hasNext}',
    );

    print('[AROUND] Request done with REMOTE response');
    return remote;
  }

  @override
  FutureOr<Page<U, T>?> after(U? item, T? cursor, int count) async {
    if (_afterFetching) {
      return null;
    }
    print('\n[AFTER] Request begun');
    _afterFetching = true;
    final cached = await _hiveProvider.after(item, cursor, count);
    print(
      '[AFTER] Cached page: [${consoleList(cached?.edges)}], ${cached?.info?.startCursor} to ${cached?.info?.endCursor}, hasPrevious: ${cached?.info?.hasPrevious}, hasNext: ${cached?.info?.hasNext}',
    );
    if (cached?.info != null) {
      print('[AFTER] Request done with CACHED response');
      _afterFetching = false;
      return cached;
    }

    print('[AFTER] Requesting REMOTE...');
    final remote = await _graphQlProvider.after(item, cursor, count);
    print(
      '[AFTER] Remote page: [${consoleList(remote?.edges)}], ${remote?.info?.startCursor} to ${remote?.info?.endCursor}, hasPrevious: ${remote?.info?.hasPrevious}, hasNext: ${remote?.info?.hasNext}',
    );

    print('[AFTER] Request done with REMOTE response');
    _afterFetching = false;
    return remote;
  }

  @override
  FutureOr<Page<U, T>?> before(U? item, T? cursor, int count) async {
    if (_beforeFetching) {
      return null;
    }
    print('\n[BEFORE] Request begun');
    _beforeFetching = true;
    final cached = await _hiveProvider.before(item, cursor, count);
    print(
      '[BEFORE] Cached page: [${consoleList(cached?.edges)}], ${cached?.info?.startCursor} to ${cached?.info?.endCursor}, hasPrevious: ${cached?.info?.hasPrevious}, hasNext: ${cached?.info?.hasNext}',
    );
    if (cached?.info != null) {
      print('[BEFORE] Request done with CACHED response');
      _beforeFetching = false;
      return cached;
    }

    print('[BEFORE] Requesting REMOTE...');
    final remote = await _graphQlProvider.before(item, cursor, count);
    print(
      '[BEFORE] Remote page: [${consoleList(remote?.edges)}], ${remote?.info?.startCursor} to ${remote?.info?.endCursor}, hasPrevious: ${remote?.info?.hasPrevious}, hasNext: ${remote?.info?.hasNext}',
    );

    print('[BEFORE] Request done with REMOTE response');
    _beforeFetching = false;
    return remote;
  }

  /// Updates the provider in the [_hiveProvider] with the provided [provider].
  void updateHiveProvider(HiveLazyProvider provider) {
    _hiveProvider.updateProvider(provider);
  }
}
