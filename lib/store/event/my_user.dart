// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
  bioUpdated,
  bioDeleted,
  blocklistRecordAdded,
  blocklistRecordRemoved,
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
  loginDeleted,
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
  const EventUserAvatarDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.avatarDeleted;
}

/// Event of an [UserAvatar] being updated.
class EventUserAvatarUpdated extends MyUserEvent {
  const EventUserAvatarUpdated(super.userId, this.avatar);

  /// New [UserAvatar].
  final UserAvatar avatar;

  @override
  MyUserEventKind get kind => MyUserEventKind.avatarUpdated;
}

/// Event of a [UserBio] being deleted.
class EventUserBioDeleted extends MyUserEvent {
  const EventUserBioDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [UserBio] was deleted.
  final PreciseDateTime at;

  @override
  MyUserEventKind get kind => MyUserEventKind.bioDeleted;
}

/// Event of a [UserBio] being updated.
class EventUserBioUpdated extends MyUserEvent {
  const EventUserBioUpdated(super.userId, this.bio, this.at);

  /// New [UserBio].
  final UserBio bio;

  /// [PreciseDateTime] when the [UserBio] was updated.
  final PreciseDateTime at;

  @override
  MyUserEventKind get kind => MyUserEventKind.bioUpdated;
}

/// Event of an [UserCallCover] being deleted.
class EventUserCallCoverDeleted extends MyUserEvent {
  const EventUserCallCoverDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.callCoverDeleted;
}

/// Event of an [UserCallCover] being updated.
class EventUserCallCoverUpdated extends MyUserEvent {
  const EventUserCallCoverUpdated(super.userId, this.callCover);

  /// New [UserCallCover].
  final UserCallCover callCover;

  @override
  MyUserEventKind get kind => MyUserEventKind.callCoverUpdated;
}

/// Event of an [MyUser] coming offline.
class EventUserCameOffline extends MyUserEvent {
  const EventUserCameOffline(super.userId, this.at);

  /// [PreciseDateTime] when the user came offline.
  final PreciseDateTime at;

  @override
  MyUserEventKind get kind => MyUserEventKind.cameOffline;
}

/// Event of an [MyUser] coming online.
class EventUserCameOnline extends MyUserEvent {
  const EventUserCameOnline(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.cameOnline;
}

/// Event of an [MyUser] being deleted.
class EventUserDeleted extends MyUserEvent {
  const EventUserDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.deleted;
}

/// Event of an [MyUser]'s [ChatDirectLink] being deleted.
class EventUserDirectLinkDeleted extends MyUserEvent {
  EventUserDirectLinkDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.directLinkDeleted;
}

/// Event of an [MyUser]'s [ChatDirectLink] being updated.
class EventUserDirectLinkUpdated extends MyUserEvent {
  const EventUserDirectLinkUpdated(super.userId, this.directLink);

  /// New [User]'s [ChatDirectLink].
  final ChatDirectLink directLink;

  @override
  MyUserEventKind get kind => MyUserEventKind.directLinkUpdated;
}

/// Event of an [MyUser]'s [UserEmail] address being added.
class EventUserEmailAdded extends MyUserEvent {
  const EventUserEmailAdded(super.userId, this.email);

  /// Added [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailAdded;
}

/// Event of an [MyUser]'s email address being confirmed.
class EventUserEmailConfirmed extends MyUserEvent {
  const EventUserEmailConfirmed(super.userId, this.email);

  /// Confirmed [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailConfirmed;
}

/// Event of an [MyUser]'s [UserEmail] address being deleted.
class EventUserEmailDeleted extends MyUserEvent {
  const EventUserEmailDeleted(super.userId, this.email);

  /// Deleted [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailDeleted;
}

/// Event of a [UserLogin] being updated.
class EventUserLoginUpdated extends MyUserEvent {
  const EventUserLoginUpdated(super.userId, this.login);

  /// New [UserLogin].
  final UserLogin login;

  @override
  MyUserEventKind get kind => MyUserEventKind.loginUpdated;
}

/// Event of a [UserLogin] being deleted.
class EventUserLoginDeleted extends MyUserEvent {
  const EventUserLoginDeleted(super.userId, this.at);

  /// [DateTime] when the [UserLogin] was deleted.
  final PreciseDateTime at;

  @override
  MyUserEventKind get kind => MyUserEventKind.loginDeleted;
}

/// Event of an [MyUser] being muted.
class EventUserMuted extends MyUserEvent {
  const EventUserMuted(super.userId, this.until);

  /// Duration of the mute.
  final MuteDuration until;

  @override
  MyUserEventKind get kind => MyUserEventKind.userMuted;
}

/// Event of an [UserName] being deleted.
class EventUserNameDeleted extends MyUserEvent {
  const EventUserNameDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.nameDeleted;
}

/// Event of an [UserName] being updated.
class EventUserNameUpdated extends MyUserEvent {
  const EventUserNameUpdated(super.userId, this.name);

  /// New [UserName].
  final UserName name;

  @override
  MyUserEventKind get kind => MyUserEventKind.nameUpdated;
}

/// Event of an [MyUser]'s password being updated.
class EventUserPasswordUpdated extends MyUserEvent {
  const EventUserPasswordUpdated(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.passwordUpdated;
}

/// Event of an [MyUser]'s phone number being added.
class EventUserPhoneAdded extends MyUserEvent {
  const EventUserPhoneAdded(super.userId, this.phone);

  /// Added [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneAdded;
}

/// Event of an [MyUser]'s phone number being confirmed.
class EventUserPhoneConfirmed extends MyUserEvent {
  const EventUserPhoneConfirmed(super.userId, this.phone);

  /// Confirmed [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneConfirmed;
}

/// Event of an [MyUser]'s phone number being deleted.
class EventUserPhoneDeleted extends MyUserEvent {
  const EventUserPhoneDeleted(super.userId, this.phone);

  /// Deleted [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneDeleted;
}

/// Event of an [MyUser]'s [Presence] being updated.
class EventUserPresenceUpdated extends MyUserEvent {
  const EventUserPresenceUpdated(super.userId, this.presence);

  /// New [MyUser]'s [Presence].
  final Presence presence;

  @override
  MyUserEventKind get kind => MyUserEventKind.presenceUpdated;
}

/// Event of an [UserTextStatus] being deleted.
class EventUserStatusDeleted extends MyUserEvent {
  const EventUserStatusDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.statusDeleted;
}

/// Event of an [UserTextStatus] being updated.
class EventUserStatusUpdated extends MyUserEvent {
  const EventUserStatusUpdated(super.userId, this.status);

  /// New [UserTextStatus].
  final UserTextStatus status;

  @override
  MyUserEventKind get kind => MyUserEventKind.statusUpdated;
}

/// Event of an [MyUser] being unmuted.
class EventUserUnmuted extends MyUserEvent {
  const EventUserUnmuted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.unmuted;
}

/// Event of an [MyUser]'s unread `Chat`s count being updated.
class EventUserUnreadChatsCountUpdated extends MyUserEvent {
  const EventUserUnreadChatsCountUpdated(super.userId, this.count);

  /// New [MyUser]'s unread `Chat`s count.
  final int count;

  @override
  MyUserEventKind get kind => MyUserEventKind.unreadChatsCountUpdated;
}

/// Event of a [User] being added or removed to/from blocklist of the [MyUser].
abstract class BlocklistEvent extends MyUserEvent {
  BlocklistEvent(this.user, this.at) : super(user.value.id);

  /// [User] this [BlocklistEvent] is about.
  final HiveUser user;

  /// [PreciseDateTime] when this [BlocklistEvent] happened.
  final PreciseDateTime at;
}

/// Event of a [BlocklistRecord] being added to blocklist of the authenticated
/// [MyUser].
class EventBlocklistRecordAdded extends BlocklistEvent {
  EventBlocklistRecordAdded(super.user, super.at, this.reason);

  /// Reason of why the [User] was blocked.
  final BlocklistReason? reason;

  @override
  MyUserEventKind get kind => MyUserEventKind.blocklistRecordAdded;
}

/// Event of a [BlocklistRecord] being removed from blocklist of the
/// authenticated [MyUser].
class EventBlocklistRecordRemoved extends BlocklistEvent {
  EventBlocklistRecordRemoved(super.user, super.at);

  @override
  MyUserEventKind get kind => MyUserEventKind.blocklistRecordRemoved;
}
