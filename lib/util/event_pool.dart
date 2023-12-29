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

import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '../store/event/my_user.dart';
import '../store/event/chat.dart';
import 'log.dart';

// Tracker for optimistic events.
class EventPool {
  /// Registred handlers for one-to-one call syncrously
  final Map<int, Mutex> _locks = {};
  // TODO: remove lock on handlers queue empty

  /// Events should be ignored when resieved from back
  final Map<int, List<PoolEntry>> _ignorance = {};

  /// Events should be neutralized with same type events
  final Map<int, PoolEntry> _neutralize = {};

  /// Adds event to pool.
  ///
  /// [event.handler] would be called when handlers of other events with same
  /// [EventType] would be awaited.
  void add(
    PoolEntry? event,
  ) {
    if (event != null) {
      if (_neutralize[event.key] != null) {
        if (!(_neutralize[event.key] == event)) {
          _neutralize.remove(event.key);
        }
      } else {
        _neutralize[event.key] = event;

        _locks[event.key] ??= Mutex();
        _locks[event.key]?.protect(() async {
          await _neutralizeWrapper(event);
        });
      }
    }
  }

  /// Returns true if same event exist waiting for ignorance.
  ///
  /// Deletes ignored events from pool.
  bool ignore(PoolEntry? event) {
    if (event != null) {
      final PoolEntry? waiter = _ignorance[event.key]
          ?.firstWhereOrNull((element) => event == element);
      if (waiter != null) {
        _ignorance[event.key]!.remove(waiter);
        return true;
      }
    }
    return false;
  }

  Future<dynamic> _neutralizeWrapper(PoolEntry event) async {
    if (_neutralize[event.key] != event) {
      // This event was neutralized.
      return;
    }

    _neutralize.remove(event.key);
    _ignorance[event.key] ??= [];
    _ignorance[event.key]!.add(event);

    // TODO: remove before review.
    await Future.delayed(const Duration(seconds: 3));

    // TODO: check error handling.
    await event.handler?.call();
  }
}

/// Types of event
enum EventType {
  myUserMuteChatsToggled,
  chatFavoriteToggled,
  noSupporting;
}

class PoolEntry {
  final dynamic sourceEvent;
  final Future<void> Function()? handler;
  final EventType type;
  final int key;
  final int propsHash;

  @override
  int get hashCode => propsHash;

  @override
  bool operator ==(Object other) =>
      other is PoolEntry && propsHash == other.propsHash;

  PoolEntry(this.sourceEvent,
      {required this.key,
      required this.propsHash,
      required this.handler,
      required this.type});
}

extension MyUserEventToPoolEntryExtension on MyUserEvent {
  PoolEntry? toPoolEntry([Future<void> Function()? handler]) {
    return switch (kind) {
      MyUserEventKind.userMuted => PoolEntry(this,
          handler: handler,
          type: EventType.myUserMuteChatsToggled,
          key: EventType.myUserMuteChatsToggled.hashCode,
          propsHash: Object.hash(
            EventType.myUserMuteChatsToggled,
            true,
          )),
      MyUserEventKind.unmuted => PoolEntry(this,
          handler: handler,
          type: EventType.myUserMuteChatsToggled,
          key: EventType.myUserMuteChatsToggled.hashCode,
          propsHash: Object.hash(
            EventType.myUserMuteChatsToggled,
            false,
          )),
      _ => null,
    };
  }
}

extension ChatEventToPoolEntryExtension on ChatEvent {
  PoolEntry? toPoolEntry([Future<void> Function()? handler]) {
    return switch (kind) {
      ChatEventKind.favorited => PoolEntry(this,
          handler: handler,
          type: EventType.chatFavoriteToggled,
          key: Object.hash(EventType.chatFavoriteToggled, chatId),
          propsHash: Object.hash(
            EventType.chatFavoriteToggled,
            chatId,
            true,
          )),
      ChatEventKind.unfavorited => PoolEntry(this,
          handler: handler,
          type: EventType.chatFavoriteToggled,
          key: Object.hash(EventType.chatFavoriteToggled, chatId),
          propsHash: Object.hash(
            EventType.chatFavoriteToggled,
            chatId,
            false,
          )),
      _ => null,
    };
  }
}

void _debugLog(String message, PoolEntry event) {
  Log.info(
      '--$message(${event.key} ${event.hashCode})', '${event.sourceEvent}');
}
