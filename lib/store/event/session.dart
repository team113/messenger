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

import '/domain/model/avatar.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/store/model/session.dart';

/// Possible kinds of [SessionEvent].
enum SessionEventKind { created, deleted, refreshed }

/// [SessionEvent]s along with the corresponding [SessionVersion] and
/// [SessionsListVersion].
class SessionEventsVersioned {
  const SessionEventsVersioned(this.events, this.ver, this.listVer);

  /// [SessionEvent]s themselves.
  final List<SessionEvent> events;

  /// Version of the [Session] state updated by these [SessionEvent]s.
  final SessionVersion ver;

  /// Version of the [Session]s list state updated by these [SessionEvent]s.
  final SessionsListVersion listVer;
}

/// Events happening in a [Session].
abstract class SessionEvent {
  const SessionEvent(this.id, this.at);

  /// ID of the [MyUser] this [SessionEvent] is related to.
  final SessionId id;

  /// [PreciseDateTime] when this [SessionEvent] happened.
  final PreciseDateTime at;

  /// Returns [SessionEventKind] of this [SessionEvent].
  SessionEventKind get kind;
}

/// Event of a new [Session] being created.
class EventSessionCreated extends SessionEvent {
  const EventSessionCreated(
    super.id,
    super.at,
    this.userAgent,
    this.remembered,
  );

  /// [UserAgent] the [Session] was created by.
  final UserAgent userAgent;

  /// Indicator whether the created [Session] is remembered and is allowed to be
  /// refreshed via `Mutation.refreshSession`.
  final bool remembered;

  @override
  SessionEventKind get kind => SessionEventKind.created;

  @override
  bool operator ==(Object other) =>
      other is EventSessionCreated &&
      other.id == id &&
      other.at == at &&
      other.userAgent == userAgent &&
      other.remembered == remembered;

  @override
  int get hashCode => Object.hash(id, at, userAgent, remembered);
}

/// Event of an [UserAvatar] being updated.
class EventSessionDeleted extends SessionEvent {
  const EventSessionDeleted(super.id, super.at);

  @override
  SessionEventKind get kind => SessionEventKind.deleted;

  @override
  bool operator ==(Object other) =>
      other is EventSessionDeleted && other.id == id && other.at == at;

  @override
  int get hashCode => Object.hash(id, at);
}

/// Event of a [UserBio] being deleted.
class EventSessionRefreshed extends SessionEvent {
  const EventSessionRefreshed(super.userId, super.at, this.userAgent);

  /// [UserAgent] the [Session] was refreshed by.
  final UserAgent userAgent;

  @override
  SessionEventKind get kind => SessionEventKind.refreshed;

  @override
  bool operator ==(Object other) =>
      other is EventSessionRefreshed &&
      other.id == id &&
      other.at == at &&
      other.userAgent == userAgent;

  @override
  int get hashCode => Object.hash(id, at, userAgent);
}
