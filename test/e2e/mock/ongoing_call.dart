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

import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/media_settings.dart';
import 'package:messenger/domain/model/ongoing_call.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/provider/gql/exceptions.dart';
import 'package:messenger/store/event/chat_call.dart';

/// [OngoingCall] mock.
class OngoingCallMock extends OngoingCall {
  OngoingCallMock(
    ChatId chatId,
    UserId me, {
    ChatCall? call,
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
    MediaSettings? mediaSettings,
    OngoingCallState state = OngoingCallState.pending,
    ChatCallCredentials? creds,
    ChatCallDeviceId? deviceId,
  }) : super(
          chatId,
          me,
          call: call,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
          mediaSettings: mediaSettings,
          state: state,
          creds: creds,
          deviceId: deviceId,
        );

  /// Heartbeat subscription indicating that [MyUser] is connected and this
  /// [OngoingCall] is alive on a client side.
  StreamSubscription? _heartbeat;

  @override
  Future<void> connect(CallService calls, Heartbeat heartbeat) async {
    if (connected || callChatItemId == null || deviceId == null) {
      return;
    }

    connected = true;
    _heartbeat?.cancel();
    _heartbeat = (await heartbeat(callChatItemId!, deviceId!)).listen(
      (e) async {
        switch (e.kind) {
          case ChatCallEventsKind.initialized:
            // No-op.
            break;

          case ChatCallEventsKind.chatCall:
            var node = e as ChatCallEventsChatCall;

            call.value = node.call;
            call.refresh();

            if (node.call.finishReason == null) {
              if (state.value == OngoingCallState.local) {
                state.value = node.call.conversationStartedAt == null
                    ? OngoingCallState.pending
                    : OngoingCallState.joining;
              }

              if (node.call.joinLink != null) {
                print('mock room join 1');
                await room
                    ?.join('${node.call.joinLink}/$me.$deviceId?token=$creds');
                state.value = OngoingCallState.active;
              }
            }
            break;

          case ChatCallEventsKind.event:
            var versioned = (e as ChatCallEventsEvent).event;
            for (var event in versioned.events) {
              switch (event.kind) {
                case ChatCallEventKind.roomReady:
                  var node = event as EventChatCallRoomReady;

                  call.value?.joinLink = node.joinLink;
                  call.refresh();

                  print('mock room join 2');
                  await room
                      ?.join('${node.joinLink}/$me.$deviceId?token=$creds');
                  state.value = OngoingCallState.active;
                  break;

                case ChatCallEventKind.finished:
                  break;

                case ChatCallEventKind.memberLeft:
                  break;

                case ChatCallEventKind.memberJoined:
                  break;

                case ChatCallEventKind.handLowered:
                  var node = event as EventChatCallHandLowered;
                  for (var m in members.entries
                      .where((e) => e.key.userId == node.user.id)) {
                    members[m.key] = false;
                  }
                  break;

                case ChatCallEventKind.handRaised:
                  var node = event as EventChatCallHandRaised;
                  for (var m in members.entries
                      .where((e) => e.key.userId == node.user.id)) {
                    members[m.key] = true;
                  }
                  break;

                case ChatCallEventKind.declined:
                  // TODO: Implement EventChatCallDeclined.
                  break;

                case ChatCallEventKind.callMoved:
                  var node = event as EventChatCallMoved;
                  chatId.value = node.newChatId;
                  call.value = node.newCall;

                  connected = false;
                  connect(calls, heartbeat);

                  calls.moveCall(node.chatId, node.newChatId);
                  break;
              }
            }
            break;
        }
      },
      onError: (e) {
        if (e is ResubscriptionRequiredException) {
          connected = false;
          connect(calls, heartbeat);
        } else {
          throw e;
        }
      },
    );
  }
}
