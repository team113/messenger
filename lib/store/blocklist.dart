// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:async/async.dart';
import 'package:get/get.dart';

import '/api/backend/extension/my_user.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/blocklist.dart';
import '/domain/repository/user.dart';
import '/domain/service/disposable_service.dart';
import '/provider/drift/blocklist.dart';
import '/provider/drift/version.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'event/blocklist.dart';
import 'model/blocklist.dart';
import 'model/my_user.dart';
import 'paginated.dart';
import 'pagination.dart';
import 'pagination/drift_graphql.dart';
import 'pagination/drift.dart';
import 'pagination/graphql.dart';
import 'user.dart';

typedef BlocklistPaginated =
    RxPaginatedImpl<UserId, RxUser, DtoBlocklistRecord, BlocklistCursor>;

/// [MyUser]'s blocklist repository.
class BlocklistRepository extends IdentityDependency
    implements AbstractBlocklistRepository {
  BlocklistRepository(
    this._graphQlProvider,
    this._blocklistLocal,
    this._userRepository,
    this._sessionLocal, {
    required super.me,
  });

  @override
  final RxInt count = RxInt(0);

  @override
  late final BlocklistPaginated blocklist = BlocklistPaginated(
    pagination: Pagination(
      onKey: (e) => e.userId,
      perPage: 15,
      provider: DriftGraphQlPageProvider(
        driftProvider: DriftPageProvider(
          fetch: ({required after, required before, UserId? around}) async {
            return await _blocklistLocal.records(limit: after + before + 1);
          },
          onKey: (e) => e.value.userId,
          onCursor: (e) => e?.cursor,
          add: (e, {bool toView = true}) async {
            await _blocklistLocal.upsertBulk(e);
          },
          delete: (e) async => await _blocklistLocal.delete(e),
          reset: () async => await _blocklistLocal.clear(),
          isFirst: (_, _) =>
              _sessionLocal.data[me]?.blocklistSynchronized == true &&
              blocklist.rawLength >= (_blocklistCount ?? double.infinity),
          isLast: (_, _) =>
              _sessionLocal.data[me]?.blocklistSynchronized == true &&
              blocklist.rawLength >= (_blocklistCount ?? double.infinity),
          compare: (a, b) => a.value.compareTo(b.value),
        ),
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) async {
            final Page<DtoBlocklistRecord, BlocklistCursor> page =
                await _blocklist(
                  after: after,
                  before: before,
                  first: first,
                  last: last,
                );

            if (page.info.hasNext == false) {
              _sessionLocal.upsert(me, blocklistSynchronized: NewType(true));
            }

            return page;
          },
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    ),
    transform: ({required DtoBlocklistRecord data, RxUser? previous}) {
      return previous ?? _userRepository.get(data.userId);
    },
  );

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Blocked [User]s local storage.
  final BlocklistDriftProvider _blocklistLocal;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepository;

  /// [VersionDriftProvider] used to store blocked [User]s list related data.
  final VersionDriftProvider _sessionLocal;

  /// Total count of blocked users.
  int? _blocklistCount;

  /// [_blocklistRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<BlocklistEvents>? _remoteSubscription;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');
    super.onInit();
  }

  @override
  void onClose() {
    _remoteSubscription?.close(immediate: true);
    super.onClose();
  }

  @override
  void onIdentityChanged(UserId me) {
    super.onIdentityChanged(me);

    Log.debug('onIdentityChanged($me)', '$runtimeType');

    _remoteSubscription?.close(immediate: true);

    if (!me.isLocal) {
      _initRemoteSubscription();
      count.value = _sessionLocal.data[me]?.blocklistCount ?? 0;
    }
  }

  /// Puts the provided [record] to [Pagination] and local storage.
  Future<void> put(DtoBlocklistRecord record, {bool pagination = false}) async {
    Log.debug('put($record, $pagination)', '$runtimeType');
    await blocklist.put(record);
  }

  /// Removes a [User] identified by the provided [userId] from the [blocklist].
  Future<void> remove(UserId userId) {
    Log.debug('remove($userId)', '$runtimeType');
    return blocklist.remove(userId);
  }

  /// Resets this [BlocklistRepository].
  Future<void> reset() async {
    Log.debug('reset()', '$runtimeType');

    await blocklist.clear();
    await blocklist.around();
  }

  /// Fetches blocked [User]s with pagination.
  Future<Page<DtoBlocklistRecord, BlocklistCursor>> _blocklist({
    int? first,
    BlocklistCursor? after,
    int? last,
    BlocklistCursor? before,
  }) async {
    Log.debug('_blocklist($first, $after, $last, $before)', '$runtimeType');

    final query = await _graphQlProvider.getBlocklist(
      first: first,
      after: after,
      last: last,
      before: before,
    );

    final users = RxList(query.edges.map((e) => e.node.user.toDto()).toList());

    // Ensure all [users] are stored in [_userRepository].
    await Future.wait(users.map(_userRepository.put));

    return Page(
      query.edges.map((e) => e.node.toDto(cursor: e.cursor)).toList(),
      query.pageInfo.toModel((c) => BlocklistCursor(c)),
    );
  }

  /// Initializes [_blocklistRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    if (isClosed) {
      return;
    }

    Log.debug('_initRemoteSubscription()', '$runtimeType');

    _remoteSubscription?.close(immediate: true);

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      _remoteSubscription = StreamQueue(
        await _blocklistRemoteEvents(
          () => _sessionLocal.data[me]?.blocklistVersion,
        ),
      );

      await _remoteSubscription!.execute(
        _blocklistRemoteEvent,
        onError: (e) async {
          if (e is StaleVersionException) {
            _sessionLocal.upsert(
              me,
              blocklistSynchronized: NewType(true),
              blocklistVersion: NewType(null),
            );
            await reset();
          }
        },
      );
    }, tag: 'blocklistEvents');
  }

  /// Subscribes to remote [BlocklistEvent]s.
  Future<Stream<BlocklistEvents>> _blocklistRemoteEvents(
    BlocklistVersion? Function() ver,
  ) async {
    Log.debug('_blocklistRemoteEvents(ver)', '$runtimeType');

    return _graphQlProvider.blocklistEvents(ver).asyncExpand((event) async* {
      Log.trace('_blocklistRemoteEvents(ver): ${event.data}', '$runtimeType');

      var events = BlocklistEvents$Subscription.fromJson(
        event.data!,
      ).blocklistEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        Log.debug(
          '_blocklistRemoteEvents(ver): SubscriptionInitialized',
          '$runtimeType',
        );

        events
            as BlocklistEvents$Subscription$BlocklistEvents$SubscriptionInitialized;
        // No-op.
      } else if (events.$$typename == 'Blocklist') {
        var list =
            events as BlocklistEvents$Subscription$BlocklistEvents$Blocklist;
        yield BlocklistEventsBlocklist(
          list.blocklist.edges
              .map(
                (e) => DtoBlocklistRecord(
                  BlocklistRecord(
                    userId: e.node.user.id,
                    reason: e.node.reason,
                    at: e.node.at,
                  ),
                  e.cursor,
                ),
              )
              .toList(),
          list.blocklist.totalCount,
          list.blocklist.ver,
        );
      } else if (events.$$typename == 'BlocklistEventsVersioned') {
        var mixin = events as BlocklistEventsVersionedMixin;
        yield BlocklistEventsEvent(
          BlocklistEventsVersioned(
            mixin.events.map((e) => _blocklistEvent(e)).toList(),
            mixin.blocklistVer,
          ),
        );
      }
    });
  }

  /// Constructs a [BlocklistEvent] from the
  /// [BlocklistEventsVersionedMixin$Events].
  BlocklistEvent _blocklistEvent(BlocklistEventsVersionedMixin$Events e) {
    Log.trace('_blocklistEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventBlocklistRecordAdded') {
      final node =
          e as BlocklistEventsVersionedMixin$Events$EventBlocklistRecordAdded;
      return EventBlocklistRecordAdded(node.user.toDto(), node.at, node.reason);
    } else if (e.$$typename == 'EventBlocklistRecordRemoved') {
      return EventBlocklistRecordRemoved(e.user.toDto(), e.at);
    } else {
      throw UnimplementedError('Unknown BlocklistEvent: ${e.$$typename}');
    }
  }

  /// Handles [BlocklistEvent] from the [_blocklistRemoteEvents] subscription.
  Future<void> _blocklistRemoteEvent(BlocklistEvents events) async {
    switch (events.kind) {
      case BlocklistEventsKind.blocklist:
        final blocklist = events as BlocklistEventsBlocklist;
        count.value = blocklist.totalCount;
        await _sessionLocal.upsert(
          me,
          blocklistCount: NewType(blocklist.totalCount),
          blocklistVersion: NewType(blocklist.ver),
        );
        break;

      case BlocklistEventsKind.event:
        final versioned = (events as BlocklistEventsEvent).event;
        final listVer = _sessionLocal.data[me]?.blocklistVersion;

        if (versioned.ver < listVer) {
          Log.debug(
            '_blocklistRemoteEvent(): ignored ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );
        } else {
          Log.debug(
            '_blocklistRemoteEvent(): ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );

          for (final BlocklistEvent event in versioned.events) {
            switch (event.kind) {
              case BlocklistEventKind.recordAdded:
                event as EventBlocklistRecordAdded;
                ++count.value;
                put(
                  DtoBlocklistRecord(
                    BlocklistRecord(
                      userId: event.user.id,
                      reason: event.reason,
                      at: event.at,
                    ),
                    null,
                  ),
                );
                break;

              case BlocklistEventKind.recordRemoved:
                event as EventBlocklistRecordRemoved;
                --count.value;
                remove(event.user.id);
                break;
            }
          }

          await _sessionLocal.upsert(
            me,
            blocklistCount: NewType(count.value),
            blocklistVersion: NewType(versioned.ver),
          );
        }
        break;
    }
  }
}
