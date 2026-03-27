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

import '/domain/model/link.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/store/model/link.dart';

/// Possible kinds of a [DirectLinkEvent].
enum DirectLinkEventKind {
  created,
  disabled,
  enabled,
  locationUpdated,
  statsUpdated,
}

/// Tag representing a [DirectLinkEvents] kind.
enum DirectLinkEventsKind { initialized, list, event }

/// [DirectLink] event union.
abstract class DirectLinkEvents {
  const DirectLinkEvents();

  /// [DirectLinkEventsKind] of this event.
  DirectLinkEventsKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class DirectLinkEventsInitialized extends DirectLinkEvents {
  const DirectLinkEventsInitialized();

  @override
  DirectLinkEventsKind get kind => DirectLinkEventsKind.initialized;
}

/// Initial state of the [DirectLink]s.
class DirectLinkEventsList extends DirectLinkEvents {
  const DirectLinkEventsList();

  @override
  DirectLinkEventsKind get kind => DirectLinkEventsKind.list;
}

/// [DirectLinkEventsVersioned] happening with a [DirectLink].
class DirectLinkEventsEvent extends DirectLinkEvents {
  const DirectLinkEventsEvent(this.event);

  /// [DirectLinkEventsVersioned] itself.
  final DirectLinkEventsVersioned event;

  @override
  DirectLinkEventsKind get kind => DirectLinkEventsKind.event;
}

/// [DirectLinkEvent]s along with the corresponding [DirectLinkVersion].
class DirectLinkEventsVersioned {
  const DirectLinkEventsVersioned(this.events, this.ver);

  /// [DirectLinkEvent]s themselves.
  final List<DirectLinkEvent> events;

  /// Version of the [DirectLink]'s state updated by these [DirectLinkEvent]s.
  final DirectLinkVersion ver;
}

/// Events happening with a [DirectLink].
abstract class DirectLinkEvent {
  const DirectLinkEvent(this.slug, this.link, this.at);

  /// Slug of the DirectLink this DirectLinkEvent is related to.
  final DirectLinkSlug slug;

  /// [DtoDirectLink] of the DirectLink this [DirectLinkEvent] is related to.
  final DtoDirectLink link;

  /// [PreciseDateTime] when this [DirectLinkEvent] happened.
  final PreciseDateTime at;

  /// Returns [DirectLinkEventKind] of this [DirectLinkEvent].
  DirectLinkEventKind get kind;
}

/// Event of a new [DirectLink] being created.
class DirectLinkCreatedEvent extends DirectLinkEvent {
  const DirectLinkCreatedEvent(super.slug, super.link, super.at);

  @override
  DirectLinkEventKind get kind => DirectLinkEventKind.created;
}

/// Event of a [DirectLink] being disabled.
class DirectLinkDisabledEvent extends DirectLinkEvent {
  const DirectLinkDisabledEvent(super.slug, super.link, super.at);

  @override
  DirectLinkEventKind get kind => DirectLinkEventKind.disabled;
}

/// Event of a [DirectLink] being enabled.
class DirectLinkEnabledEvent extends DirectLinkEvent {
  const DirectLinkEnabledEvent(super.slug, super.link, super.at);

  @override
  DirectLinkEventKind get kind => DirectLinkEventKind.enabled;
}

/// Event of a [DirectLink.location] being updated.
class DirectLinkLocationUpdatedEvent extends DirectLinkEvent {
  const DirectLinkLocationUpdatedEvent(super.slug, super.link, super.at);

  @override
  DirectLinkEventKind get kind => DirectLinkEventKind.locationUpdated;
}

/// Event of [DirectLink.visitors] or different stats being updated.
class DirectLinkStatsUpdatedEvent extends DirectLinkEvent {
  const DirectLinkStatsUpdatedEvent(super.slug, super.link, super.at);

  @override
  DirectLinkEventKind get kind => DirectLinkEventKind.statsUpdated;
}
