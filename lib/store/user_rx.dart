// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/provider/hive/user.dart';
import '/provider/gql/exceptions.dart';
import '/store/event/user.dart';
import '/store/model/user.dart';
import '/store/user.dart';
import '/util/new_type.dart';

/// [RxUser] implementation backed by local [Hive] storage.
class HiveRxUser implements RxUser {
  HiveRxUser(HiveUser hiveUser, this._userRepository, this._local)
      : user = Rx<User>(hiveUser.value);

  /// [UserRepository] that provides [UserEvent] sterem.
  final UserRepository _userRepository;

  /// [UserHiveProvider] uses for saving [HiveUser] in [Hive] storage.
  final UserHiveProvider _local;

  @override
  final Rx<User> user;

  @override
  Stream get updates => _updatesController.stream;

  /// [StreamController] that initializes remote subscription for user events or
  /// cancels it if there are no listeners.
  late final StreamController _updatesController =
      StreamController.broadcast(onListen: () {
    _initRemoteSubscription();
  }, onCancel: () {
    _remoteSubscription?.cancel();
  });

  StreamIterator<UserEventsVersioned>? _remoteSubscription;

  /// Listen to remote [Stream] of [UserEventsVersioned].
  Future<void> _initRemoteSubscription({UserVersion? ver}) async {
    var userEntity = _local.get(user.value.id);
    _remoteSubscription = StreamIterator(
        await _userRepository.userEvents(user.value.id, userEntity?.ver));
    while (await _remoteSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      Future.delayed(Duration.zero, () => _initRemoteSubscription(ver: ver));
      return false;
    }).onError<StaleVersionException>((_, __) {
      _local
          .deleteSafe(userEntity?.key)
          .then((_) async => await _initRemoteSubscription());
      return false;
    })) {
      await _userEvent(_remoteSubscription!.current);
    }
  }

  /// Event handler for [_remoteSubscription].
  Future<void> _userEvent(UserEventsVersioned versioned) async {
    var userEntity = _local.get(user.value.id);

    if (userEntity == null || versioned.ver <= userEntity.ver) {
      return;
    }

    userEntity.ver = versioned.ver;
    for (var event in versioned.events) {
      switch (event.kind) {
        case UserEventKind.avatarDeleted:
          event as EventUserAvatarDeleted;
          userEntity.value.avatar = null;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.avatarUpdated:
          event as EventUserAvatarUpdated;
          userEntity.value.avatar = event.avatar;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.bioDeleted:
          event as EventUserBioDeleted;
          userEntity.value.bio = null;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.bioUpdated:
          event as EventUserBioUpdated;
          userEntity.value.bio = event.bio;
          userEntity.value.lastSeenAt = event.at;
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
          event as EventUserCallCoverDeleted;
          userEntity.value.callCover = null;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.callCoverUpdated:
          event as EventUserCallCoverUpdated;
          userEntity.value.callCover = event.callCover;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.galleryItemAdded:
          // TODO: Handle this case.
          break;
        case UserEventKind.galleryItemDeleted:
          // TODO: Handle this case.
          break;
        case UserEventKind.nameDeleted:
          event as EventUserNameDeleted;
          userEntity.value.name = null;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.nameUpdated:
          event as EventUserNameUpdated;
          userEntity.value.name = event.name;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.presenceUpdated:
          // TODO: Handle this case.
          break;
        case UserEventKind.statusDeleted:
          event as EventUserStatusDeleted;
          userEntity.value.status = null;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.statusUpdated:
          event as EventUserStatusUpdated;
          userEntity.value.status = event.status;
          userEntity.value.lastSeenAt = event.at;
          break;
        case UserEventKind.userDeleted:
          // TODO: Handle this case.
          break;
      }
      _local.put(userEntity);
    }
  }
}
