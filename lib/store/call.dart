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
import 'package:uuid/uuid.dart';

import '/api/backend/extension/call.dart';
import '/api/backend/extension/chat.dart';
import '/api/backend/extension/user.dart';
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
import '/provider/drift/call_credentials.dart';
import '/provider/drift/chat_credentials.dart';
import '/provider/gql/graphql.dart';
import '/store/user.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
import 'event/chat_call.dart';
import 'event/incoming_chat_call.dart';

/// Implementation of an [AbstractCallRepository].
class CallRepository extends DisposableInterface
    implements AbstractCallRepository {
  CallRepository(
    this._graphQlProvider,
    this._userRepo,
    this._callCredentialsProvider,
    this._chatCredentialsProvider,
    this._settingsRepo, {
    required this.me,
  });

  /// Callback, called when the provided [Chat] should be remotely accessible.
  Future<RxChat?> Function(ChatId id)? ensureRemoteDialog;

  @override
  RxObsMap<ChatId, Rx<OngoingCall>> calls = RxObsMap<ChatId, Rx<OngoingCall>>();

  /// [UserId] of the currently authenticated [MyUser].
  final UserId me;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepo;

  /// [ChatCallCredentials] of [ChatCall]s local storage.
  final CallCredentialsDriftProvider _callCredentialsProvider;

  /// [ChatCallCredentials] of [Chat]s local storage.
  ///
  /// Used to prevent the [ChatCallCredentials] from being re-generated.
  final ChatCredentialsDriftProvider _chatCredentialsProvider;

  /// Settings repository, used to retrieve the stored [MediaSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Subscription to a list of [IncomingChatCallsTopEvent]s.
  StreamSubscription? _events;

  /// Returns the current value of [MediaSettings].
  Rx<MediaSettings?> get media => _settingsRepo.mediaSettings;

  @override
  Rx<OngoingCall>? operator [](ChatId chatId) => calls[chatId];

  @override
  void operator []=(ChatId chatId, Rx<OngoingCall> call) =>
      calls[chatId] = call;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    _subscribe(3);
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _events?.cancel();

    for (Rx<OngoingCall> call in List.from(calls.values, growable: false)) {
      remove(call.value.chatId.value);
    }

    super.onClose();
  }

  @override
  Future<Rx<OngoingCall>?> add(ChatCall call) async {
    Log.debug('add($call)', '$runtimeType');

    Rx<OngoingCall>? ongoing = calls[call.chatId];

    // If we're already in this call or call already exists, then ignore it.
    if ((ongoing != null &&
            ongoing.value.state.value != OngoingCallState.ended) ||
        call.members.any((e) => e.user.id == me)) {
      return ongoing;
    }

    // If [ChatCall] is already finished, then there's no reason to add it.
    if (call.finishReason != null) {
      return null;
    }

    if (ongoing == null) {
      ongoing = Rx<OngoingCall>(
        OngoingCall(
          call.chatId,
          me,
          call: call,
          withAudio: false,
          withVideo: false,
          withScreen: false,
          mediaSettings: media.value,
          creds: await getCredentials(call.id),
        ),
      );
      calls[call.chatId] = ongoing;
    } else {
      ongoing.value.call.value = call;
    }

    return ongoing;
  }

  @override
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

    Rx<OngoingCall>? ongoing = calls[stored.chatId];

    if (ongoing == null) {
      ongoing = Rx(
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
      calls[stored.chatId] = ongoing;
    } else {
      ongoing.value.call.value = ongoing.value.call.value ?? stored.call;
      ongoing.value.creds = ongoing.value.creds ?? stored.creds;
      ongoing.value.deviceId = ongoing.value.deviceId ?? stored.deviceId;
    }

    return ongoing;
  }

  @override
  void move(ChatId chatId, ChatId newChatId) {
    Log.debug('move($chatId, $newChatId)', '$runtimeType');
    calls.move(chatId, newChatId);
  }

  @override
  Rx<OngoingCall>? remove(ChatId chatId) {
    Log.debug('remove($chatId)', '$runtimeType');

    final Rx<OngoingCall>? call = calls.remove(chatId);
    call?.value.state.value = OngoingCallState.ended;
    call?.value.dispose();

    return call;
  }

  @override
  bool contains(ChatId chatId) {
    Log.debug('contains($chatId)', '$runtimeType');
    return calls.containsKey(chatId);
  }

  @override
  Future<Rx<OngoingCall>> start(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) async {
    Log.debug(
      'start($chatId, $withAudio, $withVideo, $withScreen)',
      '$runtimeType',
    );

    // TODO: Call should be displayed right away.
    if (chatId.isLocal && ensureRemoteDialog != null) {
      chatId = (await ensureRemoteDialog!.call(chatId))!.id;
    }

    if (calls[chatId] != null) {
      throw CallAlreadyExistsException();
    }

    final Rx<OngoingCall> call = Rx<OngoingCall>(
      OngoingCall(
        chatId,
        me,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
        mediaSettings: media.value,
        creds: await generateCredentials(chatId),
        state: OngoingCallState.local,
      ),
    );

    calls[call.value.chatId.value] = call;

    final response = await _graphQlProvider.startChatCall(
      call.value.chatId.value,
      call.value.creds!,
      call.value.videoState.value == LocalTrackState.enabling ||
          call.value.videoState.value == LocalTrackState.enabled,
    );

    call.value.deviceId = response.deviceId;

    final ChatCall? chatCall = _chatCall(response.event);
    if (chatCall != null) {
      call.value.call.value = chatCall;
      transferCredentials(chatCall.chatId, chatCall.id);
    } else {
      throw CallAlreadyJoinedException(response.deviceId);
    }
    calls[call.value.chatId.value]?.refresh();

    return call;
  }

  @override
  Future<Rx<OngoingCall>?> join(
    ChatId chatId,
    ChatCall? call, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) async {
    Log.debug(
      'join($chatId, $call, $withAudio, $withVideo, $withScreen)',
      '$runtimeType',
    );

    Rx<OngoingCall>? ongoing = calls[chatId];

    if (ongoing == null ||
        ongoing.value.state.value == OngoingCallState.ended) {
      // If we're joining an already disposed call, then replace it.
      if (ongoing?.value.state.value == OngoingCallState.ended) {
        remove(chatId);
      }

      ChatCallCredentials? credentials;
      if (call != null) {
        credentials = await getCredentials(call.id);
      }

      ongoing = Rx<OngoingCall>(
        OngoingCall(
          chatId,
          me,
          call: call,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
          mediaSettings: media.value,
          creds: credentials ?? await generateCredentials(chatId),
          state: OngoingCallState.joining,
        ),
      );
      calls[chatId] = ongoing;
    } else if (ongoing.value.state.value != OngoingCallState.active) {
      ongoing.value.state.value = OngoingCallState.joining;
      ongoing.value.setAudioEnabled(withAudio);
      ongoing.value.setVideoEnabled(withVideo);
      ongoing.value.setScreenShareEnabled(withScreen);
    } else {
      return null;
    }

    final response = await _graphQlProvider.joinChatCall(
      ongoing.value.chatId.value,
      ongoing.value.creds!,
    );

    ongoing.value.deviceId = response.deviceId;

    final ChatCall? chatCall = _chatCall(response.event);
    if (chatCall != null) {
      ongoing.value.call.value = chatCall;
      transferCredentials(chatCall.chatId, chatCall.id);
    } else {
      throw CallAlreadyJoinedException(response.deviceId);
    }

    return ongoing;
  }

  @override
  Future<void> leave(ChatId chatId, ChatCallDeviceId deviceId) async {
    Log.debug('leave($chatId, $deviceId)', '$runtimeType');
    await _graphQlProvider.leaveChatCall(chatId, deviceId);
  }

  @override
  Future<void> decline(ChatId chatId) async {
    Log.debug('decline($chatId)', '$runtimeType');

    await _graphQlProvider.declineChatCall(chatId);
    calls.remove(chatId);
  }

  @override
  Future<void> toggleHand(ChatId chatId, bool raised) async {
    Log.debug('toggleHand($chatId, $raised)', '$runtimeType');
    await _graphQlProvider.toggleChatCallHand(chatId, raised);
  }

  @override
  Future<void> redialChatCallMember(ChatId chatId, UserId memberId) async {
    Log.debug('redialChatCallMember($chatId, $memberId)', '$runtimeType');

    final Rx<OngoingCall>? ongoing = calls[chatId];
    final CallMemberId id = CallMemberId(memberId, null);

    if (ongoing != null) {
      if (ongoing.value.members.keys.none((e) => e.userId == memberId)) {
        ongoing.value.members[id] =
            CallMember(id, null, isConnected: false, isDialing: true);
      }
    }

    try {
      await _graphQlProvider.redialChatCallMember(chatId, memberId);
    } catch (_) {
      ongoing?.value.members.remove(id);
    }
  }

  @override
  Future<void> removeChatCallMember(ChatId chatId, UserId userId) async {
    Log.debug('removeChatCallMember($chatId, $userId)', '$runtimeType');
    // TODO: Implement optimism, if possible.
    await _graphQlProvider.removeChatCallMember(chatId, userId);
  }

  @override
  Future<void> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds,
    ChatName? groupName,
  ) async {
    Log.debug(
      'transformDialogCallIntoGroupCall($chatId, $additionalMemberIds, $groupName)',
      '$runtimeType',
    );

    await _graphQlProvider.transformDialogCallIntoGroupCall(
      chatId,
      additionalMemberIds,
      groupName,
    );
  }

  @override
  Future<ChatCallCredentials> generateCredentials(ChatId chatId) async {
    Log.debug('generateCredentials($chatId)', '$runtimeType');

    ChatCallCredentials? creds = await _chatCredentialsProvider.read(chatId);
    if (creds == null) {
      creds = ChatCallCredentials(const Uuid().v4());
      _chatCredentialsProvider.upsert(chatId, creds);
    }

    return creds;
  }

  @override
  Future<void> transferCredentials(ChatId chatId, ChatItemId callId) async {
    Log.debug('transferCredentials($chatId, $callId)', '$runtimeType');

    final ChatCallCredentials? creds =
        await _chatCredentialsProvider.read(chatId);
    if (creds != null) {
      _callCredentialsProvider.upsert(callId, creds.copyWith());
    }
  }

  @override
  Future<ChatCallCredentials> getCredentials(ChatItemId callId) async {
    Log.debug('getCredentials($callId)', '$runtimeType');

    ChatCallCredentials? creds = await _callCredentialsProvider.read(callId);
    if (creds == null) {
      creds = ChatCallCredentials(const Uuid().v4());
      _callCredentialsProvider.upsert(callId, creds);
    }

    return creds;
  }

  @override
  Future<void> moveCredentials(
    ChatItemId callId,
    ChatItemId newCallId,
    ChatId chatId,
    ChatId newChatId,
  ) async {
    Log.debug(
      'moveCredentials($callId, $newCallId, $chatId, $newChatId)',
      '$runtimeType',
    );

    final ChatCallCredentials? chatCreds =
        await _chatCredentialsProvider.read(chatId);
    final ChatCallCredentials? callCreds =
        await _callCredentialsProvider.read(callId);

    if (chatCreds != null) {
      _chatCredentialsProvider.delete(chatId);
      _chatCredentialsProvider.upsert(newChatId, chatCreds.copyWith());
    }

    if (callCreds != null) {
      _callCredentialsProvider.delete(callId);
      _callCredentialsProvider.upsert(newCallId, callCreds.copyWith());
    }
  }

  @override
  Future<void> removeCredentials(ChatId chatId, ChatItemId callId) async {
    Log.debug('removeCredentials($callId)', '$runtimeType');

    await _chatCredentialsProvider.delete(chatId);
    await _callCredentialsProvider.delete(callId);
  }

  @override
  Stream<ChatCallEvents> heartbeat(
    ChatItemId id,
    ChatCallDeviceId deviceId,
  ) {
    Log.debug('heartbeat($id, $deviceId)', '$runtimeType');

    return _graphQlProvider
        .callEvents(id, deviceId)
        .asyncExpand((event) async* {
      Log.trace('heartbeat($id): ${event.data}', '$runtimeType');

      final events =
          CallEvents$Subscription.fromJson(event.data!).chatCallEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const ChatCallEventsInitialized();
      } else if (events.$$typename == 'ChatCall') {
        final call = events as CallEvents$Subscription$ChatCallEvents$ChatCall;
        yield ChatCallEventsChatCall(call.toModel(), call.ver);
      } else if (events.$$typename == 'ChatCallEventsVersioned') {
        final mixin = events as ChatCallEventsVersionedMixin;
        yield ChatCallEventsEvent(
          CallEventsVersioned(
            mixin.events.map((e) => _callEvent(e)).toList(),
            mixin.ver,
          ),
        );
      }
    });
  }

  /// Returns a [Stream] of [IncomingChatCallsTopEvent]s.
  ///
  /// [count] determines the length of the list of incoming [ChatCall]s which
  /// updates will be notified via events.
  Stream<IncomingChatCallsTopEvent> _incomingEvents(int count) {
    Log.debug('_incomingEvents($count)', '$runtimeType');

    return _graphQlProvider
        .incomingCallsTopEvents(count)
        .asyncExpand((event) async* {
      Log.trace('_incomingEvents($count): ${event.data}', '$runtimeType');

      final events = IncomingCallsTopEvents$Subscription.fromJson(event.data!)
          .incomingChatCallsTopEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const IncomingChatCallsTopInitialized();
      } else if (events.$$typename == 'IncomingChatCallsTop') {
        final list = (events
                as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$IncomingChatCallsTop)
            .list;
        for (final u in list.map((e) => e.members).expand((e) => e)) {
          _userRepo.put(u.user.toDto());
        }
        yield IncomingChatCallsTop(list.map((e) => e.toModel()).toList());
      } else if (events.$$typename ==
          'EventIncomingChatCallsTopChatCallAdded') {
        final data = events
            as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$EventIncomingChatCallsTopChatCallAdded;
        yield EventIncomingChatCallsTopChatCallAdded(data.call.toModel());
      } else if (events.$$typename ==
          'EventIncomingChatCallsTopChatCallRemoved') {
        final data = events
            as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$EventIncomingChatCallsTopChatCallRemoved;
        yield EventIncomingChatCallsTopChatCallRemoved(data.call.toModel());
      }
    });
  }

  /// Constructs a [ChatCallEvent] from [ChatCallEventsVersionedMixin$Event].
  ChatCallEvent _callEvent(ChatCallEventsVersionedMixin$Events e) {
    Log.trace('_callEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventChatCallFinished') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallFinished;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallFinished(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.reason,
      );
    } else if (e.$$typename == 'EventChatCallRoomReady') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallRoomReady;
      return EventChatCallRoomReady(
        node.callId,
        node.chatId,
        node.at,
        node.joinLink,
      );
    } else if (e.$$typename == 'EventChatCallMemberLeft') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberLeft;
      _userRepo.put(node.user.toDto());
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallMemberLeft(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
        node.deviceId,
      );
    } else if (e.$$typename == 'EventChatCallMemberJoined') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberJoined;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallMemberJoined(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
        node.deviceId,
      );
    } else if (e.$$typename == 'EventChatCallMemberRedialed') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberRedialed;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallMemberRedialed(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
        node.byUser.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMemberUndialed') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberUndialed;
      return EventChatCallMemberUndialed(
        node.callId,
        node.chatId,
        node.at,
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallAnswerTimeoutPassed') {
      final node = e
          as ChatCallEventsVersionedMixin$Events$EventChatCallAnswerTimeoutPassed;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallAnswerTimeoutPassed(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.nUser?.toModel(),
        node.userId,
      );
    } else if (e.$$typename == 'EventChatCallHandLowered') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandLowered;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallHandLowered(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMoved') {
      final node = e as ChatCallEventsVersionedMixin$Events$EventChatCallMoved;
      _userRepo.put(node.user.toDto());
      for (final m in [...node.call.members, ...node.newCall.members]) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallMoved(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
        node.newChatId,
        node.newChat.toModel(),
        node.newCallId,
        node.newCall.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallHandRaised') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandRaised;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallHandRaised(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallDeclined') {
      final node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallDeclined;
      _userRepo.put(node.user.toDto());
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallDeclined(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallConversationStarted') {
      final node = e
          as ChatCallEventsVersionedMixin$Events$EventChatCallConversationStarted;
      for (final m in node.call.members) {
        _userRepo.put(m.user.toDto());
      }
      return EventChatCallConversationStarted(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
      );
    } else {
      throw UnimplementedError('Unknown ChatCallEvent: ${e.$$typename}');
    }
  }

  /// Constructs a [ChatCall] from the [ChatEventsVersionedMixin].
  ChatCall? _chatCall(ChatEventsVersionedMixin? m) {
    Log.trace('_chatCall($m)', '$runtimeType');

    for (ChatEventsVersionedMixin$Events e in m?.events ?? []) {
      if (e.$$typename == 'EventChatCallStarted') {
        final node = e as ChatEventsVersionedMixin$Events$EventChatCallStarted;
        for (final m in node.call.members) {
          _userRepo.put(m.user.toDto());
        }
        return node.call.toModel();
      } else if (e.$$typename == 'EventChatCallMemberJoined') {
        final node =
            e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;

        for (final m in node.call.members) {
          _userRepo.put(m.user.toDto());
        }
        return node.call.toModel();
      }
    }

    return null;
  }

  /// Subscribes to updates of the top [count] of incoming [ChatCall]s list.
  void _subscribe(int count) {
    if (isClosed) {
      return;
    }

    Log.debug('_subscribe($count)', '$runtimeType');

    _events?.cancel();
    _events = _incomingEvents(count).listen(
      (e) async {
        Log.debug('_subscribe($count): ${e.kind}', '$runtimeType');

        switch (e.kind) {
          case IncomingChatCallsTopEventKind.initialized:
            // No-op.
            break;

          case IncomingChatCallsTopEventKind.list:
            e as IncomingChatCallsTop;
            e.list.forEach(add);
            break;

          case IncomingChatCallsTopEventKind.added:
            e as EventIncomingChatCallsTopChatCallAdded;
            add(e.call);
            break;

          case IncomingChatCallsTopEventKind.removed:
            e as EventIncomingChatCallsTopChatCallRemoved;
            final Rx<OngoingCall>? call = calls[e.call.chatId];
            // If call is not yet connected to remote updates, then it's still
            // just a notification and it should be removed.
            if (call?.value.connected == false &&
                call?.value.isActive == false) {
              remove(e.call.chatId);
            }
            break;
        }
      },
      onError: (_) {
        // No-op.
      },
    );
  }
}
