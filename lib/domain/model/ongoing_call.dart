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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:medea_flutter_webrtc/medea_flutter_webrtc.dart' as webrtc;
import 'package:medea_jason/medea_jason.dart';
import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../service/call.dart';
import '/domain/model/media_settings.dart';
import '/domain/repository/call.dart';
import '/provider/gql/exceptions.dart' show ResubscriptionRequiredException;
import '/store/event/chat_call.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'chat.dart';
import 'chat_call.dart';
import 'chat_item.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user.dart';

/// Reactive list of [MediaDeviceInfo]s.
typedef InputDevices = RxList<MediaDeviceInfo>;

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
  /// Indicates whether the current value is [TrackMediaDirection.SendRecv] or
  /// [TrackMediaDirection.SendOnly].
  bool get isEmitting {
    switch (this) {
      case TrackMediaDirection.SendRecv:
      case TrackMediaDirection.SendOnly:
        return true;
      case TrackMediaDirection.RecvOnly:
      case TrackMediaDirection.Inactive:
        return false;
    }
  }

  /// Indicates whether the current value is [TrackMediaDirection.SendRecv].
  bool get isEnabled {
    switch (this) {
      case TrackMediaDirection.SendRecv:
        return true;
      case TrackMediaDirection.SendOnly:
      case TrackMediaDirection.RecvOnly:
      case TrackMediaDirection.Inactive:
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

  /// Reactive map of [CallMember]s of this [OngoingCall].
  final RxObsMap<CallMemberId, CallMember> members =
      RxObsMap<CallMemberId, CallMember>();

  /// Indicator whether this [OngoingCall] is [connect]ed to the remote updates
  /// or not.
  ///
  /// If `true` then this call can be considered as an answered ongoing call,
  /// and not just as a notification of an ongoing call in background.
  bool connected = false;

  /// List of [MediaDeviceInfo] of all the available devices.
  final InputDevices devices = RxList<MediaDeviceInfo>([]);

  /// List of [MediaDisplayInfo] of all the available displays.
  final RxList<MediaDisplayInfo> displays = RxList<MediaDisplayInfo>([]);

  /// Indicator whether this [OngoingCall] should not initialize any media
  /// client related resources.
  bool _background = true;

  /// Client for communication with a media server.
  Jason? _jason;

  /// Handle to a media manager tracking all the connected devices.
  MediaManagerHandle? _mediaManager;

  /// Room on a media server representing this [OngoingCall].
  RoomHandle? _room;

  /// [CallMemberId] of the authenticated [MyUser].
  CallMemberId _me;

  /// Heartbeat subscription indicating that [MyUser] is connected and this
  /// [OngoingCall] is alive on a client side.
  StreamSubscription? _heartbeat;

  /// Mutex for synchronized access to [RoomHandle.setLocalMediaSettings].
  final Mutex _mediaSettingsGuard = Mutex();

  /// Mutex guarding [toggleHand].
  final Mutex _toggleHandGuard = Mutex();

  // TODO: Temporary solution. Errors should be captured the other way.
  /// Temporary [StreamController] of the [errors].
  final StreamController<String> _errors = StreamController.broadcast();

  /// Returns the [ChatItemId] of this [OngoingCall].
  ChatItemId? get callChatItemId => call.value?.id;

  /// Returns the [CallMember] of the currently authorized [MyUser].
  CallMember get me => members[_me]!;

  /// Returns the local [Track]s.
  ObsList<Track>? get localTracks => members[_me]?.tracks;

  /// [User] that started this [OngoingCall].
  User? get caller => call.value?.caller;

  /// Returns the room on a media server representing this [OngoingCall].
  RoomHandle? get room => _room;

  /// Indicates whether this [OngoingCall] is intended to start with video.
  ///
  /// Used to determine incoming [OngoingCall] type.
  bool? get withVideo => call.value?.withVideo;

  /// Returns the [PreciseDateTime] when the actual conversation in this
  /// [ChatCall] was started (after ringing had been finished).
  PreciseDateTime? get conversationStartedAt =>
      call.value?.conversationStartedAt;

  // TODO: Temporary solution. Errors should be captured the other way.
  /// Returns the stream of the errors happening in this [OngoingCall].
  Stream<String> get errors => _errors.stream;

  /// Indicates whether this [OngoingCall] is active.
  bool get isActive => (state.value == OngoingCallState.active ||
      state.value == OngoingCallState.joining);

  /// Initializes the media client resources.
  ///
  /// No-op if already initialized.
  Future<void> init() async {
    if (_jason == null) {
      _background = false;

      try {
        _jason = Jason();
      } catch (_) {
        // TODO: So the test would run. Jason currently only supports Web and
        //       Android, and unit tests run on a host machine.
        _jason = null;
        return;
      }

      members[_me] = CallMember.me(_me);

      _mediaManager = _jason!.mediaManager();
      _mediaManager?.onDeviceChange(() async {
        await enumerateDevices();
        _pickOutputDevice();
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
  Future<void> connect(
    CallService? calls, [
    Future<Stream<ChatCallEvents>> Function(ChatItemId, ChatCallDeviceId)?
        heartbeat,
  ]) async {
    assert(
      calls != null || heartbeat != null,
      'At least one of calls and heartbeat must not be null',
    );

    if (connected || callChatItemId == null || deviceId == null) {
      return;
    }

    heartbeat ??= calls!.heartbeat;

    CallMemberId id = CallMemberId(_me.userId, deviceId);
    members.move(_me, id);
    _me = id;

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

            if (node.call.finishReason != null) {
              // Call is already ended, so remove it.
              calls?.remove(chatId.value);
              calls?.removeCredentials(node.call.id);
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
            }

            call.value = node.call;
            call.refresh();

            break;

          case ChatCallEventsKind.event:
            var versioned = (e as ChatCallEventsEvent).event;
            for (var event in versioned.events) {
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
                    calls?.removeCredentials(node.call.id);
                    calls?.remove(chatId.value);
                  }
                  break;

                case ChatCallEventKind.memberLeft:
                  var node = event as EventChatCallMemberLeft;
                  if (me.id.userId == node.user.id) {
                    calls?.remove(chatId.value);
                  }

                  final CallMemberId id =
                      CallMemberId(node.user.id, node.deviceId);
                  if (members[id]?.isConnected.value == false) {
                    members.remove(id);
                  }
                  break;

                case ChatCallEventKind.memberJoined:
                  var node = event as EventChatCallMemberJoined;

                  final CallMemberId id =
                      CallMemberId(node.user.id, node.deviceId);
                  if (!members.containsKey(id)) {
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

                  if (node.user.id == me.id.userId &&
                      _toggleHandGuard.isLocked) {
                    break;
                  }

                  for (MapEntry<CallMemberId, CallMember> m in members.entries
                      .where((e) => e.key.userId == node.user.id)) {
                    m.value.isHandRaised.value = false;
                  }

                  for (ChatCallMember m in (call.value?.members ?? [])
                      .where((e) => e.user.id == node.user.id)) {
                    m.handRaised = false;
                  }
                  break;

                case ChatCallEventKind.handRaised:
                  var node = event as EventChatCallHandRaised;

                  if (node.user.id == me.id.userId &&
                      _toggleHandGuard.isLocked) {
                    break;
                  }

                  for (MapEntry<CallMemberId, CallMember> m in members.entries
                      .where((e) => e.key.userId == node.user.id)) {
                    m.value.isHandRaised.value = true;
                  }

                  for (ChatCallMember m in (call.value?.members ?? [])
                      .where((e) => e.user.id == node.user.id)) {
                    m.handRaised = true;
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

                  calls?.moveCall(
                    chatId: node.chatId,
                    newChatId: node.newChatId,
                    callId: node.callId,
                    newCallId: node.newCallId,
                  );
                  break;

                case ChatCallEventKind.redialed:
                  // TODO: Implement EventChatCallMemberRedialed.
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
          Log.print(e.toString(), 'CALL');
          calls?.remove(chatId.value);
          throw e;
        }
      },
      onDone: () => calls?.remove(chatId.value),
    );
  }

  /// Disposes the call and [Jason] client if it was previously initialized.
  Future<void> dispose() {
    return _mediaSettingsGuard.protect(() async {
      _disposeLocalMedia();
      if (_jason != null) {
        _mediaManager!.free();
        _mediaManager = null;
        _closeRoom();
        _jason!.free();
        _jason = null;
      }
      _heartbeat?.cancel();
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
            if (deviceId != screenDevice.value) {
              await _updateSettings(screenDevice: deviceId);
            }

            await _room?.enableVideo(MediaSourceKind.Display);
            screenShareState.value = LocalTrackState.enabled;
            if (!isActive || members.length <= 1) {
              await _updateTracks();
            }
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            if (!e.toString().contains('Permission denied')) {
              screenShareState.value = LocalTrackState.disabled;
              _errors.add('enableScreenShare() call failed with $e');
              rethrow;
            }
          }
        }
        break;

      case LocalTrackState.enabled:
      case LocalTrackState.enabling:
        if (!enabled) {
          screenShareState.value = LocalTrackState.disabling;
          try {
            await _room?.disableVideo(MediaSourceKind.Display);
            _removeLocalTracks(MediaKind.Video, MediaSourceKind.Display);
            screenShareState.value = LocalTrackState.disabled;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            _errors.add('disableScreenShare() call failed with $e');
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
            if (members[_me]
                    ?.tracks
                    .where((t) =>
                        t.kind == MediaKind.Audio &&
                        t.source == MediaSourceKind.Device)
                    .isEmpty ??
                false) {
              await _room?.enableAudio();
            }
            await _room?.unmuteAudio();
            audioState.value = LocalTrackState.enabled;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            audioState.value = LocalTrackState.disabled;
            _errors.add('unmuteAudio() call failed with $e');
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
            _errors.add('muteAudio() call failed with $e');
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
            await _room?.enableVideo(MediaSourceKind.Device);
            videoState.value = LocalTrackState.enabled;
            if (!isActive || members.length <= 1) {
              _updateTracks();
            }
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            _errors.add('enableVideo() call failed with $e');
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
            await _room?.disableVideo(MediaSourceKind.Device);
            _removeLocalTracks(MediaKind.Video, MediaSourceKind.Device);
            videoState.value = LocalTrackState.disabled;
          } on MediaStateTransitionException catch (_) {
            // No-op.
          } catch (e) {
            _errors.add('disableVideo() call failed with $e');
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

  /// Populates [devices] with a list of [MediaDeviceInfo] objects representing
  /// available media input devices, such as microphones, cameras, and so forth.
  Future<void> enumerateDevices() async {
    try {
      devices.value = (await _mediaManager!.enumerateDevices())
          .whereNot((e) => e.deviceId().isEmpty)
          .toList();

      if (PlatformUtils.isDesktop && !PlatformUtils.isWeb) {
        displays.value = await _mediaManager!.enumerateDisplays();
      }
    } on EnumerateDevicesException catch (e) {
      _errors.add('Failed to enumerate devices: $e');
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
      await _mediaManager?.setOutputAudioId(deviceId);
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
          if (m.tracks.any((e) => e.kind == MediaKind.Audio)) {
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
            m.setVideoEnabled(true, source: MediaSourceKind.Device),
            m.setVideoEnabled(true, source: MediaSourceKind.Display),
          ]);
        }

        isRemoteVideoEnabled.toggle();
      } else if (!enabled && isRemoteVideoEnabled.isTrue) {
        for (CallMember m in members.values.where((e) => e.id != _me)) {
          m.tracks.where((e) => e.kind == MediaKind.Video).forEach((e) {
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

  /// Adds the provided [message] to the [errors] stream.
  ///
  /// Should (and intended to) be used as a notification measure.
  void addError(String message) => _errors.add(message);

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
    _room = _jason!.initRoom();

    _room!.onFailedLocalMedia((e) async {
      if (e is LocalMediaInitException) {
        try {
          switch (e.kind()) {
            case LocalMediaInitExceptionKind.GetUserMediaAudioFailed:
              _errors.add('Failed to acquire local audio: $e');
              await _room?.disableAudio();
              _removeLocalTracks(MediaKind.Audio, MediaSourceKind.Device);
              audioState.value = LocalTrackState.disabled;
              break;

            case LocalMediaInitExceptionKind.GetUserMediaVideoFailed:
              _errors.add('Failed to acquire local video: $e');
              await setVideoEnabled(false);
              break;

            case LocalMediaInitExceptionKind.GetDisplayMediaFailed:
              _errors.add('Failed to initiate screen capture: $e');
              await setScreenShareEnabled(false);
              break;

            default:
              _errors.add('Failed to get media: $e');

              await _room?.disableAudio();
              _removeLocalTracks(MediaKind.Audio, MediaSourceKind.Device);
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
          _errors.add('$e');
        }
      }
    });

    bool connectionLost = false;
    _room!.onConnectionLoss((e) async {
      Log.print('onConnectionLoss', 'CALL');

      if (!connectionLost) {
        connectionLost = true;

        _errors.add('Connection with media server lost $e');
        await e.reconnectWithBackoff(500, 2, 5000);
        _errors.add('Connection restored'); // for notification

        connectionLost = false;
      }
    });

    _room!.onLocalTrack((e) => _addLocalTrack(e));

    _room!.onNewConnection((conn) {
      final CallMemberId id = CallMemberId.fromString(conn.getRemoteMemberId());
      final CallMember? member = members[id];

      if (member != null) {
        member._connection = conn;
        member.isConnected.value = true;
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

      conn.onClose(() => members.remove(id));
      conn.onRemoteTrackAdded((track) async {
        final Track t = Track(track);
        final CallMember? member = members[id]?..tracks.add(t);

        track.onMuted(() => t.isMuted.value = true);
        track.onUnmuted(() => t.isMuted.value = false);

        track.onMediaDirectionChanged((TrackMediaDirection d) async {
          t.direction.value = d;

          switch (d) {
            case TrackMediaDirection.SendRecv:
              switch (track.kind()) {
                case MediaKind.Audio:
                  await t.createRenderer();
                  break;

                case MediaKind.Video:
                  await t.createRenderer();
                  break;
              }

              member?.tracks.addIf(!member.tracks.contains(t), t);
              break;

            case TrackMediaDirection.SendOnly:
              switch (track.kind()) {
                case MediaKind.Audio:
                  t.removeRenderer();
                  break;

                case MediaKind.Video:
                  t.removeRenderer();
                  break;
              }

              member?.tracks.addIf(!member.tracks.contains(t), t);
              break;

            case TrackMediaDirection.RecvOnly:
            case TrackMediaDirection.Inactive:
              t.removeRenderer();
              member?.tracks.remove(t);
              break;
          }
        });

        track.onStopped(() => member?.tracks.remove(t..dispose()));

        switch (track.kind()) {
          case MediaKind.Audio:
            if (isRemoteAudioEnabled.isTrue) {
              await t.createRenderer();
            } else {
              await member?.setAudioEnabled(false);
            }
            break;

          case MediaKind.Video:
            if (isRemoteVideoEnabled.isTrue) {
              await t.createRenderer();
            } else {
              await member?.setVideoEnabled(false, source: t.source);
            }
            break;
        }
      });
    });
  }

  /// Raises/lowers a hand of the authorized [MyUser].
  Future<void> toggleHand(CallService service) {
    members[_me]!.isHandRaised.toggle();
    return _toggleHand(service);
  }

  /// Invokes a [CallService.toggleHand] method, toggling the hand of [me].
  Future<void> _toggleHand(CallService service) async {
    if (!_toggleHandGuard.isLocked) {
      final CallMember me = members[_me]!;

      bool raised = me.isHandRaised.value;
      await _toggleHandGuard.protect(() async {
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
          _mediaManager?.setOutputAudioId(outputDevice.value!);
        }
      }

      // First, try to init the local tracks with [_mediaStreamSettings].
      List<LocalMediaTrack> tracks = [];

      // Initializes the local tracks recursively.
      Future<void> initLocalTracks() async {
        try {
          tracks = await _mediaManager!.initLocalTracks(_mediaStreamSettings(
            audio: audioState.value == LocalTrackState.enabling,
            video: videoState.value == LocalTrackState.enabling,
            screen: screenShareState.value == LocalTrackState.enabling,
            audioDevice: audioDevice.value,
            videoDevice: videoDevice.value,
            screenDevice: screenDevice.value,
            facingMode: videoDevice.value == null ? FacingMode.User : null,
          ));
        } on LocalMediaInitException catch (e) {
          switch (e.kind()) {
            case LocalMediaInitExceptionKind.GetUserMediaAudioFailed:
              audioDevice.value = null;
              audioState.value = LocalTrackState.disabled;
              await initLocalTracks();
              break;

            case LocalMediaInitExceptionKind.GetUserMediaVideoFailed:
              videoDevice.value = null;
              videoState.value = LocalTrackState.disabled;
              await initLocalTracks();
              break;

            case LocalMediaInitExceptionKind.GetDisplayMediaFailed:
              screenDevice.value = null;
              screenShareState.value = LocalTrackState.disabled;
              await initLocalTracks();
              break;

            default:
              rethrow;
          }
        }
      }

      try {
        await initLocalTracks();
      } catch (e) {
        audioState.value = LocalTrackState.disabled;
        videoState.value = LocalTrackState.disabled;
        screenShareState.value = LocalTrackState.disabled;
        _errors.add('initLocalTracks() call failed with $e');
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
        if (audioState.value != LocalTrackState.enabled) {
          await _room?.muteAudio();
        }
        if (videoState.value != LocalTrackState.enabled) {
          await _room?.disableVideo(MediaSourceKind.Device);
        }
        if (screenShareState.value != LocalTrackState.enabled) {
          await _room?.disableVideo(MediaSourceKind.Display);
        }

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
          _errors.add('setLocalMediaSettings() failed: $e');
          rethrow;
        }
      } catch (e) {
        _errors.add('setLocalMediaSettings() failed: $e');
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

    await _room?.join('$link/$_me?token=$creds');
    Log.print('Room joined!', 'CALL');

    me.isConnected.value = true;
  }

  /// Closes the [_room] and releases the associated resources.
  void _closeRoom() {
    if (_room != null) {
      try {
        _jason?.closeRoom(_room!);
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
          audioDevice == null ? MediaKind.Video : MediaKind.Audio,
          MediaSourceKind.Device,
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

          if (!isActive || members.length <= 1) {
            await _updateTracks();
          }
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
  Future<void> _updateTracks() async {
    List<LocalMediaTrack> tracks = await _mediaManager!.initLocalTracks(
      _mediaStreamSettings(
        audio: audioState.value.isEnabled,
        video: videoState.value.isEnabled,
        screen: screenShareState.value.isEnabled,
        audioDevice: audioDevice.value,
        videoDevice: videoDevice.value,
        screenDevice: screenDevice.value,
      ),
    );

    _disposeLocalMedia();
    for (LocalMediaTrack track in tracks) {
      await _addLocalTrack(track);
    }
  }

  /// Adds the provided [track] to the local tracks and initializes video
  /// renderer if required.
  Future<void> _addLocalTrack(LocalMediaTrack track) async {
    if (track.kind() == MediaKind.Video) {
      LocalTrackState state;
      switch (track.mediaSourceKind()) {
        case MediaSourceKind.Device:
          state = videoState.value;
          break;

        case MediaSourceKind.Display:
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

        if (track.mediaSourceKind() == MediaSourceKind.Device) {
          videoDevice.value = videoDevice.value ?? track.getTrack().deviceId();
        } else if (track.mediaSourceKind() == MediaSourceKind.Display) {
          screenDevice.value =
              screenDevice.value ?? track.getTrack().deviceId();
        }

        await t.createRenderer();
      }
    } else {
      _removeLocalTracks(track.kind(), track.mediaSourceKind());

      members[_me]?.tracks.add(Track(track));

      if (track.mediaSourceKind() == MediaSourceKind.Device) {
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

  /// Updates the [outputDevice] on Android.
  ///
  /// The following priority is used:
  /// 1. bluetooth headset;
  /// 2. speakerphone.
  void _pickOutputDevice() {
    if (PlatformUtils.isAndroid) {
      var output = devices
              .output()
              .firstWhereOrNull((e) => e.deviceId() == 'bluetooth-headset')
              ?.deviceId() ??
          devices
              .output()
              .firstWhereOrNull((e) => e.deviceId() == 'speakerphone')
              ?.deviceId();
      if (output != null && outputDevice.value != output) {
        setOutputDevice(output);
      }
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
      inner.mirror = track.mediaSourceKind() == MediaSourceKind.Device;
    }
  }

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
  Future<void> dispose() => Future.wait([track.dispose(), _delegate.dispose()]);
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
  Future<void> dispose() => Future.wait([track.dispose(), _delegate.dispose()]);
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
  })  : isHandRaised = RxBool(isHandRaised),
        isConnected = RxBool(isConnected),
        owner = MediaOwnerKind.remote;

  CallMember.me(
    this.id, {
    bool isHandRaised = false,
    bool isConnected = false,
  })  : isHandRaised = RxBool(isHandRaised),
        isConnected = RxBool(isConnected),
        owner = MediaOwnerKind.local;

  /// [CallMemberId] of this [CallMember].
  final CallMemberId id;

  /// List of [Track]s of this [CallMember].
  final ObsList<Track> tracks = ObsList();

  /// [MediaOwnerKind] of this [CallMember].
  final MediaOwnerKind owner;

  /// Indicator whether the hand of this [CallMember] is raised.
  final RxBool isHandRaised;

  /// Indicator whether this [CallMember] is connected to the media server.
  final RxBool isConnected;

  /// [ConnectionHandle] of this [CallMember].
  ConnectionHandle? _connection;

  /// Sets the inbound video of this [CallMember] as [enabled].
  Future<void> setVideoEnabled(
    bool enabled, {
    MediaSourceKind source = MediaSourceKind.Device,
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
  final Rx<TrackMediaDirection> direction = Rx(TrackMediaDirection.SendRecv);

  /// Indicator whether this [Track] is muted.
  late final RxBool isMuted;

  /// [MediaSourceKind] of this [Track].
  final MediaSourceKind source;

  /// [MediaKind] of this [Track].
  final MediaKind kind;

  /// Creates the [renderer] for this [Track].
  Future<void> createRenderer() async {
    switch (track.kind()) {
      case MediaKind.Audio:
        renderer.value = RtcAudioRenderer(track);
        break;

      case MediaKind.Video:
        renderer.value = RtcVideoRenderer(track);
        await (renderer.value as RtcVideoRenderer).initialize();
        (renderer.value as RtcVideoRenderer).srcObject = track.getTrack();
        break;
    }
  }

  /// Disposes the [renderer] of this [Track].
  void removeRenderer() {
    renderer.value?.dispose();
    renderer.value = null;
  }

  /// Disposes this [Track].
  void dispose() {
    removeRenderer();
    track.free();
  }

  /// Stops the [webrtc.MediaStreamTrack] of this [Track].
  void stop() {
    track.getTrack().stop();
    removeRenderer();
  }
}

extension DevicesList on InputDevices {
  /// Returns a new [Iterable] with [MediaDeviceInfo]s of
  /// [MediaDeviceKind.videoinput].
  Iterable<MediaDeviceInfo> video() {
    return where((i) => i.kind() == MediaDeviceKind.videoinput);
  }

  /// Returns a new [Iterable] with [MediaDeviceInfo]s of
  /// [MediaDeviceKind.audioinput].
  Iterable<MediaDeviceInfo> audio() {
    return where((i) => i.kind() == MediaDeviceKind.audioinput);
  }

  /// Returns a new [Iterable] with [MediaDeviceInfo]s of
  /// [MediaDeviceKind.audiooutput].
  Iterable<MediaDeviceInfo> output() {
    return where((i) => i.kind() == MediaDeviceKind.audiooutput);
  }
}
