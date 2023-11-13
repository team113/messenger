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

import 'package:async/async.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/hive/user.dart';
import '/store/event/user.dart';
import '/store/user.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/stream_utils.dart';

/// [RxUser] implementation backed by local [Hive] storage.
class HiveRxUser extends RxUser {
  HiveRxUser(
    this._userRepository,
    this._userLocal,
    HiveUser hiveUser,
  )   : user = Rx<User>(hiveUser.value),
        lastSeen = Rx(hiveUser.value.lastSeenAt) {
    // Start the [_lastSeenTimer] right away.
    _runLastSeenTimer();

    // Re-run [_runLastSeenTimer], if [User.lastSeenAt] has been changed.
    PreciseDateTime? at = user.value.lastSeenAt;
    _worker = ever(user, (User user) {
      if (at != user.lastSeenAt) {
        _runLastSeenTimer();
        at = user.lastSeenAt;
      }
    });
  }

  @override
  final Rx<User> user;

  @override
  final Rx<PreciseDateTime?> lastSeen;

  /// [UserRepository] providing the [UserEvent]s.
  final UserRepository _userRepository;

  /// [User]s local [Hive] storage.
  final UserHiveProvider _userLocal;

  /// Reactive value of the [RxChat]-dialog with this [RxUser].
  final Rx<RxChat?> _dialog = Rx<RxChat?>(null);

  /// [UserRepository.userEvents] subscription.
  ///
  /// May be uninitialized if [_listeners] counter is equal to zero.
  StreamQueue<UserEvents>? _remoteSubscription;

  /// Reference counter for [_remoteSubscription]'s actuality.
  ///
  /// [_remoteSubscription] is up only if this counter is greater than zero.
  int _listeners = 0;

  /// [Timer] refreshing the [lastSeen] to synchronize its updates.
  Timer? _lastSeenTimer;

  /// [Worker] reacting on [User] changes.
  Worker? _worker;

  @override
  Rx<RxChat?> get dialog {
    Log.debug('get dialog', '$runtimeType($id)');

    final ChatId dialogId = user.value.dialog;
    if (_dialog.value == null) {
      _userRepository.getChat?.call(dialogId).then((v) => _dialog.value = v);
    }

    return _dialog;
  }

  /// Disposes this [HiveRxUser].
  void dispose() {
    Log.debug('dispose()', '$runtimeType($id)');

    _lastSeenTimer?.cancel();
    _worker?.dispose();
  }

  @override
  void listenUpdates() {
    Log.debug('listenUpdates()', '$runtimeType($id)');

    if (_listeners++ == 0) {
      _initRemoteSubscription();
    }
  }

  @override
  void stopUpdates() {
    Log.debug('stopUpdates()', '$runtimeType($id)');

    if (--_listeners == 0) {
      _remoteSubscription?.close(immediate: true);
      _remoteSubscription = null;
    }
  }

  /// Initializes [UserRepository.userEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    Log.debug('_initRemoteSubscription()', '$runtimeType($id)');

    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = StreamQueue(
      _userRepository.userEvents(id, () => _userLocal.get(id)?.ver),
    );
    await _remoteSubscription!.execute(_userEvent);
  }

  /// Handles [UserEvents] from the [UserRepository.userEvents] subscription.
  Future<void> _userEvent(UserEvents events) async {
    Log.debug('_userEvent($events)', '$runtimeType($id)');

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

      case UserEventsKind.blocklistEvent:
        var userEntity = _userLocal.get(id);
        var versioned = (events as UserEventsBlocklistEventsEvent).event;

        // TODO: Properly account `MyUserVersion` returned.
        if (userEntity != null && userEntity.blacklistedVer > versioned.ver) {
          break;
        }

        for (var event in versioned.events) {
          _userLocal.put(event.user);
        }
        break;

      case UserEventsKind.isBlocked:
        var versioned = events as UserEventsIsBlocked;
        var userEntity = _userLocal.get(id);

        if (userEntity != null) {
          // TODO: Properly account `MyUserVersion` returned.
          if (userEntity.blacklistedVer > versioned.ver) {
            break;
          }

          userEntity.value.isBlocked = versioned.record;
          userEntity.blacklistedVer = versioned.ver;
          _userLocal.put(userEntity);
        }
        break;
    }
  }

  // TODO: Cover with unit tests.
  /// Starts the [_lastSeenTimer] refreshing the [lastSeen].
  void _runLastSeenTimer() {
    Log.debug('_runLastSeenTimer()', '$runtimeType($id)');

    _lastSeenTimer?.cancel();
    if (user.value.lastSeenAt == null) {
      return;
    }

    final DateTime now = DateTime.now();
    final Duration difference =
        now.difference(user.value.lastSeenAt!.val).abs();

    final Duration delay;
    final Duration period;

    if (difference.inHours < 1) {
      period = const Duration(minutes: 1);
      delay = Duration(
        microseconds: Duration.microsecondsPerMinute -
            difference.inMicroseconds % Duration.microsecondsPerMinute,
      );
    } else if (difference.inDays < 1) {
      period = const Duration(hours: 1);
      delay = Duration(
        microseconds: Duration.microsecondsPerHour -
            difference.inMicroseconds % Duration.microsecondsPerHour,
      );
    } else {
      period = const Duration(days: 1);
      delay = Duration(
        microseconds: Duration.microsecondsPerDay -
            difference.inMicroseconds % Duration.microsecondsPerDay,
      );
    }

    lastSeen.value = user.value.lastSeenAt;
    lastSeen.refresh();

    _lastSeenTimer = Timer(
      delay,
      () {
        lastSeen.value = user.value.lastSeenAt;
        lastSeen.refresh();

        _lastSeenTimer?.cancel();
        _lastSeenTimer = Timer.periodic(
          period,
          (timer) {
            lastSeen.value = user.value.lastSeenAt;
            lastSeen.refresh();
          },
        );
      },
    );
  }
}
