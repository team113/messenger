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

import 'dart:ui';

import 'package:graphql_flutter/graphql_flutter.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/store/event/chat_call.dart';
import '/store/model/chat_call.dart';

/// [ChatCall] related functionality.
abstract class CallGraphQlMixin {
  GraphQlClient get client;

  /// Returns a list of incoming [ChatCall]s of the authenticated [MyUser].
  ///
  /// A [ChatCall] is considered incoming when:
  /// - it's not yet answered or declined;
  /// - its [Chat] is not muted by the authenticated [MyUser];
  /// - its initiator is not the authenticated [MyUser].
  ///
  /// This list contains [ChatCall]s which require an immediate action from the
  /// authenticated [MyUser] and doesn't represent any historical data.
  ///
  /// A new [ChatCall] appears in this list when someone other than the
  /// authenticated [MyUser] starts it in a [Chat], and that [Chat] is not muted
  /// by the authenticated [MyUser].
  ///
  /// A [ChatCall] is removed from this list when:
  /// - it has been finished;
  /// - [MyUser] executes [joinChatCall] or [declineChatCall] on it;
  /// - [MyUser] executes `Mutation.muteChat` on its [Chat] (or
  /// `Mutation.muteMyUser` on himself).
  ///
  /// Executing `Mutation.muteMyUser` makes this list always empty until the
  /// consecutive execution of `Mutation.unmuteMyUser` or reaching the mute's
  /// deadline.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] at the same time, provided
  /// that [after] and [before] cursors are equal. In such case the returned
  /// page will include the [ChatCall] pointed by the cursor and the requested
  /// count of [ChatCall]s preceding and following it.
  ///
  /// If it's desired to receive the [ChatCall] pointed by the cursor without
  /// querying in both directions, one can specify [first] or [last] count as 0.
  Future<IncomingCalls$Query$IncomingChatCalls> incomingCalls({
    int? first,
    IncomingChatCallsCursor? after,
    int? last,
    IncomingChatCallsCursor? before,
  }) async {
    final variables = IncomingCallsArguments(
      first: first,
      after: after,
      last: last,
      before: before,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'IncomingCalls',
        document: IncomingCallsQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return IncomingCalls$Query.fromJson(result.data!).incomingChatCalls;
  }

  /// Subscribes to [ChatCallEvent]s of a [ChatCall].
  ///
  /// This subscription is mandatory to be created after (and only after)
  /// executing [startChatCall] or [joinChatCall] as represents a heartbeat
  /// indication of the authenticated [MyUser]'s participation in a [ChatCall].
  /// Stopping or breaking this subscription without leaving a [ChatCall] will
  /// end up by kicking the authenticated [MyUser] from the [ChatCall] by
  /// timeout (if not re-established earlier).
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized` followed by the initial state of the [ChatCall]
  /// (and they won't be emitted ever again until this subscription completes),
  /// or immediately completes without emitting anything, if such [ChatCall]
  /// hasn't been found or the authenticated [MyUser] doesn't participate in it.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Completion
  ///
  /// Finite.
  ///
  /// Completes without re-subscription necessity when:
  /// - The [ChatCall] is finished ([EventChatCallFinished] is emitted).
  /// - The authenticated [MyUser] is no longer a member of the [ChatCall]
  /// ([EventChatCallMemberLeft] is emitted for the the authenticated [MyUser]).
  /// - The [ChatCall] is not found or the authenticated [MyUser] doesn't
  /// participate in it (emits nothing, completes immediately after being
  /// established).
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  SubscriptionIterator callEvents(
    ChatItemId id,
    ChatCallDeviceId deviceId,
    Future<void> Function(QueryResult) listener,
  ) {
    final variables = CallEventsArguments(id: id, deviceId: deviceId);
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'CallEvents',
        document: CallEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      listener,
    );
  }

  /// Subscribes to updates of top [count] items of [incomingCalls] list.
  ///
  /// Note, that [EventIncomingChatCallsTopChatCallAdded] informs about a
  /// [ChatCall] becoming the topmost in [incomingCalls] list, but never about a
  /// [ChatCall] being updated itself.
  ///
  /// Note, that [EventIncomingChatCallsTopChatCallRemoved] informs about a
  /// [ChatCall] being removed from top count items of [incomingCalls] list, but
  /// never about a [ChatCall] being finished or removed itself.
  ///
  /// Instead, use [callEvents] for being informed correctly about [ChatCall]
  /// changes.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized` followed by the initial state of the
  /// [IncomingChatCallsTop] list (and they won't be emitted ever again until
  /// this subscription completes). Note, that emitting an empty list is
  /// possible valid.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Completion
  ///
  /// Infinite.
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  SubscriptionIterator incomingCallsTopEvents(
    int count,
    Future<void> Function(QueryResult) listener, {
    VoidCallback? onError,
  }) {
    final variables = IncomingCallsTopEventsArguments(count: count);
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'IncomingCallsTopEvents',
        document:
            IncomingCallsTopEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      listener,
    );
  }

  /// Starts a new [ChatCall] in the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// Once this mutation succeeds the [EventChatCallStarted] is fired to all
  /// [Chat] members via `Subscription.chatEvents`, and it's required to use
  /// [callEvents] for the authenticated [MyUser] to be able to react on all
  /// [ChatCallEvent]s happening during the started [ChatCall].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only of the following [ChatEvent]s may be produced on success:
  /// - [EventChatItemPosted] (if no [ChatCall] exists);
  /// - [EventChatCallStarted] (if no [ChatCall] exists);
  /// - [EventChatCallMemberJoined] (if [ChatCall] exists already).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]s) if there is a [ChatCall]
  /// in this [Chat] already and the authenticated [MyUser] is a member of it.
  /// Joins it if the authenticated [MyUser] is not a member yet.
  Future<StartCall$Mutation$StartChatCall$StartChatCallOk> startChatCall(
      ChatId chatId, ChatCallCredentials creds,
      [bool? withVideo]) async {
    final variables = StartCallArguments(
      chatId: chatId,
      creds: creds,
      withVideo: withVideo,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'StartCall',
        document: StartCallMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      (data) => StartChatCallException(
          (StartCall$Mutation.fromJson(data).startChatCall
                  as StartCall$Mutation$StartChatCall$StartChatCallError)
              .code),
    );
    return (StartCall$Mutation.fromJson(result.data!).startChatCall
        as StartCall$Mutation$StartChatCall$StartChatCallOk);
  }

  /// Joins the ongoing [ChatCall] in the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// Use this mutation when an [EventChatCallStarted] is received via
  /// `Subscription.chatEvents` and [MyUser] wants to accept the [ChatCall], or
  /// he wants to join an ongoing [ChatCall].
  ///
  /// Once this mutation succeeds the [EventChatCallMemberJoined] is fired to
  /// all [ChatCall] members via [callEvents], and it's required to use
  /// [callEvents] for the authenticated [MyUser] to be able to react on all
  /// [ChatCallEvent]s happening during the accepted [ChatCall].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatCallMemberJoined].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the authenticated
  /// [MyUser] joined the current [ChatCall] already (is a member of it).
  Future<JoinCall$Mutation$JoinChatCall$JoinChatCallOk> joinChatCall(
      ChatId chatId, ChatCallCredentials creds) async {
    final variables = JoinCallArguments(chatId: chatId, creds: creds);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'JoinCall',
        document: JoinCallMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      (data) => JoinChatCallException((JoinCall$Mutation.fromJson(data)
              .joinChatCall as JoinCall$Mutation$JoinChatCall$JoinChatCallError)
          .code),
    );
    return (JoinCall$Mutation.fromJson(result.data!).joinChatCall
        as JoinCall$Mutation$JoinChatCall$JoinChatCallOk);
  }

  /// Leaves the ongoing [ChatCall] in the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// Use this mutation when the authenticated [MyUser] wants to finish or leave
  /// the [ChatCall] he's participating in at the moment.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [ChatEvent]s may be produced on success:
  /// - [EventChatCallMemberLeft] (for [Chat]-groups);
  /// - [EventChatCallFinished] (for [Chat]-dialogs).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if there is no ongoing
  /// [ChatCall] in the specified [Chat] at the moment, or the authenticated
  /// [MyUser] is not a member of it already.
  Future<ChatEventsVersionedMixin?> leaveChatCall(
    ChatId chatId,
    ChatCallDeviceId deviceId,
  ) async {
    final variables = LeaveCallArguments(chatId: chatId, deviceId: deviceId);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'LeaveCall',
        document: LeaveCallMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      (data) => LeaveChatCallException(
          (LeaveCall$Mutation.fromJson(data).leaveChatCall
                  as LeaveCall$Mutation$LeaveChatCall$LeaveChatCallError)
              .code),
    );
    return (LeaveCall$Mutation.fromJson(result.data!).leaveChatCall
        as ChatEventsVersionedMixin?);
  }

  /// Declines the ongoing [ChatCall] in the specified [Chat] by the
  /// authenticated [MyUser].
  ///
  /// Use this mutation when an [EventChatCallStarted] is received via
  /// `Subscription.chatEvents` and [MyUser] doesn't want to accept the
  /// [ChatCall].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [ChatEvent]s may be produced on success:
  /// - [EventChatCallDeclined] (for [Chat]-groups);
  /// - [EventChatCallFinished] (for [Chat]-dialogs).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if there is no current
  /// [ChatCall], or it is declined by the authenticated [MyUser] already.
  Future<ChatEventsVersionedMixin?> declineChatCall(ChatId chatId) async {
    final variables = DeclineCallArguments(chatId: chatId);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'DeclineCall',
        document: DeclineCallMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      (data) => DeclineChatCallException(
          (DeclineCall$Mutation.fromJson(data).declineChatCall
                  as DeclineCall$Mutation$DeclineChatCall$DeclineChatCallError)
              .code),
    );
    return (DeclineCall$Mutation.fromJson(result.data!).declineChatCall
        as ChatEventsVersionedMixin?);
  }

  /// Raises/lowers a hand of the authenticated [MyUser] in the specified
  /// [ChatCall].
  ///
  /// Use this mutation when the authenticated [MyUser] wants to notify other
  /// [ChatCall] members about his desire to start talking. New
  /// [ChatCallMember]s always join a [ChatCall] with a lowered hand.
  ///
  /// For using this mutation the authenticated [MyUser] must be a member of
  /// the [ChatCall].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [ChatCallEvent]s may be produced on success:
  /// - [EventChatCallHandRaised] (if [raised] argument is `true`);
  /// - [EventChatCallHandLowered] (if [raised] argument is `false`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatCallEvent]) if the authenticated
  /// [MyUser] has raised/lowered his hand already.
  Future<ChatCallEventsVersionedMixin?> toggleChatCallHand(
      ChatId chatId, bool raised) async {
    final variables = ToggleCallHandArguments(chatId: chatId, raised: raised);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ToggleCallHand',
        document: ToggleCallHandMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ToggleChatCallHandException((ToggleCallHand$Mutation
                      .fromJson(data)
                  .toggleChatCallHand
              as ToggleCallHand$Mutation$ToggleChatCallHand$ToggleChatCallHandError)
          .code),
    );
    return (ToggleCallHand$Mutation.fromJson(result.data!).toggleChatCallHand
        as ChatCallEventsVersionedMixin?);
  }

  /// Redials a [User] who left or declined the ongoing [ChatCall] in the
  /// specified [Chat]-group by the authenticated [MyUser].
  ///
  /// For using this mutation the authenticated [MyUser] must be a member of the
  /// ongoing [ChatCall].
  ///
  /// Redialed [User] should see the [ChatCall.answered] indicator as `false`,
  /// and the ongoing [ChatCall] appearing in his [incomingCallsTopEvents]
  /// again.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [ChatCallEvent]s may be produced on success:
  /// - [EventChatCallMemberRedialed].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the redialed [User]
  /// didn't decline or leave the [ChatCall] yet, or has been redialed already.
  Future<ChatCallEventsVersionedMixin?> redialChatCallMember(
    ChatId chatId,
    UserId memberId,
  ) async {
    final variables = RedialChatCallMemberArguments(
      chatId: chatId,
      memberId: memberId,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'RedialChatCallMember',
        document: RedialChatCallMemberMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => RedialChatCallMemberException(
          (RedialChatCallMember$Mutation.fromJson(data).redialChatCallMember
                  as RedialChatCallMember$Mutation$RedialChatCallMember$RedialChatCallMemberError)
              .code),
    );
    return (RedialChatCallMember$Mutation.fromJson(result.data!)
        .redialChatCallMember as ChatCallEventsVersionedMixin?);
  }

  /// Moves an ongoing [ChatCall] in a [Chat]-dialog to a newly created
  /// [Chat]-group, optionally adding new members.
  ///
  /// The ongoing [ChatCall] should have its media room being created before
  /// moving, otherwise the [ChatCall] is not considered by this mutation as an
  /// ongoing one.
  ///
  /// Once this mutation succeeds, the [EventChatCallMoved] is fired to all
  /// [Chat]-dialog members via [callEvents], and it's required to establish a
  /// new [callEvents] using the emitted [EventChatCallMoved.newCallId]. Note,
  /// that the connection to the media room of the moved [ChatCall] should not
  /// be dropped, as it's simply moved to the returned
  /// [EventChatCallMoved.newCall], ensuring smooth experience for the
  /// [ChatCall] members.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatCallEvent]s are produced on success:
  /// - [EventChatCallMoved];
  /// - [EventChatCallFinished].
  ///
  /// ### Non-idempotent
  ///
  /// Each time tries to move the ongoing [ChatCall] into a new unique
  /// [Chat]-group.
  Future<ChatCallEventsVersionedMixin?> transformDialogCallIntoGroupCall(
    ChatId chatId,
    List<UserId> additionalMemberIds,
    ChatName? groupName,
  ) async {
    final variables = TransformDialogCallIntoGroupCallArguments(
      chatId: chatId,
      additionalMemberIds: additionalMemberIds,
      groupName: groupName,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'TransformDialogCallIntoGroupCall',
        document: TransformDialogCallIntoGroupCallMutation(variables: variables)
            .document,
        variables: variables.toJson(),
      ),
      onException: (data) => TransformDialogCallIntoGroupCallException(
          (TransformDialogCallIntoGroupCall$Mutation.fromJson(data)
                      .transformDialogCallIntoGroupCall
                  as TransformDialogCallIntoGroupCall$Mutation$TransformDialogCallIntoGroupCall$TransformDialogCallIntoGroupCallError)
              .code),
    );
    return (ToggleCallHand$Mutation.fromJson(result.data!).toggleChatCallHand
        as ChatCallEventsVersionedMixin?);
  }
}
