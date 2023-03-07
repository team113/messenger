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

import '../model/my_user.dart';
import '/api/backend/schema.dart' show Presence;
import '/domain/model/avatar.dart';
import '/domain/model/gallery_item.dart';
import '/domain/model/image_gallery_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/provider/hive/user.dart';

/// Possible kinds of [MyUserEvent].
enum MyUserEventKind {
  avatarDeleted,
  avatarUpdated,
  bioDeleted,
  bioUpdated,
  blacklistRecordAdded,
  blacklistRecordRemoved,
  callCoverDeleted,
  callCoverUpdated,
  cameOffline,
  cameOnline,
  deleted,
  directLinkDeleted,
  directLinkUpdated,
  emailAdded,
  emailConfirmed,
  emailDeleted,
  galleryItemAdded,
  galleryItemDeleted,
  loginUpdated,
  nameDeleted,
  nameUpdated,
  passwordUpdated,
  phoneAdded,
  phoneConfirmed,
  phoneDeleted,
  presenceUpdated,
  statusDeleted,
  statusUpdated,
  unmuted,
  unreadChatsCountUpdated,
  userMuted,
}

/// [MyUserEvent]s along with the corresponding [MyUserVersion].
class MyUserEventsVersioned {
  const MyUserEventsVersioned(this.events, this.ver);

  /// [MyUserEvent]s itself.
  final List<MyUserEvent> events;

  /// Version of the [MyUser]'s state updated by this [MyUserEvent].
  final MyUserVersion ver;
}

/// Events happening with [MyUser].
abstract class MyUserEvent {
  const MyUserEvent(this.userId);

  /// ID of the [MyUser] this [MyUserEvent] is related to.
  final UserId userId;

  /// Returns [MyUserEventKind] of this [MyUserEvent].
  MyUserEventKind get kind;
}

/// Event of an [UserAvatar] being deleted.
class EventUserAvatarDeleted extends MyUserEvent {
  const EventUserAvatarDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.avatarDeleted;
}

/// Event of an [UserAvatar] being updated.
class EventUserAvatarUpdated extends MyUserEvent {
  const EventUserAvatarUpdated(UserId userId, this.avatar) : super(userId);

  /// New [UserAvatar].
  final UserAvatar avatar;

  @override
  MyUserEventKind get kind => MyUserEventKind.avatarUpdated;
}

/// Event of an [UserBio] being deleted.
class EventUserBioDeleted extends MyUserEvent {
  const EventUserBioDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.bioDeleted;
}

/// Event of an [UserBio] being updated.
class EventUserBioUpdated extends MyUserEvent {
  const EventUserBioUpdated(UserId userId, this.bio) : super(userId);

  /// New [UserBio].
  final UserBio bio;

  @override
  MyUserEventKind get kind => MyUserEventKind.bioUpdated;
}

/// Event of an [UserCallCover] being deleted.
class EventUserCallCoverDeleted extends MyUserEvent {
  const EventUserCallCoverDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.callCoverDeleted;
}

/// Event of an [UserCallCover] being updated.
class EventUserCallCoverUpdated extends MyUserEvent {
  const EventUserCallCoverUpdated(UserId userId, this.callCover)
      : super(userId);

  /// New [UserCallCover].
  final UserCallCover callCover;

  @override
  MyUserEventKind get kind => MyUserEventKind.callCoverUpdated;
}

/// Event of an [MyUser] coming offline.
class EventUserCameOffline extends MyUserEvent {
  const EventUserCameOffline(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.cameOffline;
}

/// Event of an [MyUser] coming online.
class EventUserCameOnline extends MyUserEvent {
  const EventUserCameOnline(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.cameOnline;
}

/// Event of an [MyUser] being deleted.
class EventUserDeleted extends MyUserEvent {
  const EventUserDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.deleted;
}

/// Event of an [MyUser]'s [ChatDirectLink] being deleted.
class EventUserDirectLinkDeleted extends MyUserEvent {
  EventUserDirectLinkDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.directLinkDeleted;
}

/// Event of an [MyUser]'s [ChatDirectLink] being updated.
class EventUserDirectLinkUpdated extends MyUserEvent {
  const EventUserDirectLinkUpdated(UserId userId, this.directLink)
      : super(userId);

  /// New [User]'s [ChatDirectLink].
  final ChatDirectLink directLink;

  @override
  MyUserEventKind get kind => MyUserEventKind.directLinkUpdated;
}

/// Event of an [MyUser]'s [UserEmail] address being added.
class EventUserEmailAdded extends MyUserEvent {
  const EventUserEmailAdded(UserId userId, this.email) : super(userId);

  /// Added [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailAdded;
}

/// Event of an [MyUser]'s email address being confirmed.
class EventUserEmailConfirmed extends MyUserEvent {
  const EventUserEmailConfirmed(UserId userId, this.email) : super(userId);

  /// Confirmed [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailConfirmed;
}

/// Event of an [MyUser]'s [UserEmail] address being deleted.
class EventUserEmailDeleted extends MyUserEvent {
  const EventUserEmailDeleted(UserId userId, this.email) : super(userId);

  /// Deleted [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailDeleted;
}

/// Event of an [MyUser]'s `GalleryItem` being added.
class EventUserGalleryItemAdded extends MyUserEvent {
  const EventUserGalleryItemAdded(UserId userId, this.galleryItem)
      : super(userId);

  /// Added `GalleryItem`.
  final ImageGalleryItem galleryItem;

  @override
  MyUserEventKind get kind => MyUserEventKind.galleryItemAdded;
}

/// Event of an [MyUser]'s `GalleryItem` being deleted.
class EventUserGalleryItemDeleted extends MyUserEvent {
  const EventUserGalleryItemDeleted(UserId userId, this.galleryItemId)
      : super(userId);

  /// ID of the deleted `GalleryItem`.
  final GalleryItemId galleryItemId;

  @override
  MyUserEventKind get kind => MyUserEventKind.galleryItemDeleted;
}

/// Event of an [UserLogin] being updated.
class EventUserLoginUpdated extends MyUserEvent {
  const EventUserLoginUpdated(UserId userId, this.login) : super(userId);

  /// New [UserLogin].
  final UserLogin login;

  @override
  MyUserEventKind get kind => MyUserEventKind.loginUpdated;
}

/// Event of an [MyUser] being muted.
class EventUserMuted extends MyUserEvent {
  const EventUserMuted(UserId userId, this.until) : super(userId);

  /// Duration of the mute.
  final MuteDuration until;

  @override
  MyUserEventKind get kind => MyUserEventKind.userMuted;
}

/// Event of an [UserName] being deleted.
class EventUserNameDeleted extends MyUserEvent {
  const EventUserNameDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.nameDeleted;
}

/// Event of an [UserName] being updated.
class EventUserNameUpdated extends MyUserEvent {
  const EventUserNameUpdated(UserId userId, this.name) : super(userId);

  /// New [UserName].
  final UserName name;

  @override
  MyUserEventKind get kind => MyUserEventKind.nameUpdated;
}

/// Event of an [MyUser]'s password being updated.
class EventUserPasswordUpdated extends MyUserEvent {
  const EventUserPasswordUpdated(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.passwordUpdated;
}

/// Event of an [MyUser]'s phone number being added.
class EventUserPhoneAdded extends MyUserEvent {
  const EventUserPhoneAdded(UserId userId, this.phone) : super(userId);

  /// Added [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneAdded;
}

/// Event of an [MyUser]'s phone number being confirmed.
class EventUserPhoneConfirmed extends MyUserEvent {
  const EventUserPhoneConfirmed(UserId userId, this.phone) : super(userId);

  /// Confirmed [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneConfirmed;
}

/// Event of an [MyUser]'s phone number being deleted.
class EventUserPhoneDeleted extends MyUserEvent {
  const EventUserPhoneDeleted(UserId userId, this.phone) : super(userId);

  /// Deleted [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneDeleted;
}

/// Event of an [MyUser]'s [Presence] being updated.
class EventUserPresenceUpdated extends MyUserEvent {
  const EventUserPresenceUpdated(UserId userId, this.presence) : super(userId);

  /// New [MyUser]'s [Presence].
  final Presence presence;

  @override
  MyUserEventKind get kind => MyUserEventKind.presenceUpdated;
}

/// Event of an [UserTextStatus] being deleted.
class EventUserStatusDeleted extends MyUserEvent {
  const EventUserStatusDeleted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.statusDeleted;
}

/// Event of an [UserTextStatus] being updated.
class EventUserStatusUpdated extends MyUserEvent {
  const EventUserStatusUpdated(UserId userId, this.status) : super(userId);

  /// New [UserTextStatus].
  final UserTextStatus status;

  @override
  MyUserEventKind get kind => MyUserEventKind.statusUpdated;
}

/// Event of an [MyUser] being unmuted.
class EventUserUnmuted extends MyUserEvent {
  const EventUserUnmuted(UserId userId) : super(userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.unmuted;
}

/// Event of an [MyUser]'s unread `Chat`s count being updated.
class EventUserUnreadChatsCountUpdated extends MyUserEvent {
  const EventUserUnreadChatsCountUpdated(UserId userId, this.count)
      : super(userId);

  /// New [MyUser]'s unread `Chat`s count.
  final int count;

  @override
  MyUserEventKind get kind => MyUserEventKind.unreadChatsCountUpdated;
}

/// Event of a [User] being added or removed to/from blacklist of the [MyUser].
abstract class BlacklistEvent extends MyUserEvent {
  const BlacklistEvent(super.userId, this.user, this.at);

  /// [User] this [BlacklistEvent] is about.
  final HiveUser user;

  /// [PreciseDateTime] when this [BlacklistEvent] happened.
  final PreciseDateTime at;
}

/// Event of an [User] was added to the [MyUser]'s blacklist.
class EventBlacklistRecordAdded extends BlacklistEvent {
  const EventBlacklistRecordAdded(super.userId, super.user, super.at);

  @override
  MyUserEventKind get kind => MyUserEventKind.blacklistRecordAdded;
}

/// Event of an [User] was removed from the [MyUser]'s blacklist.
class EventBlacklistRecordRemoved extends BlacklistEvent {
  const EventBlacklistRecordRemoved(super.userId, super.user, super.at);

  @override
  MyUserEventKind get kind => MyUserEventKind.blacklistRecordRemoved;
}
