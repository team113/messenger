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
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/api/backend/extension/call.dart';
import 'package:uuid/uuid.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Accepts call
///
/// Examples:
/// - Then Bob sends "test.txt" attachment to me
final StepDefinitionGeneric userAcceptCall = and1<TestUser, CustomWorld>(
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
    print('test device id ${response.deviceId}');
    var chatCall = _chatCall(response.event);
    ongoingCall.call.value = chatCall!;

    await ongoingCall.init(customUser.userId);

    ongoingCall.connect(Get.find());

    customUser.call = ongoingCall;
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

class CallServiceMock extends CallService {
  CallServiceMock(AuthService authService,
      AbstractSettingsRepository settingsRepo, AbstractCallRepository callsRepo)
      : super(authService, settingsRepo, callsRepo);
}
