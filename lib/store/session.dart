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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/my_user.dart';
import '/api/backend/schema.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/repository/session.dart';
import '/domain/service/disposable_service.dart';
import '/provider/drift/account.dart';
import '/provider/drift/geolocation.dart';
import '/provider/drift/session.dart';
import '/provider/drift/version.dart';
import '/provider/geo/geo.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'event/session.dart';
import 'model/session_data.dart';
import 'model/session.dart';

/// [Session]s repository.
class SessionRepository extends IdentityDependency
    implements AbstractSessionRepository {
  SessionRepository(
    this._graphQlProvider,
    this._accountLocal,
    this._versionLocal,
    this._sessionLocal,
    this._geoLocal,
    this._geoProvider, {
    required super.me,
  });

  @override
  final RxList<RxSessionImpl> sessions = RxList();

  @override
  final RxBool connected = RxBool(true);

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// Storage providing the [UserId] of the currently active [MyUser].
  final AccountDriftProvider _accountLocal;

  /// [VersionDriftProvider] used to retrieve the
  /// [SessionData.sessionsListVersion].
  final VersionDriftProvider _versionLocal;

  /// [SessionDriftProvider] of the locally stored [Session]s.
  final SessionDriftProvider _sessionLocal;

  /// [GeoLocationDriftProvider] of the locally stored [IpGeoLocation]s.
  final GeoLocationDriftProvider _geoLocal;

  /// [GeoLocationProvider] fetching the [IpGeoLocation]s.
  final GeoLocationProvider _geoProvider;

  /// [SessionDriftProvider.watch] subscription.
  StreamSubscription? _localSubscription;

  /// [_sessionRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<SessionEventsVersioned>? _remoteSubscription;

  /// [GraphQlProvider.connected] subscription determining the [_hasGraphQl].
  StreamSubscription? _graphQlSubscription;

  /// [Connectivity.onConnectivityChanged] subscription for listening to
  /// [connected] changes.
  StreamSubscription? _connectivitySubscription;

  /// [IpAddress] of this device.
  IpAddress? _ip;

  /// [Mutex]ex guarding the [fetch]ing of the [IpAddress]es.
  final Map<IpAddress?, Mutex> _guards = {};

  /// Language to receive [IpGeoLocation]s on.
  String? _language;

  /// Indicator whether the [Connectivity] package reported that this device has
  /// an active network connection.
  bool _hasNetwork = true;

  /// Indicator whether the [GraphQlProvider] reported that the GraphQL server
  /// isn't down.
  bool _hasGraphQl = true;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    // For popups this store should be used for connectivity check only.
    if (!WebUtils.isPopup) {
      _initLocalSubscription();
      _initRemoteSubscription();
    }

    _initConnectivity();

    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _localSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);
    _connectivitySubscription?.cancel();
    _graphQlSubscription?.cancel();

    super.onClose();
  }

  @override
  void onIdentityChanged(UserId me) {
    super.onIdentityChanged(me);

    Log.debug('onIdentityChanged($me)', '$runtimeType');

    _localSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);

    // For popups this store should be used for connectivity check only.
    if (!me.isLocal && !WebUtils.isPopup) {
      _initLocalSubscription();
      _initRemoteSubscription();
    }
  }

  @override
  Future<IpGeoLocation> fetch({IpAddress? ip}) async {
    Log.debug('fetch(ip: $ip) with $_language', '$runtimeType');

    Mutex? mutex = _guards[ip];
    if (mutex == null) {
      mutex = Mutex();
      _guards[ip] = mutex;
    }

    return await mutex.protect(() async {
      IpAddress? address = ip;

      if (address == null) {
        _ip ??= await _geoProvider.current();
        address = _ip;
      }

      if (address == null) {
        throw Exception('Unreachable');
      }

      final local = await _geoLocal.read(address, language: _language);
      if (local != null) {
        // Consider the persisted result as obsolete, if 30 days has passed
        // since it was persisted.
        if (local.updatedAt.val.difference(DateTime.now()).abs().inDays < 30) {
          return local.value;
        }
      }

      final response = await _geoProvider.get(address, language: _language);
      _geoLocal.upsert(address, response, language: _language);

      return response;
    });
  }

  @override
  Future<void> setLanguage(String? language) async {
    Log.debug('setLanguage($language)', '$runtimeType');

    final bool wasNull = _language == null;
    if (_language != language) {
      _language = language?.split('-').firstOrNull?.split('_').firstOrNull;

      final List<Future> futures = [];
      if (!wasNull) {
        for (var e in sessions) {
          futures.add(e.init());
        }
      }

      await Future.wait(futures);
    }
  }

  /// Initializes [SessionDriftProvider.watch] subscription.
  Future<void> _initLocalSubscription() async {
    if (isClosed) {
      return;
    }

    Log.debug('_initLocalSubscription()', '$runtimeType');

    _localSubscription = _sessionLocal.watch().listen((events) {
      for (var e in events) {
        switch (e.op) {
          case OperationKind.added:
          case OperationKind.updated:
            final existing = sessions.indexWhere((o) => o.id == e.key);
            if (existing == -1) {
              sessions.insert(0, RxSessionImpl(this, e.value!)..init());
            } else {
              sessions[existing].session.value = e.value!;
            }
            sessions.sort();
            sessions.refresh();
            break;

          case OperationKind.removed:
            sessions.removeWhere((s) => s.id == e.key);
            sessions.sort();
            sessions.refresh();
            break;
        }
      }
    });
  }

  /// Initializes [_sessionRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    Log.debug('_initRemoteSubscription()', '$runtimeType');

    _remoteSubscription?.close(immediate: true);

    if (isClosed || me.isLocal) {
      return;
    }

    await WebUtils.protect(() async {
      if (isClosed || me.isLocal) {
        return;
      }

      _remoteSubscription = StreamQueue(
        await _sessionRemoteEvents(
          () => _versionLocal.data[_accountLocal.userId]?.sessionsListVersion,
        ),
      );

      await _remoteSubscription!.execute(
        _sessionRemoteEvent,
        onError: (e) {
          if (e is StaleVersionException) {
            _versionLocal.upsert(
              _accountLocal.userId!,
              sessionsListVersion: NewType(null),
            );
            sessions.clear();
          }
        },
      );
    }, tag: 'sessionsEvents');
  }

  /// Handles [SessionEvent] from the [_sessionRemoteEvents] subscription.
  Future<void> _sessionRemoteEvent(
    SessionEventsVersioned versioned, {
    bool updateVersion = true,
  }) async {
    final listVer =
        _versionLocal.data[_accountLocal.userId]?.sessionsListVersion;
    if (versioned.listVer < listVer) {
      Log.debug(
        '_sessionRemoteEvent(): ignored ${versioned.events.map((e) => e.kind)}',
        '$runtimeType',
      );
      return;
    } else {
      Log.debug(
        '_sessionRemoteEvent(): ${versioned.events.map((e) => e.kind)}',
        '$runtimeType',
      );
    }

    if (_accountLocal.userId != null) {
      _versionLocal.upsert(
        _accountLocal.userId!,
        sessionsListVersion: NewType(versioned.listVer),
      );
    }

    for (final SessionEvent event in versioned.events) {
      switch (event.kind) {
        case SessionEventKind.created:
          event as EventSessionCreated;

          final session = event.toModel();

          _sessionLocal.upsert(session);
          final existing = sessions.indexWhere((e) => e.id == event.id);
          if (existing == -1) {
            sessions.insert(0, RxSessionImpl(this, session)..init());
          } else {
            sessions[existing].session.value = session;
            sessions.sort();
            sessions.refresh();
          }
          break;

        case SessionEventKind.deleted:
          event as EventSessionDeleted;
          _sessionLocal.delete(event.id);
          sessions.removeWhere((e) => e.id == event.id);
          sessions.sort();
          sessions.refresh();
          break;

        case SessionEventKind.refreshed:
          event as EventSessionRefreshed;

          final session = event.toModel();

          _sessionLocal.upsert(session);
          final existing = sessions.indexWhere((e) => e.id == event.id);
          if (existing == -1) {
            sessions.insert(0, RxSessionImpl(this, session)..init());
          } else {
            sessions[existing].session.value = session;
            sessions.sort();
            sessions.refresh();
          }
          break;
      }
    }
  }

  /// Subscribes to remote [SessionEvent]s of the authenticated [MyUser].
  Future<Stream<SessionEventsVersioned>> _sessionRemoteEvents(
    SessionsListVersion? Function() ver,
  ) async {
    Log.debug('_sessionRemoteEvents(ver)', '$runtimeType');

    return (_graphQlProvider.sessionsEvents(ver)).asyncExpand((event) async* {
      Log.trace('_sessionRemoteEvents(ver): ${event.data}', '$runtimeType');

      final events = SessionsEvents$Subscription.fromJson(
        event.data!,
      ).sessionsEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        Log.debug(
          '_sessionRemoteEvents(ver): SubscriptionInitialized',
          '$runtimeType',
        );
      } else if (events.$$typename == 'SessionsList') {
        Log.debug('_sessionRemoteEvents(ver): SessionsList', '$runtimeType');

        final e =
            events as SessionsEvents$Subscription$SessionsEvents$SessionsList;
        final sessions = e.list.map((e) => e.toModel()).toList();

        await _sessionLocal.clear();
        _sessionLocal.upsertBulk(sessions);

        if (_accountLocal.userId != null) {
          _versionLocal.upsert(
            _accountLocal.userId!,
            sessionsListVersion: NewType(e.listVer),
          );
        }

        for (var e in sessions) {
          this.sessions.add(RxSessionImpl(this, e)..init());
        }
        this.sessions.sort();
        this.sessions.refresh();
      } else if (events.$$typename == 'SessionEventsVersioned') {
        var mixin = events as SessionEventsVersionedMixin;
        yield SessionEventsVersioned(
          mixin.events.map((e) => _sessionEvent(e)).toList(),
          mixin.ver,
          mixin.listVer,
        );
      }
    });
  }

  /// Constructs a [SessionEvent] from the [SessionEventsVersionedMixin$Events].
  SessionEvent _sessionEvent(SessionEventsVersionedMixin$Events e) {
    Log.trace('_sessionEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventSessionCreated') {
      final node = e as SessionEventsVersionedMixin$Events$EventSessionCreated;
      return EventSessionCreated(
        e.id,
        e.at,
        node.userAgent,
        node.remembered,
        node.ip,
      );
    } else if (e.$$typename == 'EventSessionDeleted') {
      return EventSessionDeleted(e.id, e.at);
    } else if (e.$$typename == 'EventSessionRefreshed') {
      final node =
          e as SessionEventsVersionedMixin$Events$EventSessionRefreshed;
      return EventSessionRefreshed(e.id, e.at, node.userAgent, node.ip);
    } else {
      throw UnimplementedError('Unknown SessionEvent: ${e.$$typename}');
    }
  }

  /// Initializes the [Connectivity] changing the [connected] status.
  Future<void> _initConnectivity() async {
    _hasGraphQl = _graphQlProvider.connected.value;
    _graphQlSubscription = _graphQlProvider.connected.listen((hasGraphQl) {
      _hasGraphQl = hasGraphQl;
      connected.value = _hasNetwork && _hasGraphQl;

      Log.debug(
        '_graphQlProvider.connected -> $hasGraphQl (${connected.value})',
        '$runtimeType',
      );
    });

    void apply(List<ConnectivityResult> result) {
      _hasNetwork =
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet) ||
          result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.vpn) ||
          result.contains(ConnectivityResult.other);

      connected.value = _hasNetwork && _hasGraphQl;

      Log.debug(
        'Connectivity().onConnectivityChanged -> $result (${connected.value})',
        '$runtimeType',
      );
    }

    try {
      apply(await Connectivity().checkConnectivity());
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
        apply,
      );
    } on MissingPluginException {
      // No-op.
    }
  }
}

/// [RxSession] implementation.
class RxSessionImpl extends RxSession {
  RxSessionImpl(this._repository, Session session, {IpGeoLocation? geo})
    : session = Rx(session),
      geo = Rx(geo);

  @override
  final Rx<Session> session;

  @override
  final Rx<IpGeoLocation?> geo;

  /// [SessionRepository] this [RxSessionImpl] is from.
  final SessionRepository _repository;

  /// Initializes this [RxSessionImpl].
  Future<void> init() async {
    try {
      geo.value = await _repository.fetch(ip: session.value.ip);
    } catch (e) {
      Log.debug(
        'Failed to retrieve IP geolocation information: $e',
        '$runtimeType',
      );
    }
  }
}
