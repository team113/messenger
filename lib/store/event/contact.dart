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

import '../model/contact.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';

/// Possible kinds of a [ChatContactEvent].
enum ChatContactEventKind {
  created,
  deleted,
  emailAdded,
  emailRemoved,
  favorited,
  groupAdded,
  groupRemoved,
  nameUpdated,
  phoneAdded,
  phoneRemoved,
  unfavorited,
  userAdded,
  userRemoved,
}

/// Tag representing a [ChatContactsEvents] kind.
enum ChatContactsEventsKind { initialized, chatContactsList, event }

/// [ChatContact]s list event union.
abstract class ChatContactsEvents {
  const ChatContactsEvents();

  /// [ChatContactsEventsKind] of this event.
  ChatContactsEventsKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class ChatContactsEventsInitialized extends ChatContactsEvents {
  const ChatContactsEventsInitialized();

  @override
  ChatContactsEventsKind get kind => ChatContactsEventsKind.initialized;
}

/// [ChatContactEventsVersioned] happening in [ChatContact]s list.
class ChatContactsEventsEvent extends ChatContactsEvents {
  const ChatContactsEventsEvent(this.event);

  /// [ChatContactEventsVersioned] itself.
  final ChatContactEventsVersioned event;

  @override
  ChatContactsEventsKind get kind => ChatContactsEventsKind.event;
}

/// [ChatContactEvent]s accompanied by the corresponding [ChatContactVersion]
/// and [ChatContactsListVersion].
class ChatContactEventsVersioned {
  const ChatContactEventsVersioned(this.events, this.ver, this.listVer);

  /// [ChatContactEvent]s itself.
  final List<ChatContactEvent> events;

  /// Version of the [ChatContact] state updated by this [ChatContactEvent].
  final ChatContactVersion ver;

  /// Version of the [ChatContact]s list updated by this [ChatContactEvent].
  final ChatContactsListVersion listVer;
}

/// Events happening with [ChatContact].
abstract class ChatContactEvent {
  const ChatContactEvent(this.contactId, this.at);

  /// ID of the [ChatContact] this [ChatContactEvent] is related to.
  final ChatContactId contactId;

  /// [PreciseDateTime] when this [ChatContactEvent] happened.
  final PreciseDateTime at;

  /// Returns [ChatContactEventKind] of this [ChatContactEvent].
  ChatContactEventKind get kind;
}

/// Event of a new [ChatContact] being created.
class EventChatContactCreated extends ChatContactEvent {
  const EventChatContactCreated(super.contactId, super.at, this.name);

  /// Name of the created [ChatContact].
  final UserName name;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.created;
}

/// Event of a [ChatContact] being deleted.
class EventChatContactDeleted extends ChatContactEvent {
  const EventChatContactDeleted(super.contactId, super.at);

  @override
  ChatContactEventKind get kind => ChatContactEventKind.deleted;
}

/// Event of an [UserEmail] being added to a [ChatContact].
class EventChatContactEmailAdded extends ChatContactEvent {
  const EventChatContactEmailAdded(super.contactId, super.at, this.email);

  /// Added [UserEmail].
  final UserEmail email;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.emailAdded;
}

/// Event of an [UserEmail] being removed from a [ChatContact].
class EventChatContactEmailRemoved extends ChatContactEvent {
  const EventChatContactEmailRemoved(super.contactId, super.at, this.email);

  /// Removed [UserEmail].
  final UserEmail email;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.emailRemoved;
}

/// Event of a [ChatContact] being favorited.
class EventChatContactFavorited extends ChatContactEvent {
  const EventChatContactFavorited(super.contactId, super.at, this.position);

  /// Position of the [ChatContact] in the favorites list.
  final ChatContactFavoritePosition position;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.favorited;
}

/// Event of a [Chat]-group being added to the [ChatContact].
class EventChatContactGroupAdded extends ChatContactEvent {
  const EventChatContactGroupAdded(super.contactId, super.at, this.group);

  /// [Chat]-group added to the [ChatContact].
  final Chat group;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.groupAdded;
}

/// Event of a [Chat]-group being removed from a [ChatContact].
class EventChatContactGroupRemoved extends ChatContactEvent {
  const EventChatContactGroupRemoved(super.contactId, super.at, this.groupId);

  /// ID of the removed [Chat]-group.
  final ChatId groupId;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.groupRemoved;
}

/// Event of a [ChatContact]'s name being updated.
class EventChatContactNameUpdated extends ChatContactEvent {
  const EventChatContactNameUpdated(super.contactId, super.at, this.name);

  /// Updated name of the [ChatContact].
  final UserName name;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.nameUpdated;
}

/// Event of an [UserPhone] being added to a [ChatContact].
class EventChatContactPhoneAdded extends ChatContactEvent {
  const EventChatContactPhoneAdded(super.contactId, super.at, this.phone);

  /// Added [UserPhone].
  final UserPhone phone;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.phoneAdded;
}

/// Event of an [UserPhone] being removed from a [ChatContact].
class EventChatContactPhoneRemoved extends ChatContactEvent {
  const EventChatContactPhoneRemoved(super.contactId, super.at, this.phone);

  /// Removed [UserPhone].
  final UserPhone phone;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.phoneRemoved;
}

/// Event of a [ChatContact] being unfavorited.
class EventChatContactUnfavorited extends ChatContactEvent {
  const EventChatContactUnfavorited(super.contactId, super.at);

  @override
  ChatContactEventKind get kind => ChatContactEventKind.unfavorited;
}

/// Event of an [User] being added to a [ChatContact].
class EventChatContactUserAdded extends ChatContactEvent {
  const EventChatContactUserAdded(super.contactId, super.at, this.user);

  /// [User] added to the [ChatContact].
  final User user;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.userAdded;
}

/// Event of an [User] being removed from a [ChatContact].
class EventChatContactUserRemoved extends ChatContactEvent {
  const EventChatContactUserRemoved(super.contactId, super.at, this.userId);

  /// ID of the removed [User].
  final UserId userId;

  @override
  ChatContactEventKind get kind => ChatContactEventKind.userRemoved;
}
