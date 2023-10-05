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

import 'dart:async';

import 'package:flutter/services.dart' show ClipboardData;
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:medea_jason/medea_jason.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_call.dart';
import 'package:messenger/domain/model/contact.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/provider/gql/graphql.dart';

import '../parameters/users.dart';

/// [FlutterWidgetTesterWorld] storing a custom state during a single test.
class CustomWorld extends FlutterWidgetTesterWorld {
  /// [Map] of [Session]s simulating [User]s identified by their names.
  final Map<String, CustomUser> sessions = {};

  /// [Map] of group [Chat]s identified by their names.
  final Map<String, ChatId> groups = {};

  /// [Map] of [ChatContact]s identified by their names.
  final Map<String, ChatContactId> contacts = {};

  /// [ClipboardData] currently stored in this [CustomWorld].
  ClipboardData? clipboard;

  /// [UserId] of the currently authenticated [MyUser].
  UserId? me;

  @override
  void dispose() {
    for (var session in sessions.values) {
      session.call?.dispose();
    }

    super.dispose();
  }
}

/// [Session] with some additional info about the [User] it represents.
class CustomUser {
  CustomUser(this.session, this.userId, this.userNum);

  /// [Session] of this [CustomUser].
  final Session session;

  /// [UserId] of this [CustomUser].
  final UserId userId;

  /// [UserNum] of this [CustomUser].
  final UserNum userNum;

  /// Map of the dialogs this [CustomUser] is a member.
  Map<TestUser, ChatId> dialogs = {};

  /// Map of the groups this [CustomUser] is a member.
  Map<String, ChatId> groups = {};

  /// Current [Call] this [CustomUser] participates in.
  Call? call;
}

/// Ongoing [ChatCall] in a [Chat].
class Call {
  Call(this.chatCall, this.chatId, this.deviceId, this.creds);

  /// [ChatCall] associated with this [Call].
  ChatCall chatCall;

  /// One-time secret credentials to authenticate with on a media server.
  ChatCallCredentials? creds;

  /// ID of the [Chat] this [Call] takes place in.
  final ChatId chatId;

  /// ID of the device this [Call] is taking place on.
  final ChatCallDeviceId deviceId;

  /// [Jason] instance of this [Call].
  Jason? jason;

  /// Room on a media server.
  RoomHandle? room;

  /// [StreamSubscription] to the call events.
  StreamSubscription? eventsSubscription;

  /// Disposes this [Call].
  dispose() {
    if (room != null) {
      try {
        jason?.closeRoom(room!);
        room?.free();
      } catch (_) {}
    }
    jason?.free();
    eventsSubscription?.cancel();
  }

  /// Starts the call events subscription.
  Future<void> connect(GraphQlProvider provider) async {
    jason = Jason();
    room = jason!.initRoom();

    room!.onFailedLocalMedia((p0) {});
    room!.onConnectionLoss((p0) {});
    room!.onNewConnection((p0) {});

    if (chatCall.joinLink != null) {
      await room!.join('${chatCall.joinLink}?token=$creds');
    }

    eventsSubscription =
        provider.callEvents(chatCall.id, deviceId).listen((event) async {
      var events = CallEvents$Subscription.fromJson(event.data!).chatCallEvents;

      if (events.$$typename == 'ChatCallEventsVersioned') {
        var mixin = events as ChatCallEventsVersionedMixin;

        for (var e in mixin.events) {
          if (e.$$typename == 'EventChatCallRoomReady') {
            var node =
                e as ChatCallEventsVersionedMixin$Events$EventChatCallRoomReady;
            await room!.join('${node.joinLink}?token=$creds');
          } else if (e.$$typename == 'ChatCall') {
            var call = e as CallEvents$Subscription$ChatCallEvents$ChatCall;
            if (call.joinLink != null) {
              await room!.join('${call.joinLink}?token=$creds');
            }
          }
        }
      }
    });

    await room!.disableVideo(MediaSourceKind.device);
    await room!.disableVideo(MediaSourceKind.display);
    await room!.disableAudio();
  }
}
