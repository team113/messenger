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

import '/domain/model/chat.dart';
import '/provider/hive/chat.dart';

/// Possible kinds of a [RecentChatsEvent].
enum RecentChatsEventKind {
  initialized,
  list,
  updated,
  deleted,
}

/// Events happening with the recent [Chat]s list.
abstract class RecentChatsEvent {
  const RecentChatsEvent();

  /// Returns [RecentChatsEventKind] of this [RecentChatsEvent].
  RecentChatsEventKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class RecentChatsTopInitialized extends RecentChatsEvent {
  const RecentChatsTopInitialized();

  @override
  RecentChatsEventKind get kind => RecentChatsEventKind.initialized;
}

/// Initial top of recent [Chat]s list.
class RecentChatsTop extends RecentChatsEvent {
  const RecentChatsTop(this.list);

  /// List of recent [Chat]s.
  final List<HiveChat> list;

  @override
  RecentChatsEventKind get kind => RecentChatsEventKind.list;
}

/// Event of a [Chat] position being updated in a recent [Chat]s list.
class EventRecentChatsUpdated extends RecentChatsEvent {
  const EventRecentChatsUpdated(this.chat);

  /// [Chat] which position was updated.
  final HiveChat chat;

  @override
  RecentChatsEventKind get kind => RecentChatsEventKind.updated;
}

/// Event of a [Chat] being removed from a recent [Chat]s list.
class EventRecentChatsDeleted extends RecentChatsEvent {
  const EventRecentChatsDeleted(this.chatId);

  /// ID of the removed [Chat].
  final ChatId chatId;

  @override
  RecentChatsEventKind get kind => RecentChatsEventKind.deleted;
}
