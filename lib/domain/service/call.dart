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

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/chat.dart';
import '/domain/service/auth.dart';
import '/domain/service/chat.dart';
import '/store/event/chat_call.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Service controlling incoming and outgoing [OngoingCall]s.
class CallService extends DisposableService {
  CallService(this._authService, this._chatService, this._callsRepo);

  /// Unmodifiable map of the currently displayed [OngoingCall]s.
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
    Log.debug(
      'call($chatId, $withAudio, $withVideo, $withScreen)',
      '$runtimeType',
    );

    final Rx<OngoingCall>? stored = _callsRepo[chatId];
    final WebStoredCall? webStored = WebUtils.getCall(chatId);
    final ChatCallDeviceId? webDevice = webStored?.deviceId;

    if (webDevice != null) {
      // Call seems to already exist in the Web, thus try to leave and remove
      // the existing one.
      WebUtils.removeCall(chatId);
      await _callsRepo.leave(chatId, webDevice);
    } else if (stored != null &&
        stored.value.state.value != OngoingCallState.ended) {
      // No-op, as already exists.
      return;
    }

    try {
      final Rx<OngoingCall> call = await _callsRepo.start(
        chatId,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
      );

      if (isClosed) {
        call.value.dispose();
      } else {
        call.value.connect(this);
      }
    } on CallAlreadyJoinedException catch (e) {
      await _callsRepo.leave(chatId, e.deviceId);
      return await join(
        chatId,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
      );
    } catch (e) {
      // If any other error occurs, it's guaranteed that the broken call will be
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
    Log.debug(
      'join($chatId, $withAudio, $withVideo, $withScreen)',
      '$runtimeType',
    );

    final WebStoredCall? webStored = WebUtils.getCall(chatId);
    final ChatCallDeviceId? webDevice = webStored?.deviceId;

    if (webDevice != null && !WebUtils.isPopup) {
      // Call seems to already exist in the Web, thus try to leave and remove
      // the existing one.
      WebUtils.removeCall(chatId);
      await _callsRepo.leave(chatId, webDevice);
    }

    try {
      final FutureOr<RxChat?> chatOrFuture = _chatService.get(chatId);
      final RxChat? chat = chatOrFuture is RxChat?
          ? chatOrFuture
          : await chatOrFuture;

      final ChatCall? chatCall = chat?.chat.value.ongoingCall;

      Rx<OngoingCall>? call;

      try {
        call = await _callsRepo.join(
          chatId,
          chatCall,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
        );
      } on CallAlreadyJoinedException catch (e) {
        await _callsRepo.leave(chatId, e.deviceId);
        call = await _callsRepo.join(
          chatId,
          chatCall,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
        );
      }

      if (isClosed) {
        call?.value.dispose();
      } else {
        call?.value.connect(this);
      }
    } catch (e) {
      // If any other error occurs, it's guaranteed that the broken call will be
      // removed.
      _callsRepo.remove(chatId);
      rethrow;
    }
  }

  /// Leaves or declines an [OngoingCall] identified by the given [chatId].
  Future<void> leave(ChatId chatId, [ChatCallDeviceId? deviceId]) async {
    Log.debug('leave($chatId, $deviceId)', '$runtimeType');

    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      deviceId ??= call.value.deviceId;
      call.value.state.value = OngoingCallState.ended;
      call.value.dispose();
    }

    deviceId ??= WebUtils.getCall(chatId)?.deviceId;

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
    Log.debug('decline($chatId)', '$runtimeType');

    final Rx<OngoingCall>? call = _callsRepo[chatId];
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
    Log.debug(
      'addStored($stored, $withAudio, $withVideo, $withScreen)',
      '$runtimeType',
    );

    return _callsRepo.addStored(
      stored,
      withAudio: withAudio,
      withVideo: withVideo,
      withScreen: withScreen,
    );
  }

  /// Removes an [OngoingCall] identified by the given [chatId].
  void remove(ChatId chatId) {
    Log.debug('remove($chatId)', '$runtimeType');
    _callsRepo.remove(chatId);
  }

  /// Raises/lowers a hand of the authenticated [MyUser] in the [OngoingCall]
  /// identified by the given [chatId].
  Future<void> toggleHand(ChatId chatId, bool raised) async {
    Log.debug('toggleHand($chatId, $raised)', '$runtimeType');

    final Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      await _callsRepo.toggleHand(chatId, raised);
    }
  }

  /// Redials a [User] who left or declined the ongoing [ChatCall] in the
  /// specified [Chat]-group by the authenticated [MyUser].
  Future<void> redialChatCallMember(ChatId chatId, UserId memberId) async {
    Log.debug('redialChatCallMember($chatId, $memberId)', '$runtimeType');
    await _callsRepo.redialChatCallMember(chatId, memberId);
  }

  /// Removes the specified [User] from the [ChatCall] of the specified
  /// [Chat]-group by authority of the authenticated [MyUser].
  ///
  /// If the specified [User] participates in the [ChatCall] from multiple
  /// devices simultaneously, then removes all the devices at once.
  Future<void> removeChatCallMember(ChatId chatId, UserId userId) async {
    Log.debug('removeChatCallMember($chatId, $userId)', '$runtimeType');

    if (_callsRepo.contains(chatId)) {
      await _callsRepo.removeChatCallMember(chatId, userId);
    }
  }

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group, optionally adding new members.
  Future<void> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds, {
    ChatName? groupName,
  }) async {
    Log.debug(
      'transformDialogCallIntoGroupCall($chatId, $additionalMemberIds, $groupName)',
      '$runtimeType',
    );

    await _callsRepo.transformDialogCallIntoGroupCall(
      chatId,
      additionalMemberIds,
      groupName,
    );
  }

  /// Returns heartbeat subscription used to keep [MyUser] in an [OngoingCall].
  Stream<ChatCallEvents> heartbeat(ChatItemId id, ChatCallDeviceId deviceId) {
    Log.debug('heartbeat($id, $deviceId)', '$runtimeType');
    return _callsRepo.heartbeat(id, deviceId);
  }

  /// Switches an [OngoingCall] identified by its [chatId] to the specified
  /// [newChatId].
  void moveCall({
    required ChatId chatId,
    required ChatId newChatId,
    required ChatItemId callId,
    required ChatItemId newCallId,
  }) {
    Log.debug(
      'moveCall($chatId, $newChatId, $callId, $newCallId)',
      '$runtimeType',
    );

    final Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      _callsRepo.move(chatId, newChatId);
      _callsRepo.moveCredentials(callId, newCallId, chatId, newChatId);
      if (WebUtils.isPopup) {
        WebUtils.moveCall(chatId, newChatId, newState: call.value.toStored());
      }
    }
  }

  /// Copies the [ChatCallCredentials] from the provided [Chat] and links them
  /// to the specified [OngoingCall].
  void transferCredentials(ChatId chatId, ChatItemId callId) {
    Log.debug('transferCredentials($chatId, $callId)', '$runtimeType');
    _callsRepo.transferCredentials(chatId, callId);
  }

  /// Removes the [ChatCallCredentials] of an [OngoingCall] identified by the
  /// provided [id].
  Future<void> removeCredentials(ChatId chatId, ChatItemId callId) {
    Log.debug('removeCredentials($chatId, $callId)', '$runtimeType');
    return _callsRepo.removeCredentials(chatId, callId);
  }

  /// Returns a [RxChat] by the provided [id].
  FutureOr<RxChat?> getChat(ChatId id) {
    Log.debug('getChat($id)', '$runtimeType');
    return _chatService.get(id);
  }
}
