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
  /// [_EventType] would be awaited.
  void add(
    PoolEntry event,
  ) {
    _debugLog('_adding', event);
    switch (event.type.mode) {
      case _EventMode.queue:
        {
          final lock = _getLock(event.key);
          lock.protect(
            () async {
              await _queueWrapper(event);
            },
          );
        }
      case _EventMode.neutralize:
        {
          if (_neutralize[event.key] != null) {
            if (!_same(_neutralize[event.key]!, event)) {
              _debugLog('neutralized', event);
              _neutralize.remove(event.key);
            } else {
              // No-op
            }
          } else {
            final lock = _getLock(event.key);
            _neutralize[event.key] = event;
            lock.protect(
              () async {
                await _neutralizeWrapper(event);
              },
            );
          }
        }
      case _EventMode.skip:
        {
          /// No-op.
        }
    }
  }

  /// Returns true if same event exist waiting for ignorance.
  ///
  /// Deletes ignored events from pool
  bool ignore(PoolEntry event) {
    final PoolEntry? waiter = _ignorance[event.key]
        ?.firstWhereOrNull((element) => _same(event, element));

    if (waiter != null) {
      _debugLog('ignored', event);
      _ignorance[event.key]!.remove(waiter);
      return true;
    }
    _debugLog('NOT ignored', event);
    return false;
  }

  Mutex _getLock(int key) {
    _locks[key] ??= Mutex();
    return _locks[key]!;
  }

  bool _same(PoolEntry e1, PoolEntry e2) {
    if (e1.type != e2.type) return false;
    return (e1.hash == e2.hash);
  }

  Future<dynamic> _queueWrapper(PoolEntry event) async {
    _ignorance[event.key] ??= [];
    _ignorance[event.key]!.add(event);

    // TODO: error handling
    await event.handler?.call();
  }

  Future<dynamic> _neutralizeWrapper(PoolEntry event) async {
    if (_neutralize[event.key] != event) {
      return;
    }
    _neutralize.remove(event.key);
    _ignorance[event.key] ??= [];
    _ignorance[event.key]!.add(event);

    await Future.delayed(const Duration(seconds: 3));

    // TODO: error handling
    await event.handler?.call();
  }
}

/// Types of event
enum _EventType {
  myUserMuteChatsToggled,
  chatFavoriteToggled,
  noSupporting;

  _EventMode get mode => switch (this) {
        myUserMuteChatsToggled => _EventMode.neutralize,
        chatFavoriteToggled => _EventMode.neutralize,
        noSupporting => _EventMode.skip,
      };
}

/// Modes of [_EventType] processing.
enum _EventMode {
  queue,
  neutralize,
  skip;
}

class PoolEntry {
  final dynamic sourceEvent;
  final Future<void> Function()? handler;
  final _EventType type;
  final int key;
  final int hash;
  PoolEntry(
      {required this.key,
      required this.hash,
      required this.sourceEvent,
      required this.handler,
      required this.type});
}

extension MyUserEventToPoolEntryExtension on MyUserEvent {
  PoolEntry toPoolEntry([Future<void> Function()? handler]) {
    return PoolEntry(
        sourceEvent: this,
        handler: handler,
        type: eventType(),
        key: eventKey(),
        hash: eventHash());
  }

  /// Returns [_EventType] of event [kind], if event [kind] is supporting.
  _EventType eventType() {
    return switch (kind) {
      MyUserEventKind.userMuted => _EventType.myUserMuteChatsToggled,
      MyUserEventKind.unmuted => _EventType.myUserMuteChatsToggled,
      _ => _EventType.noSupporting,
    };
  }

  int eventKey() {
    return switch (kind) {
      MyUserEventKind.userMuted => eventType().hashCode,
      MyUserEventKind.unmuted => eventType().hashCode,
      _ => 0,
    };
  }

  int eventHash() {
    return switch (kind) {
      MyUserEventKind.userMuted => Object.hash(eventType(), true),
      MyUserEventKind.unmuted => Object.hash(eventType(), false),
      _ => 0,
    };
  }
}

extension ChatEventToPoolEntryExtension on ChatEvent {
  PoolEntry toPoolEntry([Future<void> Function()? handler]) {
    return PoolEntry(
        sourceEvent: this,
        handler: handler,
        type: eventType(),
        key: eventKey(),
        hash: eventHash());
  }

  /// Returns [_EventType] of event [kind], if event [kind] is supporting.
  _EventType eventType() {
    return switch (kind) {
      ChatEventKind.favorited => _EventType.chatFavoriteToggled,
      ChatEventKind.unfavorited => _EventType.chatFavoriteToggled,
      _ => _EventType.noSupporting,
    };
  }

  int eventKey() {
    return switch (kind) {
      ChatEventKind.favorited => Object.hash(eventType(), chatId),
      ChatEventKind.unfavorited => Object.hash(eventType(), chatId),
      _ => 0,
    };
  }

  int eventHash() {
    return switch (kind) {
      ChatEventKind.favorited => Object.hash(eventKey(), true),
      ChatEventKind.unfavorited => Object.hash(eventKey(), false),
      _ => 0,
    };
  }
}

void _debugLog(String message, PoolEntry event) {
  Log.info('--$message(${event.key} ${event.hash})', '${event.sourceEvent}');
}
