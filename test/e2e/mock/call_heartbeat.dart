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

import 'dart:async';

import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/api/backend/extension/call.dart';
import 'package:messenger/api/backend/extension/user.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/store/event/chat_call.dart';

/// Get access to mocked call heartbeat.
class CallHeartbeatMock {
  CallHeartbeatMock(this._graphQlProvider);

  final GraphQlProvider _graphQlProvider;

  Future<Stream<ChatCallEvents>> heartbeat(
      ChatItemId id, ChatCallDeviceId deviceId) async {
    return (await _graphQlProvider.callEvents(id, deviceId))
        .asyncExpand((event) async* {
      GraphQlProviderExceptions.fire(event);
      var events = CallEvents$Subscription.fromJson(event.data!).chatCallEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const ChatCallEventsInitialized();
      } else if (events.$$typename == 'ChatCall') {
        var call = events as CallEvents$Subscription$ChatCallEvents$ChatCall;
        yield ChatCallEventsChatCall(call.toModel(), call.ver);
      } else if (events.$$typename == 'ChatCallEventsVersioned') {
        var mixin = events as ChatCallEventsVersionedMixin;
        yield ChatCallEventsEvent(
          CallEventsVersioned(
            mixin.events.map((e) => _callEvent(e)).toList(),
            mixin.ver,
          ),
        );
      }
    });
  }

  /// Constructs a [ChatCallEvent] from [ChatCallEventsVersionedMixin$Event].
  ChatCallEvent _callEvent(ChatCallEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventChatCallFinished') {
      var node = e as ChatCallEventsVersionedMixin$Events$EventChatCallFinished;

      return EventChatCallFinished(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.reason,
      );
    } else if (e.$$typename == 'EventChatCallRoomReady') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallRoomReady;
      return EventChatCallRoomReady(
        node.callId,
        node.chatId,
        node.at,
        node.joinLink,
      );
    } else if (e.$$typename == 'EventChatCallMemberLeft') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberLeft;

      return EventChatCallMemberLeft(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMemberJoined') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberJoined;

      return EventChatCallMemberJoined(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallHandLowered') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandLowered;

      return EventChatCallHandLowered(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMoved') {
      var node = e as ChatCallEventsVersionedMixin$Events$EventChatCallMoved;

      return EventChatCallMoved(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
        node.newChatId,
        node.newChat.toModel(),
        node.newCallId,
        node.newCall.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallHandRaised') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandRaised;

      return EventChatCallHandRaised(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallDeclined') {
      var node = e as ChatCallEventsVersionedMixin$Events$EventChatCallDeclined;

      return EventChatCallDeclined(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else {
      throw UnimplementedError('Unknown ChatCallEvent: ${e.$$typename}');
    }
  }
}
