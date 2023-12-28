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

import 'dart:math';

import 'package:get/get.dart';
import 'package:messenger/store/event/chat.dart';
import 'package:messenger/util/log.dart';
import 'package:mutex/mutex.dart';

import '../store/event/my_user.dart';

EventPool eventPool = EventPool();

// Tracker for optimistic events.
class EventPool {
  /// Registred handlers for one-to-one call syncrously
  final Map<int, Mutex> _locks = {};
  // TODO: remove lock on handlers queue empty

  /// Events should be ignored when resieved from back
  final Map<int, List<OptimisticEventPoolEntry>> _ignorance = {};

  /// Events should be neutralized with same type events
  final Map<int, OptimisticEventPoolEntry> _neutralize = {};

  /// Adds event to pool.
  ///
  /// [event.handler] would be called when handlers of other events with same
  /// [OptimisticEventType] would be awaited.
  void add(
    OptimisticEventPoolEntry event,
  ) {
    switch (event.type.mode) {
      case OptimisticEventMode.queue:
        {
          Future<dynamic> queueWrapper(OptimisticEventPoolEntry event) async {
            _ignorance[event.key] ??= [];
            _ignorance[event.key]!.add(event);

            // TODO: error handling
            await event.handler?.call();
          }

          final lock = _getLock(event.key);
          lock.protect(
            () async {
              await queueWrapper(event);
            },
          );
        }
      case OptimisticEventMode.neutralize:
        {
          Future<dynamic> neutralizeWrapper(
              OptimisticEventPoolEntry event) async {
            if (_neutralize[event.key] != event) {
              return;
            }
            _neutralize.remove(event.key);
            _ignorance[event.key] ??= [];
            _ignorance[event.key]!.add(event);

            // TODO: error handling
            await event.handler?.call();
          }

          if (_neutralize[event.key] != null) {
            if (!same(_neutralize[event.key]!, event)) {
              _neutralize.remove(event.key);
            } else {
              // No-op
            }
          } else {
            final lock = _getLock(event.key);
            _neutralize[event.key] = event;
            lock.protect(
              () async {
                await neutralizeWrapper(event);
              },
            );
          }
        }
      case OptimisticEventMode.skip:
        {
          /// No-op.
        }
    }
  }

  /// Returns true if same event exist waiting for ignorance.
  ///
  /// Deletes ignored events from pool
  bool ignore(OptimisticEventPoolEntry event) {
    final OptimisticEventPoolEntry? waiter = _ignorance[event.key]
        ?.firstWhereOrNull((element) => same(event, element));

    if (waiter != null) {
      Log.info('--ignored(${event.sourceEvent})', '$runtimeType');
      _ignorance[event.key]!.remove(waiter);
      return true;
    }

    return false;
  }

  Mutex _getLock(int key) {
    _locks[key] ??= Mutex();
    return _locks[key]!;
  }

  bool same(OptimisticEventPoolEntry e1, OptimisticEventPoolEntry e2) {
    if (e1.type != e2.type) return false;
    return (e1.hash != e2.hash);
  }
}

/// Types of [OptimisticEvent] event kinds
enum OptimisticEventType {
  myUserMuteChatsToggled,
  chatFavoriteToggled,
  noSupporting;

  OptimisticEventMode get mode => switch (this) {
        myUserMuteChatsToggled => OptimisticEventMode.neutralize,
        chatFavoriteToggled => OptimisticEventMode.neutralize,
        noSupporting => OptimisticEventMode.skip,
      };
}

/// Mode of [OptimisticEvent] processing.
enum OptimisticEventMode {
  queue,
  neutralize,
  skip;
}

class OptimisticEventPoolEntry {
  final dynamic sourceEvent;
  final Future<void> Function()? handler;
  final OptimisticEventType type;
  final int key;
  final int hash;
  OptimisticEventPoolEntry(
      {required this.key,
      required this.hash,
      required this.sourceEvent,
      required this.handler,
      required this.type});
}

extension MyUserEventOptimisticEventPoolEntryExtension on MyUserEvent {
  OptimisticEventPoolEntry toPoolEntry([Future<void> Function()? handler]) {
    return OptimisticEventPoolEntry(
        sourceEvent: this,
        handler: handler,
        type: eventType(),
        key: eventKey(),
        hash: eventHash());
  }

  /// Returns [OptimisticEventType] of event [kind], if event [kind] is supporting.
  OptimisticEventType eventType() {
    return switch (kind) {
      MyUserEventKind.userMuted => OptimisticEventType.myUserMuteChatsToggled,
      MyUserEventKind.unmuted => OptimisticEventType.myUserMuteChatsToggled,
      _ => OptimisticEventType.noSupporting,
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

extension ChatEventOptimisticEventPoolEntryExtension on ChatEvent {
  OptimisticEventPoolEntry toPoolEntry([Future<void> Function()? handler]) {
    return OptimisticEventPoolEntry(
        sourceEvent: this,
        handler: handler,
        type: eventType(),
        key: eventKey(),
        hash: eventHash());
  }

  /// Returns [OptimisticEventType] of event [kind], if event [kind] is supporting.
  OptimisticEventType eventType() {
    return switch (kind) {
      ChatEventKind.favorited => OptimisticEventType.chatFavoriteToggled,
      ChatEventKind.unfavorited => OptimisticEventType.chatFavoriteToggled,
      _ => OptimisticEventType.noSupporting,
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
