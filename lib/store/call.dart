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

import '/api/backend/extension/call.dart';
import '/api/backend/extension/chat.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/provider/gql/exceptions.dart';
import '/provider/gql/graphql.dart';
import '/store/user.dart';
import '/util/obs/obs.dart';
import 'event/chat_call.dart';
import 'event/incoming_chat_call.dart';

/// Implementation of an [AbstractCallRepository].
class CallRepository implements AbstractCallRepository {
  CallRepository(this._graphQlProvider, this._userRepo);

  @override
  RxObsMap<ChatId, Rx<OngoingCall>> get calls => _calls;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository? _userRepo;

  /// Reactive map of the current [OngoingCall]s.
  final RxObsMap<ChatId, Rx<OngoingCall>> _calls =
      RxObsMap<ChatId, Rx<OngoingCall>>();

  @override
  Rx<OngoingCall>? operator [](ChatId chatId) => _calls[chatId];

  @override
  void operator []=(ChatId chatId, Rx<OngoingCall> call) =>
      _calls[chatId] = call;

  @override
  void add(Rx<OngoingCall> call) => _calls[call.value.chatId.value] = call;

  @override
  void move(ChatId chatId, ChatId newChatId) => _calls.move(chatId, newChatId);

  @override
  Rx<OngoingCall>? remove(ChatId chatId) => _calls.remove(chatId);

  @override
  bool contains(ChatId chatId) => _calls.containsKey(chatId);

  @override
  Future<void> start(Rx<OngoingCall> call) async {
    _calls[call.value.chatId.value] = call;

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
    } else {
      throw CallAlreadyJoinedException();
    }
    _calls[call.value.chatId.value]?.refresh();
  }

  @override
  Future<void> join(Rx<OngoingCall> call) async {
    var response = await _graphQlProvider.joinChatCall(
        call.value.chatId.value, call.value.creds!);

    call.value.deviceId = response.deviceId;

    var chatCall = _chatCall(response.event);
    if (chatCall != null) {
      call.value.call.value = chatCall;
    } else {
      throw CallAlreadyJoinedException();
    }
  }

  @override
  Future<void> leave(ChatId chatId, ChatCallDeviceId deviceId) async {
    await _graphQlProvider.leaveChatCall(chatId, deviceId);
    _calls.remove(chatId);
  }

  @override
  Future<void> decline(ChatId chatId) async {
    await _graphQlProvider.declineChatCall(chatId);
    _calls.remove(chatId);
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
            _userRepo?.put(u.user.toHive());
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
        _userRepo?.put(m.user.toHive());
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
      _userRepo?.put(node.user.toHive());
      for (var m in node.call.members) {
        _userRepo?.put(m.user.toHive());
      }
      return EventChatCallMemberLeft(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMemberJoined') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallMemberJoined;
      for (var m in node.call.members) {
        _userRepo?.put(m.user.toHive());
      }
      return EventChatCallMemberJoined(
        node.callId,
        node.chatId,
        node.at,
        node.call.toModel(),
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallHandLowered') {
      var node =
          e as ChatCallEventsVersionedMixin$Events$EventChatCallHandLowered;
      for (var m in node.call.members) {
        _userRepo?.put(m.user.toHive());
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
      _userRepo?.put(node.user.toHive());
      for (var m in [...node.call.members, ...node.newCall.members]) {
        _userRepo?.put(m.user.toHive());
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
        _userRepo?.put(m.user.toHive());
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
      _userRepo?.put(node.user.toHive());
      for (var m in node.call.members) {
        _userRepo?.put(m.user.toHive());
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
          _userRepo?.put(m.user.toHive());
        }
        return node.call.toModel();
      } else if (e.$$typename == 'EventChatCallMemberJoined') {
        var node =
            e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;

        for (var m in node.call.members) {
          _userRepo?.put(m.user.toHive());
        }
        return node.call.toModel();
      }
    }

    return null;
  }
}
