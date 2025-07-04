// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';

import '../model/chat.dart';
import '../model/chat_call.dart';
import '../model/chat_item.dart';
import '../model/my_user.dart';
import '../model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/store/event/chat_call.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';

/// [OngoingCall]s repository interface.
abstract class AbstractCallRepository {
  /// Map of the current [OngoingCall]s.
  RxObsMap<ChatId, Rx<OngoingCall>> get calls;

  /// Returns reactive [OngoingCall] if there's any identified by [chatId].
  Rx<OngoingCall>? operator [](ChatId chatId);

  /// Replaces the value of [OngoingCall] identified by [chatId] to [call].
  void operator []=(ChatId chatId, Rx<OngoingCall> call);

  /// Adds the provided [ChatCall] to the [calls], if not already.
  ///
  /// If [dontAddIfAccounted] is `true`, then this [call] won't be added if it
  /// was [add]ed by anything earlier, even if it's already gone.
  Future<Rx<OngoingCall>?> add(
    ChatCall call, {
    bool dontAddIfAccounted = false,
  });

  /// Transforms the provided [WebStoredCall] into an [OngoingCall] and adds it,
  /// if not already.
  Rx<OngoingCall> addStored(
    WebStoredCall stored, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  });

  /// Switches the [OngoingCall] identified by its [chatId] to the specified
  /// [newChatId].
  void move(ChatId chatId, ChatId newChatId);

  /// Ends an [OngoingCall] happening in the [Chat] identified by the provided
  /// [chatId].
  Rx<OngoingCall>? remove(ChatId chatId);

  /// Returns `true` if an [OngoingCall] identified by [chatId] exists in the
  /// [calls] map.
  bool contains(ChatId chatId);

  /// Starts a new [OngoingCall] in the specified [chatId] by the authenticated
  /// [MyUser].
  Future<Rx<OngoingCall>> start(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  });

  /// Joins the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<Rx<OngoingCall>?> join(
    ChatId chatId,
    ChatCall? call, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  });

  /// Leaves the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<void> leave(ChatId chatId, ChatCallDeviceId deviceId);

  /// Declines the current [OngoingCall] in the specified [chatId] by the
  /// authenticated [MyUser].
  Future<void> decline(ChatId chatId);

  /// Raises/lowers a hand of the authenticated [MyUser] in the specified
  /// [ChatCall].
  Future<void> toggleHand(ChatId chatId, bool raised);

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group, optionally adding new members.
  Future<void> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds,
    ChatName? groupName,
  );

  /// Redials a [User] who left or declined the ongoing [ChatCall] in the
  /// specified [Chat]-group by the authenticated [MyUser].
  Future<void> redialChatCallMember(ChatId chatId, UserId memberId);

  /// Removes the specified [User] from the [ChatCall] of the specified
  /// [Chat]-group by authority of the authenticated [MyUser].
  ///
  /// If the specified [User] participates in the [ChatCall] from multiple
  /// devices simultaneously, then removes all the devices at once.
  Future<void> removeChatCallMember(ChatId chatId, UserId userId);

  /// Generates the [ChatCallCredentials] for a [Chat] identified by the
  /// provided [chatId].
  ///
  /// These [ChatCallCredentials] are considered backup and should be linked to
  /// an [OngoingCall] by calling [transferCredentials] once its [ChatItemId] is
  /// acquired.
  Future<ChatCallCredentials> generateCredentials(ChatId chatId);

  /// Copies the [ChatCallCredentials] from the provided [Chat] and links them
  /// to the specified [OngoingCall].
  Future<void> transferCredentials(ChatId chatId, ChatItemId callId);

  /// Returns the [ChatCallCredentials] for an [OngoingCall] identified by the
  /// provided [callId].
  Future<ChatCallCredentials> getCredentials(ChatItemId callId);

  /// Moves the [ChatCallCredentials] from the [callId] to the [newCallId].
  Future<void> moveCredentials(
    ChatItemId callId,
    ChatItemId newCallId,
    ChatId chatId,
    ChatId newChatId,
  );

  /// Removes the [ChatCallCredentials] of an [OngoingCall] identified by the
  /// provided [chatId] and [callId].
  Future<void> removeCredentials(ChatId chatId, ChatItemId callId);

  /// Subscribes to [ChatCallEvent]s of an [OngoingCall].
  ///
  /// This subscription is mandatory to be created after executing [start] or
  /// [join] as represents a heartbeat indication of the authenticated
  /// [MyUser]'s participation in an [OngoingCall]. Stopping or breaking this
  /// subscription without leaving the [OngoingCall] will end up by kicking the
  /// authenticated [MyUser] from this [OngoingCall] by timeout.
  Stream<ChatCallEvents> heartbeat(ChatItemId id, ChatCallDeviceId deviceId);
}

/// Cannot join or start an [OngoingCall] as the authenticated [MyUser] has
/// already joined it.
class CallAlreadyJoinedException implements Exception {
  const CallAlreadyJoinedException(this.deviceId);

  /// [ChatCallDeviceId] of the already joined device.
  final ChatCallDeviceId deviceId;
}
