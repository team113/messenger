import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/domain/model/chat_item.dart';
import '/provider/hive/base.dart';
import '/provider/hive/chat_item.dart';
import '/store/pagination2.dart';
import 'graphql.dart';
import 'hive.dart';

String consoleList<U>(RxList<U>? items) {
  return '${items?.map((m) {
    if (m is HiveChatMessage) {
      return '${(m.value as ChatMessage).text}';
    }
    return '$m';
  })}';
}

class HiveGraphQlPageProvider<U, T> implements PageProvider<U, T> {
  HiveGraphQlPageProvider(this._hiveProvider, this._graphQlProvider);

  /// [HivePageProvider] fetching elements from the [Hive].
  final HivePageProvider<U, T> _hiveProvider;

  /// [GraphQlPageProvider] fetching elements from the remote.
  final GraphQlPageProvider<U, T> _graphQlProvider;

  bool _afterFetching = false;
  bool _beforeFetching = false;
  bool _aroundFetching = false;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    print('\n[AROUND] Request begun');
    _aroundFetching = true;
    final cached = await _hiveProvider.around(item, cursor, count);
    print(
      '[AROUND] Cached page: [${consoleList(cached.edges)}], ${cached.info?.startCursor} to ${cached.info?.endCursor}, hasPrevious: ${cached.info?.hasPrevious}, hasNext: ${cached.info?.hasNext}',
    );
    if (cached.info != null) {
      if (cached.info!.startCursor == null && cached.info!.endCursor == null) {
        print('[AROUND] Request ongoing with CACHED response');

        Future(() async {
          final remote = await _graphQlProvider.around(item, cursor, count);
          cached.edges.value = remote.edges;
          cached.info = remote.info;

          _aroundFetching = false;
          print(
            '[AROUND] OFFLOADED Remote page: [${consoleList(remote.edges)}], ${remote.info?.startCursor} to ${remote.info?.endCursor}, hasPrevious: ${remote.info?.hasPrevious}, hasNext: ${remote.info?.hasNext}',
          );
        });

        return cached;
      } else {
        print('[AROUND] Request done with CACHED response');
        _aroundFetching = false;
        return cached;
      }
    }

    print('[AROUND] Requesting REMOTE...');
    final remote = await _graphQlProvider.around(item, cursor, count);
    print(
      '[AROUND] Remote page: [${consoleList(remote.edges)}], ${remote.info?.startCursor} to ${remote.info?.endCursor}, hasPrevious: ${remote.info?.hasPrevious}, hasNext: ${remote.info?.hasNext}',
    );

    print('[AROUND] Request done with REMOTE response');
    _aroundFetching = false;
    return remote;
  }

  @override
  FutureOr<Page<U, T>?> after(U? item, T? cursor, int count) async {
    if (_afterFetching || _aroundFetching) {
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
    if (_beforeFetching || _aroundFetching) {
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
