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

import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/api/backend/extension/call.dart';
import 'package:messenger/api/backend/extension/user.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/store/event/chat_call.dart';
import 'package:uuid/uuid.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Accepts call by provided user in the currently opened [Chat].
///
/// Examples:
/// - Then Bob accept call
final StepDefinitionGeneric userJoinCall = and1<TestUser, CustomWorld>(
  '{user} accept call',
  (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    var ongoingCall = OngoingCall(
      ChatId(router.route.split('/').last),
      customUser.userId,
      withAudio: false,
      withVideo: false,
      withScreen: false,
      creds: ChatCallCredentials(const Uuid().v4()),
      state: OngoingCallState.joining,
    );

    var response = await provider.joinChatCall(
      ongoingCall.chatId.value,
      ongoingCall.creds!,
    );

    ongoingCall.deviceId = response.deviceId;
    var chatCall = _chatCall(response.event);
    ongoingCall.call.value = chatCall!;

    await ongoingCall.init(customUser.userId);

    await ongoingCall.connect(
        Get.find(), CallHeartbeat(provider, customUser.userId));

    customUser.call = ongoingCall;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Decline call by provided user in the currently opened [Chat].
///
/// Examples:
/// - Then Bob decline call
final StepDefinitionGeneric userDeclineCall = and1<TestUser, CustomWorld>(
  '{user} decline call',
  (TestUser user, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]!.session.token;

    await provider.declineChatCall(ChatId(router.route.split('/').last));
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Starts call by provided user in the currently opened [Chat].
///
/// Examples:
/// - Then Bob start call
final StepDefinitionGeneric userStartCall = and1<TestUser, CustomWorld>(
  '{user} start call',
  (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    var ongoingCall = OngoingCall(
      ChatId(router.route.split('/').last),
      customUser.userId,
      withAudio: false,
      withVideo: false,
      withScreen: false,
      creds: ChatCallCredentials(const Uuid().v4()),
      state: OngoingCallState.joining,
    );

    var response = await provider.startChatCall(
      ongoingCall.chatId.value,
      ongoingCall.creds!,
    );

    ongoingCall.deviceId = response.deviceId;
    var chatCall = _chatCall(response.event);
    ongoingCall.call.value = chatCall!;

    await ongoingCall.init(customUser.userId);

    await ongoingCall.connect(
        Get.find(), CallHeartbeat(provider, customUser.userId));

    customUser.call = ongoingCall;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Ends call by provided user in the currently opened [Chat].
///
/// Examples:
/// - Then Bob leave call
final StepDefinitionGeneric userEndCall = and1<TestUser, CustomWorld>(
  '{user} leave call',
      (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    await provider.leaveChatCall(
      customUser.call!.chatId.value,
      customUser.call!.deviceId!,
    );
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Constructs a [ChatCall] from the [ChatEventsVersionedMixin].
ChatCall? _chatCall(ChatEventsVersionedMixin? m) {
  for (ChatEventsVersionedMixin$Events e in m?.events ?? []) {
    if (e.$$typename == 'EventChatCallStarted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallStarted;

      return node.call.toModel();
    } else if (e.$$typename == 'EventChatCallMemberJoined') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
      return node.call.toModel();
    }
  }

  return null;
}

class CallHeartbeat implements AbstractCallHeartbeat {
  CallHeartbeat(this._graphQlProvider, this._me);

  final GraphQlProvider _graphQlProvider;

  final UserId _me;

  @override
  UserId get me => _me;

  @override
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
