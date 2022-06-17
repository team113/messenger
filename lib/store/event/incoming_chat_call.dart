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

import '/domain/model/chat_call.dart';

/// Possible kinds of an [IncomingChatCallsTopEvent].
enum IncomingChatCallsTopEventKind {
  initialized,
  list,
  added,
  removed,
}

/// Event indicating changes in an ongoing [ChatCall]s list.
abstract class IncomingChatCallsTopEvent {
  const IncomingChatCallsTopEvent();

  /// [IncomingChatCallsTopEventKind] of this event.
  IncomingChatCallsTopEventKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class IncomingChatCallsTopInitialized extends IncomingChatCallsTopEvent {
  const IncomingChatCallsTopInitialized();

  @override
  IncomingChatCallsTopEventKind get kind =>
      IncomingChatCallsTopEventKind.initialized;
}

/// Initial top of incoming [ChatCall]s list.
class IncomingChatCallsTop extends IncomingChatCallsTopEvent {
  const IncomingChatCallsTop(this.list);

  /// List of top incoming [ChatCall]s.
  final List<ChatCall> list;

  @override
  IncomingChatCallsTopEventKind get kind => IncomingChatCallsTopEventKind.list;
}

/// Event of a [ChatCall] being added to an ongoing list.
class EventIncomingChatCallsTopChatCallAdded extends IncomingChatCallsTopEvent {
  const EventIncomingChatCallsTopChatCallAdded(this.call);

  /// Added [ChatCall].
  final ChatCall call;

  @override
  IncomingChatCallsTopEventKind get kind => IncomingChatCallsTopEventKind.added;
}

/// Event of a [ChatCall] being removed from an ongoing list.
class EventIncomingChatCallsTopChatCallRemoved
    extends IncomingChatCallsTopEvent {
  const EventIncomingChatCallsTopChatCallRemoved(this.call);

  /// Removed [ChatCall].
  final ChatCall call;

  @override
  IncomingChatCallsTopEventKind get kind =>
      IncomingChatCallsTopEventKind.removed;
}
