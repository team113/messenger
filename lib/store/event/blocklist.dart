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

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/store/model/blocklist.dart';
import '/store/model/user.dart';

/// Tag representing a [BlocklistEvents] kind.
enum BlocklistEventsKind { blocklist, event }

/// Event emitted by `Subscription.blocklistEvents`.
abstract class BlocklistEvents {
  const BlocklistEvents();

  /// Returns [BlocklistEventsKind] of these [BlocklistEvents].
  BlocklistEventsKind get kind;
}

/// List of [BlocklistRecord]s.
class BlocklistEventsBlocklist extends BlocklistEvents {
  const BlocklistEventsBlocklist(this.records, this.totalCount, this.ver);

  /// List of [DtoBlocklistRecord] edges.
  final List<DtoBlocklistRecord> records;

  /// Total count of [BlocklistRecord]s.
  final int totalCount;

  /// Version of this [BlocklistRecord]s list.
  final BlocklistVersion ver;

  @override
  BlocklistEventsKind get kind => BlocklistEventsKind.blocklist;
}

/// [BlocklistEventsVersioned] type of [BlocklistEvents] event.
class BlocklistEventsEvent extends BlocklistEvents {
  const BlocklistEventsEvent(this.event);

  /// [BlocklistEventsVersioned] themselves.
  final BlocklistEventsVersioned event;

  @override
  BlocklistEventsKind get kind => BlocklistEventsKind.event;
}

/// Possible kinds of [MyUserEvent].
enum BlocklistEventKind { recordAdded, recordRemoved }

/// [BlocklistEvent]s along with the corresponding [BlocklistVersion].
class BlocklistEventsVersioned {
  const BlocklistEventsVersioned(this.events, this.ver);

  /// [BlocklistEvent]s themselves.
  final List<BlocklistEvent> events;

  /// Version of the [BlocklistRecord]s list state updated by these [events].
  final BlocklistVersion ver;
}

/// Event of a [User] being added or removed to/from [BlocklistRecord]s.
abstract class BlocklistEvent {
  const BlocklistEvent(this.user, this.at);

  /// [DtoUser] this [BlocklistEvent] is about.
  final DtoUser user;

  /// [PreciseDateTime] when this [BlocklistEvent] happened.
  final PreciseDateTime at;

  /// Returns [BlocklistEventKind] of this [BlocklistEvent].
  BlocklistEventKind get kind;
}

/// Event of a [BlocklistRecord] being added to blocklist of the authenticated
/// [MyUser].
class EventBlocklistRecordAdded extends BlocklistEvent {
  const EventBlocklistRecordAdded(super.user, super.at, this.reason);

  /// Reason of why the [User] was blocked.
  final BlocklistReason? reason;

  @override
  BlocklistEventKind get kind => BlocklistEventKind.recordAdded;

  @override
  bool operator ==(Object other) =>
      other is EventBlocklistRecordAdded &&
      user == other.user &&
      at == other.at &&
      reason == other.reason;

  @override
  int get hashCode => kind.hashCode;
}

/// Event of a [BlocklistRecord] being removed from blocklist of the
/// authenticated [MyUser].
class EventBlocklistRecordRemoved extends BlocklistEvent {
  const EventBlocklistRecordRemoved(super.user, super.at);

  @override
  BlocklistEventKind get kind => BlocklistEventKind.recordRemoved;

  @override
  bool operator ==(Object other) =>
      other is EventBlocklistRecordAdded &&
      user == other.user &&
      at == other.at;

  @override
  int get hashCode => kind.hashCode;
}
