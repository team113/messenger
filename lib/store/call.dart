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
import 'package:uuid/uuid.dart';

import '/api/backend/extension/call.dart';
import '/api/backend/extension/chat.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/media_settings.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/settings.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/provider/hive/chat_call_credentials.dart';
import '/store/user.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/web/web_utils.dart';
import 'event/chat_call.dart';
import 'event/incoming_chat_call.dart';

/// Implementation of an [AbstractCallRepository].
class CallRepository implements AbstractCallRepository {
  CallRepository(
    this._graphQlProvider,
    this._userRepo,
    this._credentialsProvider,
    this._settingsRepo, {
    required this.me,
  });

  @override
  RxObsMap<ChatId, Rx<OngoingCall>> calls = RxObsMap<ChatId, Rx<OngoingCall>>();

  /// [UserId] of the currently authenticated [MyUser].
  final UserId me;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepo;

  /// [ChatCallCredentialsHiveProvider] persisting the [ChatCallCredentials].
  final ChatCallCredentialsHiveProvider _credentialsProvider;

  /// Settings repository, used to get the stored [MediaSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Temporary [ChatCallCredentials] of the [Chat]s containing just started
  /// [OngoingCall]s.
  final Map<ChatId, ChatCallCredentials> _credentials = {};

  /// Subscription to [IncomingChatCallsTopEvent]s list.
  StreamSubscription? _events;

  /// Returns the current [MediaSettings] value.
  Rx<MediaSettings?> get media => _settingsRepo.mediaSettings;

  @override
  Rx<OngoingCall>? operator [](ChatId chatId) => calls[chatId];

  @override
  void operator []=(ChatId chatId, Rx<OngoingCall> call) =>
      calls[chatId] = call;

  @override
  void init() {
    _subscribe(3);
  }

  @override
  void dispose() {
    _events?.cancel();
  }

  @override
  void move(ChatId chatId, ChatId newChatId) => calls.move(chatId, newChatId);

  @override
  Rx<OngoingCall>? remove(ChatId chatId) => calls.remove(chatId);

  @override
  bool contains(ChatId chatId) => calls.containsKey(chatId);

  @override
  Future<OngoingCall> start(
    ChatId chatId, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) async {
    Rx<OngoingCall> call = Rx<OngoingCall>(
      OngoingCall(
        chatId,
        me,
        withAudio: withAudio,
        withVideo: withVideo,
        withScreen: withScreen,
        mediaSettings: media.value,
        creds: generateCredentials(chatId),
        state: OngoingCallState.local,
      ),
    );

    calls[call.value.chatId.value] = call;

    var response = await _graphQlProvider.startChatCall(
      call.value.chatId.value,
      call.value.creds!,
      call.value.videoState.value == LocalTrackState.enabling ||
          call.value.videoState.value == LocalTrackState.enabled,
    );

    call.value.deviceId = response.deviceId;

    var chatCall = _chatCall(response.event);
    if (chatCall != null) {
      call.value.call.value = chatCall;
      transferCredentials(chatCall.chatId, chatCall.id);
    } else {
      throw CallAlreadyJoinedException(response.deviceId);
    }
    calls[call.value.chatId.value]?.refresh();

    return call.value;
  }

  @override
  Future<OngoingCall?> join(
    ChatId chatId,
    ChatItemId? callId, {
    bool withAudio = true,
    bool withVideo = false,
    bool withScreen = false,
  }) async {
    Rx<OngoingCall> call;
    final Rx<OngoingCall>? stored = calls[chatId];

    if (stored == null || stored.value.state.value == OngoingCallState.ended) {
      // If we're joining an already disposed call, then replace it.
      if (stored?.value.state.value == OngoingCallState.ended) {
        var removed = remove(chatId);
        removed?.value.dispose();
      }

      ChatCallCredentials? credentials;
      if (callId != null) {
        credentials = getCredentials(callId);
      }

      call = Rx<OngoingCall>(
        OngoingCall(
          chatId,
          me,
          withAudio: withAudio,
          withVideo: withVideo,
          withScreen: withScreen,
          mediaSettings: media.value,
          creds: credentials ?? generateCredentials(chatId),
          state: OngoingCallState.joining,
        ),
      );
    } else if (stored.value.state.value != OngoingCallState.active) {
      stored.value.state.value = OngoingCallState.joining;
      stored.value.setAudioEnabled(withAudio);
      stored.value.setVideoEnabled(withVideo);
      stored.value.setScreenShareEnabled(withScreen);

      call = stored;
    } else {
      return null;
    }

    calls[chatId] = call;

    var response = await _graphQlProvider.joinChatCall(
        call.value.chatId.value, call.value.creds!);

    call.value.deviceId = response.deviceId;

    var chatCall = _chatCall(response.event);
    if (chatCall != null) {
      call.value.call.value = chatCall;
      transferCredentials(chatCall.chatId, chatCall.id);
    } else {
      throw CallAlreadyJoinedException(response.deviceId);
    }

    return call.value;
  }

  @override
  Future<void> leave(ChatId chatId, ChatCallDeviceId deviceId) async {
    await _graphQlProvider.leaveChatCall(chatId, deviceId);
  }

  @override
  Future<void> decline(ChatId chatId) async {
    await _graphQlProvider.declineChatCall(chatId);
    calls.remove(chatId);
  }

  @override
  void addCall(ChatCall chatCall) {
    final Rx<OngoingCall>? stored = calls[chatCall.chatId];

    // If we're already in this call or call already exist, then ignore it.
    if ((stored != null &&
            stored.value.state.value != OngoingCallState.ended) ||
        chatCall.members.any((e) => e.user.id == me)) {
      return;
    }

    Rx<OngoingCall>? call = calls[chatCall.chatId];

    if (call == null) {
      Rx<OngoingCall> call = Rx<OngoingCall>(
        OngoingCall(
          chatCall.chatId,
          me,
          call: chatCall,
          withAudio: false,
          withVideo: false,
          withScreen: false,
          mediaSettings: media.value,
          creds: getCredentials(chatCall.id),
        ),
      );
      calls[chatCall.chatId] = call;
    } else {
      call.value.call.value = chatCall;
    }
  }

  @override
  Rx<OngoingCall> addStoredCall(
    WebStoredCall stored, {
    bool withAudio = true,
    bool withVideo = true,
    bool withScreen = false,
  }) {
    Rx<OngoingCall>? call = calls[stored.chatId];

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
      calls[stored.chatId] = call;
    } else {
      call.value.call.value = call.value.call.value ?? stored.call;
      call.value.creds = call.value.creds ?? stored.creds;
      call.value.deviceId = call.value.deviceId ?? stored.deviceId;
    }

    return call;
  }

  @override
  void endCall(ChatId chatId) {
    var removed = remove(chatId);
    removed?.value.state.value = OngoingCallState.ended;
    removed?.value.dispose();
  }

  @override
  Future<void> toggleHand(ChatId chatId, bool raised) =>
      _graphQlProvider.toggleChatCallHand(chatId, raised);

  @override
  Future<void> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds,
    ChatName? groupName,
  ) =>
      _graphQlProvider.transformDialogCallIntoGroupCall(
        chatId,
        additionalMemberIds,
        groupName,
      );

  @override
  ChatCallCredentials generateCredentials(ChatId id) {
    ChatCallCredentials? creds = _credentials[id];
    if (creds == null) {
      creds = ChatCallCredentials(const Uuid().v4());
      _credentials[id] = creds;
    }

    return creds;
  }

  @override
  void transferCredentials(ChatId chatId, ChatItemId callId) {
    ChatCallCredentials? creds = _credentials[chatId];
    if (creds != null) {
      _credentialsProvider.put(callId, creds);
      _credentials.remove(chatId);
    }
  }

  @override
  ChatCallCredentials getCredentials(ChatItemId id) {
    ChatCallCredentials? creds = _credentialsProvider.get(id);
    if (creds == null) {
      creds = ChatCallCredentials(const Uuid().v4());
      _credentialsProvider.put(id, creds);
    }

    return creds;
  }

  @override
  void moveCredentials(ChatItemId callId, ChatItemId newCallId) {
    ChatCallCredentials? creds = _credentialsProvider.get(callId);
    if (creds != null) {
      _credentialsProvider.put(newCallId, creds);
      _credentialsProvider.remove(callId);
    }
  }

  @override
  Future<void> removeCredentials(ChatItemId id) {
    return _credentialsProvider.remove(id);
  }

  @override
  Future<Stream<ChatCallEvents>> heartbeat(
    ChatItemId id,
    ChatCallDeviceId deviceId,
  ) async {
    return (await _graphQlProvider.callEvents(id, deviceId))
        .asyncExpand((event) async* {
      GraphQlProviderExceptions.fire(event);
      var events = CallEvents$Subscription.fromJson(event.data!).chatCallEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const ChatCallEventsInitialized();
      } else if (events.$$typename == 'ChatCall') {
        var call = events as CallEvents$Subscription$ChatCallEvents$ChatCall;
        yield ChatCallEventsChatCall(call.toModel(), call.ver);
      } else if (events.$$typename == 'ChatCallEventsVersioned') {
        var mixin = events as ChatCallEventsVersionedMixin;
        yield ChatCallEventsEvent(
          CallEventsVersioned(
            mixin.events.map((e) => _callEvent(e)).toList(),
            mixin.ver,
          ),
        );
      }
    });
  }

  @override
  Future<Stream<IncomingChatCallsTopEvent>> events(int count) async =>
      (await _graphQlProvider.incomingCallsTopEvents(count))
          .asyncExpand((event) async* {
        GraphQlProviderExceptions.fire(event);
        var events = IncomingCallsTopEvents$Subscription.fromJson(event.data!)
            .incomingChatCallsTopEvents;

        if (events.$$typename == 'SubscriptionInitialized') {
          yield const IncomingChatCallsTopInitialized();
        } else if (events.$$typename == 'IncomingChatCallsTop') {
          var list = (events
                  as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$IncomingChatCallsTop)
              .list;
          for (var u in list.map((e) => e.members).expand((e) => e)) {
            _userRepo.put(u.user.toHive());
          }
          yield IncomingChatCallsTop(list.map((e) => e.toModel()).toList());
        } else if (events.$$typename ==
            'EventIncomingChatCallsTopChatCallAdded') {
          var data = events
              as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$EventIncomingChatCallsTopChatCallAdded;
          yield EventIncomingChatCallsTopChatCallAdded(data.call.toModel());
        } else if (events.$$typename ==
            'EventIncomingChatCallsTopChatCallRemoved') {
          var data = events
              as IncomingCallsTopEvents$Subscription$IncomingChatCallsTopEvents$EventIncomingChatCallsTopChatCallRemoved;
          yield EventIncomingChatCallsTopChatCallRemoved(data.call.toModel());
        }
      });

  /// Constructs a [ChatCallEvent] from [ChatCallEventsVersionedMixin$Event].
  ChatCallEvent _callEvent(ChatCallEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventChatCallFinished') {
      var node = e as ChatCallEventsVersionedMixin$Events$EventChatCallFinished;
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
      }
      return EventChatCallFinished(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.reason,
      );
    } else if (e.$$typename == 'EventChatCallRoomReady') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallRoomReady;
      return EventChatCallRoomReady(
        node.callId,
        node.chatId,
        node.at,
        node.joinLink,
      );
    } else if (e.$$typename == 'EventChatCallMemberLeft') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberLeft;
      _userRepo.put(node.user.toHive());
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
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
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberJoined;
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
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
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberRedialed;
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
      }
      return EventChatCallMemberRedialed(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
        node.byUser.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallHandLowered') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandLowered;
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
      }
      return EventChatCallHandLowered(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMoved') {
      var node = e as ChatCallEventsVersionedMixin$Events$EventChatCallMoved;
      _userRepo.put(node.user.toHive());
      for (var m in [...node.call.members, ...node.newCall.members]) {
        _userRepo.put(m.user.toHive());
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
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandRaised;
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
      }
      return EventChatCallHandRaised(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallDeclined') {
      var node = e as ChatCallEventsVersionedMixin$Events$EventChatCallDeclined;
      _userRepo.put(node.user.toHive());
      for (var m in node.call.members) {
        _userRepo.put(m.user.toHive());
      }
      return EventChatCallDeclined(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else {
      throw UnimplementedError('Unknown ChatCallEvent: ${e.$$typename}');
    }
  }

  /// Constructs a [ChatCall] from the [ChatEventsVersionedMixin].
  ChatCall? _chatCall(ChatEventsVersionedMixin? m) {
    for (ChatEventsVersionedMixin$Events e in m?.events ?? []) {
      if (e.$$typename == 'EventChatCallStarted') {
        var node = e as ChatEventsVersionedMixin$Events$EventChatCallStarted;
        for (var m in node.call.members) {
          _userRepo.put(m.user.toHive());
        }
        return node.call.toModel();
      } else if (e.$$typename == 'EventChatCallMemberJoined') {
        var node =
            e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;

        for (var m in node.call.members) {
          _userRepo.put(m.user.toHive());
        }
        return node.call.toModel();
      }
    }

    return null;
  }

  /// Subscribes to the updates of the top [count] of incoming [ChatCall]s list.
  void _subscribe(int count) async {
    _events?.cancel();
    _events = (await events(count)).listen(
      (e) async {
        switch (e.kind) {
          case IncomingChatCallsTopEventKind.initialized:
            // No-op.
            break;

          case IncomingChatCallsTopEventKind.list:
            e as IncomingChatCallsTop;
            for (ChatCall c in e.list) {
              addCall(c);
            }
            break;

          case IncomingChatCallsTopEventKind.added:
            e as EventIncomingChatCallsTopChatCallAdded;
            addCall(e.call);
            break;

          case IncomingChatCallsTopEventKind.removed:
            e as EventIncomingChatCallsTopChatCallRemoved;
            endCall(e.call.chatId);
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
