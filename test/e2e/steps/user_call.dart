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
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/api/backend/extension/call.dart';
import 'package:uuid/uuid.dart';

import '../mock/call_heartbeat.dart';
import '../mock/ongoing_call.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Accepts incoming call by provided user.
///
/// Examples:
/// - Then Bob accept call
final StepDefinitionGeneric userJoinCall = and1<TestUser, CustomWorld>(
  '{user} accept call',
  (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    await Future.delayed(100.milliseconds);
    var incomingCalls = await provider.incomingCalls();
    var ongoingCall = OngoingCallMock(
      incomingCalls.nodes.first.chatId,
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
      Get.find(),
      CallHeartbeatMock(provider).heartbeat,
    );

    customUser.call = ongoingCall;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Decline incoming call by provided user.
///
/// Examples:
/// - Then Bob decline call
final StepDefinitionGeneric userDeclineCall = and1<TestUser, CustomWorld>(
  '{user} decline call',
  (TestUser user, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]!.session.token;

    var incomingCalls = await provider.incomingCalls();
    await provider.declineChatCall(incomingCalls.nodes.first.chatId);
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Starts call by provided user in [Chat] with the authenticated [MyUser].
///
/// Examples:
/// - Then Bob start call
final StepDefinitionGeneric userStartCall = and1<TestUser, CustomWorld>(
  '{user} start call',
  (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    var ongoingCall = OngoingCallMock(
      customUser.chat!,
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
      Get.find(),
      CallHeartbeatMock(provider).heartbeat,
    );

    customUser.call = ongoingCall;
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Ends active call by provided user.
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
