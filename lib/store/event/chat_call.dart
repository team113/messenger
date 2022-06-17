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

import '../model/chat_item.dart';
import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';

/// Tag representing a [ChatCallEvent] kind.
enum ChatCallEventKind {
  callMoved,
  declined,
  finished,
  handLowered,
  handRaised,
  memberJoined,
  memberLeft,
  roomReady,
}

/// Tag representing a [ChatCallEvents] kind.
enum ChatCallEventsKind {
  initialized,
  chatCall,
  event,
}

/// [ChatCall] event union.
abstract class ChatCallEvents {
  const ChatCallEvents();

  /// [ChatCallEventKind] of this event.
  ChatCallEventsKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class ChatCallEventsInitialized extends ChatCallEvents {
  const ChatCallEventsInitialized();

  @override
  ChatCallEventsKind get kind => ChatCallEventsKind.initialized;
}

/// Initial state of the [ChatCall].
class ChatCallEventsChatCall extends ChatCallEvents {
  const ChatCallEventsChatCall(this.call, this.ver);

  /// Initial state itself.
  final ChatCall call;

  /// Initial [ChatItemVersion] of the [ChatCall].
  final ChatItemVersion ver;

  @override
  ChatCallEventsKind get kind => ChatCallEventsKind.chatCall;
}

/// [CallEventsVersioned] happening in the [ChatCall].
class ChatCallEventsEvent extends ChatCallEvents {
  const ChatCallEventsEvent(this.event);

  /// [CallEventsVersioned] itself.
  final CallEventsVersioned event;

  @override
  ChatCallEventsKind get kind => ChatCallEventsKind.event;
}

/// [ChatCallEvent]s accompanied by the corresponding [ChatItemVersion].
class CallEventsVersioned {
  const CallEventsVersioned(this.events, this.ver);

  /// [ChatCallEvent]s itself.
  final List<ChatCallEvent> events;

  /// Version of the [ChatCall]'s state updated by this [ChatCallEvent].
  final ChatItemVersion ver;
}

/// Event happening in a [ChatCall].
abstract class ChatCallEvent {
  const ChatCallEvent(this.callId, this.chatId, this.at);

  /// ID of the [ChatCall] this [ChatCallEvent] is related to.
  final ChatItemId callId;

  /// ID of the [Chat] this [ChatCallEvent] is happened in.
  final ChatId chatId;

  /// [PreciseDateTime] when this [ChatCallEvent] happened.
  final PreciseDateTime at;

  /// [ChatCallEventKind] of this event.
  ChatCallEventKind get kind;
}

/// Event of a [ChatCall] being finished.
class EventChatCallFinished extends ChatCallEvent {
  const EventChatCallFinished(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.reason,
  ) : super(callId, chatId, at);

  /// Finished [ChatCall].
  final ChatCall call;

  /// Reason of why the [ChatCall] was finished.
  final ChatCallFinishReason reason;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.finished;
}

/// Event of a media server room being ready to accept the connection from
/// [MyUser].
///
/// Client side should connect to a media server when this event is received.
/// Use [joinLink] to reach the media server and the [ChatCallCredentials] to
/// authenticate. Otherwise, the authenticated [MyUser] will be kicked from the
/// [ChatCall] by timeout.
class EventChatCallRoomReady extends ChatCallEvent {
  const EventChatCallRoomReady(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.joinLink,
  ) : super(callId, chatId, at);

  /// Link for joining the room on a media server.
  final ChatCallRoomJoinLink joinLink;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.roomReady;
}

/// Event of a [User] leaving a [ChatCall].
class EventChatCallMemberLeft extends ChatCallEvent {
  const EventChatCallMemberLeft(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.user,
  ) : super(callId, chatId, at);

  /// Left [ChatCall].
  final ChatCall call;

  /// [User] who left the [ChatCall].
  final User user;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.memberLeft;
}

/// Event of a [User] joined a [ChatCall].
class EventChatCallMemberJoined extends ChatCallEvent {
  const EventChatCallMemberJoined(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.user,
  ) : super(callId, chatId, at);

  /// Joined [ChatCall].
  final ChatCall call;

  /// [User] who joined the [ChatCall].
  final User user;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.memberJoined;
}

/// Event of a [ChatMember]'s hand being lowered in a [ChatCall].
class EventChatCallHandLowered extends ChatCallEvent {
  const EventChatCallHandLowered(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.user,
  ) : super(callId, chatId, at);

  /// [ChatCall] the [ChatMember]'s hand being lowered in.
  final ChatCall call;

  /// [User] representing the [ChatMember] who lowered a hand in the [ChatCall].
  final User user;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.handLowered;
}

/// Event of a [ChatCall] being moved from its [Chat]-dialog to a newly created
/// [Chat]-group.
class EventChatCallMoved extends ChatCallEvent {
  const EventChatCallMoved(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.user,
    this.newChatId,
    this.newChat,
    this.newCallId,
    this.newCall,
  ) : super(callId, chatId, at);

  /// Moved [ChatCall] in the [Chat]-dialog.
  final ChatCall call;

  /// [User] who moved the [ChatCall].
  final User user;

  /// ID of the newly created [Chat]-group the [ChatCall] was moved to.
  final ChatId newChatId;

  /// Newly created [Chat]-group the [ChatCall] was moved to.
  final Chat newChat;

  /// ID of the moved [ChatCall] in the newly created [Chat]-group.
  final ChatItemId newCallId;

  /// Moved [ChatCall] in the newly created [Chat]-group.
  final ChatCall newCall;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.callMoved;
}

/// Event of a [ChatMember]'s hand being raised in a [ChatCall].
class EventChatCallHandRaised extends ChatCallEvent {
  const EventChatCallHandRaised(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.user,
  ) : super(callId, chatId, at);

  /// [ChatCall] the [ChatMember]'s hand being raised in.
  final ChatCall call;

  /// [User] representing the [ChatMember] who raised a hand in the [ChatCall].
  final User user;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.handRaised;
}

/// Event of a [ChatCall] being declined by a [ChatMember].
class EventChatCallDeclined extends ChatCallEvent {
  const EventChatCallDeclined(
    ChatItemId callId,
    ChatId chatId,
    PreciseDateTime at,
    this.call,
    this.user,
  ) : super(callId, chatId, at);

  /// Declined [ChatCall].
  final ChatCall call;

  /// [User] who declined the [ChatCall].
  final User user;

  @override
  ChatCallEventKind get kind => ChatCallEventKind.declined;
}
