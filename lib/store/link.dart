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

import 'dart:async';

import 'package:async/async.dart';
import 'package:get/get.dart';

import '/api/backend/extension/link.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/link.dart';
import '/domain/model/user.dart';
import '/domain/repository/link.dart';
import '/domain/repository/paginated.dart';
import '/provider/drift/version.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
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

  /// [GraphQlProvider] used to operate with API in order to create links.
  final GraphQlProvider _graphQlProvider;

  /// [VersionDriftProvider] used to store blocked [User]s list related data.
  final VersionDriftProvider _versionLocal;

  /// [PaginatedImpl]s for [DirectLink] lists sorted by their [_LinkDestination]
  /// keys.
  final Map<
    _LinkDestination,
    PaginatedImpl<DirectLinkSlug, DirectLink, DirectLink, DirectLinksCursor>
  >
  _paginates = {};

  /// [_directLinksRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<DirectLinkEvents>? _remoteSubscription;

  /// [StreamController] for the [updatesFor] listening of
  /// [DirectLink]s updates for [ChatId]s.
  final Map<ChatId, StreamController<void>> _updates = {};

  /// [_directLinksRemoteEvents] of [_updates].
  final Map<ChatId, StreamQueue<DirectLinkEvents>> _subscriptions = {};

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
        perPage: 15,
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
        compare: (a, b) => a.compareTo(b),
      ),
    );
  }

  @override
  Stream<void> updatesFor(ChatId id) {
    final controller = _updates[id] ??= StreamController.broadcast(
      onListen: () async {
        Log.debug('updates($id) -> onListen()', '$runtimeType');
        await _initRemoteSubscription(chatId: id);
      },
      onCancel: () {
        Log.debug('updates($id) -> onCancel()', '$runtimeType');
        _subscriptions.remove(id)?.close(immediate: true);
      },
    );

    return controller.stream;
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
  Future<void> _initRemoteSubscription({ChatId? chatId}) async {
    if (isClosed) {
      return;
    }

    Log.debug('_initRemoteSubscription()', '$runtimeType');

    if (chatId == null) {
      _remoteSubscription?.close(immediate: true);
    } else {
      _subscriptions.remove(chatId)?.close(immediate: true);
    }

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      final StreamQueue<DirectLinkEvents> queue;

      if (chatId == null) {
        queue = _remoteSubscription = StreamQueue(
          _directLinksRemoteEvents(chatId: chatId),
        );
      } else {
        queue = _subscriptions[chatId] = StreamQueue(
          _directLinksRemoteEvents(chatId: chatId),
        );
      }

      await queue.execute(
        _directLinksEvent,
        onError: (e) async {
          if (e is StaleVersionException) {
            // No-op.
          }
        },
      );
    }, tag: 'directLinksEvents($chatId)');

    if (chatId == null) {
      _remoteSubscription?.close(immediate: true);
      _remoteSubscription = null;
    } else {
      _subscriptions.remove(chatId)?.close(immediate: true);
    }
  }

  /// Subscribes to the remote updates of the [links].
  Stream<DirectLinkEvents> _directLinksRemoteEvents({ChatId? chatId}) {
    Log.debug('_directLinksRemoteEvents()', '$runtimeType');

    return _graphQlProvider.directLinksEvents(chatId: chatId).asyncExpand((
      event,
    ) async* {
      Log.trace('_directLinksRemoteEvents(): ${event.data}', '$runtimeType');

      var events = DirectLinksEvents$Subscription.fromJson(
        event.data!,
      ).directLinksEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const DirectLinkEventsInitialized();
      } else if (events.$$typename == 'DirectLinksList') {
        yield DirectLinkEventsList();
      } else if (events.$$typename == 'DirectLinkVersionedEvents') {
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
    Log.trace('_directLinkRemoteEvent($e)', '$runtimeType');

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
              UserId? userId;
              ChatId? chatId;

              final location = event.link.value.location;
              switch (location) {
                case DirectLinkLocationUser user:
                  userId = user.responder;
                  break;

                case DirectLinkLocationGroup group:
                  chatId = group.group;
                  break;
              }

              if (e.key.userId == userId && e.key.chatId == chatId) {
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

  /// [UserId] part of this [_LinkDestination].
  final UserId? userId;

  /// [ChatId] part of this [_LinkDestination].
  final ChatId? chatId;

  @override
  int get hashCode => Object.hash(userId, chatId);

  @override
  bool operator ==(Object other) {
    return other is _LinkDestination &&
        other.userId == userId &&
        other.chatId == chatId;
  }
}
