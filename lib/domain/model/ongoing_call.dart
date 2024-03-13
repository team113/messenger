// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/domain/model/media_settings.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/provider/gql/exceptions.dart' show ResubscriptionRequiredException;
import '/store/event/chat_call.dart';
import '/util/audio_utils.dart';
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
  /// [LocalTrackState.enabling].
  bool get isEnabled {
    switch (this) {
      case LocalTrackState.enabled:
      case LocalTrackState.enabling:
        return true;
      case LocalTrackState.disabled:
      case LocalTrackState.disabling:
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
        _preferredAudioDevice = mediaSettings?.audioDevice,
        _preferredOutputDevice = mediaSettings?.outputDevice,
        _preferredVideoDevice = mediaSettings?.videoDevice,
        _preferredScreenDevice = mediaSettings?.screenDevice {
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

    _stateWorker = ever(this.state, (state) {
      _participated = _participated || isActive;
    });
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

  /// [DeviceDetails] currently used as a microphone device.
  final Rx<DeviceDetails?> audioDevice = Rx(null);

  /// [DeviceDetails] currently used as a audio output device.
  final Rx<DeviceDetails?> outputDevice = Rx(null);

  /// [DeviceDetails] currently used as a video device.
  final Rx<DeviceDetails?> videoDevice = Rx(null);

  /// [MediaDisplayDetails] currently used as a screen share device.
  final Rx<MediaDisplayDetails?> screenDevice = Rx(null);

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

  /// List of [DeviceDetails] of all the available devices.
  final RxList<DeviceDetails> devices = RxList<DeviceDetails>([]);

  /// List of [MediaDisplayDetails] of all the available displays.
  final RxList<MediaDisplayDetails> displays = RxList<MediaDisplayDetails>([]);

  /// ID of the preferred microphone device.
  ///
  /// Used during [_pickAudioDevice] to determine, whether the [audioDevice]
  /// should be changed, or ignored.
  String? _preferredAudioDevice;

  /// ID of the preferred audio output device.
  ///
  /// Used during [_pickOutputDevice] to determine, whether the [outputDevice]
  /// should be changed, or ignored.
  String? _preferredOutputDevice;

  /// ID of the preferred video device.
  ///
  /// Used to determine the [videoDevice].
  final String? _preferredVideoDevice;

  /// ID of the preferred video device.
  ///
  /// Used to determine the [screenDevice].
  final String? _preferredScreenDevice;

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

  /// [StreamSubscription] for the [MediaUtilsImpl.onDeviceChange] stream
  /// updating the [devices].
  StreamSubscription? _devicesSubscription;

  /// [StreamSubscription] for the [MediaUtilsImpl.onDisplayChange] stream
  /// updating the [displays].
  StreamSubscription? _displaysSubscription;

  /// [Worker] reacting on the [MediaUtilsImpl.outputDeviceId] changes updating
  /// the [outputDevice].
  Worker? _outputWorker;

  /// Indicator whether [isActive] was `true` at least once during the lifecycle
  /// of this [OngoingCall].
  ///
  /// Required, as neither [state] nor [connected] hold its values when
  /// [dispose]d.
  bool _participated = false;

  /// [Worker] reacting on the [state] changes updating the [_participated].
  Worker? _stateWorker;

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

  /// Indicates whether the current authorized [MyUser] is the caller.
  bool get outgoing => me.id.userId == caller?.id || caller == null;

  /// Indicates whether [isActive] was `true` at least once during the lifecycle
  /// of this [OngoingCall].
  ///
  /// Intended be used to determine whether [OngoingCall] is not a notification.
  bool get participated => _participated;

  /// Initializes the media client resources.
  ///
  /// No-op if already initialized.
  Future<void> init({FutureOr<RxChat?> Function(ChatId)? getChat}) async {
    Log.debug('init()', '$runtimeType');

    if (_background) {
      _background = false;

      _devicesSubscription = MediaUtils.onDeviceChange.listen((e) async {
        Log.debug('onDeviceChange(${e.map((e) => e.label())})', '$runtimeType');

        final List<DeviceDetails> previous =
            List.from(devices, growable: false);

        devices.value = e;

        final List<DeviceDetails> removed = [];

        for (DeviceDetails d in previous) {
          if (devices.none((p) => p.deviceId() == d.deviceId())) {
            removed.add(d);
          }
        }

        final bool audioChanged = !previous
            .audio()
            .map((e) => e.deviceId())
            .sameAs(devices.audio().map((e) => e.deviceId()));

        final bool outputChanged = !previous
            .output()
            .map((e) => e.deviceId())
            .sameAs(devices.output().map((e) => e.deviceId()));

        final bool videoChanged = !previous
            .video()
            .map((e) => e.deviceId())
            .sameAs(devices.video().map((e) => e.deviceId()));

        if (audioChanged) {
          _pickAudioDevice();
        }

        if (outputChanged) {
          _pickOutputDevice();
        }

        if (videoChanged) {
          _pickVideoDevice(previous, removed);
        }
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

      // Puts the members of the provided [chat] to the [members] through
      // [_addDialing].
      Future<void> addDialingsFrom(RxChat? chat) async {
        if (chat == null) {
          return;
        }

        final int membersCount = chat.chat.value.membersCount;
        final bool shouldAddDialed =
            (outgoing && conversationStartedAt == null) ||
                chat.chat.value.isDialog;

        // Dialed [User]s should be added, if [membersCount] is less than a page
        // of [Chat.members].
        if (membersCount <= chat.members.perPage && shouldAddDialed) {
          if (chat.members.length < membersCount) {
            await chat.members.around();
          }

          // If [connected], then the dialed [User] will be added in [connect],
          // when handling [ChatMembersDialedAll].
          if (!connected) {
            for (UserId e
                in chat.members.items.keys.where((e) => e != me.id.userId)) {
              _addDialing(e);
            }
          }
        }
      }

      // Retrieve the [RxChat] this [OngoingCall] is happening in to add its
      // members to the [members] in redialing mode as fast as possible.
      final FutureOr<RxChat?>? chatOrFuture = getChat?.call(chatId.value);
      if (chatOrFuture is RxChat?) {
        addDialingsFrom(chatOrFuture);
      } else {
        chatOrFuture.then(addDialingsFrom);
      }

      _initRoom();
      await _setInitialMediaSettings();
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
    Log.debug('connect($calls)', '$runtimeType');

    _participated = true;

    if (connected || callChatItemId == null || deviceId == null) {
      return;
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
            Log.debug('heartbeat(): ${e.kind}', '$runtimeType');
            break;

          case ChatCallEventsKind.chatCall:
            Log.debug('heartbeat(): ${e.kind}', '$runtimeType');

            final node = e as ChatCallEventsChatCall;

            _handToggles.clear();

            if (node.call.finishReason != null) {
              // Call is already ended, so remove it.
              calls.remove(chatId.value);
              calls.removeCredentials(node.call.chatId, node.call.id);
            } else {
              call.value = node.call;
              call.refresh();

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
                // Remove the members, who are not connected and still
                // redialing, that are missing from the [dialed].
                members.removeWhere(
                  (_, v) =>
                      v.isConnected.isFalse &&
                      v.isDialing.isTrue &&
                      dialed.members.none((e) => e.user.id == v.id.userId) &&
                      node.call.members.none((e) => e.user.id == v.id.userId),
                );

                for (final ChatMember m in dialed.members) {
                  _addDialing(m.user.id);
                }
              } else if (dialed == null) {
                // Remove the members, who are not connected and still
                // redialing, since no one is [dialed].
                members.removeWhere(
                  (_, v) =>
                      v.isConnected.isFalse &&
                      v.isDialing.isTrue &&
                      node.call.members.none((e) => e.user.id == v.id.userId),
                );
              }

              // Subscribes to the [RxChat.members] changes, adding the dialed
              // users.
              //
              // Additionally handles the case, when [dialed] are
              // [ChatMembersDialedAll], since we need to have a [RxChat] to
              // retrieve the whole list of users this way.
              Future<void> redialAndResubscribe(RxChat? v) async {
                if (!connected || v == null) {
                  // [OngoingCall] might have been disposed or disconnected
                  // while this [Future] was executing.
                  return;
                }

                // Add the redialed members of the call to the [members].
                if (dialed is ChatMembersDialedAll &&
                    v.chat.value.membersCount <= v.members.perPage) {
                  if (v.members.length < v.chat.value.membersCount) {
                    await v.members.around();
                  }

                  // Check if [ChatCall.dialed] is still [ChatMembersDialedAll].
                  if (call.value?.dialed is ChatMembersDialedAll) {
                    final Iterable<RxUser> dialings =
                        v.members.values.map((e) => e.user).where(
                              (e) =>
                                  e.id != me.id.userId &&
                                  dialed.answeredMembers
                                      .none((a) => a.user.id == e.id),
                            );

                    // Remove the members, who are not connected and still
                    // redialing, that are missing from the [dialings].
                    members.removeWhere(
                      (_, v) =>
                          v.isConnected.isFalse &&
                          v.isDialing.isTrue &&
                          dialings.none((e) => e.id == v.id.userId) &&
                          node.call.members
                              .none((e) => e.user.id == v.id.userId),
                    );

                    for (final RxUser e in dialings) {
                      _addDialing(e.id);
                    }
                  }
                }
              }

              // Retrieve the [RxChat] to subscribe to its [RxChat.members]
              // changes, so that added users are displayed as dialed right
              // away.
              final FutureOr<RxChat?> chatOrFuture =
                  calls.getChat(chatId.value);
              if (chatOrFuture is RxChat?) {
                redialAndResubscribe(chatOrFuture);
              } else {
                chatOrFuture.then(redialAndResubscribe);
              }

              members[_me]?.isHandRaised.value = node.call.members
                      .firstWhereOrNull((e) => e.user.id == _me.userId)
                      ?.handRaised ??
                  false;
            }
            break;

          case ChatCallEventsKind.event:
            final versioned = (e as ChatCallEventsEvent).event;
            Log.debug(
              'heartbeat(ChatCallEventsEvent): ${versioned.events.map((e) => e.kind)}',
              '$runtimeType($id)',
            );

            for (final ChatCallEvent event in versioned.events) {
              switch (event.kind) {
                case ChatCallEventKind.roomReady:
                  final node = event as EventChatCallRoomReady;

                  if (!_background) {
                    await _joinRoom(node.joinLink);
                  }

                  call.value?.joinLink = node.joinLink;
                  call.refresh();

                  state.value = OngoingCallState.active;
                  break;

                case ChatCallEventKind.finished:
                  final node = event as EventChatCallFinished;
                  if (node.chatId == chatId.value) {
                    calls.removeCredentials(node.call.chatId, node.call.id);
                    calls.remove(chatId.value);
                  }
                  break;

                case ChatCallEventKind.memberLeft:
                  final node = event as EventChatCallMemberLeft;
                  if (me.id.userId == node.user.id &&
                      me.id.deviceId == node.deviceId) {
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
                  final node = event as EventChatCallMemberJoined;

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
                  final node = event as EventChatCallHandLowered;

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
                  final node = event as EventChatCallHandRaised;

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
                  final node = event as EventChatCallDeclined;
                  final CallMemberId id = CallMemberId(node.user.id, null);
                  if (members[id]?.isConnected.value == false) {
                    members.remove(id)?.dispose();
                  }
                  break;

                case ChatCallEventKind.callMoved:
                  final node = event as EventChatCallMoved;
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
                  final node = event as EventChatCallMemberRedialed;
                  _addDialing(node.user.id);
                  break;

                case ChatCallEventKind.answerTimeoutPassed:
                  final node = event as EventChatCallAnswerTimeoutPassed;

                  if (node.user?.id != null) {
                    final CallMemberId id = CallMemberId(node.user!.id, null);
                    if (members[id]?.isConnected.value == false) {
                      members.remove(id)?.dispose();
                    }
                  } else {
                    call.value?.dialed = null;

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

                case ChatCallEventKind.undialed:
                  final node = event as EventChatCallMemberUndialed;

                  final CallMemberId id = CallMemberId(node.user.id, null);
                  if (members[id]?.isConnected.value == false) {
                    members.remove(id)?.dispose();
                  }
                  break;
              }
            }
            break;
        }
      },
      onError: (e) {
        if (e is! ResubscriptionRequiredException) {
          throw e;
        }
      },
    );
  }

  /// Disposes the call and [Jason] client if it was previously initialized.
  Future<void> dispose() {
    Log.debug('dispose()', '$runtimeType');

    _heartbeat?.cancel();
    _participated = _participated || connected || isActive;
    _stateWorker?.dispose();
    connected = false;

    return _mediaSettingsGuard.protect(() async {
      _disposeLocalMedia();
      if (!_background) {
        _closeRoom();
      }
      _devicesSubscription?.cancel();
      _displaysSubscription?.cancel();
      _heartbeat?.cancel();
      _outputWorker?.dispose();
      connected = false;
    });
  }

  /// Leaves this [OngoingCall].
  ///
  /// Throws a [LeaveChatCallException].
  Future<void> leave(CallService calls) async {
    Log.debug('leave()', '$runtimeType');
    await calls.leave(chatId.value, deviceId);
  }

  /// Declines this [OngoingCall].
  ///
  /// Throws a [DeclineChatCallException].
  Future<void> decline(CallService calls) async {
    Log.debug('decline()', '$runtimeType');
    await calls.decline(chatId.value);
  }

  /// Joins this [OngoingCall].
  ///
  /// Throws a [JoinChatCallException], [CallDoesNotExistException].
  Future<void> join(
    CallService calls, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) async {
    Log.debug(
      'join($withAudio, $withVideo, $withScreen)',
      '$runtimeType',
    );

    await calls.join(
      chatId.value,
      withAudio: withAudio,
      withVideo: withVideo,
      withScreen: withScreen,
    );
  }

  /// Enables/disables local screen-sharing stream based on [enabled].
  Future<void> setScreenShareEnabled(
    bool enabled, {
    MediaDisplayDetails? device,
  }) async {
    Log.debug(
      'setScreenShareEnabled($enabled, ${device?.deviceId()})',
      '$runtimeType',
    );

    switch (screenShareState.value) {
      case LocalTrackState.disabled:
      case LocalTrackState.disabling:
        if (enabled) {
          screenShareState.value = LocalTrackState.enabling;
          try {
            await _updateSettings(screenDevice: device ?? displays.firstOrNull);
            await _room?.enableVideo(MediaSourceKind.display);
            screenShareState.value = LocalTrackState.enabled;

            final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
              screen: ScreenPreferences(device: screenDevice.value?.deviceId()),
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
    Log.debug('setAudioEnabled($enabled)', '$runtimeType');

    switch (audioState.value) {
      case LocalTrackState.disabled:
      case LocalTrackState.disabling:
        if (enabled) {
          audioState.value = LocalTrackState.enabling;
          try {
            if (!hasAudio) {
              await _room?.enableAudio();

              final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
                audio: AudioPreferences(device: audioDevice.value?.deviceId()),
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
    Log.debug('setVideoEnabled($enabled)', '$runtimeType');

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
                device: videoDevice.value?.deviceId(),
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
  Future<void> toggleAudio() async {
    Log.debug('toggleAudio()', '$runtimeType');

    await setAudioEnabled(
      audioState.value != LocalTrackState.enabled &&
          audioState.value != LocalTrackState.enabling,
    );
  }

  /// Toggles local video stream on and off.
  Future<void> toggleVideo([bool? enabled]) async {
    Log.debug('toggleVideo($enabled)', '$runtimeType');

    await setVideoEnabled(
      videoState.value != LocalTrackState.enabled &&
          videoState.value != LocalTrackState.enabling,
    );
  }

  /// Populates [devices] with a list of [DeviceDetails] objects representing
  /// available media input devices, such as microphones, cameras, and so forth.
  Future<void> enumerateDevices({bool media = true, bool screen = true}) async {
    Log.debug('enumerateDevices($media, $screen)', '$runtimeType');

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

  /// Sets the provided [device] as a currently used [audioDevice].
  ///
  /// Does nothing if [device] is already the [audioDevice].
  Future<void> setAudioDevice(DeviceDetails device) {
    Log.debug('setAudioDevice($device)', '$runtimeType');

    _preferredAudioDevice = device.id();
    return _setAudioDevice(device);
  }

  /// Sets the provided [device] as a currently used [videoDevice].
  ///
  /// Does nothing if [device] is already the [videoDevice].
  Future<void> setVideoDevice(DeviceDetails device) async {
    Log.debug('setVideoDevice($device)', '$runtimeType');

    if ((videoDevice.value != null && device != videoDevice.value) ||
        (videoDevice.value == null &&
            devices.video().firstOrNull?.deviceId() != device.deviceId())) {
      await _updateSettings(videoDevice: device);
    }
  }

  /// Sets the provided [device] as a currently used [outputDevice].
  ///
  /// Does nothing if [device] is already the [outputDevice].
  Future<void> setOutputDevice(DeviceDetails device) {
    Log.debug('setOutputDevice($device)', '$runtimeType');

    _preferredOutputDevice = device.id();
    return _setOutputDevice(device);
  }

  /// Sets inbound audio in this [OngoingCall] as [enabled] or not.
  ///
  /// No-op if [isRemoteAudioEnabled] is already [enabled].
  Future<void> setRemoteAudioEnabled(bool enabled) async {
    Log.debug('setRemoteAudioEnabled($enabled)', '$runtimeType');

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
    Log.debug('setRemoteVideoEnabled($enabled)', '$runtimeType');

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
  Future<void> toggleRemoteAudio() async {
    Log.debug('toggleRemoteAudio()', '$runtimeType');
    await setRemoteAudioEnabled(!isRemoteAudioEnabled.value);
  }

  /// Toggles inbound video in this [OngoingCall] on and off.
  Future<void> toggleRemoteVideo() async {
    Log.debug('toggleRemoteVideo()', '$runtimeType');
    await setRemoteVideoEnabled(!isRemoteVideoEnabled.value);
  }

  /// Adds the provided [message] to the [notifications] stream as
  /// [ErrorNotification].
  ///
  /// Should (and intended to) be used as a notification measure.
  void addError(String message) {
    Log.debug('addError($message)', '$runtimeType');
    _notifications.add(ErrorNotification(message: message));
  }

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
    DeviceDetails? audioDevice,
    DeviceDetails? videoDevice,
    MediaDisplayDetails? screenDevice,
    FacingMode? facingMode,
  }) {
    Log.debug(
      '_mediaStreamSettings($audio, $video, $screen, $audioDevice, $videoDevice, $screenDevice, $facingMode)',
      '$runtimeType',
    );

    final MediaStreamSettings settings = MediaStreamSettings();

    if (audio) {
      AudioTrackConstraints constraints = AudioTrackConstraints();
      if (audioDevice != null) {
        constraints.deviceId(audioDevice.deviceId());
      }
      settings.audio(constraints);
    }

    if (video) {
      DeviceVideoTrackConstraints constraints = DeviceVideoTrackConstraints();
      if (videoDevice != null) constraints.deviceId(videoDevice.deviceId());
      if (facingMode != null) constraints.idealFacingMode(facingMode);
      settings.deviceVideo(constraints);
    }

    if (screen) {
      DisplayVideoTrackConstraints constraints = DisplayVideoTrackConstraints();
      if (screenDevice != null) {
        constraints.deviceId(screenDevice.deviceId());
      }
      constraints.idealFrameRate(30);
      settings.displayVideo(constraints);
    }

    return settings;
  }

  /// Initializes the [_room].
  void _initRoom() {
    Log.debug('_initRoom()', '$runtimeType');

    _room = MediaUtils.jason!.initRoom();

    _room!.onFailedLocalMedia((e) async {
      Log.debug('onFailedLocalMedia($e)', '$runtimeType');

      if (e is LocalMediaInitException) {
        try {
          switch (e.kind()) {
            case LocalMediaInitExceptionKind.getUserMediaAudioFailed:
              addError('Failed to acquire local audio: ${e.message()}');
              await _room?.disableAudio();
              _removeLocalTracks(MediaKind.audio, MediaSourceKind.device);
              audioState.value = LocalTrackState.disabled;
              break;

            case LocalMediaInitExceptionKind.getUserMediaVideoFailed:
              addError('Failed to acquire local video: ${e.message()}');
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
      Log.debug('onConnectionLoss', '$runtimeType');

      if (connectionLost.isFalse) {
        connectionLost.value = true;

        _notifications.add(ConnectionLostNotification());
        await e.reconnectWithBackoff(500, 2, 5000);
        _notifications.add(ConnectionRestoredNotification());

        connectionLost.value = false;
      }
    });

    _room!.onNewConnection((conn) {
      Log.debug('onNewConnection', '$runtimeType');

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
        Log.debug('onClose', '$runtimeType');
        members.remove(id)?.dispose();
      });

      conn.onRemoteTrackAdded((track) async {
        final MediaKind kind = track.kind();
        final MediaSourceKind source = track.mediaSourceKind();

        Log.debug(
          'onRemoteTrackAdded $kind-$source, ${track.mediaDirection()}',
          '$runtimeType',
        );

        final Track t = Track(track);

        final CallMember? redialed = members[redialedId];
        if (redialed?.isDialing.value == true) {
          members.move(redialedId, id);
        }

        member = members[id];
        member?.id = id;
        member?.isConnected.value = true;
        member?.isDialing.value = false;

        if (track.mediaDirection().isEmitting) {
          member?.tracks.add(t);
        }

        track.onMuted(() {
          Log.debug('onMuted $kind-$source', '$runtimeType');
          t.isMuted.value = true;
        });

        track.onUnmuted(() {
          Log.debug('onUnmuted $kind-$source', '$runtimeType');
          t.isMuted.value = false;
        });

        track.onMediaDirectionChanged((TrackMediaDirection d) async {
          Log.debug(
            'onMediaDirectionChanged $kind-$source ${track.mediaDirection()}',
            '$runtimeType',
          );

          t.direction.value = d;

          switch (d) {
            case TrackMediaDirection.sendRecv:
              members[id]?.tracks.addIf(!members[id]!.tracks.contains(t), t);
              switch (kind) {
                case MediaKind.audio:
                  await t.createRenderer();
                  break;

                case MediaKind.video:
                  await t.createRenderer();
                  break;
              }
              break;

            case TrackMediaDirection.sendOnly:
              members[id]?.tracks.addIf(!members[id]!.tracks.contains(t), t);
              await t.removeRenderer();
              break;

            case TrackMediaDirection.recvOnly:
            case TrackMediaDirection.inactive:
              members[id]?.tracks.remove(t);
              await t.removeRenderer();
              break;
          }
        });

        track.onStopped(() {
          Log.debug('onStopped $kind-$source', '$runtimeType');
          members[id]?.tracks.remove(t..dispose());
        });

        switch (kind) {
          case MediaKind.audio:
            if (isRemoteAudioEnabled.isTrue) {
              if (track.mediaDirection().isEmitting) {
                await t.createRenderer();
              }
            } else {
              await members[id]?.setAudioEnabled(false);
            }
            break;

          case MediaKind.video:
            if (isRemoteVideoEnabled.isTrue) {
              if (track.mediaDirection().isEmitting) {
                await t.createRenderer();
              }
            } else {
              await members[id]?.setVideoEnabled(false, source: t.source);
            }
            break;
        }
      });

      conn.onQualityScoreUpdate((p) {
        Log.debug(
          'onQualityScoreUpdate with ${conn.getRemoteMemberId()}: $p',
          '$runtimeType',
        );

        members[id]?.quality.value = p;
      });
    });
  }

  /// Raises/lowers a hand of the authorized [MyUser].
  Future<void> toggleHand(CallService service) {
    Log.debug('toggleHand()', '$runtimeType');

    // Toggle the hands of all the devices of the authenticated [MyUser].
    for (MapEntry<CallMemberId, CallMember> m
        in members.entries.where((e) => e.key.userId == _me.userId)) {
      m.value.isHandRaised.toggle();
    }
    return _toggleHand(service);
  }

  /// Invokes a [CallService.toggleHand] method, toggling the hand of [me].
  Future<void> _toggleHand(CallService service) async {
    Log.debug('_toggleHand()', '$runtimeType');

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

  /// Adds a [CallMember] identified by its [userId], if none is in the
  /// [members] already.
  void _addDialing(UserId userId) {
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

  /// Initializes the local media tracks and renderers before the call has
  /// started.
  ///
  /// Disposes this [OngoingCall] if it was marked for disposal.
  ///
  /// This behaviour is required for [Jason] to correctly release its resources.
  Future<void> _initLocalMedia() async {
    Log.debug('_initLocalMedia()', '$runtimeType');

    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      await Permission.microphone.request();
      await Permission.camera.request();
    }

    await _mediaSettingsGuard.protect(() async {
      // Populate [devices] with a list of available media input devices.
      try {
        await enumerateDevices();
      } catch (_) {
        // No-op.
      }

      // On mobile platforms, output device is picked in the following priority:
      // - headphones;
      // - earpiece (if [videoState] is disabled);
      // - speaker (if [videoState] is enabled).
      if (PlatformUtils.isMobile) {
        _outputWorker = ever(
          MediaUtils.outputDeviceId,
          (id) {
            outputDevice.value =
                devices.output().firstWhereOrNull((e) => e.deviceId() == id) ??
                    outputDevice.value;
          },
        );

        if (outputDevice.value == null) {
          final Iterable<DeviceDetails> output = devices.output();
          outputDevice.value = output.firstWhereOrNull(
            (e) => e.speaker == AudioSpeakerKind.headphones,
          );

          if (outputDevice.value == null) {
            final bool speaker =
                PlatformUtils.isWeb ? true : videoState.value.isEnabled;

            if (speaker) {
              outputDevice.value = output.firstWhereOrNull(
                (e) => e.speaker == AudioSpeakerKind.speaker,
              );
            }

            outputDevice.value ??= output.firstWhereOrNull(
              (e) => e.speaker == AudioSpeakerKind.earpiece,
            );
          }
        }
      } else {
        // On any other platform the output device is the preferred one.
        outputDevice.value = devices
                .output()
                .firstWhereOrNull((e) => e.id() == _preferredOutputDevice) ??
            devices.output().firstOrNull;
      }

      audioDevice.value = devices
              .audio()
              .firstWhereOrNull((e) => e.id() == _preferredAudioDevice) ??
          devices.audio().firstOrNull;

      videoDevice.value = devices
          .video()
          .firstWhereOrNull((e) => e.id() == _preferredVideoDevice);

      screenDevice.value = displays
          .firstWhereOrNull((e) => e.deviceId() == _preferredScreenDevice);

      if (outputDevice.value != null) {
        MediaUtils.setOutputDevice(outputDevice.value!.deviceId());
      }

      // First, try to init the local tracks with [_mediaStreamSettings].
      List<LocalMediaTrack> tracks = [];

      // Initializes the local tracks recursively.
      Future<void> initLocalTracks() async {
        try {
          tracks = await MediaUtils.getTracks(
            audio: hasAudio || audioState.value.isEnabled
                ? AudioPreferences(
                    device: audioDevice.value?.deviceId() ??
                        devices.audio().firstOrNull?.deviceId(),
                  )
                : null,
            video: videoState.value.isEnabled
                ? VideoPreferences(
                    device: videoDevice.value?.deviceId() ??
                        devices.video().firstOrNull?.deviceId(),
                    facingMode:
                        videoDevice.value == null ? FacingMode.user : null,
                  )
                : null,
            screen: screenShareState.value.isEnabled
                ? ScreenPreferences(
                    device: screenDevice.value?.deviceId() ??
                        displays.firstOrNull?.deviceId(),
                  )
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
    Log.debug('_disposeLocalMedia()', '$runtimeType');

    for (Track t in members[_me]?.tracks ?? []) {
      t.dispose();
    }
    members[_me]?.tracks.clear();
  }

  /// Sets the [_mediaStreamSettings] with track statuses based on [audioState],
  /// [videoState], [screenShareState].
  Future<void> _setInitialMediaSettings() async {
    Log.debug('_setInitialMediaSettings()', '$runtimeType');

    try {
      // Set all the constraints to ensure no disabled track is sent while
      // initializing the local media.
      await _room?.setLocalMediaSettings(
        _mediaStreamSettings(
          audio: hasAudio || audioState.value.isEnabled,
          video: videoState.value.isEnabled,
          screen: screenShareState.value.isEnabled,
        ),
        false,
        true,
      );
    } on StateError catch (e) {
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
  }

  /// Joins the [_room] with the provided [ChatCallRoomJoinLink].
  ///
  /// Re-initializes the [_room], if this [link] is different from the currently
  /// used [ChatCall.joinLink].
  Future<void> _joinRoom(ChatCallRoomJoinLink link) async {
    Log.debug('_joinRoom($link)', '$runtimeType');

    Log.info('Joining the room...', '$runtimeType');
    if (call.value?.joinLink != null && call.value?.joinLink != link) {
      Log.info(
        'Closing the previous one and connecting to the new',
        '$runtimeType',
      );

      final List<CallMember> connected = members.values
          .where((e) => e.isConnected.value == true && e.id != _me)
          .toList();

      _closeRoom(false);
      _initRoom();

      members.addEntries(
        connected
            .map((e) => MapEntry(e.id, CallMember(e.id, null, isDialing: true)))
            .toList(),
      );

      await _setInitialMediaSettings();
      await _initLocalMedia();
    }

    try {
      await _room?.join('$link?token=$creds');
    } on RpcClientException catch (e) {
      Log.error(
        'Joining the room failed due to: ${e.message()}',
        '$runtimeType',
      );

      rethrow;
    }

    Log.info('Room joined!', '$runtimeType');
  }

  /// Closes the [_room] and releases the associated resources.
  void _closeRoom([bool dispose = true]) {
    Log.debug('_closeRoom()', '$runtimeType');

    if (_room != null) {
      try {
        MediaUtils.jason?.closeRoom(_room!);
        _room!.free();
      } catch (_) {
        // No-op, as the room might be in a detached state.
      }
    }
    _room = null;

    if (dispose) {
      for (Track t in members.values.expand((e) => e.tracks)) {
        t.dispose();
      }
    }

    members.removeWhere((id, _) => id != _me);
  }

  /// Updates the local media settings with [audioDevice], [videoDevice] or
  /// [screenDevice].
  Future<void> _updateSettings({
    DeviceDetails? audioDevice,
    DeviceDetails? videoDevice,
    MediaDisplayDetails? screenDevice,
  }) async {
    Log.debug(
      '_updateSettings($audioDevice, $videoDevice, $screenDevice)',
      '$runtimeType',
    );

    if (audioDevice != null || videoDevice != null || screenDevice != null) {
      try {
        await _mediaSettingsGuard.acquire();
        _removeLocalTracks(
          audioDevice == null ? MediaKind.video : MediaKind.audio,
          screenDevice == null
              ? MediaSourceKind.device
              : MediaSourceKind.display,
        );

        try {
          // On Web settings do not change if provided the same IDs, so we
          // should reset settings first.
          if (PlatformUtils.isWeb && audioDevice != this.audioDevice.value) {
            await _room?.setLocalMediaSettings(
              _mediaStreamSettings(),
              true,
              true,
            );
          }

          final MediaStreamSettings settings = _mediaStreamSettings(
            audioDevice: audioDevice ?? this.audioDevice.value,
            videoDevice: videoDevice ?? this.videoDevice.value,
            screenDevice: screenDevice ?? this.screenDevice.value,
          );

          await _room?.setLocalMediaSettings(settings, true, true);
          this.audioDevice.value = audioDevice ?? this.audioDevice.value;
          this.videoDevice.value = videoDevice ?? this.videoDevice.value;
          this.screenDevice.value = screenDevice ?? this.screenDevice.value;

          await _updateTracks(
            audio: audioDevice != null,
            video: videoDevice != null,
            screen: screenDevice != null,
          );
        } catch (e) {
          Log.error(
            '_updateSettings(audioDevice: $audioDevice, videoDevice: $videoDevice, screenDevice: $screenDevice) failed: $e',
            '$runtimeType',
          );

          rethrow;
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
    Log.debug('_updateTracks($audio, $video, $screen)', '$runtimeType');

    final List<LocalMediaTrack> tracks = await MediaUtils.getTracks(
      audio: audioState.value.isEnabled && audio
          ? AudioPreferences(device: audioDevice.value?.deviceId())
          : null,
      video: videoState.value.isEnabled && video
          ? VideoPreferences(
              device: videoDevice.value?.deviceId(),
              facingMode: videoDevice.value == null ? FacingMode.user : null,
            )
          : null,
      screen: screenShareState.value.isEnabled && screen
          ? ScreenPreferences(device: screenDevice.value?.deviceId())
          : null,
    );

    for (LocalMediaTrack track in tracks) {
      await _addLocalTrack(track);
    }
  }

  /// Adds the provided [track] to the local tracks and initializes video
  /// renderer if required.
  Future<void> _addLocalTrack(LocalMediaTrack track) async {
    Log.debug('_addLocalTrack($track)', '$runtimeType');

    final MediaKind kind = track.kind();
    final MediaSourceKind source = track.mediaSourceKind();

    track.onEnded(() {
      Log.debug('track.onEnded($track)', '$runtimeType');

      switch (kind) {
        case MediaKind.audio:
          // Currently used [MediaKind.audio] track has ended, try picking a new
          // one.
          audioDevice.value = null;
          _pickAudioDevice();
          break;

        case MediaKind.video:
          switch (source) {
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

    if (kind == MediaKind.video) {
      LocalTrackState state;
      switch (source) {
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
        _removeLocalTracks(kind, source);

        Track t = Track(track);
        members[_me]?.tracks.add(t);

        switch (source) {
          case MediaSourceKind.device:
            videoDevice.value = videoDevice.value ??
                devices.firstWhereOrNull(
                  (e) => e.deviceId() == track.getTrack().deviceId(),
                );
            break;

          case MediaSourceKind.display:
            screenDevice.value = screenDevice.value ??
                displays.firstWhereOrNull(
                  (e) => e.deviceId() == track.getTrack().deviceId(),
                );
            break;
        }

        await t.createRenderer();
      }
    } else {
      _removeLocalTracks(kind, source);

      members[_me]?.tracks.add(Track(track));

      if (source == MediaSourceKind.device) {
        audioDevice.value = audioDevice.value ??
            devices.firstWhereOrNull(
              (e) => e.deviceId() == track.getTrack().deviceId(),
            );
      }
    }
  }

  /// Removes and stops the [LocalMediaTrack]s that match the [kind] and
  /// [source] from the local [CallMember].
  void _removeLocalTracks(MediaKind kind, MediaSourceKind source) {
    Log.debug('_removeLocalTracks($kind, $source)', '$runtimeType');

    members[_me]?.tracks.removeWhere((t) {
      if (t.kind == kind && t.source == source) {
        t.dispose();
        return true;
      }
      return false;
    });
  }

  /// Picks the [outputDevice] based on the [devices] list.
  void _pickOutputDevice() {
    Log.debug('_pickOutputDevice()', '$runtimeType');

    // TODO: For Android and iOS, default device is __NOT__ the first one.
    final Iterable<DeviceDetails> output = devices.output();
    final DeviceDetails? device =
        output.firstWhereOrNull((e) => e.id() == _preferredOutputDevice) ??
            output.firstOrNull;

    if (device != null && outputDevice.value != device) {
      _notifications.add(DeviceChangedNotification(device: device));
      _setOutputDevice(device);
    }
  }

  /// Picks the [audioDevice] based on the [devices] list.
  void _pickAudioDevice() async {
    Log.debug('_pickAudioDevice()', '$runtimeType');

    // TODO: For Android and iOS, default device is __NOT__ the first one.
    final Iterable<DeviceDetails> audio = devices.audio();
    final DeviceDetails? device =
        audio.firstWhereOrNull((e) => e.id() == _preferredAudioDevice) ??
            audio.firstOrNull;

    if (device != null && audioDevice.value != device) {
      _notifications.add(DeviceChangedNotification(device: device));
      await _setAudioDevice(device);
    }
  }

  /// Picks the [videoDevice] based on the provided [previous] and [removed].
  void _pickVideoDevice([
    List<DeviceDetails> previous = const [],
    List<DeviceDetails> removed = const [],
  ]) async {
    Log.debug(
      '_pickVideoDevice(previous: ${previous.video().map((e) => e.label())}, removed: ${removed.video().map((e) => e.label())})',
      '$runtimeType',
    );

    if (removed.any((e) => e.deviceId() == videoDevice.value?.deviceId()) ||
        (videoDevice.value == null &&
            removed.any((e) =>
                e.deviceId() == previous.video().firstOrNull?.deviceId()))) {
      await setVideoEnabled(false);
      videoDevice.value = null;
    }
  }

  /// Disables screen sharing, if the [screenDevice] is [removed].
  void _pickScreenDevice(List<MediaDisplayDetails> removed) async {
    Log.debug(
      '_pickScreenDevice(removed: ${removed.map((e) => e.title())})',
      '$runtimeType',
    );

    if (removed.any((e) => e.deviceId() == screenDevice.value?.deviceId())) {
      await setScreenShareEnabled(false);
    }
  }

  /// Sets the provided [device] as a currently used [audioDevice].
  ///
  /// Does nothing if [device] is already the [audioDevice].
  Future<void> _setAudioDevice(DeviceDetails device) async {
    Log.debug('_setAudioDevice($device)', '$runtimeType');

    if (device != audioDevice.value) {
      await _updateSettings(audioDevice: device);
    }
  }

  /// Sets the provided [device] as a currently used [outputDevice].
  ///
  /// Does nothing if [device] is already the [outputDevice].
  Future<void> _setOutputDevice(DeviceDetails device) async {
    Log.debug('_setOutputDevice($device)', '$runtimeType');

    if (device != outputDevice.value) {
      final DeviceDetails? previous = outputDevice.value;

      outputDevice.value = device;

      try {
        // [MediaUtils.setOutputDevice] seems to switch the speaker in
        // [AudioUtils] as well, when [hasRemote] is `true`.
        await Future.wait([
          if (!hasRemote) AudioUtils.setSpeaker(device.speaker),
          MediaUtils.setOutputDevice(device.deviceId()),
        ]);
      } catch (e) {
        addError(e.toString());
        outputDevice.value = previous;
        rethrow;
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
    Log.debug('RtcVideoRenderer()', '$runtimeType');

    if (track is LocalMediaTrack) {
      autoRotate = false;

      if (PlatformUtils.isMobile) {
        mirror = track.getTrack().facingMode() == webrtc.FacingMode.user;
      } else {
        mirror = track.mediaSourceKind() == MediaSourceKind.device;
      }
    }

    // Listen for resizes to update [width] and [height].
    _delegate.onResize = () {
      width.value = _delegate.videoWidth;
      height.value = _delegate.videoHeight;
    };
  }

  /// Indicator whether this [RtcVideoRenderer] should be mirrored.
  bool mirror = false;

  /// Indicator whether this [RtcVideoRenderer] should be auto rotated.
  bool autoRotate = true;

  /// Actual [webrtc.VideoRenderer].
  final webrtc.VideoRenderer _delegate = webrtc.createVideoRenderer();

  /// Reactive width of this [RtcVideoRenderer].
  late final RxInt width = RxInt(_delegate.videoWidth);

  /// Reactive height of this [RtcVideoRenderer].
  late final RxInt height = RxInt(_delegate.videoHeight);

  /// Returns inner [webrtc.VideoRenderer].
  ///
  /// This should be only used to interop with `flutter_webrtc`.
  webrtc.VideoRenderer get inner => _delegate;

  /// Sets [webrtc.VideoRenderer.srcObject] property.
  set srcObject(webrtc.MediaStreamTrack? track) =>
      _delegate.setSrcObject(track);

  /// Initializes inner [webrtc.VideoRenderer].
  Future<void> initialize() async {
    Log.debug('initialize()', '$runtimeType');
    await _delegate.initialize();
  }

  @override
  Future<void> dispose() async {
    Log.debug('dispose()', '$runtimeType');
    await _delegate.dispose();
  }
}

/// Convenience wrapper around an [webrtc.AudioRenderer].
class RtcAudioRenderer extends RtcRenderer {
  RtcAudioRenderer(MediaTrack track) : super(track.getTrack()) {
    Log.debug('RtcAudioRenderer()', '$runtimeType');
    srcObject = track.getTrack();
  }

  /// Actual [webrtc.AudioRenderer].
  final webrtc.AudioRenderer _delegate = webrtc.createAudioRenderer();

  /// Sets [webrtc.AudioRenderer.srcObject] property.
  set srcObject(webrtc.MediaStreamTrack? track) => _delegate.srcObject = track;

  @override
  Future<void> dispose() async {
    Log.debug('dispose()', '$runtimeType');
    await _delegate.dispose();
  }
}

/// Call member ID of an [OngoingCall] containing its [UserId] and
/// [ChatCallDeviceId].
class CallMemberId {
  const CallMemberId(this.userId, this.deviceId);

  /// Constructs a [CallMemberId] from the provided [string].
  factory CallMemberId.fromString(String string) {
    final List<String> split = string.split('.');
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
    Log.debug('dispose()', '$runtimeType');

    for (final Track t in tracks) {
      t.dispose();
    }
  }

  /// Sets the inbound video of this [CallMember] as [enabled].
  Future<void> setVideoEnabled(
    bool enabled, {
    MediaSourceKind source = MediaSourceKind.device,
  }) async {
    Log.debug('setVideoEnabled($enabled, $source)', '$runtimeType');

    if (enabled) {
      await _connection?.enableRemoteVideo(source);
    } else {
      await _connection?.disableRemoteVideo(source);
    }
  }

  /// Sets the inbound audio of this [CallMember] as [enabled].
  Future<void> setAudioEnabled(bool enabled) async {
    Log.debug('setAudioEnabled($enabled)', '$runtimeType');

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
    Log.debug('Track($kind, $source)', '$runtimeType');

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
    Log.debug('createRenderer() for $kind-$source', '$runtimeType');

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
    Log.debug('removeRenderer() for $kind-$source', '$runtimeType');

    await _rendererGuard.protect(() async {
      renderer.value?.dispose();
      renderer.value = null;
    });
  }

  /// Disposes this [Track].
  ///
  /// No-op, if this [Track] was already disposed.
  Future<void> dispose() async {
    Log.debug('dispose()', '$runtimeType');

    if (!_disposed) {
      _disposed = true;
      await Future.wait([removeRenderer(), track.free()]);
    }
  }

  /// Stops the [webrtc.MediaStreamTrack] of this [Track].
  Future<void> stop() async {
    Log.debug('stop()', '$runtimeType');

    await Future.wait([
      track.getTrack().stop(),
      removeRenderer(),
    ]);
  }
}

/// Extension adding an ability to querying the [DeviceDetails] by
/// [MediaDeviceKind].
extension DevicesList on List<DeviceDetails> {
  /// Returns a new [Iterable] with [DeviceDetails] of
  /// [MediaDeviceKind.videoInput].
  Iterable<DeviceDetails> video() {
    return where((i) => i.kind() == MediaDeviceKind.videoInput);
  }

  /// Returns a new [Iterable] with [DeviceDetails] of
  /// [MediaDeviceKind.audioInput].
  Iterable<DeviceDetails> audio() {
    return where((i) => i.kind() == MediaDeviceKind.audioInput);
  }

  /// Returns a new [Iterable] with [DeviceDetails] of
  /// [MediaDeviceKind.audioOutput].
  Iterable<DeviceDetails> output() {
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
