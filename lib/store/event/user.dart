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

import '/api/backend/schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/provider/hive/user.dart';
import '/store/model/user.dart';
import '/ui/page/home/widget/gallery_popup.dart';

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
  galleryItemAdded,
  galleryItemDeleted,
  nameDeleted,
  nameUpdated,
  presenceUpdated,
  statusDeleted,
  statusUpdated,
  userDeleted,
}

/// Tag representing a [UserEvents] kind.
enum UserEventsKind {
  initialized,
  user,
  event,
}

/// [User] event union.
abstract class UserEvents {
  const UserEvents();

  /// [UserEventsKind] of this event.
  UserEventsKind get kind;
}

/// [UserEvent]s along with the corresponding [UserVersion].
class UserEventsVersioned {
  const UserEventsVersioned(this.events, this.ver);

  /// [UserEvent]s themselves.
  final List<UserEvent> events;

  /// Version of the [User]'s state updated by these [UserEvent]s.
  final UserVersion ver;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class UserEventsInitialized extends UserEvents {
  const UserEventsInitialized();

  @override
  UserEventsKind get kind => UserEventsKind.initialized;
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
  const EventUserAvatarDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.avatarDeleted;

  /// [PreciseDateTime] when the [UserAvatar] was deleted.
  final PreciseDateTime at;
}

/// Event of an [UserAvatar] being updated.
class EventUserAvatarUpdated extends UserEvent {
  const EventUserAvatarUpdated(UserId userId, this.avatar, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.avatarUpdated;

  /// New [UserAvatar].
  final UserAvatar avatar;

  /// [PreciseDateTime] when the [UserAvatar] was updated.
  final PreciseDateTime at;
}

/// Event of an [UserBio] being deleted.
class EventUserBioDeleted extends UserEvent {
  const EventUserBioDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.bioDeleted;

  /// [PreciseDateTime] when the [UserBio] was deleted.
  final PreciseDateTime at;
}

/// Event of an [UserBio] being updated.
class EventUserBioUpdated extends UserEvent {
  const EventUserBioUpdated(UserId userId, this.bio, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.bioUpdated;

  /// New [UserBio].
  final UserBio bio;

  /// [PreciseDateTime] when the [UserBio] was updated.
  final PreciseDateTime at;
}

/// Event of an [UserCallCover] being deleted.
class EventUserCallCoverDeleted extends UserEvent {
  const EventUserCallCoverDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.callCoverDeleted;

  /// [PreciseDateTime] when the [UserCallCover] was deleted.
  final PreciseDateTime at;
}

/// Event of an [UserCallCover] being updated.
class EventUserCallCoverUpdated extends UserEvent {
  const EventUserCallCoverUpdated(UserId userId, this.callCover, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.callCoverUpdated;

  /// New [UserCallCover].
  final UserCallCover callCover;

  /// [PreciseDateTime] when the [UserCallCover] was updated.
  final PreciseDateTime at;
}

/// Event of an [User] coming offline.
class EventUserCameOffline extends UserEvent {
  const EventUserCameOffline(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.cameOffline;

  /// [PreciseDateTime] when the [User] was online the last time.
  final PreciseDateTime at;
}

/// Event of an [User] coming offline.
class EventUserCameOnline extends UserEvent {
  const EventUserCameOnline(UserId userId) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.cameOnline;
}

/// Event of an [User] being deleted.
class EventUserDeleted extends UserEvent {
  const EventUserDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.userDeleted;

  /// [PreciseDateTime] when the [User] was deleted.
  final PreciseDateTime at;
}

/// Event of an [UserName] being deleted.
class EventUserNameDeleted extends UserEvent {
  const EventUserNameDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.nameDeleted;

  /// [PreciseDateTime] when the [UserName] was deleted.
  final PreciseDateTime at;
}

/// Event of an [UserName] being updated.
class EventUserNameUpdated extends UserEvent {
  const EventUserNameUpdated(UserId userId, this.name, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.nameUpdated;

  /// New [UserName].
  final UserName name;

  /// [PreciseDateTime] when the [UserName] was updated.
  final PreciseDateTime at;
}

/// Event of an [User]'s `GalleryItem` being added.
class EventUserGalleryItemAdded extends UserEvent {
  const EventUserGalleryItemAdded(UserId userId, this.galleryItem, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.galleryItemAdded;

  /// Added `GalleryItem`.
  final ImageGalleryItem galleryItem;

  /// [PreciseDateTime] when the [GalleryItem] was added to the [User]'s
  /// gallery.
  final PreciseDateTime at;
}

/// Event of an [User]'s `GalleryItem` being deleted.
class EventUserGalleryItemDeleted extends UserEvent {
  const EventUserGalleryItemDeleted(UserId userId, this.galleryItemId, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.galleryItemDeleted;

  /// ID of the deleted `GalleryItem`.
  final GalleryItemId galleryItemId;

  /// [PreciseDateTime] when the [GalleryItem] was deleted from the [User]'s
  /// gallery.
  final PreciseDateTime at;
}

/// Event of an [User]'s [Presence] being updated.
class EventUserPresenceUpdated extends UserEvent {
  const EventUserPresenceUpdated(UserId userId, this.presence, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.presenceUpdated;

  /// New [User]'s [Presence].
  final Presence presence;

  /// [PreciseDateTime] when the [User]'s [Presence] was updated.
  final PreciseDateTime at;
}

/// Event of an [UserTextStatus] being deleted.
class EventUserStatusDeleted extends UserEvent {
  const EventUserStatusDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.statusDeleted;

  /// [PreciseDateTime] when the [UserTextStatus] was deleted.
  final PreciseDateTime at;
}

/// Event of an [UserTextStatus] being updated.
class EventUserStatusUpdated extends UserEvent {
  const EventUserStatusUpdated(UserId userId, this.status, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.statusUpdated;

  /// New [UserTextStatus].
  final UserTextStatus status;

  /// [PreciseDateTime] when the [UserTextStatus] was updated.
  final PreciseDateTime at;
}
