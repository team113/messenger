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

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/provider/hive/user.dart';
import '/provider/gql/exceptions.dart'
    show ResubscriptionRequiredException, StaleVersionException;
import '/store/event/user.dart';
import '/store/user.dart';
import '/util/log.dart';
import '/util/new_type.dart';

/// [RxUser] implementation backed by local [Hive] storage.
class HiveRxUser extends RxUser {
  HiveRxUser(
    this._userRepository,
    this._userLocal,
    HiveUser hiveUser,
  ) : user = Rx<User>(hiveUser.value);

  @override
  final Rx<User> user;

  /// [UserRepository] providing the [UserEvent]s.
  final UserRepository _userRepository;

  /// [User]s local [Hive] storage.
  final UserHiveProvider _userLocal;

  /// [UserRepository.userEvents] subscription.
  ///
  /// May be uninitialized if [_listeners] counter is equal to zero.
  StreamIterator<UserEvents>? _remoteSubscription;

  /// [CancelToken] canceling the remote subscribing, if any.
  final CancelToken _remoteSubscriptionToken = CancelToken();

  /// Reference counter for [_remoteSubscription]'s actuality.
  ///
  /// [_remoteSubscription] is up only if this counter is greater than zero.
  int _listeners = 0;

  @override
  void listenUpdates() {
    if (_listeners++ == 0) {
      _initRemoteSubscription();
    }
  }

  @override
  void stopUpdates() {
    if (--_listeners == 0) {
      _remoteSubscription?.cancel();
      _remoteSubscription = null;
      _remoteSubscriptionToken.cancel();
    }
  }

  /// Initializes [UserRepository.userEvents] subscription.
  Future<void> _initRemoteSubscription({bool noVersion = false}) async {
    var ver = noVersion ? null : _userLocal.get(id)?.ver;
    _remoteSubscription = StreamIterator(
      await _userRepository.userEvents(id, ver, _remoteSubscriptionToken),
    );
    while (await _remoteSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      _initRemoteSubscription();
      return false;
    }).onError<StaleVersionException>((_, __) {
      _initRemoteSubscription(noVersion: true);
      return false;
    }).onError((e, __) {
      Log.print(
        'Unexpected error in user($id) remote subscription: $e',
        'HiveRxUser',
      );
      _initRemoteSubscription();
      return false;
    })) {
      await _userEvent(_remoteSubscription!.current);
    }
  }

  /// Handles [UserEvents] from the [UserRepository.userEvents] subscription.
  Future<void> _userEvent(UserEvents events) async {
    switch (events.kind) {
      case UserEventsKind.initialized:
        // No-op.
        break;

      case UserEventsKind.user:
        events as UserEventsUser;
        var saved = _userLocal.get(id);
        if (saved == null || saved.ver < events.user.ver) {
          await _userLocal.put(events.user);
        }
        break;

      case UserEventsKind.event:
        var userEntity = _userLocal.get(id);
        var versioned = (events as UserEventsEvent).event;
        if (userEntity == null || versioned.ver <= userEntity.ver) {
          return;
        }

        userEntity.ver = versioned.ver;
        for (var event in versioned.events) {
          switch (event.kind) {
            case UserEventKind.avatarDeleted:
              userEntity.value.avatar = null;
              break;

            case UserEventKind.avatarUpdated:
              event as EventUserAvatarUpdated;
              userEntity.value.avatar = event.avatar;
              break;

            case UserEventKind.bioDeleted:
              userEntity.value.bio = null;
              break;

            case UserEventKind.bioUpdated:
              event as EventUserBioUpdated;
              userEntity.value.bio = event.bio;
              break;

            case UserEventKind.cameOffline:
              event as EventUserCameOffline;
              userEntity.value.online = false;
              userEntity.value.lastSeenAt = event.at;
              break;

            case UserEventKind.cameOnline:
              userEntity.value.online = true;
              break;

            case UserEventKind.callCoverDeleted:
              userEntity.value.callCover = null;
              break;

            case UserEventKind.callCoverUpdated:
              event as EventUserCallCoverUpdated;
              userEntity.value.callCover = event.callCover;
              break;

            case UserEventKind.galleryItemAdded:
              event as EventUserGalleryItemAdded;
              userEntity.value.gallery ??= [];
              userEntity.value.gallery?.insert(0, event.galleryItem);
              break;

            case UserEventKind.galleryItemDeleted:
              event as EventUserGalleryItemDeleted;
              userEntity.value.gallery
                  ?.removeWhere((item) => item.id == event.galleryItemId);
              break;

            case UserEventKind.nameDeleted:
              userEntity.value.name = null;
              break;

            case UserEventKind.nameUpdated:
              event as EventUserNameUpdated;
              userEntity.value.name = event.name;
              break;

            case UserEventKind.presenceUpdated:
              event as EventUserPresenceUpdated;
              userEntity.value.presence = event.presence;
              break;

            case UserEventKind.statusDeleted:
              userEntity.value.status = null;
              break;

            case UserEventKind.statusUpdated:
              event as EventUserStatusUpdated;
              userEntity.value.status = event.status;
              break;

            case UserEventKind.userDeleted:
              userEntity.value.isDeleted = true;
              break;
          }

          _userLocal.put(userEntity);
        }
        break;

      case UserEventsKind.blacklistEvent:
        var userEntity = _userLocal.get(id);
        var versioned = (events as UserEventsBlacklistEventsEvent).event;

        // TODO: Properly account `MyUserVersion` returned.
        if (userEntity != null && userEntity.blacklistedVer > versioned.ver) {
          break;
        }

        for (var event in versioned.events) {
          _userLocal.put(event.user);
        }
        break;

      case UserEventsKind.isBlacklisted:
        var versioned = events as UserEventsIsBlacklisted;
        var userEntity = _userLocal.get(id);

        if (userEntity != null) {
          // TODO: Properly account `MyUserVersion` returned.
          if (userEntity.blacklistedVer > versioned.ver) {
            break;
          }

          userEntity.value.isBlacklisted = versioned.blacklisted;
          userEntity.blacklistedVer = versioned.ver;
          _userLocal.put(userEntity);
        }
        break;
    }
  }
}
