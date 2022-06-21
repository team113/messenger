import '/api/backend/schema.dart';
import '/domain/model/avatar.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model/user.dart';
import '/store/model/user.dart';

/// Possible kinds of [MyUserEvent].
enum UserEventKind {
  avatarDeleted,
  avatarUpdated,
  bioDeleted,
  bioUpdated,
  cameOffline,
  cameOnline,
  callCoverDeleted,
  callCoverUpdated,
  galleryItemAdded,
  galleryItemDeleted,
  nameDeleted,
  nameUpdated,
  presenceUpdated,
  statusDeleted,
  statusUpdated,
  userDeleted,
}

/// [UserEvent]s along with the corresponding [UserVersion].
class UserEventsVersioned {
  const UserEventsVersioned(this.events, this.ver);

  /// [UserEvent]s itself.
  final List<UserEvent> events;

  /// Version of the [User]'s state updated by this [UserEvent].
  final UserVersion ver;
}

/// Events happening with [User].
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

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [UserAvatar] being updated.
class EventUserAvatarUpdated extends UserEvent {
  const EventUserAvatarUpdated(UserId userId, this.avatar, this.at)
      : super(userId);

  @override
  UserEventKind get kind => UserEventKind.avatarUpdated;

  final UserAvatar avatar;

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [UserBio] being deleted.
class EventUserBioDeleted extends UserEvent {
  const EventUserBioDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.bioDeleted;

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [UserBio] being updated.
class EventUserBioUpdated extends UserEvent {
  const EventUserBioUpdated(UserId userId, this.bio, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.bioUpdated;

  final UserBio bio;

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [UserCallCover] being deleted.
class EventUserCallCoverDeleted extends UserEvent {
  const EventUserCallCoverDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.callCoverDeleted;

  /// [PreciseDateTime] when this event happened.
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

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [User] coming offline.
class EventUserCameOffline extends UserEvent {
  const EventUserCameOffline(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.cameOffline;

  /// [PreciseDateTime] when this event happened.
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
  const EventUserDeleted(UserId userId) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.userDeleted;
}

/// Event of an [UserName] being deleted.
class EventUserNameDeleted extends UserEvent {
  const EventUserNameDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.nameDeleted;

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [UserName] being updated.
class EventUserNameUpdated extends UserEvent {
  const EventUserNameUpdated(UserId userId, this.name, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.nameUpdated;

  /// New [UserName].
  final UserName name;

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

// TODO: Provide `GalleryItem`
/// Event of an [User]'s `GalleryItem` being added.
class EventUserGalleryItemAdded extends UserEvent {
  const EventUserGalleryItemAdded(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.galleryItemAdded;

  /// [PreciseDateTime] when this event happened.
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

  /// [PreciseDateTime] when this event happened.
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

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}

/// Event of an [UserTextStatus] being deleted.
class EventUserStatusDeleted extends UserEvent {
  const EventUserStatusDeleted(UserId userId, this.at) : super(userId);

  @override
  UserEventKind get kind => UserEventKind.statusDeleted;

  /// [PreciseDateTime] when this event happened.
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

  /// [PreciseDateTime] when this event happened.
  final PreciseDateTime at;
}
