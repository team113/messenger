// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:async/async.dart';
import 'package:get/get.dart';

import '../provider/drift/version.dart';
import '../provider/gql/exceptions.dart';
import '../util/new_type.dart';
import '../util/stream_utils.dart';
import '../util/web/web_utils.dart';
import '/api/backend/extension/link.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/link.dart';
import '/domain/model/user.dart';
import '/domain/repository/link.dart';
import '/domain/repository/paginated.dart';
import '/provider/gql/graphql.dart';
import '/util/log.dart';
import 'event/link.dart';
import 'model/link.dart';
import 'model/page_info.dart';
import 'paginated.dart';
import 'pagination.dart';
import 'pagination/graphql.dart';

/// [DirectLink] repository.
class LinkRepository extends DisposableInterface
    implements AbstractLinkRepository {
  LinkRepository(this._graphQlProvider, this._versionLocal, {required this.me});

  /// [UserId] of the currently authenticated [MyUser] this repository is bound
  /// to.
  final UserId me;

  final GraphQlProvider _graphQlProvider;

  /// [VersionDriftProvider] used to store blocked [User]s list related data.
  final VersionDriftProvider _versionLocal;

  final Map<
    _LinkDestination,
    PaginatedImpl<DirectLinkSlug, DirectLink, DirectLink, DirectLinksCursor>
  >
  _paginates = {};

  /// [_myUserRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<DirectLinkEvents>? _remoteSubscription;

  @override
  void onInit() {
    Log.debug('onInit', '$runtimeType');

    _initRemoteSubscription();

    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose', '$runtimeType');

    _remoteSubscription?.close();

    for (var e in _paginates.values) {
      e.dispose();
    }
    _paginates.clear();

    super.onClose();
  }

  @override
  Paginated<DirectLinkSlug, DirectLink> links({
    UserId? userId,
    ChatId? chatId,
  }) {
    final identifier = _LinkDestination(userId: userId, chatId: chatId);

    final existing = _paginates[identifier];
    if (existing != null) {
      return existing;
    }

    return _paginates[identifier] = PaginatedImpl(
      pagination: Pagination<DirectLink, DirectLinksCursor, DirectLinkSlug>(
        provider: GraphQlPageProvider(
          fetch:
              ({
                int? first,
                int? last,
                DirectLinksCursor? before,
                DirectLinksCursor? after,
              }) async {
                if (chatId?.isLocal == true) {
                  return Page([], PageInfo());
                }

                final query = await _graphQlProvider.directLinks(
                  chatId: chatId,
                  by: userId == null
                      ? null
                      : DirectLinksFilter(
                          location: DirectLinkLocationInput(userId: userId),
                        ),
                  pagination: DirectLinksPagination(
                    first: first,
                    after: after,
                    last: last,
                    before: before,
                  ),
                );

                return Page(
                  query.edges
                      .map((e) => e.node.toDto(cursor: e.cursor))
                      .map((e) => e.value)
                      .toList(),
                  query.pageInfo.toModel(DirectLinksCursor.new),
                );
              },
        ),
        onKey: (e) => e.slug,
      ),
    );
  }

  @override
  Future<void> updateLink(DirectLinkSlug slug, UserId? userId) async {
    final mixin = await _graphQlProvider.updateDirectLink(
      slug,
      userId == null ? null : DirectLinkLocationInput(userId: userId),
    );

    if (mixin != null) {
      final DirectLinkEventsEvent events = DirectLinkEventsEvent(
        DirectLinkEventsVersioned(
          mixin.events.map(_directLinkRemoteEvent).toList(),
          mixin.ver,
        ),
      );

      await _directLinksEvent(events);
    }
  }

  @override
  Future<void> updateGroupLink(ChatId groupId, DirectLinkSlug? slug) async {
    final mixin = await _graphQlProvider.updateGroupDirectLink(groupId, slug);

    if (mixin != null) {
      final DirectLinkEventsEvent events = DirectLinkEventsEvent(
        DirectLinkEventsVersioned(
          mixin.events.map(_directLinkRemoteEvent).toList(),
          mixin.ver,
        ),
      );

      await _directLinksEvent(events);
    }
  }

  /// Initializes [_directLinksRemoteEvents] subscription.
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

      _remoteSubscription = StreamQueue(_directLinksRemoteEvents());

      await _remoteSubscription!.execute(
        _directLinksEvent,
        onError: (e) async {
          if (e is StaleVersionException) {
            // await clear();
            // await _pagination?.around(cursor: _lastReadItemCursor);
          }
        },
      );
    }, tag: 'directLinksEvents()');

    _remoteSubscription = null;
  }

  /// Subscribes to the remote updates of the [links].
  Stream<DirectLinkEvents> _directLinksRemoteEvents({ChatId? chatId}) {
    Log.debug('_directLinksRemoteEvents()', '$runtimeType');

    return _graphQlProvider.directLinksEvents(chatId: chatId).asyncExpand((
      event,
    ) async* {
      Log.trace('_directLinksRemoteEvents(): ${event.data}', '$runtimeType');

      var events = RecentChatsTopEvents$Subscription.fromJson(
        event.data!,
      ).recentChatsTopEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const DirectLinkEventsInitialized();
      } else if (events.$$typename == 'DirectLinkEventsList') {
        yield DirectLinkEventsList();
      } else if (events.$$typename == 'RecentChatsTopChatRemovedEvent') {
        final mixin =
            events
                as DirectLinksEvents$Subscription$DirectLinksEvents$DirectLinkVersionedEvents;
        yield DirectLinkEventsEvent(
          DirectLinkEventsVersioned(
            mixin.events.map(_directLinkRemoteEvent).toList(),
            mixin.ver,
          ),
        );
      }
    });
  }

  /// Constructs a [DirectLinkEvent] from the
  /// [DirectLinkVersionedEventsMixin$Events].
  DirectLinkEvent _directLinkRemoteEvent(
    DirectLinkVersionedEventsMixin$Events e,
  ) {
    Log.trace('chatEvent($e)', '$runtimeType');

    if (e.$$typename == 'DirectLinkCreatedEvent') {
      return DirectLinkCreatedEvent(
        e.slug,
        e.link.node.toDto(cursor: e.link.cursor),
        e.at,
      );
    } else if (e.$$typename == 'DirectLinkDisabledEvent') {
      return DirectLinkDisabledEvent(
        e.slug,
        e.link.node.toDto(cursor: e.link.cursor),
        e.at,
      );
    } else if (e.$$typename == 'DirectLinkEnabledEvent') {
      return DirectLinkEnabledEvent(
        e.slug,
        e.link.node.toDto(cursor: e.link.cursor),
        e.at,
      );
    } else if (e.$$typename == 'DirectLinkLocationUpdatedEvent') {
      return DirectLinkLocationUpdatedEvent(
        e.slug,
        e.link.node.toDto(cursor: e.link.cursor),
        e.at,
      );
    } else if (e.$$typename == 'DirectLinkStatsUpdatedEvent') {
      return DirectLinkStatsUpdatedEvent(
        e.slug,
        e.link.node.toDto(cursor: e.link.cursor),
        e.at,
      );
    } else {
      throw UnimplementedError('Unknown ChatEvent: ${e.$$typename}');
    }
  }

  /// Handles [DirectLinkEvents] from the [_directLinksRemoteEvents]
  /// subscription.
  Future<void> _directLinksEvent(
    DirectLinkEvents events, {
    bool updateVersion = true,
  }) async {
    switch (events.kind) {
      case DirectLinkEventsKind.initialized:
        Log.debug('_directLinksEvent(): initialized', '$runtimeType');
        break;

      case DirectLinkEventsKind.list:
        events as DirectLinkEventsList;
        Log.debug('_directLinksEvent(): list', '$runtimeType');
        break;

      case DirectLinkEventsKind.event:
        final versioned = (events as DirectLinkEventsEvent).event;
        final listVer = _versionLocal.data[me]?.directLinksListVersion;

        if (versioned.ver < listVer) {
          Log.debug(
            '_directLinksEvent(): ignored ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );
        } else {
          Log.debug(
            '_directLinksEvent(): ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );

          for (final DirectLinkEvent event in versioned.events) {
            for (var e in _paginates.entries) {
              if (e.key.userId == me && e.key.chatId == null) {
                await e.value.pagination?.put(
                  event.link.value,
                  ignoreBounds: true,
                );
              }
            }
          }

          if (updateVersion) {
            await _versionLocal.upsert(
              me,
              directLinksListVersion: NewType(versioned.ver),
            );
          }
        }
        break;
    }
  }
}

/// [UserId] and a [ChatId] used as a possible destination of a [DirectLink].
class _LinkDestination {
  _LinkDestination({this.userId, this.chatId});

  final UserId? userId;
  final ChatId? chatId;
}
