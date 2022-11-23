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
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/store/chat.dart';
import '/store/model/chat.dart';

/// Tag representing a [FavoriteChatsEvent] kind.
enum FavoriteChatsEventKind {
  favorited,
  unfavorited,
}

/// Tag representing a [FavoriteChatsEvents] kind.
enum FavoriteChatsEventsKind {
  initialized,
  chatsList,
  event,
}

/// The favorite [Chat]s list event union
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
  const FavoriteChatsEventsChatsList(this.chatList);

  /// Initial state itself.
  final List<ChatData> chatList;

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
  final List<FavoriteChatsEvent> events;

  /// Version of the [FavoriteChatsEvent]'s state updated by these [FavoriteChatsEvent]s.
  final FavoriteChatsListVersion ver;
}

/// Events happening in the the favorite [Chat]s list.
abstract class FavoriteChatsEvent {
  const FavoriteChatsEvent(this.chatId, this.at);

  /// ID of the [Chat] this [FavoriteChatsEvent] is happened in.
  final ChatId chatId;

  /// [PreciseDateTime] when this [FavoriteChatsEvent] happened.
  final PreciseDateTime at;

  /// Returns [FavoriteChatsEventKind] of this [FavoriteChatsEvent].
  FavoriteChatsEventKind get kind;
}

/// Event of a [Chat] being added to the favorites list of the authenticated
/// [MyUser].
class EventChatFavorited extends FavoriteChatsEvent {
  const EventChatFavorited(ChatId chatId, PreciseDateTime at, this.position)
      : super(chatId, at);

  /// Position of the [Chat] in the favorites list.
  final ChatFavoritePosition position;

  @override
  FavoriteChatsEventKind get kind => FavoriteChatsEventKind.favorited;
}

/// Event of a [Chat] being removed from the favorites list of the authenticated
/// [MyUser].
class EventChatUnfavorited extends FavoriteChatsEvent {
  const EventChatUnfavorited(ChatId chatId, PreciseDateTime at)
      : super(chatId, at);

  @override
  FavoriteChatsEventKind get kind => FavoriteChatsEventKind.unfavorited;
}
