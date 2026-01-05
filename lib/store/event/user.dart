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

import '/api/backend/schema.dart' show UserPresence;
import '/domain/model/avatar.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/blocklist.dart';
import '/store/model/user.dart';
import 'blocklist.dart';
import 'changed.dart';

/// Possible kinds of [UserEvent].
enum UserEventKind {
  avatarDeleted,
  avatarUpdated,
  bioDeleted,
  bioUpdated,
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
  welcomeMessageDeleted,
  welcomeMessageUpdated,
}

/// Tag representing a [UserEvents] kind.
enum UserEventsKind { blocklistEvent, initialized, isBlocked, user, event }

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

/// Information about some [User] being present in [MyUser]'s blocklist of the
/// authenticated [MyUser].
class UserEventsIsBlocked extends UserEvents {
  UserEventsIsBlocked(this.record, this.ver);

  /// [BlocklistRecord] of the [User] in blocklist.
  ///
  /// `null` if the [User] is not blocked by the authenticated [MyUser].
  final BlocklistRecord? record;

  /// Version of the authenticated [MyUser]'s state.
  final BlocklistVersion ver;

  @override
  UserEventsKind get kind => UserEventsKind.isBlocked;
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
  final DtoUser user;

  @override
  UserEventsKind get kind => UserEventsKind.user;
}

/// Events happening with a [User].
abstract class UserEvent {
  const UserEvent(this.userId);

  /// ID of the [User] this [UserEvent] is related to.
  final UserId userId;

  /// Returns [UserEventKind] of this [UserEvent].
  UserEventKind get kind;
}

/// Event of a [UserAvatar] being deleted.
class EventUserAvatarRemoved extends UserEvent {
  const EventUserAvatarRemoved(super.userId, this.at);

  /// [PreciseDateTime] when the [UserAvatar] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.avatarDeleted;
}

/// Event of a [UserAvatar] being updated.
class EventUserAvatarUpdated extends UserEvent {
  const EventUserAvatarUpdated(super.userId, this.avatar, this.at);

  /// New [UserAvatar].
  final UserAvatar avatar;

  /// [PreciseDateTime] when the [UserAvatar] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.avatarUpdated;
}

/// Event of a [UserBio] being deleted.
class EventUserBioRemoved extends UserEvent {
  const EventUserBioRemoved(super.userId, this.at);

  /// [PreciseDateTime] when the [UserBio] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.bioDeleted;
}

/// Event of a [UserBio] being updated.
class EventUserBioUpdated extends UserEvent {
  const EventUserBioUpdated(super.userId, this.bio, this.at);

  /// New [UserBio].
  final UserBio bio;

  /// [PreciseDateTime] when the [UserBio] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.bioUpdated;
}

/// Event of a [UserCallCover] being deleted.
class EventUserCallCoverRemoved extends UserEvent {
  const EventUserCallCoverRemoved(super.userId, this.at);

  /// [PreciseDateTime] when the [UserCallCover] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.callCoverDeleted;
}

/// Event of a [UserCallCover] being updated.
class EventUserCallCoverUpdated extends UserEvent {
  const EventUserCallCoverUpdated(super.userId, this.callCover, this.at);

  /// New [UserCallCover].
  final UserCallCover callCover;

  /// [PreciseDateTime] when the [UserCallCover] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.callCoverUpdated;
}

/// Event of a [User] coming offline.
class EventUserCameOffline extends UserEvent {
  const EventUserCameOffline(super.userId, this.at);

  /// [PreciseDateTime] when the [User] was online the last time.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.cameOffline;
}

/// Event of a [User] coming online.
class EventUserCameOnline extends UserEvent {
  const EventUserCameOnline(super.userId);

  @override
  UserEventKind get kind => UserEventKind.cameOnline;
}

/// Event of a [User] being deleted.
class EventUserDeleted extends UserEvent {
  const EventUserDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [User] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.userDeleted;
}

/// Event of a [UserName] being deleted.
class EventUserNameRemoved extends UserEvent {
  const EventUserNameRemoved(super.userId, this.at);

  /// [PreciseDateTime] when the [UserName] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.nameDeleted;
}

/// Event of a [UserName] being updated.
class EventUserNameUpdated extends UserEvent {
  const EventUserNameUpdated(super.userId, this.name, this.at);

  /// New [UserName].
  final UserName name;

  /// [PreciseDateTime] when the [UserName] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.nameUpdated;
}

/// Event of a [User]'s [UserPresence] being updated.
class EventUserPresenceUpdated extends UserEvent {
  const EventUserPresenceUpdated(super.userId, this.presence, this.at);

  /// New [User]'s [UserPresence].
  final UserPresence presence;

  /// [PreciseDateTime] when the [User]'s [UserPresence] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.presenceUpdated;
}

/// Event of a [UserTextStatus] being deleted.
class EventUserStatusRemoved extends UserEvent {
  const EventUserStatusRemoved(super.userId, this.at);

  /// [PreciseDateTime] when the [UserTextStatus] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.statusDeleted;
}

/// Event of a [UserTextStatus] being updated.
class EventUserStatusUpdated extends UserEvent {
  const EventUserStatusUpdated(super.userId, this.status, this.at);

  /// New [UserTextStatus].
  final UserTextStatus status;

  /// [PreciseDateTime] when the [UserTextStatus] was updated.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.statusUpdated;
}

/// Event of a [WelcomeMessage] being deleted by its author.
class EventUserWelcomeMessageDeleted extends UserEvent {
  EventUserWelcomeMessageDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [WelcomeMessage] was deleted.
  final PreciseDateTime at;

  @override
  UserEventKind get kind => UserEventKind.welcomeMessageDeleted;

  @override
  bool operator ==(Object other) =>
      other is EventUserWelcomeMessageDeleted && other.at == at;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of a [WelcomeMessage] being updated by its author.
class EventUserWelcomeMessageUpdated extends UserEvent {
  EventUserWelcomeMessageUpdated(
    super.userId,
    this.at,
    this.text,
    this.attachments,
  );

  /// [PreciseDateTime] when the [WelcomeMessage] was updated.
  final PreciseDateTime at;

  /// Edited [WelcomeMessage.text].
  ///
  /// `null` means that the previous [WelcomeMessage.text] remains unchanged.
  final ChangedChatMessageText? text;

  /// Edited [WelcomeMessage.attachments].
  ///
  /// `null` means that the previous [WelcomeMessage.attachments] remain
  /// unchanged.
  final ChangedChatMessageAttachments? attachments;

  @override
  UserEventKind get kind => UserEventKind.welcomeMessageUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserWelcomeMessageUpdated && other.at == at;

  @override
  int get hashCode => kind.hashCode;
}
