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

import 'package:get/get.dart';
import 'package:messenger/provider/hive/calls_settings.dart';

import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/chat.dart';
import '/domain/service/auth.dart';
import '/domain/service/chat.dart';
import '/provider/gql/exceptions.dart'
    show TransformDialogCallIntoGroupCallException;
import '/store/event/chat_call.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Service controlling incoming and outgoing [OngoingCall]s.
class CallService extends DisposableService {
  CallService(
    this._authService,
    this._chatService,
    this._callsRepo,
  );

  /// Unmodifiable map of the current [OngoingCall]s.
  RxObsMap<ChatId, Rx<OngoingCall>> get calls => _callsRepo.calls;

  /// [AuthService] to get the authenticated [MyUser].
  final AuthService _authService;

  /// [ChatService] to access a [Chat.ongoingCall].
  final ChatService _chatService;

  /// Repository of [OngoingCall]s collection.
  final AbstractCallRepository _callsRepo;

  /// Returns ID of the authenticated [MyUser].
  UserId get me => _authService.credentials.value!.userId;

  /// Starts an [OngoingCall] in a [Chat] with the given [chatId].
  Future<void> call(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) async {
    final Rx<OngoingCall>? stored = _callsRepo[chatId];

    if (WebUtils.containsCall(chatId)) {
      throw CallIsInPopupException();
    } else if (stored != null &&
        stored.value.state.value != OngoingCallState.ended) {
      throw CallAlreadyExistsException();
    }

    try {
      Rx<OngoingCall> call = await _callsRepo.start(
        chatId,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
      );
      call.value.connect(this);
    } catch (e) {
      // If an error occurs, it's guaranteed that the broken call will be
      // removed.
      _callsRepo.remove(chatId);
      rethrow;
    }
  }

  /// Joins an [OngoingCall] identified by the given [chatId].
  Future<void> join(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) async {
    if (WebUtils.containsCall(chatId) && !WebUtils.isPopup) {
      throw CallIsInPopupException();
    }

    try {
      final RxChat? chat = await _chatService.get(chatId);
      final ChatItemId? callId = chat?.chat.value.ongoingCall?.id;

      Rx<OngoingCall>? call;

      try {
        call = await _callsRepo.join(
          chatId,
          callId,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
        );
      } on CallAlreadyJoinedException catch (e) {
        await _callsRepo.leave(chatId, e.deviceId);
        call = await _callsRepo.join(
          chatId,
          callId,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
        );
      }

      call?.value.connect(this);
    } catch (e) {
      // If an error occurs, it's guaranteed that the broken call will be
      // removed.
      _callsRepo.remove(chatId);
      rethrow;
    }
  }

  /// Leaves an [OngoingCall] identified by the given [chatId].
  Future<void> leave(ChatId chatId, [ChatCallDeviceId? deviceId]) async {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      deviceId ??= call.value.deviceId;
      call.value.state.value = OngoingCallState.ended;
      call.value.dispose();
    }

    if (deviceId != null) {
      await _callsRepo.leave(chatId, deviceId);
    } else {
      await _callsRepo.decline(chatId);
    }

    _callsRepo.remove(chatId);
    WebUtils.removeCall(chatId);
  }

  /// Declines an [OngoingCall] identified by the given [chatId].
  Future<void> decline(ChatId chatId) async {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      // Closing the popup window will kill the pending requests, so it's
      // required to await the decline.
      if (WebUtils.isPopup) {
        await _callsRepo.decline(chatId);
        call.value.state.value = OngoingCallState.ended;
        call.value.dispose();
      } else {
        call.value.state.value = OngoingCallState.ended;
        call.value.dispose();
        await _callsRepo.decline(chatId);
      }
    }
  }

  /// Constructs an [OngoingCall] from the provided [stored] call.
  Rx<OngoingCall> addStored(
    WebStoredCall stored, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) {
    return _callsRepo.addStored(
      stored,
      withAudio: withAudio,
      withVideo: withVideo,
      withScreen: withScreen,
    );
  }

  /// Removes an [OngoingCall] identified by the given [chatId].
  void remove(ChatId chatId) => _callsRepo.remove(chatId);

  /// Raises/lowers a hand of the authenticated [MyUser] in the [OngoingCall]
  /// identified by the given [chatId].
  Future<void> toggleHand(ChatId chatId, bool raised) async {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      await _callsRepo.toggleHand(chatId, raised);
    }
  }

  /// Redials a [User] who left or declined the ongoing [ChatCall] in the
  /// specified [Chat]-group by the authenticated [MyUser].
  Future<void> redialChatCallMember(ChatId chatId, UserId memberId) async {
    if (_callsRepo.contains(chatId)) {
      await _callsRepo.redialChatCallMember(chatId, memberId);
    }
  }

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group, optionally adding new members.
  Future<void> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds, {
    ChatName? groupName,
  }) async {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      await _callsRepo.transformDialogCallIntoGroupCall(
        chatId,
        additionalMemberIds,
        groupName,
      );
    } else {
      throw const TransformDialogCallIntoGroupCallException(
        TransformDialogCallIntoGroupCallErrorCode.noCall,
      );
    }
  }

  /// Returns heartbeat subscription used to keep [MyUser] in an [OngoingCall].
  Future<Stream<ChatCallEvents>> heartbeat(
    ChatItemId id,
    ChatCallDeviceId deviceId,
  ) =>
      _callsRepo.heartbeat(id, deviceId);

  /// Switches an [OngoingCall] identified by its [chatId] to the specified
  /// [newChatId].
  void moveCall({
    required ChatId chatId,
    required ChatId newChatId,
    required ChatItemId callId,
    required ChatItemId newCallId,
  }) {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      _callsRepo.move(chatId, newChatId);
      _callsRepo.moveCredentials(callId, newCallId);
      if (WebUtils.isPopup) {
        WebUtils.moveCall(chatId, newChatId, newState: call.value.toStored());
      }
    }
  }

  /// Transfers the [ChatCallCredentials] from the provided [Chat] to the
  /// specified [OngoingCall].
  void transferCredentials(ChatId chatId, ChatItemId callId) =>
      _callsRepo.transferCredentials(chatId, callId);

  /// Removes the [ChatCallCredentials] of an [OngoingCall] identified by the
  /// provided [id].
  Future<void> removeCredentials(ChatItemId id) =>
      _callsRepo.removeCredentials(id);

  Future<void> setCallPrefs(CallPreferences prefs) =>
      _callsRepo.setPrefs(prefs);

  CallPreferences? getCallPrefs(ChatId id) => _callsRepo.getPrefs(id);
}
