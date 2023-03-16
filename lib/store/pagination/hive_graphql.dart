import 'dart:async';

import 'package:get/get.dart';

import '/domain/model/chat_item.dart';
import '/provider/hive/chat_item.dart';
import '/store/pagination2.dart';
import 'graphql.dart';
import 'hive.dart';

String consoleList<U>(RxList<U> items) {
  return '${items.map((m) {
    if (m is HiveChatMessage) {
      return '${(m.value as ChatMessage).text}';
    }
    return '$m';
  })}';
}

class HiveGraphQlPageProvider<U, T, K> implements PageProvider<U, T> {
  HiveGraphQlPageProvider(this._hiveProvider, this._graphQlProvider);

  final HivePageProvider<U, T> _hiveProvider;
  final GraphQlPageProvider<U, T, K> _graphQlProvider;

  @override
  FutureOr<Page<U, T>> around(U? item, T? cursor, int count) async {
    print('\n[AROUND] Request begun');
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

          await _hiveProvider.put(remote);
          print(
            '[AROUND] OFFLOADED Remote page: [${consoleList(remote.edges)}], ${remote.info?.startCursor} to ${remote.info?.endCursor}, hasPrevious: ${remote.info?.hasPrevious}, hasNext: ${remote.info?.hasNext}',
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
    await _hiveProvider.put(remote);
    print(
      '[AROUND] Remote page: [${consoleList(remote.edges)}], ${remote.info?.startCursor} to ${remote.info?.endCursor}, hasPrevious: ${remote.info?.hasPrevious}, hasNext: ${remote.info?.hasNext}',
    );

    print('[AROUND] Request done with REMOTE response');
    return remote;
  }

  @override
  FutureOr<Page<U, T>> after(Page<U, T> page, int count) async {
    print('\n[AFTER] Request begun');
    final cached = await _hiveProvider.after(page, count);
    print(
      '[AFTER] Cached page: [${consoleList(cached.edges)}], ${cached.info?.startCursor} to ${cached.info?.endCursor}, hasPrevious: ${cached.info?.hasPrevious}, hasNext: ${cached.info?.hasNext}',
    );
    if (cached.info != null) {
      print('[AFTER] Request done with CACHED response');
      return cached;
    }

    print('[AFTER] Requesting REMOTE...');
    final remote = await _graphQlProvider.after(page, count);
    await _hiveProvider.put(remote);
    print(
      '[AFTER] Remote page: [${consoleList(remote.edges)}], ${remote.info?.startCursor} to ${remote.info?.endCursor}, hasPrevious: ${remote.info?.hasPrevious}, hasNext: ${remote.info?.hasNext}',
    );

    print('[AFTER] Request done with REMOTE response');
    return remote;
  }

  @override
  FutureOr<Page<U, T>> before(Page<U, T> page, int count) async {
    print('\n[BEFORE] Request begun');
    final cached = await _hiveProvider.before(page, count);
    print(
      '[BEFORE] Cached page: [${consoleList(cached.edges)}], ${cached.info?.startCursor} to ${cached.info?.endCursor}, hasPrevious: ${cached.info?.hasPrevious}, hasNext: ${cached.info?.hasNext}',
    );
    if (cached.info != null) {
      print('[BEFORE] Request done with CACHED response');
      return cached;
    }

    print('[BEFORE] Requesting REMOTE...');
    final remote = await _graphQlProvider.before(page, count);
    await _hiveProvider.put(remote);
    print(
      '[BEFORE] Remote page: [${consoleList(remote.edges)}], ${remote.info?.startCursor} to ${remote.info?.endCursor}, hasPrevious: ${remote.info?.hasPrevious}, hasNext: ${remote.info?.hasNext}',
    );

    print('[BEFORE] Request done with REMOTE response');
    return remote;
  }
}
