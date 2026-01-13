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

import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/provider/drift/user.dart';
import '/store/event/user.dart';
import '/store/user.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'model/user.dart';

/// [RxUser] implementation backed by local [ScopedDriftProvider] storage.
class RxUserImpl extends RxUser {
  RxUserImpl(this._userRepository, this._userLocal, DtoUser dto)
    : user = Rx<User>(dto.value),
      lastSeen = Rx(dto.value.lastSeenAt) {
    // Start the [_lastSeenTimer] right away.
    _runLastSeenTimer();

    final ChatContactId? contactId = user.value.contacts.firstOrNull?.id;
    if (contactId != null) {
      final FutureOr<RxChatContact?> contactOrFuture = _userRepository
          .getContact
          ?.call(contactId);

      if (contactOrFuture is RxChatContact?) {
        contact.value = contactOrFuture;
      } else {
        contactOrFuture.then((v) => contact.value = v);
      }
    }

    // Re-run [_runLastSeenTimer], if [User.lastSeenAt] has been changed.
    PreciseDateTime? at = user.value.lastSeenAt;
    _worker = ever(user, (User user) async {
      if (at != user.lastSeenAt) {
        _runLastSeenTimer();
        at = user.lastSeenAt;
      }

      final ChatContactId? contactId = user.contacts.firstOrNull?.id;
      if (contact.value?.id != contactId) {
        if (contactId != null) {
          final FutureOr<RxChatContact?> contactOrFuture = _userRepository
              .getContact
              ?.call(contactId);

          if (contactOrFuture is RxChatContact?) {
            contact.value = contactOrFuture;
          } else {
            contact.value = await contactOrFuture;
          }
        } else {
          contact.value = null;
        }
      }
    });

    _localSubscription = _userLocal.watch(id).listen((e) {
      if (e != null) {
        user.value = e.value;
      }
    });
  }

  @override
  final Rx<User> user;

  @override
  final Rx<PreciseDateTime?> lastSeen;

  @override
  final Rx<RxChatContact?> contact = Rx(null);

  /// [UserRepository] providing the [UserEvent]s.
  final UserRepository _userRepository;

  /// [User]s local storage.
  final UserDriftProvider _userLocal;

  /// Reactive value of the [RxChat]-dialog with this [RxUser].
  Rx<RxChat?>? _dialog;

  /// [UserRepository.userEvents] subscription.
  StreamQueue<UserEvents>? _remoteSubscription;

  /// [UserDriftProvider.watch] subscription.
  StreamSubscription? _localSubscription;

  /// [StreamController] for [updates] of this [RxUserImpl].
  ///
  /// Behaves like a reference counter: when [updates] are listened to, this
  /// invokes [_initRemoteSubscription], and when [updates] aren't listened,
  /// cancels it.
  late final StreamController<void> _controller = StreamController.broadcast(
    onListen: _initRemoteSubscription,
    onCancel: () {
      _remoteSubscription?.close(immediate: true);
      _remoteSubscription = null;
    },
  );

  /// [Timer] refreshing the [lastSeen] to synchronize its updates.
  Timer? _lastSeenTimer;

  /// [Worker] reacting on [User] changes.
  Worker? _worker;

  /// Indicator whether this [RxUserImpl] has invoked [dispose] or not.
  bool _disposed = false;

  @override
  Rx<RxChat?> get dialog {
    final ChatId dialogId = user.value.dialog;
    if (_dialog == null) {
      final FutureOr<RxChat?> chatOrFuture = _userRepository.getChat?.call(
        dialogId,
      );

      if (chatOrFuture is RxChat?) {
        _dialog = Rx(chatOrFuture);
      } else {
        _dialog = Rx(null);
        chatOrFuture.then((v) => _dialog?.value = v);
      }
    }

    return _dialog!;
  }

  @override
  Stream<void> get updates => _controller.stream;

  /// Returns a [UserId] of the currently authenticated [MyUser].
  UserId get me => _userRepository.me;

  /// Disposes this [RxUserImpl].
  void dispose() {
    Log.debug('dispose()', '$runtimeType($id)');

    _disposed = true;
    _lastSeenTimer?.cancel();
    _worker?.dispose();
    _localSubscription?.cancel();
  }

  /// Initializes [UserRepository.userEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    Log.debug('_initRemoteSubscription()', '$runtimeType($id)');

    _remoteSubscription?.close(immediate: true);

    if (me.isLocal || id.isLocal) {
      return;
    }

    await WebUtils.protect(() async {
      if (_disposed) {
        return;
      }

      _remoteSubscription = StreamQueue(
        await _userRepository.userEvents(
          id,
          () async => (await _userLocal.read(id))?.ver,
        ),
      );
      await _remoteSubscription!.execute(_userEvent);
    }, tag: 'userEvents($id)');
  }

  /// Handles [UserEvents] from the [UserRepository.userEvents] subscription.
  Future<void> _userEvent(UserEvents events) async {
    switch (events.kind) {
      case UserEventsKind.initialized:
        Log.debug('_userEvent(${events.kind})', '$runtimeType($id)');
        break;

      case UserEventsKind.user:
        Log.debug('_userEvent(${events.kind})', '$runtimeType($id)');

        events as UserEventsUser;
        final saved = await _userLocal.read(id);
        if (saved == null || saved.ver <= events.user.ver) {
          await _userLocal.upsert(events.user);
        }
        break;

      case UserEventsKind.event:
        final userEntity = await _userLocal.read(id);
        final versioned = (events as UserEventsEvent).event;
        if (userEntity == null || versioned.ver < userEntity.ver) {
          Log.debug(
            '_userEvent(${events.kind}): ignored ${versioned.events.map((e) => e.kind)} cuz ${versioned.ver} is lower than ${userEntity?.ver}',
            '$runtimeType($id)',
          );
          return;
        }

        Log.debug(
          '_userEvent(${events.kind}): ${versioned.events.map((e) => e.kind)}',
          '$runtimeType($id)',
        );

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

            case UserEventKind.welcomeMessageDeleted:
              userEntity.value.welcomeMessage = null;
              break;

            case UserEventKind.welcomeMessageUpdated:
              event as EventUserWelcomeMessageUpdated;
              userEntity.value.welcomeMessage = WelcomeMessage(
                text: event.text == null
                    ? userEntity.value.welcomeMessage?.text
                    : event.text?.changed,
                attachments: event.attachments == null
                    ? userEntity.value.welcomeMessage?.attachments ?? []
                    : event.attachments?.attachments ?? [],
                at: event.at,
              );
              break;
          }

          _userLocal.upsert(userEntity);
        }
        break;

      case UserEventsKind.blocklistEvent:
        final userEntity = await _userLocal.read(id);
        final versioned = (events as UserEventsBlocklistEventsEvent).event;

        // TODO: Properly account `MyUserVersion` returned.
        if (userEntity != null && userEntity.blockedVer > versioned.ver) {
          break;
        }

        for (var event in versioned.events) {
          _userLocal.upsert(event.user);
        }
        break;

      case UserEventsKind.isBlocked:
        final versioned = events as UserEventsIsBlocked;
        final userEntity = await _userLocal.read(id);

        if (userEntity != null) {
          // TODO: Properly account `MyUserVersion` returned.
          if (userEntity.blockedVer > versioned.ver) {
            break;
          }

          userEntity.value.isBlocked = versioned.record;
          userEntity.blockedVer = versioned.ver;
          _userLocal.upsert(userEntity);
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
    final Duration difference = now
        .difference(user.value.lastSeenAt!.val)
        .abs();

    final Duration delay;
    final Duration period;

    if (difference.inHours < 1) {
      period = const Duration(minutes: 1);
      delay = Duration(
        microseconds:
            Duration.microsecondsPerMinute -
            difference.inMicroseconds % Duration.microsecondsPerMinute,
      );
    } else if (difference.inDays < 1) {
      period = const Duration(hours: 1);
      delay = Duration(
        microseconds:
            Duration.microsecondsPerHour -
            difference.inMicroseconds % Duration.microsecondsPerHour,
      );
    } else {
      period = const Duration(days: 1);
      delay = Duration(
        microseconds:
            Duration.microsecondsPerDay -
            difference.inMicroseconds % Duration.microsecondsPerDay,
      );
    }

    lastSeen.value = user.value.lastSeenAt;
    lastSeen.refresh();

    _lastSeenTimer = Timer(delay, () {
      Log.debug(
        '_runLastSeenTimer(): delay($delay) has passed',
        '$runtimeType($id)',
      );

      lastSeen.value = user.value.lastSeenAt;
      lastSeen.refresh();

      _lastSeenTimer?.cancel();
      _lastSeenTimer = Timer.periodic(period, (timer) {
        Log.debug(
          '_runLastSeenTimer(): period($period) has passed',
          '$runtimeType($id)',
        );

        lastSeen.value = user.value.lastSeenAt;
        lastSeen.refresh();
      });
    });
  }
}
