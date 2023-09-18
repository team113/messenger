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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;
import 'package:medea_jason/medea_jason.dart';
import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../service/call.dart';
import '/domain/model/media_settings.dart';
import '/store/event/chat_call.dart';
import '/util/log.dart';
import '/util/media_utils.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'chat.dart';
import 'chat_call.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

/// Possible states of an [OngoingCall].
enum OngoingCallState {
  /// Initialized locally, so a server is not yet aware of it.
  local,

  /// Initialization request was sent to a server and is pending.
  pending,

  /// Join request was sent to a server and is pending.
  joining,

  /// Successfully created and joined.
  active,

  /// Ended and disposed locally.
  ended,
}

/// Possible states of a [LocalMediaTrack].
enum LocalTrackState {
  /// Transitioning to [LocalTrackState.disabled].
  disabling,

  /// Not being sent.
  disabled,

  /// Transitioning to [LocalTrackState.enabled].
  enabling,

  /// Captured and sent to the remote.
  enabled,
}

/// Extension adding helper methods to a [LocalTrackState].
extension LocalTrackStateImpl on LocalTrackState {
  /// Indicates whether the current value is [LocalTrackState.enabling] or
  /// [LocalTrackState.disabling].
  bool get isTransition {
    switch (this) {
      case LocalTrackState.enabling:
      case LocalTrackState.disabling:
        return true;
      case LocalTrackState.disabled:
      case LocalTrackState.enabled:
        return false;
    }
  }

  /// Indicates whether the current value is [LocalTrackState.enabled] or
  /// [LocalTrackState.disabling].
  bool get isEnabled {
    switch (this) {
      case LocalTrackState.enabled:
      case LocalTrackState.disabling:
        return true;
      case LocalTrackState.disabled:
      case LocalTrackState.enabling:
        return false;
    }
  }
}

/// Extension adding helper methods to a [TrackMediaDirection].
extension TrackMediaDirectionEmitting on TrackMediaDirection {
  /// Indicates whether the current value is [TrackMediaDirection.sendRecv] or
  /// [TrackMediaDirection.sendOnly].
  bool get isEmitting {
    switch (this) {
      case TrackMediaDirection.sendRecv:
      case TrackMediaDirection.sendOnly:
        return true;
      case TrackMediaDirection.recvOnly:
      case TrackMediaDirection.inactive:
        return false;
    }
  }

  /// Indicates whether the current value is [TrackMediaDirection.sendRecv].
  bool get isEnabled {
    switch (this) {
      case TrackMediaDirection.sendRecv:
        return true;
      case TrackMediaDirection.sendOnly:
      case TrackMediaDirection.recvOnly:
      case TrackMediaDirection.inactive:
        return false;
    }
  }
}

/// Ongoing [ChatCall] in a [Chat].
///
/// Proper initialization requires [connect] once the inner [ChatCall] is set.
class OngoingCall {
  OngoingCall(
    ChatId chatId,
    UserId me, {
    ChatCall? call,
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
    MediaSettings? mediaSettings,
    OngoingCallState state = OngoingCallState.pending,
    this.creds,
    this.deviceId,
  })  : chatId = Rx(chatId),
        _me = CallMemberId(me, null),
        audioDevice = RxnString(mediaSettings?.audioDevice),
        videoDevice = RxnString(mediaSettings?.videoDevice),
        screenDevice = RxnString(mediaSettings?.screenDevice),
        outputDevice = RxnString(mediaSettings?.outputDevice) {
    this.state = Rx<OngoingCallState>(state);
    this.call = Rx(call);

    members[_me] = CallMember.me(_me, isConnected: true);

    if (withAudio) {
      audioState = Rx(LocalTrackState.enabling);
    } else {
      audioState = Rx(LocalTrackState.disabled);
    }

    if (withVideo) {
      videoState = Rx(LocalTrackState.enabling);
    } else {
      videoState = Rx(LocalTrackState.disabled);
    }

    if (withScreen) {
      screenShareState = Rx(LocalTrackState.enabling);
    } else {
      screenShareState = Rx(LocalTrackState.disabled);
    }
  }

  /// ID of the [Chat] this [OngoingCall] takes place in.
  final Rx<ChatId> chatId;

  /// [ChatCall] associated with this [OngoingCall].
  ///
  /// Guaranteed to be `null` on [OngoingCallState.local] [state] and non-`null`
  /// otherwise.
  late final Rx<ChatCall?> call;

  /// One-time secret credentials to authenticate with on a media server.
  ChatCallCredentials? creds;

  /// ID of the device this [OngoingCall] is taking place on.
  ChatCallDeviceId? deviceId;

  // TODO: State should be encapsulated, so there would be no external ways to
  //       change it. However, this is not supported by the GetX's `Rx`.
  /// State of this [OngoingCall].
  late Rx<OngoingCallState> state;

  /// [LocalTrackState] of a local audio stream.
  late final Rx<LocalTrackState> audioState;

  /// [LocalTrackState] of a local video stream.
  late final Rx<LocalTrackState> videoState;

  /// [LocalTrackState] of a local screen-share stream.
  late final Rx<LocalTrackState> screenShareState;

  /// ID of the currently used video device.
  late final RxnString videoDevice;

  /// ID of the currently used microphone device.
  late final RxnString audioDevice;

  /// ID of the currently used screen share device.
  final RxnString screenDevice;

  /// ID of the currently used audio output device.
  late final RxnString outputDevice;

  /// Indicator whether the inbound audio in this [OngoingCall] is enabled or
  /// not.
  final RxBool isRemoteAudioEnabled = RxBool(true);

  /// Indicator whether the inbound video in this [OngoingCall] is enabled or
  /// not.
  final RxBool isRemoteVideoEnabled = RxBool(true);

  /// Returns a [Stream] of the [CallNotification]s.
  Stream<CallNotification> get notifications => _notifications.stream;

  /// Reactive map of [CallMember]s of this [OngoingCall].
  final RxObsMap<CallMemberId, CallMember> members =
      RxObsMap<CallMemberId, CallMember>();

  /// Indicator whether the connection to the remote updates was lost and an
  /// ongoing reconnection is happening.
  final RxBool connectionLost = RxBool(false);

  /// Indicator whether this [OngoingCall] is [connect]ed to the remote updates
  /// or not.
  ///
  /// If `true` then this call can be considered as an answered ongoing call,
  /// and not just as a notification of an ongoing call in background.
  bool connected = false;

  /// List of [MediaDeviceDetails] of all the available devices.
  final RxList<MediaDeviceDetails> devices = RxList<MediaDeviceDetails>([]);

  /// List of [MediaDisplayDetails] of all the available displays.
  final RxList<MediaDisplayDetails> displays = RxList<MediaDisplayDetails>([]);

  /// Indicator whether this [OngoingCall] should not initialize any media
  /// client related resources.
  bool _background = true;

  /// Room on a media server representing this [OngoingCall].
  RoomHandle? _room;

  /// [CallMemberId] of the authenticated [MyUser].
  CallMemberId _me;

  /// Heartbeat subscription indicating that [MyUser] is connected and this
  /// [OngoingCall] is alive on a client side.
  StreamSubscription? _heartbeat;

  /// Subscription to the [RxChat.members] changes adding and removing the
  /// redialed [members].
  StreamSubscription? _membersSubscription;

  /// Mutex for synchronized access to [RoomHandle.setLocalMediaSettings].
  final Mutex _mediaSettingsGuard = Mutex();

  /// Mutex guarding [toggleHand].
  final Mutex _toggleHandGuard = Mutex();

  /// [_toggleHand]s of the authenticated [MyUser] used to discard the
  /// [connect]ed events following these invokes.
  final List<bool> _handToggles = [];

  /// [StreamController] of the [notifications].
  final StreamController<CallNotification> _notifications =
      StreamController.broadcast();

  /// [StreamSubscription] for the [MediaUtils.onDeviceChange] stream updating
  /// the [devices].
  StreamSubscription? _devicesSubscription;

  /// [StreamSubscription] for the [MediaUtils.onDisplayChange] stream updating
  /// the [displays].
  StreamSubscription? _displaysSubscription;

  /// [ChatItemId] of this [OngoingCall].
  ChatItemId? get callChatItemId => call.value?.id;

  /// Returns the [CallMember] of the currently authorized [MyUser].
  CallMember get me => members[_me]!;

  /// Returns the local [Track]s.
  ObsList<Track>? get localTracks => members[_me]?.tracks;

  /// [User] that started this [OngoingCall].
  User? get caller => call.value?.author;

  /// Indicator whether this [OngoingCall] is intended to start with video.
  ///
  /// Used to determine incoming [OngoingCall] type.
  bool? get withVideo => call.value?.withVideo;

  /// [PreciseDateTime] when the actual conversation in this [ChatCall] was
  /// started (after ringing had been finished).
  PreciseDateTime? get conversationStartedAt =>
      call.value?.conversationStartedAt;

  /// Indicates whether this [OngoingCall] is active.
  bool get isActive => (state.value == OngoingCallState.active ||
      state.value == OngoingCallState.joining);

  /// Indicator whether this [OngoingCall] has any remote connection active.
  bool get hasRemote =>
      isActive && members.values.where((e) => e.isConnected.isTrue).length > 1;

  /// Indicates whether this [OngoingCall] has an active microphone track.
  bool get hasAudio =>
      members[_me]
          ?.tracks
          .where((t) =>
              t.kind == MediaKind.audio && t.source == MediaSourceKind.device)
          .isNotEmpty ??
      false;

  /// Initializes the media client resources.
  ///
  /// No-op if already initialized.
  Future<void> init() async {
    if (_background) {
      _background = false;

      _devicesSubscription = MediaUtils.onDeviceChange.listen((e) async {
        print('_mediaManager?.onDeviceChange');

        final List<MediaDeviceDetails> previous =
            List.from(devices, growable: false);

        devices.value = e;

        final List<MediaDeviceDetails> added = [];
        final List<MediaDeviceDetails> removed = [];

        for (MediaDeviceDetails d in devices) {
          if (previous.none((p) => p.deviceId() == d.deviceId())) {
            added.add(d);
          }
        }

        for (MediaDeviceDetails d in previous) {
          if (devices.none((p) => p.deviceId() == d.deviceId())) {
            removed.add(d);
          }
        }

        _pickAudioDevice(previous, added, removed);
        _pickOutputDevice(previous, added, removed);
        _pickVideoDevice(previous, removed);
      });

      _displaysSubscription = MediaUtils.onDisplayChange.listen((e) async {
        final List<MediaDisplayDetails> previous =
            List.from(displays, growable: false);

        displays.value = e;

        final List<MediaDisplayDetails> removed = [];

        for (MediaDisplayDetails d in previous) {
          if (displays.none((p) => p.deviceId() == d.deviceId())) {
            removed.add(d);
          }
        }

        _pickScreenDevice(removed);
      });

      _initRoom();

      await _initLocalMedia();

      if (state.value == OngoingCallState.active &&
          call.value?.joinLink != null) {
        await _joinRoom(call.value!.joinLink!);
      }
    }
  }

  /// Starts the [CallService.heartbeat] subscription indicating that this
  /// [OngoingCall] is ready to connect to a media server.
  ///
  /// No-op if already [connected].
  void connect(CallService calls) {
    if (connected || callChatItemId == null || deviceId == null) {
      return;
    }

    // Adds a [CallMember] identified by its [userId], if none is in the
    // [members] already.
    void addDialing(UserId userId) {
      final CallMemberId id = CallMemberId(userId, null);

      if (members.values.none((e) => e.id.userId == id.userId)) {
        members[id] = CallMember(
          id,
          null,
          isHandRaised: call.value?.members
                  .firstWhereOrNull((e) => e.user.id == id.userId)
                  ?.handRaised ??
              false,
          isConnected: false,
          isDialing: true,
        );
      }
    }

    CallMemberId id = CallMemberId(_me.userId, deviceId);
    members[_me]?.id = id;
    members.move(_me, id);
    _me = id;

    connected = true;
    _heartbeat?.cancel();
    _heartbeat = calls.heartbeat(callChatItemId!, deviceId!).listen(
      (e) async {
        switch (e.kind) {
          case ChatCallEventsKind.initialized:
            Log.print('ChatCallEventsKind.initialized', 'CALL');
            break;

          case ChatCallEventsKind.chatCall:
            var node = e as ChatCallEventsChatCall;
            Log.print('ChatCallEventsKind.chatCall', 'CALL');

            _handToggles.clear();

            if (node.call.finishReason != null) {
              // Call is already ended, so remove it.
              calls.remove(chatId.value);
              calls.removeCredentials(node.call.id);
            } else {
              if (state.value == OngoingCallState.local) {
                state.value = node.call.conversationStartedAt == null
                    ? OngoingCallState.pending
                    : OngoingCallState.joining;
              }

              if (node.call.joinLink != null) {
                if (!_background) {
                  await _joinRoom(node.call.joinLink!);
                }
                state.value = OngoingCallState.active;
              }

              final ChatMembersDialed? dialed = node.call.dialed;
              if (dialed is ChatMembersDialedConcrete) {
                for (var m in dialed.members) {
                  addDialing(m.user.id);
                }
              }

              // Get a [RxChat] this [OngoingCall] is happening in to query its
              // [RxChat.members] list.
              calls.getChat(chatId.value).then((v) {
                if (!connected) {
                  // [OngoingCall] might have been disposed or disconnected
                  // while this [Future] was executing.
                  return;
                }

                if (dialed is ChatMembersDialedAll) {
                  for (var m in (v?.chat.value.members ?? []).where((e) =>
                      e.user.id != me.id.userId &&
                      dialed.answeredMembers
                          .none((a) => a.user.id == e.user.id))) {
                    addDialing(m.user.id);
                  }
                }

                _membersSubscription?.cancel();
                _membersSubscription = v?.members.changes.listen((event) {
                  switch (event.op) {
                    case OperationKind.added:
                      addDialing(event.key!);
                      break;

                    case OperationKind.removed:
                      members.remove(CallMemberId(event.key!, null))?.dispose();
                      break;

                    case OperationKind.updated:
                      // No-op.
                      break;
                  }
                });
              });

              members[_me]?.isHandRaised.value = node.call.members
                      .firstWhereOrNull((e) => e.user.id == _me.userId)
                      ?.handRaised ??
                  false;
            }

            call.value = node.call;
            call.refresh();
            break;

          case ChatCallEventsKind.event:
            var versioned = (e as ChatCallEventsEvent).event;
            for (var event in versioned.events) {
              Log.print('${event.kind}', 'CALL');
              switch (event.kind) {
                case ChatCallEventKind.roomReady:
                  var node = event as EventChatCallRoomReady;

                  if (!_background) {
                    await _joinRoom(node.joinLink);
                  }

                  call.value?.joinLink = node.joinLink;
                  call.refresh();

                  state.value = OngoingCallState.active;
                  break;

                case ChatCallEventKind.finished:
                  var node = event as EventChatCallFinished;
                  if (node.chatId == chatId.value) {
                    calls.removeCredentials(node.call.id);
                    calls.remove(chatId.value);
                  }
                  break;

                case ChatCallEventKind.memberLeft:
                  var node = event as EventChatCallMemberLeft;
                  if (calls.me == node.user.id) {
                    calls.remove(chatId.value);
                  }

                  final CallMemberId id =
                      CallMemberId(node.user.id, node.deviceId);

                  if (members[id]?.isConnected.value == false) {
                    members.remove(id)?.dispose();
                  }

                  if (members.keys.none((e) => e.userId == node.user.id)) {
                    call.value?.members
                        .removeWhere((e) => e.user.id == node.user.id);
                  }
                  break;

                case ChatCallEventKind.memberJoined:
                  var node = event as EventChatCallMemberJoined;

                  final CallMemberId redialedId =
                      CallMemberId(node.user.id, null);
                  final CallMemberId id =
                      CallMemberId(node.user.id, node.deviceId);

                  final CallMember? redialed = members[redialedId];
                  if (redialed != null) {
                    redialed.id = id;
                    redialed.isDialing.value = false;
                    members.move(redialedId, id);
                  }

                  final CallMember? member = members[id];

                  if (member == null) {
                    members[id] = CallMember(
                      id,
                      null,
                      isHandRaised: call.value?.members
                              .firstWhereOrNull((e) => e.user.id == id.userId)
                              ?.handRaised ??
                          false,
                      isConnected: false,
                    );
                  }
                  break;

                case ChatCallEventKind.handLowered:
                  var node = event as EventChatCallHandLowered;

                  // Ignore the event, if it's our hand and is already lowered.
                  if (node.user.id == _me.userId &&
                      _handToggles.firstOrNull == false) {
                    _handToggles.removeAt(0);
                  } else {
                    for (MapEntry<CallMemberId, CallMember> m in members.entries
                        .where((e) => e.key.userId == node.user.id)) {
                      m.value.isHandRaised.value = false;
                    }
                  }

                  for (ChatCallMember m in (call.value?.members ?? [])
                      .where((e) => e.user.id == node.user.id)) {
                    m.handRaised = false;
                  }
                  break;

                case ChatCallEventKind.handRaised:
                  var node = event as EventChatCallHandRaised;

                  // Ignore the event, if it's our hand and is already raised.
                  if (node.user.id == _me.userId &&
                      _handToggles.firstOrNull == true) {
                    _handToggles.removeAt(0);
                  } else {
                    for (MapEntry<CallMemberId, CallMember> m in members.entries
                        .where((e) => e.key.userId == node.user.id)) {
                      m.value.isHandRaised.value = true;
                    }
                  }

                  for (ChatCallMember m in (call.value?.members ?? [])
                      .where((e) => e.user.id == node.user.id)) {
                    m.handRaised = true;
                  }
                  break;

                case ChatCallEventKind.declined:
                  var node = event as EventChatCallDeclined;
                  final CallMemberId id = CallMemberId(node.user.id, null);
                  if (members[id]?.isConnected.value == false) {
                    members.remove(id)?.dispose();
                  }
                  break;

                case ChatCallEventKind.callMoved:
                  var node = event as EventChatCallMoved;
                  chatId.value = node.newChatId;
                  call.value = node.newCall;

                  connected = false;
                  connect(calls);

                  calls.moveCall(
                    chatId: node.chatId,
                    newChatId: node.newChatId,
                    callId: node.callId,
                    newCallId: node.newCallId,
                  );
                  break;

                case ChatCallEventKind.redialed:
                  var node = event as EventChatCallMemberRedialed;
                  addDialing(node.user.id);
                  break;

                case ChatCallEventKind.answerTimeoutPassed:
                  var node = event as EventChatCallAnswerTimeoutPassed;

                  if (node.user?.id != null) {
                    final CallMemberId id = CallMemberId(node.user!.id, null);
                    if (members[id]?.isConnected.value == false) {
                      members.remove(id)?.dispose();
                    }
                  } else {
                    members.removeWhere((k, v) {
                      if (k.deviceId == null && v.isConnected.isFalse) {
                        v.dispose();
                        return true;
                      }

                      return false;
                    });
                  }
                  break;

                case ChatCallEventKind.conversationStarted:
                  // TODO: Implement [EventChatCallConversationStarted].
                  break;
              }
            }
            break;
        }
      },
    );
  }

  /// Disposes the call and [Jason] client if it was previously initialized.
  Future<void> dispose() {
    _heartbeat?.cancel();
    _membersSubscription?.cancel();
    connected = false;

    return _mediaSettingsGuard.protect(() async {
      _disposeLocalMedia();
      if (!_background) {
        _closeRoom();
      }
      _devicesSubscription?.cancel();
      _displaysSubscription?.cancel();
      _heartbeat?.cancel();
      _membersSubscription?.cancel();
      connected = false;
    });
  }

  /// Leaves this [OngoingCall].
  ///
  /// Throws a [LeaveChatCallException].
  Future<void> leave(CallService calls) => calls.leave(chatId.value, deviceId);

  /// Declines this [OngoingCall].
  ///
  /// Throws a [DeclineChatCallException].
  Future<void> decline(CallService calls) => calls.decline(chatId.value);

  /// Joins this [OngoingCall].
  ///
  /// Throws a [JoinChatCallException], [CallDoesNotExistException].
  Future<void> join(
    CallService calls, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) async =>
      await calls.join(
        chatId.value,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
      );

  /// Enables/disables local screen-sharing stream based on [enabled].
  Future<void> setScreenShareEnabled(bool enabled, {String? deviceId}) async {
    switch (screenShareState.value) {
      case LocalTrackState.disabled:
      case LocalTrackState.disabling:
        if (enabled) {
          screenShareState.value = LocalTrackState.enabling;
          try {
            await _updateSettings(
              screenDevice: deviceId ?? displays.firstOrNull?.deviceId(),
            );
            await _room?.enableVideo(MediaSourceKind.display);
            screenShareState.value = LocalTrackState.enabled;

            final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
              screen: ScreenPreferences(device: screenDevice.value),
            );
            tracks.forEach(_addLocalTrack);
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } on LocalMediaInitException catch (e) {
            screenShareState.value = LocalTrackState.disabled;
            if (!e.message().contains('Permission denied')) {
              addError('enableScreenShare() call failed with $e');
              rethrow;
            }
          } catch (e) {
            screenShareState.value = LocalTrackState.disabled;
            addError('enableScreenShare() call failed with $e');
            rethrow;
          }
        }
        break;

      case LocalTrackState.enabled:
      case LocalTrackState.enabling:
        if (!enabled) {
          screenShareState.value = LocalTrackState.disabling;
          try {
            await _room?.disableVideo(MediaSourceKind.display);
            _removeLocalTracks(MediaKind.video, MediaSourceKind.display);
            screenShareState.value = LocalTrackState.disabled;
            screenDevice.value = null;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            addError('disableScreenShare() call failed with $e');
            screenShareState.value = LocalTrackState.enabled;
            rethrow;
          }
        }
        break;
    }
  }

  /// Enables/disables local audio stream based on [enabled].
  Future<void> setAudioEnabled(bool enabled) async {
    switch (audioState.value) {
      case LocalTrackState.disabled:
      case LocalTrackState.disabling:
        if (enabled) {
          audioState.value = LocalTrackState.enabling;
          try {
            print('LocalTrackState.enabling');
            if (members[_me]
                    ?.tracks
                    .where((t) =>
                        t.kind == MediaKind.audio &&
                        t.source == MediaSourceKind.device)
                    .isEmpty ??
                false) {
              print('enableAudio');
              await _room?.enableAudio();

              final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
                audio: AudioPreferences(device: audioDevice.value),
              );
              tracks.forEach(_addLocalTrack);
            }
            await _room?.unmuteAudio();
            audioState.value = LocalTrackState.enabled;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } on LocalMediaInitException catch (e) {
            audioState.value = LocalTrackState.disabled;
            if (!e.message().contains('Permission denied')) {
              addError('unmuteAudio() call failed due to ${e.message()}');
              rethrow;
            }
          } catch (e) {
            audioState.value = LocalTrackState.disabled;
            addError('unmuteAudio() call failed with $e');
            rethrow;
          }
        }
        break;

      case LocalTrackState.enabled:
      case LocalTrackState.enabling:
        if (!enabled) {
          audioState.value = LocalTrackState.disabling;
          try {
            await _room?.muteAudio();
            audioState.value = LocalTrackState.disabled;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            audioState.value = LocalTrackState.enabled;
            addError('muteAudio() call failed with $e');
            rethrow;
          }
        }
        break;
    }
  }

  /// Enables/disables local video stream based on [enabled].
  Future<void> setVideoEnabled(bool enabled) async {
    switch (videoState.value) {
      case LocalTrackState.disabled:
      case LocalTrackState.disabling:
        if (enabled) {
          videoState.value = LocalTrackState.enabling;
          try {
            await _room?.enableVideo(MediaSourceKind.device);
            videoState.value = LocalTrackState.enabled;

            final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
              video: VideoPreferences(
                device: videoDevice.value,
                facingMode: videoDevice.value == null ? FacingMode.user : null,
              ),
            );
            tracks.forEach(_addLocalTrack);
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } on LocalMediaInitException catch (e) {
            videoState.value = LocalTrackState.disabled;
            if (!e.message().contains('Permission denied')) {
              addError('enableVideo() call failed with $e');
              rethrow;
            }
          } catch (e) {
            addError('enableVideo() call failed with $e');
            videoState.value = LocalTrackState.disabled;
            rethrow;
          }
        }
        break;

      case LocalTrackState.enabled:
      case LocalTrackState.enabling:
        if (!enabled) {
          videoState.value = LocalTrackState.disabling;
          try {
            await _room?.disableVideo(MediaSourceKind.device);
            _removeLocalTracks(MediaKind.video, MediaSourceKind.device);
            videoState.value = LocalTrackState.disabled;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            addError('disableVideo() call failed with $e');
            videoState.value = LocalTrackState.enabled;
            rethrow;
          }
          break;
        }
    }
  }

  /// Toggles local audio stream on and off.
  Future<void> toggleAudio() =>
      setAudioEnabled(audioState.value != LocalTrackState.enabled &&
          audioState.value != LocalTrackState.enabling);

  /// Toggles local video stream on and off.
  Future<void> toggleVideo([bool? enabled]) =>
      setVideoEnabled(videoState.value != LocalTrackState.enabled &&
          videoState.value != LocalTrackState.enabling);

  /// Populates [devices] with a list of [MediaDeviceDetails] objects
  /// representing available media input devices, such as microphones, cameras,
  /// and so forth.
  Future<void> enumerateDevices({
    bool media = true,
    bool screen = true,
  }) async {
    try {
      if (media) {
        devices.value = await MediaUtils.enumerateDevices();
      }

      if (screen && PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
        displays.value = await MediaUtils.enumerateDisplays();
      }
    } on EnumerateDevicesException catch (e) {
      addError('Failed to enumerate devices: $e');
      rethrow;
    }
  }

  /// Sets device with [deviceId] as a currently used [audioDevice].
  ///
  /// Does nothing if [deviceId] is already an ID of the [audioDevice].
  Future<void> setAudioDevice(String deviceId) async {
    if ((audioDevice.value != null && deviceId != audioDevice.value) ||
        (audioDevice.value == null &&
            devices.audio().firstOrNull?.deviceId() != deviceId)) {
      await _updateSettings(audioDevice: deviceId);
    }
  }

  /// Sets device with [deviceId] as a currently used [videoDevice].
  ///
  /// Does nothing if [deviceId] is already an ID of the [videoDevice].
  Future<void> setVideoDevice(String deviceId) async {
    if ((videoDevice.value != null && deviceId != videoDevice.value) ||
        (videoDevice.value == null &&
            devices.video().firstOrNull?.deviceId() != deviceId)) {
      await _updateSettings(videoDevice: deviceId);
    }
  }

  /// Sets device with [deviceId] as a currently used [outputDevice].
  ///
  /// Does nothing if [deviceId] is already an ID of the [outputDevice].
  Future<void> setOutputDevice(String deviceId) async {
    if (deviceId != outputDevice.value) {
      await MediaUtils.mediaManager?.setOutputAudioId(deviceId);
      outputDevice.value = deviceId;
    }
  }

  /// Sets inbound audio in this [OngoingCall] as [enabled] or not.
  ///
  /// No-op if [isRemoteAudioEnabled] is already [enabled].
  Future<void> setRemoteAudioEnabled(bool enabled) async {
    try {
      final List<Future> futures = [];

      if (enabled && isRemoteAudioEnabled.isFalse) {
        for (CallMember m in members.values.where((e) => e.id != _me)) {
          futures.add(m.setAudioEnabled(true));
        }

        isRemoteAudioEnabled.toggle();
      } else if (!enabled && isRemoteAudioEnabled.isTrue) {
        for (CallMember m in members.values.where((e) => e.id != _me)) {
          if (m.tracks.any((e) => e.kind == MediaKind.audio)) {
            futures.add(m.setAudioEnabled(false));
          }
        }

        isRemoteAudioEnabled.toggle();
      }

      await Future.wait(futures);
    } on MediaStateTransitionException catch (_) {
      // No-op.
    }
  }

  /// Sets inbound video in this [OngoingCall] as [enabled] or not.
  ///
  /// No-op if [isRemoteVideoEnabled] is already [enabled].
  Future<void> setRemoteVideoEnabled(bool enabled) async {
    try {
      final List<Future> futures = [];

      if (enabled && isRemoteVideoEnabled.isFalse) {
        for (CallMember m in members.values.where((e) => e.id != _me)) {
          futures.addAll([
            m.setVideoEnabled(true, source: MediaSourceKind.device),
            m.setVideoEnabled(true, source: MediaSourceKind.display),
          ]);
        }

        isRemoteVideoEnabled.toggle();
      } else if (!enabled && isRemoteVideoEnabled.isTrue) {
        for (CallMember m in members.values.where((e) => e.id != _me)) {
          m.tracks.where((e) => e.kind == MediaKind.video).forEach((e) {
            futures.add(m.setVideoEnabled(false, source: e.source));
          });
        }

        isRemoteVideoEnabled.toggle();
      }

      await Future.wait(futures);
    } on MediaStateTransitionException catch (_) {
      // No-op.
    }
  }

  /// Toggles inbound audio in this [OngoingCall] on and off.
  Future<void> toggleRemoteAudio() =>
      setRemoteAudioEnabled(!isRemoteAudioEnabled.value);

  /// Toggles inbound video in this [OngoingCall] on and off.
  Future<void> toggleRemoteVideo() =>
      setRemoteVideoEnabled(!isRemoteVideoEnabled.value);

  /// Adds the provided [message] to the [notifications] stream as
  /// [ErrorNotification].
  ///
  /// Should (and intended to) be used as a notification measure.
  void addError(String message) =>
      _notifications.add(ErrorNotification(message: message));

  /// Returns [MediaStreamSettings] with [audio], [video], [screen] enabled or
  /// not.
  ///
  /// Optionally, [audioDevice], [videoDevice] and [screenDevice] set the
  /// devices and [facingMode] sets the ideal [FacingMode] of the local video
  /// stream.
  MediaStreamSettings _mediaStreamSettings({
    bool audio = true,
    bool video = true,
    bool screen = true,
    String? audioDevice,
    String? videoDevice,
    String? screenDevice,
    FacingMode? facingMode,
  }) {
    MediaStreamSettings settings = MediaStreamSettings();

    if (audio) {
      AudioTrackConstraints constraints = AudioTrackConstraints();
      if (audioDevice != null) constraints.deviceId(audioDevice);
      settings.audio(constraints);
    }

    if (video) {
      DeviceVideoTrackConstraints constraints = DeviceVideoTrackConstraints();
      if (videoDevice != null) constraints.deviceId(videoDevice);
      if (facingMode != null) constraints.idealFacingMode(facingMode);
      settings.deviceVideo(constraints);
    }

    if (screen) {
      DisplayVideoTrackConstraints constraints = DisplayVideoTrackConstraints();
      if (screenDevice != null) {
        constraints.deviceId(screenDevice);
      }
      constraints.idealFrameRate(30);
      settings.displayVideo(constraints);
    }

    return settings;
  }

  /// Initializes the [_room].
  void _initRoom() {
    _room = MediaUtils.jason!.initRoom();

    _room!.onFailedLocalMedia((e) async {
      Log.print('onFailedLocalMedia', 'CALL');
      if (e is LocalMediaInitException) {
        try {
          switch (e.kind()) {
            case LocalMediaInitExceptionKind.getUserMediaAudioFailed:
              addError('Failed to acquire local audio: $e');
              await _room?.disableAudio();
              _removeLocalTracks(MediaKind.audio, MediaSourceKind.device);
              audioState.value = LocalTrackState.disabled;
              break;

            case LocalMediaInitExceptionKind.getUserMediaVideoFailed:
              addError('Failed to acquire local video: $e');
              await setVideoEnabled(false);
              break;

            case LocalMediaInitExceptionKind.getDisplayMediaFailed:
              if (e.message().contains('Permission denied')) {
                break;
              }

              addError('Failed to initiate screen capture: $e');
              await setScreenShareEnabled(false);
              break;

            default:
              if (e.message().contains('Permission denied')) {
                break;
              }

              addError('Failed to get media: $e');

              await _room?.disableAudio();
              _removeLocalTracks(MediaKind.audio, MediaSourceKind.device);
              audioState.value = LocalTrackState.disabled;
              audioDevice.value = null;

              await setVideoEnabled(false);
              videoState.value = LocalTrackState.disabled;
              videoDevice.value = null;

              await setScreenShareEnabled(false);
              screenShareState.value = LocalTrackState.disabled;
              screenDevice.value = null;
              return;
          }
        } catch (e) {
          addError('$e');
        }
      }
    });

    _room!.onConnectionLoss((e) async {
      Log.print('onConnectionLoss', 'CALL');

      if (connectionLost.isFalse) {
        connectionLost.value = true;

        _notifications.add(ConnectionLostNotification());
        await e.reconnectWithBackoff(500, 2, 5000);
        _notifications.add(ConnectionRestoredNotification());

        connectionLost.value = false;
      }
    });

    _room!.onNewConnection((conn) {
      Log.print('onNewConnection', 'CALL');

      final CallMemberId id = CallMemberId.fromString(conn.getRemoteMemberId());
      final CallMemberId redialedId = CallMemberId(id.userId, null);

      final CallMember? redialed = members[redialedId];
      if (redialed?.isDialing.value == true) {
        members.move(redialedId, id);
      }

      CallMember? member = members[id];

      if (member != null) {
        member.id = id;
        member._connection = conn;
        member.isConnected.value = true;
        member.isDialing.value = false;
      } else {
        members[id] = CallMember(
          id,
          conn,
          isHandRaised: call.value?.members
                  .firstWhereOrNull((e) => e.user.id == id.userId)
                  ?.handRaised ??
              false,
          isConnected: true,
        );
      }

      conn.onClose(() {
        Log.print('onClose', 'CALL');
        members.remove(id)?.dispose();
      });

      conn.onRemoteTrackAdded((track) async {
        Log.print(
          'onRemoteTrackAdded ${track.kind()}-${track.mediaSourceKind()}, ${track.mediaDirection()}',
          'CALL',
        );

        final Track t = Track(track);

        if (track.mediaDirection().isEmitting) {
          final CallMember? redialed = members[redialedId];
          if (redialed?.isDialing.value == true) {
            members.move(redialedId, id);
          }

          member = members[id];
          member?.id = id;
          member?.isConnected.value = true;
          member?.isDialing.value = false;

          member?.tracks.add(t);
        }

        track.onMuted(() {
          t.isMuted.value = true;
          Log.print('onMuted', 'CALL');
        });

        track.onUnmuted(() {
          t.isMuted.value = false;
          Log.print('onUnmuted', 'CALL');
        });

        track.onMediaDirectionChanged((TrackMediaDirection d) async {
          Log.print(
            'onMediaDirectionChanged ${track.kind()}-${track.mediaSourceKind()} ${track.mediaDirection()}',
            'CALL',
          );

          t.direction.value = d;

          switch (d) {
            case TrackMediaDirection.sendRecv:
            case TrackMediaDirection.sendOnly:
              member?.tracks.addIf(!member!.tracks.contains(t), t);
              switch (track.kind()) {
                case MediaKind.audio:
                  await t.createRenderer();
                  break;

                case MediaKind.video:
                  await t.createRenderer();
                  break;
              }
              break;

            case TrackMediaDirection.recvOnly:
            case TrackMediaDirection.inactive:
              member?.tracks.remove(t);
              await t.removeRenderer();
              break;
          }
        });

        track.onStopped(() {
          Log.print(
            'onStopped ${track.kind()}-${track.mediaSourceKind()}',
            'CALL',
          );

          member?.tracks.remove(t..dispose());
        });

        switch (track.kind()) {
          case MediaKind.audio:
            if (isRemoteAudioEnabled.isTrue) {
              if (track.mediaDirection().isEmitting) {
                await t.createRenderer();
              }
            } else {
              await member?.setAudioEnabled(false);
            }
            break;

          case MediaKind.video:
            if (isRemoteVideoEnabled.isTrue) {
              if (track.mediaDirection().isEmitting) {
                await t.createRenderer();
              }
            } else {
              await member?.setVideoEnabled(false, source: t.source);
            }
            break;
        }
      });

      conn.onQualityScoreUpdate((p0) {
        member?.quality.value = p0;
        Log.print(
          'onQualityScoreUpdate with ${conn.getRemoteMemberId()}: $p0',
          'CALL',
        );
      });
    });
  }

  /// Raises/lowers a hand of the authorized [MyUser].
  Future<void> toggleHand(CallService service) {
    // Toggle the hands of all the devices of the authenticated [MyUser].
    for (MapEntry<CallMemberId, CallMember> m
        in members.entries.where((e) => e.key.userId == _me.userId)) {
      m.value.isHandRaised.toggle();
    }
    return _toggleHand(service);
  }

  /// Invokes a [CallService.toggleHand] method, toggling the hand of [me].
  Future<void> _toggleHand(CallService service) async {
    if (!_toggleHandGuard.isLocked) {
      final CallMember me = members[_me]!;

      bool raised = me.isHandRaised.value;
      await _toggleHandGuard.protect(() async {
        _handToggles.add(raised);
        await service.toggleHand(chatId.value, raised);
      });

      if (raised != me.isHandRaised.value) {
        _toggleHand(service);
      }
    }
  }

  /// Initializes the local media tracks and renderers before the call has
  /// started.
  ///
  /// Disposes this [OngoingCall] if it was marked for disposal.
  ///
  /// This behaviour is required for [Jason] to correctly release its resources.
  Future<void> _initLocalMedia() async {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      await Permission.microphone.request();
      await Permission.camera.request();
    }
    await _mediaSettingsGuard.protect(() async {
      // Populate [devices] with a list of available media input devices.
      if (videoDevice.value == null &&
          screenDevice.value == null &&
          (audioDevice.value == null || audioDevice.value == 'default') &&
          (outputDevice.value == null || outputDevice.value == 'default')) {
        enumerateDevices();
      } else {
        try {
          await enumerateDevices();
        } catch (_) {
          // No-op.
        }

        _ensureCorrectDevices();

        if (outputDevice.value != null) {
          MediaUtils.mediaManager?.setOutputAudioId(outputDevice.value!);
        }
      }

      // First, try to init the local tracks with [_mediaStreamSettings].
      List<LocalMediaTrack> tracks = [];

      // Initializes the local tracks recursively.
      Future<void> initLocalTracks() async {
        try {
          tracks = await MediaUtils.getTracks(
            audio: audioState.value == LocalTrackState.enabling
                ? AudioPreferences(device: audioDevice.value)
                : null,
            video: videoState.value == LocalTrackState.enabling
                ? VideoPreferences(
                    device: videoDevice.value,
                    facingMode:
                        videoDevice.value == null ? FacingMode.user : null,
                  )
                : null,
            screen: screenShareState.value == LocalTrackState.enabling
                ? ScreenPreferences(device: screenDevice.value)
                : null,
          );
        } on LocalMediaInitException catch (e) {
          switch (e.kind()) {
            case LocalMediaInitExceptionKind.getUserMediaAudioFailed:
              audioDevice.value = null;
              audioState.value = LocalTrackState.disabled;
              await initLocalTracks();
              break;

            case LocalMediaInitExceptionKind.getUserMediaVideoFailed:
              videoDevice.value = null;
              videoState.value = LocalTrackState.disabled;
              await initLocalTracks();
              break;

            case LocalMediaInitExceptionKind.getDisplayMediaFailed:
              screenDevice.value = null;
              screenShareState.value = LocalTrackState.disabled;
              await initLocalTracks();
              break;

            default:
              rethrow;
          }
        }
      }

      if (audioState.value != LocalTrackState.enabled &&
          audioState.value != LocalTrackState.enabling) {
        await _room?.muteAudio();
      }
      if (videoState.value != LocalTrackState.enabled &&
          videoState.value != LocalTrackState.enabling) {
        await _room?.disableVideo(MediaSourceKind.device);
      }
      if (screenShareState.value != LocalTrackState.enabled &&
          screenShareState.value != LocalTrackState.enabling) {
        await _room?.disableVideo(MediaSourceKind.display);
      }

      try {
        await initLocalTracks();
      } catch (e) {
        audioState.value = LocalTrackState.disabled;
        videoState.value = LocalTrackState.disabled;
        screenShareState.value = LocalTrackState.disabled;
        addError('initLocalTracks() call failed with $e');
      }

      // Add the local tracks asynchronously.
      for (LocalMediaTrack track in tracks) {
        _addLocalTrack(track);
      }

      // Update the list of [devices] just in case the permissions were given.
      enumerateDevices().then((_) => _pickOutputDevice());

      audioState.value = audioState.value == LocalTrackState.enabling
          ? LocalTrackState.enabled
          : audioState.value;
      videoState.value = videoState.value == LocalTrackState.enabling
          ? LocalTrackState.enabled
          : videoState.value;
      screenShareState.value =
          screenShareState.value == LocalTrackState.enabling
              ? LocalTrackState.enabled
              : screenShareState.value;

      try {
        // Second, set all constraints to `true` (disabled tracks will not be
        // sent).
        await _room?.setLocalMediaSettings(
          _mediaStreamSettings(
            audioDevice: audioDevice.value,
            videoDevice: videoDevice.value,
            screenDevice: screenDevice.value,
          ),
          false,
          true,
        );
      } on StateError catch (e) {
        // TODO: Proper handling. Jason should add enum so we don't assert the
        //       message.
        // [_room] is allowed to be in a detached state there as the call might
        // has already ended.
        if (!e.toString().contains('detached')) {
          addError('setLocalMediaSettings() failed: $e');
          rethrow;
        }
      } catch (e) {
        addError('setLocalMediaSettings() failed: $e');
        rethrow;
      }
    });
  }

  /// Disposes the local media tracks.
  void _disposeLocalMedia() {
    for (Track t in members[_me]?.tracks ?? []) {
      t.dispose();
    }
    members[_me]?.tracks.clear();
  }

  /// Joins the [_room] with the provided [ChatCallRoomJoinLink].
  ///
  /// Re-initializes the [_room], if this [link] is different from the currently
  /// used [ChatCall.joinLink].
  Future<void> _joinRoom(ChatCallRoomJoinLink link) async {
    me.isConnected.value = false;

    Log.print('Joining the room...', 'CALL');
    if (call.value?.joinLink != null && call.value?.joinLink != link) {
      Log.print('Closing the previous one and connecting to the new', 'CALL');
      _closeRoom();
      _initRoom();
    }

    try {
      await _room?.join('$link?token=$creds');
    } on RpcClientException catch (e) {
      Log.error('Joining the room failed due to: ${e.message()}');
      rethrow;
    }

    Log.print('Room joined!', 'CALL');

    me.isConnected.value = true;
  }

  /// Closes the [_room] and releases the associated resources.
  void _closeRoom() {
    if (_room != null) {
      try {
        MediaUtils.jason?.closeRoom(_room!);
        _room!.free();
      } catch (_) {
        // No-op, as the room might be in a detached state.
      }
    }
    _room = null;

    for (Track t in members.values.expand((e) => e.tracks)) {
      t.dispose();
    }
    members.removeWhere((id, _) => id != _me);
  }

  /// Updates the local media settings with [audioDevice], [videoDevice] or
  /// [screenDevice].
  Future<void> _updateSettings({
    String? audioDevice,
    String? videoDevice,
    String? screenDevice,
  }) async {
    if (audioDevice != null || videoDevice != null || screenDevice != null) {
      try {
        await _mediaSettingsGuard.acquire();
        _removeLocalTracks(
          audioDevice == null ? MediaKind.video : MediaKind.audio,
          screenDevice == null
              ? MediaSourceKind.device
              : MediaSourceKind.display,
        );

        MediaStreamSettings settings = _mediaStreamSettings(
          audioDevice: audioDevice ?? this.audioDevice.value,
          videoDevice: videoDevice ?? this.videoDevice.value,
          screenDevice: screenDevice ?? this.screenDevice.value,
        );
        try {
          await _room?.setLocalMediaSettings(settings, true, true);
          this.audioDevice.value = audioDevice ?? this.audioDevice.value;
          this.videoDevice.value = videoDevice ?? this.videoDevice.value;
          this.screenDevice.value = screenDevice ?? this.screenDevice.value;

          await _updateTracks(
            audio: audioDevice != null,
            video: videoDevice != null,
            screen: screenDevice != null,
          );
        } catch (_) {
          // No-op.
        }
      } finally {
        _mediaSettingsGuard.release();
      }
    }
  }

  /// Updates the local tracks corresponding to the current media
  /// [LocalTrackState]s.
  Future<void> _updateTracks({
    bool audio = false,
    bool video = false,
    bool screen = false,
  }) async {
    final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
      audio: hasAudio && audio
          ? AudioPreferences(device: audioDevice.value)
          : null,
      video: videoState.value.isEnabled && video
          ? VideoPreferences(
              device: videoDevice.value,
              facingMode: videoDevice.value == null ? FacingMode.user : null,
            )
          : null,
      screen: screenShareState.value.isEnabled && screen
          ? ScreenPreferences(device: screenDevice.value)
          : null,
    );

    for (LocalMediaTrack track in tracks) {
      await _addLocalTrack(track);
    }
  }

  /// Adds the provided [track] to the local tracks and initializes video
  /// renderer if required.
  Future<void> _addLocalTrack(LocalMediaTrack track) async {
    track.onEnded(() {
      switch (track.kind()) {
        case MediaKind.audio:
          setAudioEnabled(false);
          break;

        case MediaKind.video:
          switch (track.mediaSourceKind()) {
            case MediaSourceKind.device:
              setVideoEnabled(false);
              break;

            case MediaSourceKind.display:
              setScreenShareEnabled(false);
              break;
          }
          break;
      }
    });

    if (track.kind() == MediaKind.video) {
      LocalTrackState state;
      switch (track.mediaSourceKind()) {
        case MediaSourceKind.device:
          state = videoState.value;
          break;

        case MediaSourceKind.display:
          state = screenShareState.value;
          break;
      }

      if (state == LocalTrackState.disabling ||
          state == LocalTrackState.disabled) {
        track.free();
      } else {
        _removeLocalTracks(track.kind(), track.mediaSourceKind());

        Track t = Track(track);
        members[_me]?.tracks.add(t);

        if (track.mediaSourceKind() == MediaSourceKind.device) {
          videoDevice.value = videoDevice.value ?? track.getTrack().deviceId();
        } else if (track.mediaSourceKind() == MediaSourceKind.display) {
          screenDevice.value =
              screenDevice.value ?? track.getTrack().deviceId();
        }

        await t.createRenderer();
      }
    } else {
      _removeLocalTracks(track.kind(), track.mediaSourceKind());

      members[_me]?.tracks.add(Track(track));

      if (track.mediaSourceKind() == MediaSourceKind.device) {
        audioDevice.value = audioDevice.value ?? track.getTrack().deviceId();
      }
    }
  }

  /// Removes and stops the [LocalMediaTrack]s that match the [kind] and
  /// [source] from the local [CallMember].
  void _removeLocalTracks(MediaKind kind, MediaSourceKind source) {
    members[_me]?.tracks.removeWhere((t) {
      if (t.kind == kind && t.source == source) {
        t.dispose();
        return true;
      }
      return false;
    });
  }

  /// Ensures the [audioDevice], [videoDevice], [screenDevice], and
  /// [outputDevice] are present in the [devices] list.
  ///
  /// If the device is not found, then sets it to `null`.
  void _ensureCorrectDevices() {
    if (audioDevice.value != null &&
        devices.audio().none((d) => d.deviceId() == audioDevice.value)) {
      audioDevice.value = null;
    }

    if (videoDevice.value != null &&
        devices.video().none((d) => d.deviceId() == videoDevice.value)) {
      videoDevice.value = null;
    }

    if (screenDevice.value != null &&
        displays.none((d) => d.deviceId() == screenDevice.value)) {
      screenDevice.value = null;
    }

    if (outputDevice.value != null &&
        devices.output().none((d) => d.deviceId() == outputDevice.value)) {
      outputDevice.value = null;
    }
  }

  /// Picks the [outputDevice] based on the provided [previous], [added] and
  /// [removed].
  void _pickOutputDevice([
    List<MediaDeviceDetails> previous = const [],
    List<MediaDeviceDetails> added = const [],
    List<MediaDeviceDetails> removed = const [],
  ]) {
    MediaDeviceDetails? device;

    if (added.output().isNotEmpty) {
      device = added.output().first;
    } else if (removed.any((e) => e.deviceId() == outputDevice.value) ||
        (outputDevice.value == null &&
            removed.any((e) =>
                e.deviceId() == previous.output().firstOrNull?.deviceId()))) {
      device = devices.output().first;
    }

    if (device != null) {
      _notifications.add(DeviceChangedNotification(device: device));
      setOutputDevice(device.deviceId());
    }
  }

  /// Picks the [audioDevice] based on the provided [previous], [added] and
  /// [removed].
  void _pickAudioDevice([
    List<MediaDeviceDetails> previous = const [],
    List<MediaDeviceDetails> added = const [],
    List<MediaDeviceDetails> removed = const [],
  ]) {
    MediaDeviceDetails? device;

    if (added.audio().isNotEmpty) {
      device = added.audio().first;
    } else if (removed.any((e) => e.deviceId() == audioDevice.value) ||
        (audioDevice.value == null &&
            removed.any((e) =>
                e.deviceId() == previous.audio().firstOrNull?.deviceId()))) {
      device = devices.audio().first;
    }

    if (device != null) {
      _notifications.add(DeviceChangedNotification(device: device));
      setAudioDevice(device.deviceId());
    }
  }

  /// Picks the [videoDevice] based on the provided [previous] and [removed].
  void _pickVideoDevice([
    List<MediaDeviceDetails> previous = const [],
    List<MediaDeviceDetails> removed = const [],
  ]) {
    if (removed.any((e) => e.deviceId() == videoDevice.value) ||
        (videoDevice.value == null &&
            removed.any((e) =>
                e.deviceId() == previous.video().firstOrNull?.deviceId()))) {
      setVideoEnabled(false);
      videoDevice.value = null;
    }
  }

  /// Disables screen sharing, if the [screenDevice] is [removed].
  void _pickScreenDevice(List<MediaDisplayDetails> removed) {
    if (removed.any((e) => e.deviceId() == screenDevice.value)) {
      setScreenShareEnabled(false);
    }
  }
}

/// Possible kinds of a media ownership.
enum MediaOwnerKind { local, remote }

/// Convenience wrapper around a [webrtc.MediaStreamTrack].
abstract class RtcRenderer {
  const RtcRenderer(this.track);

  /// Native media track of this [RtcRenderer].
  final webrtc.MediaStreamTrack track;

  /// Disposes this [RtcRenderer] and its [track].
  Future<void> dispose();
}

/// Convenience wrapper around a [webrtc.VideoRenderer].
class RtcVideoRenderer extends RtcRenderer {
  RtcVideoRenderer(MediaTrack track) : super(track.getTrack()) {
    if (track is LocalMediaTrack) {
      autoRotate = false;

      if (PlatformUtils.isMobile) {
        mirror = track.getTrack().facingMode() == webrtc.FacingMode.user;
      } else {
        mirror = track.mediaSourceKind() == MediaSourceKind.device;
      }
    }
  }

  /// Indicator whether this [RtcVideoRenderer] should be mirrored.
  bool mirror = false;

  /// Indicator whether this [RtcVideoRenderer] should be auto rotated.
  bool autoRotate = true;

  /// Actual [webrtc.VideoRenderer].
  final webrtc.VideoRenderer _delegate = webrtc.createVideoRenderer();

  /// Returns actual width of the [track].
  int get width => _delegate.videoWidth;

  /// Returns actual height of the [track].
  int get height => _delegate.videoHeight;

  /// Returns actual aspect ratio of the [track].
  double get aspectRatio => width / height;

  /// Returns inner [webrtc.VideoRenderer].
  ///
  /// This should be only used to interop with `flutter_webrtc`.
  webrtc.VideoRenderer get inner => _delegate;

  /// Sets [webrtc.VideoRenderer.srcObject] property.
  set srcObject(webrtc.MediaStreamTrack? track) =>
      _delegate.setSrcObject(track);

  /// Initializes inner [webrtc.VideoRenderer].
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<void> dispose() => _delegate.dispose();
}

/// Convenience wrapper around an [webrtc.AudioRenderer].
class RtcAudioRenderer extends RtcRenderer {
  RtcAudioRenderer(MediaTrack track) : super(track.getTrack()) {
    srcObject = track.getTrack();
  }

  /// Actual [webrtc.AudioRenderer].
  final webrtc.AudioRenderer _delegate = webrtc.createAudioRenderer();

  /// Sets [webrtc.AudioRenderer.srcObject] property.
  set srcObject(webrtc.MediaStreamTrack? track) => _delegate.srcObject = track;

  @override
  Future<void> dispose() => _delegate.dispose();
}

/// Call member ID of an [OngoingCall] containing its [UserId] and
/// [ChatCallDeviceId].
class CallMemberId {
  const CallMemberId(this.userId, this.deviceId);

  /// Constructs a [CallMemberId] from the provided [string].
  factory CallMemberId.fromString(String string) {
    var split = string.split('.');
    if (split.length != 2) {
      throw const FormatException('Must have a UserId.DeviceId format');
    }

    return CallMemberId(UserId(split[0]), ChatCallDeviceId(split[1]));
  }

  /// [UserId] part of this [CallMemberId].
  final UserId userId;

  /// [ChatCallDeviceId] part of this [CallMemberId].
  final ChatCallDeviceId? deviceId;

  @override
  int get hashCode => '$userId.$deviceId'.hashCode;

  @override
  String toString() => '$userId.$deviceId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallMemberId &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          deviceId == other.deviceId;
}

/// Participant of an [OngoingCall].
class CallMember {
  CallMember(
    this.id,
    this._connection, {
    bool isHandRaised = false,
    bool isConnected = false,
    bool isDialing = false,
  })  : isHandRaised = RxBool(isHandRaised),
        isConnected = RxBool(isConnected),
        isDialing = RxBool(isDialing),
        owner = MediaOwnerKind.remote;

  CallMember.me(
    this.id, {
    bool isHandRaised = false,
    bool isConnected = false,
    bool isDialing = false,
  })  : isHandRaised = RxBool(isHandRaised),
        isConnected = RxBool(isConnected),
        isDialing = RxBool(isDialing),
        owner = MediaOwnerKind.local;

  /// [CallMemberId] of this [CallMember].
  CallMemberId id;

  /// List of [Track]s of this [CallMember].
  final ObsList<Track> tracks = ObsList();

  /// [MediaOwnerKind] of this [CallMember].
  final MediaOwnerKind owner;

  /// Indicator whether the hand of this [CallMember] is raised.
  final RxBool isHandRaised;

  /// Indicator whether this [CallMember] is connected to the media server.
  final RxBool isConnected;

  /// Indicator whether this [CallMember] is dialing.
  final RxBool isDialing;

  /// Signal quality of this [CallMember] ranging from 1 to 4.
  final RxInt quality = RxInt(4);

  /// [ConnectionHandle] of this [CallMember].
  ConnectionHandle? _connection;

  /// Disposes the [tracks] of this [CallMember].
  void dispose() {
    for (var t in tracks) {
      t.dispose();
    }
  }

  /// Sets the inbound video of this [CallMember] as [enabled].
  Future<void> setVideoEnabled(
    bool enabled, {
    MediaSourceKind source = MediaSourceKind.device,
  }) async {
    if (enabled) {
      await _connection?.enableRemoteVideo(source);
    } else {
      await _connection?.disableRemoteVideo(source);
    }
  }

  /// Sets the inbound audio of this [CallMember] as [enabled].
  Future<void> setAudioEnabled(bool enabled) async {
    if (enabled) {
      await _connection?.enableRemoteAudio();
    } else {
      await _connection?.disableRemoteAudio();
    }
  }
}

/// Convenience wrapper around a [MediaTrack].
class Track {
  Track(this.track)
      : kind = track.kind(),
        source = track.mediaSourceKind() {
    if (track is RemoteMediaTrack) {
      isMuted = RxBool((track as RemoteMediaTrack).muted());
    } else {
      isMuted = RxBool(false);
    }
  }

  /// [MediaTrack] itself.
  final MediaTrack track;

  /// [RtcRenderer] of this [Track], if any.
  final Rx<RtcRenderer?> renderer = Rx(null);

  /// [TrackMediaDirection] this [Track] has.
  final Rx<TrackMediaDirection> direction = Rx(TrackMediaDirection.sendRecv);

  /// Indicator whether this [Track] is muted.
  late final RxBool isMuted;

  /// [MediaSourceKind] of this [Track].
  final MediaSourceKind source;

  /// [MediaKind] of this [Track].
  final MediaKind kind;

  /// Indicator whether this [Track] is already disposed or not.
  ///
  /// Used to prohibit multiple [dispose] invoking.
  bool _disposed = false;

  /// [Mutex] guarding the [renderer] synchronized access.
  ///
  /// Used to neglect the possible [createRenderer] and [removeRenderer] races.
  final Mutex _rendererGuard = Mutex();

  /// Creates the [renderer] for this [Track].
  Future<void> createRenderer() async {
    await _rendererGuard.protect(() async {
      if (renderer.value != null) {
        await renderer.value?.dispose();
      }

      switch (track.kind()) {
        case MediaKind.audio:
          renderer.value = RtcAudioRenderer(track);
          break;

        case MediaKind.video:
          renderer.value = RtcVideoRenderer(track);
          await (renderer.value as RtcVideoRenderer?)?.initialize();
          (renderer.value as RtcVideoRenderer?)?.srcObject = track.getTrack();
          break;
      }
    });
  }

  /// Disposes the [renderer] of this [Track].
  Future<void> removeRenderer() async {
    await _rendererGuard.protect(() async {
      renderer.value?.dispose();
      renderer.value = null;
    });
  }

  /// Disposes this [Track].
  ///
  /// No-op, if this [Track] was already disposed.
  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      await Future.wait([removeRenderer(), track.free()]);
    }
  }

  /// Stops the [webrtc.MediaStreamTrack] of this [Track].
  Future<void> stop() async {
    await Future.wait([
      track.getTrack().stop(),
      removeRenderer(),
    ]);
  }
}

/// Extension adding an ability to querying the [MediaDeviceDetails] by
/// [MediaDeviceKind].
extension DevicesList on List<MediaDeviceDetails> {
  /// Returns a new [Iterable] with [MediaDeviceDetails] of
  /// [MediaDeviceKind.videoInput].
  Iterable<MediaDeviceDetails> video() {
    return where((i) => i.kind() == MediaDeviceKind.videoInput);
  }

  /// Returns a new [Iterable] with [MediaDeviceDetails] of
  /// [MediaDeviceKind.audioInput].
  Iterable<MediaDeviceDetails> audio() {
    return where((i) => i.kind() == MediaDeviceKind.audioInput);
  }

  /// Returns a new [Iterable] with [MediaDeviceDetails] of
  /// [MediaDeviceKind.audioOutput].
  Iterable<MediaDeviceDetails> output() {
    return where((i) => i.kind() == MediaDeviceKind.audioOutput);
  }
}

/// Possible [CallNotification] kind.
enum CallNotificationKind {
  connectionLost,
  connectionRestored,
  deviceChanged,
  error,
}

/// Notification of an event happened in [OngoingCall].
abstract class CallNotification {
  /// Returns the [CallNotificationKind] of this [CallNotification].
  CallNotificationKind get kind;
}

/// [CallNotification] of a device changed event.
class DeviceChangedNotification extends CallNotification {
  DeviceChangedNotification({required this.device});

  /// [MediaDeviceDetails] of the device changed.
  final MediaDeviceDetails device;

  @override
  CallNotificationKind get kind => CallNotificationKind.deviceChanged;
}

// TODO: Temporary solution. Errors should be captured the other way.
/// [CallNotification] of an error.
class ErrorNotification extends CallNotification {
  ErrorNotification({required this.message});

  /// Message of this [ErrorNotification] describing the error happened.
  final String message;

  @override
  CallNotificationKind get kind => CallNotificationKind.error;
}

/// [CallNotification] of a connection lost event.
class ConnectionLostNotification extends CallNotification {
  @override
  CallNotificationKind get kind => CallNotificationKind.connectionLost;
}

/// [CallNotification] of a connection restored event.
class ConnectionRestoredNotification extends CallNotification {
  @override
  CallNotificationKind get kind => CallNotificationKind.connectionRestored;
}
