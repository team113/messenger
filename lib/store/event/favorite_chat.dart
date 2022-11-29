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

import '/domain/model/chat.dart';
import '/store/chat.dart';
import '/store/event/chat.dart';
import '/store/model/chat.dart';

/// Tag representing a [FavoriteChatsEvents] kind.
enum FavoriteChatsEventsKind {
  initialized,
  chatsList,
  event,
}

/// Favorite [Chat]s list event union.
abstract class FavoriteChatsEvents {
  const FavoriteChatsEvents();

  /// [FavoriteChatsEventsKind] of this event.
  FavoriteChatsEventsKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class FavoriteChatsEventsInitialized extends FavoriteChatsEvents {
  const FavoriteChatsEventsInitialized();

  @override
  FavoriteChatsEventsKind get kind => FavoriteChatsEventsKind.initialized;
}

/// Initial state of the favorite [Chat]s list.
class FavoriteChatsEventsChatsList extends FavoriteChatsEvents {
  const FavoriteChatsEventsChatsList(this.chatList, this.ver);

  /// Initial state itself.
  final List<ChatData> chatList;

  /// Version of the initial favorite [Chat]s list.
  final FavoriteChatsListVersion ver;

  @override
  FavoriteChatsEventsKind get kind => FavoriteChatsEventsKind.chatsList;
}

/// [FavoriteChatsEventsVersioned] happening in the favorite [Chat]s list.
class FavoriteChatsEventsEvent extends FavoriteChatsEvents {
  const FavoriteChatsEventsEvent(this.event);

  /// [FavoriteChatsEventsVersioned] itself.
  final FavoriteChatsEventsVersioned event;

  @override
  FavoriteChatsEventsKind get kind => FavoriteChatsEventsKind.event;
}

/// [FavoriteChatsEvent]s along with the corresponding
/// [FavoriteChatsListVersion].
class FavoriteChatsEventsVersioned {
  const FavoriteChatsEventsVersioned(this.events, this.ver);

  /// [FavoriteChatsEvent]s themselves.
  final List<ChatEvent> events;

  /// Version of the [FavoriteChatsEvent]'s state updated by these
  /// [FavoriteChatsEvent]s.
  final FavoriteChatsListVersion ver;
}
