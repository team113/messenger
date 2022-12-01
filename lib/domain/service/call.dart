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

import '/api/backend/schema.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/settings.dart';
import '/domain/service/auth.dart';
import '/domain/service/chat.dart';
import '/provider/gql/exceptions.dart'
    show
        ResubscriptionRequiredException,
        TransformDialogCallIntoGroupCallException;
import '/store/event/chat_call.dart';
import '/store/event/incoming_chat_call.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
import 'disposable_service.dart';

/// Service controlling incoming and outgoing [OngoingCall]s.
class CallService extends DisposableService {
  CallService(
    this._authService,
    this._chatService,
    this._settingsRepo,
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

  /// Settings repository, used to get the stored [MediaSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Subscription to [IncomingChatCallsTopEvent]s list.
  StreamSubscription? _events;

  /// Returns ID of the authenticated [MyUser].
  UserId get me => _authService.credentials.value!.userId;

  /// Returns the current [MediaSettings] value.
  Rx<MediaSettings?> get media => _settingsRepo.mediaSettings;

  @override
  void onReady() {
    super.onReady();
    _subscribe(3);
  }

  @override
  void onClose() {
    super.onClose();

    for (Rx<OngoingCall> call
        in List.from(_callsRepo.calls.values, growable: false)) {
      Rx<OngoingCall>? removed = _callsRepo.remove(call.value.chatId.value);
      removed?.value.state.value = OngoingCallState.ended;
      removed?.value.dispose();
    }

    _events?.cancel();
  }

  /// Starts an [OngoingCall] in a [Chat] with the given [chatId].
  Future<void> call(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) async {
    if (WebUtils.containsCall(chatId)) {
      throw CallIsInPopupException();
    } else if (_callsRepo.contains(chatId)) {
      throw CallAlreadyExistsException();
    }

    try {
      Rx<OngoingCall> call = Rx<OngoingCall>(
        OngoingCall(
          chatId,
          me,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
          mediaSettings: media.value,
          creds: _callsRepo.generateCredentials(chatId),
          state: OngoingCallState.local,
        ),
      );
      await _callsRepo.start(call);
      call.value.connect(this);
    } catch (e) {
      // If an error occurs, it's guaranteed that the broken call will be
      // removed.
      var removed = _callsRepo.remove(chatId);
      removed?.value.state.value = OngoingCallState.ended;
      removed?.value.dispose();
      rethrow;
    }
  }

  /// Joins an [OngoingCall] identified by the given [chatId].
  Future<void> join(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = true,
  }) async {
    if (WebUtils.containsCall(chatId) && !WebUtils.isPopup) {
      throw CallIsInPopupException();
    }

    final Rx<OngoingCall>? stored = _callsRepo[chatId];
    ChatCallCredentials? credentials = stored?.value.creds;

    try {
      if (stored == null ||
          stored.value.state.value == OngoingCallState.ended) {
        // If we're joining an already disposed call, then replace it.
        if (stored?.value.state.value == OngoingCallState.ended) {
          var removed = _callsRepo.remove(chatId);
          removed?.value.dispose();
        } else {
          RxChat? chat = await _chatService.get(chatId);
          ChatItemId? id = chat?.chat.value.ongoingCall?.id;
          if (id != null) {
            credentials = _callsRepo.getCredentials(id);
          }
        }

        Rx<OngoingCall> call = Rx<OngoingCall>(
          OngoingCall(
            chatId,
            me,
            withAudio: withAudio,
            withVideo: withVideo,
            mediaSettings: media.value,
            creds: credentials ?? _callsRepo.generateCredentials(chatId),
            state: OngoingCallState.joining,
          ),
        );

        _callsRepo.add(call);
        try {
          await _callsRepo.join(call);
        } on CallAlreadyJoinedException catch (e) {
          await _callsRepo.leave(chatId, e.deviceId);
          await _callsRepo.join(call);
        }
        call.value.connect(this);
      } else if (stored.value.state.value != OngoingCallState.active) {
        stored.value.state.value = OngoingCallState.joining;
        stored.value.setAudioEnabled(withAudio);
        stored.value.setVideoEnabled(withVideo);
        await _callsRepo.join(stored);
        stored.value.connect(this);
      }
    } catch (e) {
      // If an error occurs, it's guaranteed that the broken call will be
      // removed.
      var removed = _callsRepo.remove(chatId);
      removed?.value.state.value = OngoingCallState.ended;
      removed?.value.dispose();
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
      _callsRepo.remove(chatId);
    }

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
    Rx<OngoingCall>? call = _callsRepo[stored.chatId];

    if (call == null) {
      call = Rx(
        OngoingCall(
          stored.chatId,
          me,
          call: stored.call,
          creds: stored.creds,
          deviceId: stored.deviceId,
          state: stored.state,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
          mediaSettings: media.value,
        ),
      );

      _callsRepo.add(call);
    } else {
      call.value.call.value = call.value.call.value ?? stored.call;
      call.value.creds = call.value.creds ?? stored.creds;
      call.value.deviceId = call.value.deviceId ?? stored.deviceId;
    }

    return call;
  }

  /// Removes an [OngoingCall] identified by the given [chatId].
  void remove(ChatId chatId) {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      var removed = _callsRepo.remove(chatId);
      removed?.value.state.value = OngoingCallState.ended;
      removed?.value.dispose();
    }
  }

  /// Raises/lowers a hand of the authenticated [MyUser] in the [OngoingCall]
  /// identified by the given [chatId].
  Future<void> toggleHand(ChatId chatId, bool raised) async {
    Rx<OngoingCall>? call = _callsRepo[chatId];
    if (call != null) {
      await _callsRepo.toggleHand(chatId, raised);
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

  /// Subscribes to the updates of the top [count] of incoming [ChatCall]s list.
  void _subscribe(int count) async {
    _events?.cancel();
    _events = (await _callsRepo.events(count)).listen(
      (e) async {
        switch (e.kind) {
          case IncomingChatCallsTopEventKind.initialized:
            // No-op.
            break;

          case IncomingChatCallsTopEventKind.list:
            e as IncomingChatCallsTop;
            for (ChatCall c in e.list) {
              if (!_callsRepo.calls.containsKey(c.chatId)) {
                Rx<OngoingCall> call = Rx<OngoingCall>(
                  OngoingCall(
                    c.chatId,
                    me,
                    call: c,
                    withAudio: false,
                    withVideo: c.withVideo &&
                        c.caller?.id == me &&
                        c.conversationStartedAt == null,
                    withScreen: false,
                    creds: _callsRepo.getCredentials(c.id),
                  ),
                );
                _callsRepo.add(call);
              }
            }
            break;

          case IncomingChatCallsTopEventKind.added:
            e as EventIncomingChatCallsTopChatCallAdded;

            // If we're already in this call, then ignore it.
            if (e.call.members.any((e) => e.user.id == me)) {
              return;
            }

            Rx<OngoingCall>? call = _callsRepo[e.call.chatId];

            if (call == null) {
              Rx<OngoingCall> call = Rx<OngoingCall>(
                OngoingCall(
                  e.call.chatId,
                  me,
                  call: e.call,
                  withAudio: false,
                  withVideo: false,
                  withScreen: false,
                  mediaSettings: media.value,
                  creds: _callsRepo.getCredentials(e.call.id),
                ),
              );
              _callsRepo.add(call);
            } else {
              call.value.call.value = e.call;
            }
            break;

          case IncomingChatCallsTopEventKind.removed:
            e as EventIncomingChatCallsTopChatCallRemoved;
            Rx<OngoingCall>? call = _callsRepo[e.call.chatId];
            // If call is not yet connected to the remote updates, then it's
            // still just a notification and it should be removed.
            if (call?.value.connected == false &&
                call?.value.isActive == false) {
              var removed = _callsRepo.remove(e.call.chatId);
              removed?.value.state.value = OngoingCallState.ended;
              removed?.value.dispose();
            }
            break;
        }
      },
      onError: (e) {
        if (e is ResubscriptionRequiredException) {
          _subscribe(count);
        } else {
          Log.print(e.toString(), 'CallService');
          throw e;
        }
      },
    );
  }
}
