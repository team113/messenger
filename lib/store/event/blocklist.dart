// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

enum BlocklistEventsKind { blocklist, event }

abstract class BlocklistEvents {
  const BlocklistEvents();

  /// Returns [BlocklistEventsKind] of these [BlocklistEvents].
  BlocklistEventsKind get kind;
}

class BlocklistEventsBlocklist extends BlocklistEvents {
  const BlocklistEventsBlocklist(this.records, this.totalCount);

  final List<DtoBlocklistRecord> records;
  final int totalCount;

  @override
  BlocklistEventsKind get kind => BlocklistEventsKind.blocklist;
}

class BlocklistEventsEvent extends BlocklistEvents {
  const BlocklistEventsEvent(this.event);

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

  final BlocklistVersion ver;
}

abstract class BlocklistEvent {
  const BlocklistEvent(this.user, this.at);

  final DtoUser user;
  final PreciseDateTime at;

  /// Returns [BlocklistEventKind] of this [BlocklistEvent].
  BlocklistEventKind get kind;
}

class EventBlocklistRecordAdded extends BlocklistEvent {
  const EventBlocklistRecordAdded(super.user, super.at, this.reason);

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
