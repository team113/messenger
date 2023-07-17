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

import '/api/backend/schema.dart' show Presence;
import '/domain/model/avatar.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/provider/hive/user.dart';
import '/store/model/my_user.dart';
import '/store/model/user.dart';
import 'my_user.dart' show BlocklistEvent;

/// Possible kinds of [UserEvent].
enum UserEventKind {
  avatarDeleted,
  avatarUpdated,
  callCoverDeleted,
  callCoverUpdated,
  cameOffline,
  cameOnline,
  nameDeleted,
  nameUpdated,
  presenceUpdated,
  statusDeleted,
  statusUpdated,
  userDeleted,
}

/// Tag representing a [UserEvents] kind.
enum UserEventsKind {
  blocklistEvent,
  initialized,
  isBlocked,
  user,
  event,
}

/// Tag representing a [BlocklistEvent] kind.
enum BlocklistEventsKind {
  recordAdded,
  recordRemoved,
}

/// [User] event union.
abstract class UserEvents {
  const UserEvents();

  /// [UserEventsKind] of this event.
  UserEventsKind get kind;
}

/// [UserEvent]s along with the corresponding [UserVersion].
class UserEventsVersioned extends UserEvents {
  const UserEventsVersioned(this.events, this.ver);

  /// [UserEvent]s themselves.
  final List<UserEvent> events;

  /// Version of the [User]'s state updated by these [UserEvent]s.
  final UserVersion ver;

  @override
  UserEventsKind get kind => UserEventsKind.event;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class UserEventsInitialized extends UserEvents {
  const UserEventsInitialized();

  @override
  UserEventsKind get kind => UserEventsKind.initialized;
}

/// Information about some [User] being present in [MyUser]'s blacklist of the
/// authenticated [MyUser].
class UserEventsIsBlocked extends UserEvents {
  UserEventsIsBlocked(this.record, this.ver);

  /// [BlocklistRecord] of the [User] in blacklist.
  ///
  /// `null` if the [User] is not blacklisted by the authenticated [MyUser].
  final BlocklistRecord? record;

  /// Version of the authenticated [MyUser]'s state.
  final MyUserVersion ver;

  @override
  UserEventsKind get kind => UserEventsKind.isBlocked;
}

/// [BlocklistEventsVersioned] along with the corresponding [MyUserVersion].
class BlocklistEventsVersioned extends UserEvents {
  BlocklistEventsVersioned(this.events, this.ver);

  /// [BlocklistEvent]s themselves.
  final List<BlocklistEvent> events;

  /// Version of the [MyUser]'s state updated by these
  /// [BlocklistEventsVersioned].
  final MyUserVersion ver;

  @override
  UserEventsKind get kind => UserEventsKind.blocklistEvent;
}

class UserEventsBlocklistEventsEvent extends UserEvents {
  const UserEventsBlocklistEventsEvent(this.event);

  /// [UserEventsVersioned] itself.
  final BlocklistEventsVersioned event;

  @override
  UserEventsKind get kind => UserEventsKind.blocklistEvent;
}

/// [UserEventsEvent] happening with the [User].
class UserEventsEvent extends UserEvents {
  const UserEventsEvent(this.event);

  /// [UserEventsVersioned] itself.
  final UserEventsVersioned event;

  @override
  UserEventsKind get kind => UserEventsKind.event;
}

/// Initial state of the [User].
class UserEventsUser extends UserEvents {
  const UserEventsUser(this.user);

  /// Initial state itself.
  final HiveUser user;

  @override
  UserEventsKind get kind => UserEventsKind.user;
}

/// Events happening with an [User].
abstract class UserEvent {
  const UserEvent(this.userId);

  /// ID of the [User] this [UserEvent] is related to.
  final UserId userId;

  /// Returns [UserEventKind] of this [UserEvent].
  UserEventKind get kind;
}

/// Event of an [UserAvatar] being deleted.
class EventUserAvatarDeleted extends UserEvent {
  const EventUserAvatarDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [UserAvatar] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.avatarDeleted;
}

/// Event of an [UserAvatar] being updated.
class EventUserAvatarUpdated extends UserEvent {
  const EventUserAvatarUpdated(super.userId, this.avatar, this.at);

  /// New [UserAvatar].
  final UserAvatar avatar;

  /// [PreciseDateTime] when the [UserAvatar] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.avatarUpdated;
}

/// Event of an [UserCallCover] being deleted.
class EventUserCallCoverDeleted extends UserEvent {
  const EventUserCallCoverDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [UserCallCover] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.callCoverDeleted;
}

/// Event of an [UserCallCover] being updated.
class EventUserCallCoverUpdated extends UserEvent {
  const EventUserCallCoverUpdated(super.userId, this.callCover, this.at);

  /// New [UserCallCover].
  final UserCallCover callCover;

  /// [PreciseDateTime] when the [UserCallCover] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.callCoverUpdated;
}

/// Event of an [User] coming offline.
class EventUserCameOffline extends UserEvent {
  const EventUserCameOffline(super.userId, this.at);

  /// [PreciseDateTime] when the [User] was online the last time.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.cameOffline;
}

/// Event of an [User] coming online.
class EventUserCameOnline extends UserEvent {
  const EventUserCameOnline(super.userId);

  @override
  UserEventKind get kind => UserEventKind.cameOnline;
}

/// Event of an [User] being deleted.
class EventUserDeleted extends UserEvent {
  const EventUserDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [User] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.userDeleted;
}

/// Event of an [UserName] being deleted.
class EventUserNameDeleted extends UserEvent {
  const EventUserNameDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [UserName] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.nameDeleted;
}

/// Event of an [UserName] being updated.
class EventUserNameUpdated extends UserEvent {
  const EventUserNameUpdated(super.userId, this.name, this.at);

  /// New [UserName].
  final UserName name;

  /// [PreciseDateTime] when the [UserName] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.nameUpdated;
}

/// Event of an [User]'s [Presence] being updated.
class EventUserPresenceUpdated extends UserEvent {
  const EventUserPresenceUpdated(super.userId, this.presence, this.at);

  /// New [User]'s [Presence].
  final Presence presence;

  /// [PreciseDateTime] when the [User]'s [Presence] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.presenceUpdated;
}

/// Event of an [UserTextStatus] being deleted.
class EventUserStatusDeleted extends UserEvent {
  const EventUserStatusDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [UserTextStatus] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.statusDeleted;
}

/// Event of an [UserTextStatus] being updated.
class EventUserStatusUpdated extends UserEvent {
  const EventUserStatusUpdated(super.userId, this.status, this.at);

  /// New [UserTextStatus].
  final UserTextStatus status;

  /// [PreciseDateTime] when the [UserTextStatus] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.statusUpdated;
}
