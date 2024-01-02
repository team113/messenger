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

import '/store/event/my_user.dart';
import '/store/event/chat.dart';
import 'log.dart';

/// Tracker for optimistic events.
class EventPool {
  /// Adds [PoolEntry] to this [EventPool].
  void add(PoolEntry? event) {
    Log.debug('add($event)', '$runtimeType');

    if (event != null) {
      if (_collapses[event.key] != null) {
        if (!(_collapses[event.key] == event)) {
          // Collapse with registred [PoolEntry]
          _collapses.remove(event.key);
        }
      } else {
        _collapses[event.key] = event;

        _locks[event.key] ??= Mutex();
        _locks[event.key]?.protect(() async {
          await _collapsableWrapper(event);
        });
      }
    }
  }

  /// Indicates whether [PoolEntry] should be ignored.
  bool ignore(PoolEntry? event) {
    Log.debug('ignore($event)', '$runtimeType');

    if (event != null) {
      final PoolEntry? waiter =
          _ignores[event.key]?.firstWhereOrNull((element) => event == element);
      if (waiter != null) {
        _ignores[event.key]!.remove(waiter);
        return true;
      }
    }
    return false;
  }

  /// [Mutex]es guarding synchronized call [PoolEntry] handlers.
  final Map<int, Mutex> _locks = {};

  /// [PoolEntry]es, that should be ignored when resieved from back.
  final Map<int, List<PoolEntry>> _ignores = {};

  /// [PoolEntry]es, that should be collapsed with event of same type.
  final Map<int, PoolEntry> _collapses = {};

  /// Implements collapsable behavior for handle [PoolEntry].
  Future<dynamic> _collapsableWrapper(PoolEntry event) async {
    if (_collapses[event.key] != event) {
      // This event was collapsed.
      return;
    } else {
      _collapses.remove(event.key);
    }

    _ignores[event.key] ??= [];
    _ignores[event.key]!.add(event);

    await event.handler?.call();
  }
}

/// Entry for tracking events in [EventPool].
class PoolEntry {
  /// Handler of this [PoolEntry].
  ///
  /// It would be called when handlers of other [PoolEntry] with same [key]
  /// would be complited.
  final Future<void> Function()? handler;

  /// [EventType] of this [PoolEntry].
  final EventType type;

  /// Key of this [PoolEntry].
  final int key;

  /// Stores hashed valuable properties of event, realted to this [PoolEntry].
  final int propsHash;

  @override
  int get hashCode => propsHash;

  @override
  bool operator ==(Object other) =>
      other is PoolEntry && propsHash == other.propsHash;

  PoolEntry(this.handler,
      {required this.key, required this.propsHash, required this.type});

  @override
  String toString() => 'PoolEntry($type, $key, $propsHash)';
}

/// Types of tracking events.
enum EventType {
  myUserMuteChatsToggled,
  chatFavoriteToggled;
}

/// Extension adding [PoolEntry] construction from a [MyUserEvent].
extension MyUserEventToPoolEntryExtension on MyUserEvent {
  /// Constructs a new [PoolEntry] from this [MyUserEvent].
  PoolEntry? toPoolEntry([Future<void> Function()? handler]) {
    return switch (kind) {
      MyUserEventKind.userMuted => PoolEntry(handler,
          type: EventType.myUserMuteChatsToggled,
          key: EventType.myUserMuteChatsToggled.hashCode,
          propsHash: Object.hash(
            EventType.myUserMuteChatsToggled,
            true,
          )),
      MyUserEventKind.unmuted => PoolEntry(handler,
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

/// Extension adding [PoolEntry] construction from a [ChatEvent].
extension ChatEventToPoolEntryExtension on ChatEvent {
  /// Constructs a new [PoolEntry] from this [ChatEvent].
  PoolEntry? toPoolEntry([Future<void> Function()? handler]) {
    return switch (kind) {
      ChatEventKind.favorited => PoolEntry(handler,
          type: EventType.chatFavoriteToggled,
          key: Object.hash(EventType.chatFavoriteToggled, chatId),
          propsHash: Object.hash(
            EventType.chatFavoriteToggled,
            chatId,
            true,
          )),
      ChatEventKind.unfavorited => PoolEntry(handler,
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
