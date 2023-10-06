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
import 'package:messenger/api/backend/extension/call.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:uuid/uuid.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Accepts incoming call by the provided [TestUser].
///
/// Examples:
/// - When Bob accepts call
final StepDefinitionGeneric userJoinCall = when1<TestUser, CustomWorld>(
  '{user} accepts call',
  (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    await Future.delayed(1.seconds);
    var incomingCall = (await provider.incomingCalls()).nodes.first;
    var creds = ChatCallCredentials(const Uuid().v4());

    var response = await provider.joinChatCall(incomingCall.chatId, creds);

    ChatCall? chatCall = _chatCall(response.event);
    Call call = Call(
      chatCall!,
      incomingCall.chatId,
      response.deviceId,
      creds,
      provider,
    );

    await call.connect();
    customUser.call = call;
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Declines incoming call by the provided [TestUser].
///
/// Examples:
/// - When Bob declines call
final StepDefinitionGeneric userDeclineCall = when1<TestUser, CustomWorld>(
  '{user} declines call',
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

/// Starts call by the provided [TestUser] in the dialog with the provided
/// [TestUser].
///
/// Examples:
/// - When Bob starts call in dialog with me
/// - When Bob starts call in dialog with Charlie
final StepDefinitionGeneric userStartCallInDialog =
    when2<TestUser, TestUser, CustomWorld>(
  '{user} starts call in dialog with {user}',
  (TestUser user, TestUser withUser, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    customUser.call = await _startCall(
      provider,
      customUser.userId,
      customUser.dialogs[withUser]!,
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Starts call by the provided [TestUser] in the group with the provided name.
///
/// Examples:
/// - When Bob starts call in "Name" group
/// - When Charlie starts call in "Name" group
final StepDefinitionGeneric userStartCallInGroup =
    when2<TestUser, String, CustomWorld>(
  '{user} starts call in {string} group',
  (TestUser user, String name, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    customUser.call = await _startCall(
      provider,
      customUser.userId,
      customUser.groups[name]!,
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Ends active call by the provided [TestUser].
///
/// Examples:
/// - When Bob leaves call
/// - When Charlie cancels call
final StepDefinitionGeneric userEndCall = when1<TestUser, CustomWorld>(
  RegExp(r'{user} (?:leaves|cancels) call$'),
  (TestUser user, context) async {
    CustomUser customUser = context.world.sessions[user.name]!;
    final provider = GraphQlProvider();
    provider.token = customUser.session.token;

    await provider.leaveChatCall(
      customUser.call!.chatId,
      customUser.call!.deviceId,
    );
    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Starts [ChatCall] by the [User] with the provided [UserId] in the [Chat]
/// with the provided [ChatId].
Future<Call> _startCall(
  GraphQlProvider provider,
  UserId byUser,
  ChatId chatId,
) async {
  var creds = ChatCallCredentials(const Uuid().v4());
  var response = await provider.startChatCall(chatId, creds, false);

  ChatCall? chatCall = _chatCall(response.event);
  Call call = Call(chatCall!, chatId, response.deviceId, creds, provider);

  await call.connect();

  return call;
}

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
