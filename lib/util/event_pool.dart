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

EventPool eventPool = EventPool();

// Tracker for optimistic events.
class EventPool {
  /// Registred handlers for one-to-one call syncrously
  Map<OptimisticEventType, Mutex> _locks = {};

  /// Events should be ignored when resieved from back
  Map<OptimisticEventType, List<OptimisticEventPoolEntry>> _ignorance = {};

  /// Events should be neutralized with same type events
  Map<OptimisticEventType, OptimisticEventPoolEntry> _neutralize = {};

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
            _ignorance[event.type] ??= [];
            _ignorance[event.type]!.add(event);

            await event.handler?.call();
          }

          final lock = _getLock(event.type);
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
            if (_neutralize[event.type] != event) {
              return;
            }
            await event.handler?.call();
          }

          if (_neutralize[event.type] != null) {
            if (!same(_neutralize[event.type]!, event)) {
              _neutralize.remove(event.type);
            } else {
              // No-op
            }
          } else {
            final lock = _getLock(event.type);
            _neutralize[event.type] = event;
            lock.protect(
              () async {
                await neutralizeWrapper(event);
              },
            );
          }
          _ignorance[event.type] ??= [];
          _ignorance[event.type]!.add(event);
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
    final OptimisticEventPoolEntry? waiter = _ignorance[event.type]
        ?.firstWhereOrNull((element) => same(event, element));

    if (waiter != null) {
      _ignorance[event.type]!.remove(waiter);
      return true;
    }

    return false;
  }

  Mutex _getLock(OptimisticEventType type) {
    _locks[type] ??= Mutex();
    return _locks[type]!;
  }

  bool same(OptimisticEventPoolEntry e1, OptimisticEventPoolEntry e2) {
    final s1 = e1.sourceEvent;
    final s2 = e2.sourceEvent;
    if (s1 is MyUserEvent && s2 is MyUserEvent) {
      return s1.kind == s2.kind;
    }
    return false;
  }
}

/// Types of [OptimisticEvent] event kinds
enum OptimisticEventType {
  myUserToggleMute,
  noRegistred;

  OptimisticEventMode get mode => switch (this) {
        myUserToggleMute => OptimisticEventMode.neutralize,
        noRegistred => OptimisticEventMode.skip,
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

  OptimisticEventPoolEntry(
      {required this.sourceEvent, required this.handler, required this.type});
}

extension MyUserEventOptimisticEventPoolEntryExtension on MyUserEvent {
  /// Returns [OptimisticEventType] of event [kind], if event [kind] is displacable.
  static OptimisticEventType _fromMyUserKind(MyUserEventKind kind) {
    return switch (kind) {
      MyUserEventKind.userMuted => OptimisticEventType.myUserToggleMute,
      MyUserEventKind.unmuted => OptimisticEventType.myUserToggleMute,
      _ => OptimisticEventType.noRegistred,
    };
  }

  OptimisticEventPoolEntry toPoolEntry([Future<void> Function()? handler]) {
    return OptimisticEventPoolEntry(
        sourceEvent: this, handler: handler, type: _fromMyUserKind(kind));
  }
}
