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

  @override
  bool operator ==(Object other) => other is EventUserAvatarDeleted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [UserAvatar] being updated.
class EventUserAvatarUpdated extends MyUserEvent {
  const EventUserAvatarUpdated(super.userId, this.avatar);

  /// New [UserAvatar].
  final UserAvatar avatar;

  @override
  MyUserEventKind get kind => MyUserEventKind.avatarUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserAvatarUpdated &&
      avatar.original.relativeRef == other.avatar.original.relativeRef &&
      avatar.crop == other.avatar.crop;

  @override
  int get hashCode => avatar.hashCode;
}

/// Event of a [UserBio] being deleted.
class EventUserBioDeleted extends MyUserEvent {
  const EventUserBioDeleted(super.userId, this.at);

  /// [PreciseDateTime] when the [UserBio] was deleted.
  final PreciseDateTime at;

  @override
  MyUserEventKind get kind => MyUserEventKind.bioDeleted;

  @override
  bool operator ==(Object other) =>
      other is EventUserBioDeleted && at == other.at;

  @override
  int get hashCode => at.hashCode;
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

  @override
  bool operator ==(Object other) =>
      other is EventUserBioUpdated && bio == other.bio && at == other.at;

  @override
  int get hashCode => Object.hash(bio, at);
}

/// Event of an [UserCallCover] being deleted.
class EventUserCallCoverDeleted extends MyUserEvent {
  const EventUserCallCoverDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.callCoverDeleted;

  @override
  bool operator ==(Object other) => other is EventUserCallCoverDeleted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [UserCallCover] being updated.
class EventUserCallCoverUpdated extends MyUserEvent {
  const EventUserCallCoverUpdated(super.userId, this.callCover);

  /// New [UserCallCover].
  final UserCallCover callCover;

  @override
  MyUserEventKind get kind => MyUserEventKind.callCoverUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserCallCoverUpdated &&
      callCover.original.relativeRef == other.callCover.original.relativeRef &&
      callCover.crop == other.callCover.crop;

  @override
  int get hashCode => callCover.hashCode;
}

/// Event of an [MyUser] coming offline.
class EventUserCameOffline extends MyUserEvent {
  const EventUserCameOffline(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.cameOffline;

  @override
  bool operator ==(Object other) => other is EventUserCameOffline;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [MyUser] coming online.
class EventUserCameOnline extends MyUserEvent {
  const EventUserCameOnline(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.cameOnline;

  @override
  bool operator ==(Object other) => other is EventUserCameOnline;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [MyUser] being deleted.
class EventUserDeleted extends MyUserEvent {
  const EventUserDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.deleted;

  @override
  bool operator ==(Object other) => other is EventUserDeleted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [MyUser]'s [ChatDirectLink] being deleted.
class EventUserDirectLinkDeleted extends MyUserEvent {
  EventUserDirectLinkDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.directLinkDeleted;

  @override
  bool operator ==(Object other) => other is EventUserDirectLinkDeleted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [MyUser]'s [ChatDirectLink] being updated.
class EventUserDirectLinkUpdated extends MyUserEvent {
  const EventUserDirectLinkUpdated(super.userId, this.directLink);

  /// New [User]'s [ChatDirectLink].
  final ChatDirectLink directLink;

  @override
  MyUserEventKind get kind => MyUserEventKind.directLinkUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserDirectLinkUpdated && directLink == other.directLink;

  @override
  int get hashCode => directLink.hashCode;
}

/// Event of an [MyUser]'s [UserEmail] address being added.
class EventUserEmailAdded extends MyUserEvent {
  const EventUserEmailAdded(super.userId, this.email);

  /// Added [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailAdded;

  @override
  bool operator ==(Object other) =>
      other is EventUserEmailAdded && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

/// Event of an [MyUser]'s email address being confirmed.
class EventUserEmailConfirmed extends MyUserEvent {
  const EventUserEmailConfirmed(super.userId, this.email);

  /// Confirmed [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailConfirmed;

  @override
  bool operator ==(Object other) =>
      other is EventUserEmailConfirmed && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

/// Event of an [MyUser]'s [UserEmail] address being deleted.
class EventUserEmailDeleted extends MyUserEvent {
  const EventUserEmailDeleted(super.userId, this.email);

  /// Deleted [UserEmail].
  final UserEmail email;

  @override
  MyUserEventKind get kind => MyUserEventKind.emailDeleted;

  @override
  bool operator ==(Object other) =>
      other is EventUserEmailDeleted && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

/// Event of a [UserLogin] being updated.
class EventUserLoginUpdated extends MyUserEvent {
  const EventUserLoginUpdated(super.userId, this.login);

  /// New [UserLogin].
  final UserLogin login;

  @override
  MyUserEventKind get kind => MyUserEventKind.loginUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserLoginUpdated && login == other.login;

  @override
  int get hashCode => login.hashCode;
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

  @override
  bool operator ==(Object other) =>
      other is EventUserMuted && until == other.until;

  @override
  int get hashCode => until.hashCode;
}

/// Event of an [UserName] being deleted.
class EventUserNameDeleted extends MyUserEvent {
  const EventUserNameDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.nameDeleted;

  @override
  bool operator ==(Object other) => other is EventUserNameDeleted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [UserName] being updated.
class EventUserNameUpdated extends MyUserEvent {
  const EventUserNameUpdated(super.userId, this.name);

  /// New [UserName].
  final UserName name;

  @override
  MyUserEventKind get kind => MyUserEventKind.nameUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserNameUpdated && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Event of an [MyUser]'s password being updated.
class EventUserPasswordUpdated extends MyUserEvent {
  const EventUserPasswordUpdated(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.passwordUpdated;

  @override
  bool operator ==(Object other) => other is EventUserPasswordUpdated;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [MyUser]'s phone number being added.
class EventUserPhoneAdded extends MyUserEvent {
  const EventUserPhoneAdded(super.userId, this.phone);

  /// Added [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneAdded;

  @override
  bool operator ==(Object other) =>
      other is EventUserPhoneAdded && phone == other.phone;

  @override
  int get hashCode => phone.hashCode;
}

/// Event of an [MyUser]'s phone number being confirmed.
class EventUserPhoneConfirmed extends MyUserEvent {
  const EventUserPhoneConfirmed(super.userId, this.phone);

  /// Confirmed [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneConfirmed;

  @override
  bool operator ==(Object other) =>
      other is EventUserPhoneConfirmed && phone == other.phone;

  @override
  int get hashCode => phone.hashCode;
}

/// Event of an [MyUser]'s phone number being deleted.
class EventUserPhoneDeleted extends MyUserEvent {
  const EventUserPhoneDeleted(super.userId, this.phone);

  /// Deleted [UserPhone].
  final UserPhone phone;

  @override
  MyUserEventKind get kind => MyUserEventKind.phoneDeleted;

  @override
  bool operator ==(Object other) =>
      other is EventUserPhoneDeleted && phone == other.phone;

  @override
  int get hashCode => phone.hashCode;
}

/// Event of an [MyUser]'s [Presence] being updated.
class EventUserPresenceUpdated extends MyUserEvent {
  const EventUserPresenceUpdated(super.userId, this.presence);

  /// New [MyUser]'s [Presence].
  final Presence presence;

  @override
  MyUserEventKind get kind => MyUserEventKind.presenceUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserPresenceUpdated && presence == other.presence;

  @override
  int get hashCode => presence.hashCode;
}

/// Event of an [UserTextStatus] being deleted.
class EventUserStatusDeleted extends MyUserEvent {
  const EventUserStatusDeleted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.statusDeleted;

  @override
  bool operator ==(Object other) => other is EventUserStatusDeleted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [UserTextStatus] being updated.
class EventUserStatusUpdated extends MyUserEvent {
  const EventUserStatusUpdated(super.userId, this.status);

  /// New [UserTextStatus].
  final UserTextStatus status;

  @override
  MyUserEventKind get kind => MyUserEventKind.statusUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserStatusUpdated && status == other.status;

  @override
  int get hashCode => status.hashCode;
}

/// Event of an [MyUser] being unmuted.
class EventUserUnmuted extends MyUserEvent {
  const EventUserUnmuted(super.userId);

  @override
  MyUserEventKind get kind => MyUserEventKind.unmuted;

  @override
  bool operator ==(Object other) => other is EventUserUnmuted;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of an [MyUser]'s unread `Chat`s count being updated.
class EventUserUnreadChatsCountUpdated extends MyUserEvent {
  const EventUserUnreadChatsCountUpdated(super.userId, this.count);

  /// New [MyUser]'s unread `Chat`s count.
  final int count;

  @override
  MyUserEventKind get kind => MyUserEventKind.unreadChatsCountUpdated;

  @override
  bool operator ==(Object other) =>
      other is EventUserUnreadChatsCountUpdated && count == other.count;

  @override
  int get hashCode => count.hashCode;
}

/// Event of a [User] being added or removed to/from blocklist of the [MyUser].
abstract class BlocklistEvent extends MyUserEvent {
  BlocklistEvent(this.user, this.at) : super(user.value.id);

  /// [User] this [BlocklistEvent] is about.
  final HiveUser user;

  /// [PreciseDateTime] when this [BlocklistEvent] happened.
  final PreciseDateTime at;

  @override
  bool operator ==(Object other) =>
      other is BlocklistEvent &&
      user.value.id == other.user.value.id &&
      at == other.at;

  @override
  int get hashCode => Object.hash(user, at);
}

/// Event of a [BlocklistRecord] being added to blocklist of the authenticated
/// [MyUser].
class EventBlocklistRecordAdded extends BlocklistEvent {
  EventBlocklistRecordAdded(super.user, super.at, this.reason);

  /// Reason of why the [User] was blocked.
  final BlocklistReason? reason;

  @override
  MyUserEventKind get kind => MyUserEventKind.blocklistRecordAdded;

  @override
  bool operator ==(Object other) =>
      other is EventBlocklistRecordAdded && reason == other.reason;

  @override
  int get hashCode => reason.hashCode;
}

/// Event of a [BlocklistRecord] being removed from blocklist of the
/// authenticated [MyUser].
class EventBlocklistRecordRemoved extends BlocklistEvent {
  EventBlocklistRecordRemoved(super.user, super.at);

  @override
  MyUserEventKind get kind => MyUserEventKind.blocklistRecordRemoved;

  @override
  bool operator ==(Object other) => other is EventBlocklistRecordRemoved;

  @override
  int get hashCode => kind.hashCode;
}
