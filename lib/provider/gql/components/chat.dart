// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'dart:convert';

import 'package:dio/dio.dart'
    as dio
    show
        MultipartFile,
        Options,
        FormData,
        DioException,
        CancelToken,
        DioExceptionType;
import 'package:graphql/client.dart';

import '../base.dart';
import '../exceptions.dart';
import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/store/model/chat_item.dart';
import '/store/model/chat.dart';
import '/util/log.dart';

/// [Chat] related functionality.
mixin ChatGraphQlMixin {
  GraphQlClient get client;

  /// Returns a [Chat] by its ID.
  ///
  /// The authenticated [MyUser] should be a member of the [Chat] in order to
  /// view it.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetChat$Query> getChat(ChatId id) async {
    Log.debug('getChat($id)', '$runtimeType');

    final variables = GetChatArguments(id: id);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetChat',
        document: GetChatQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetChat$Query.fromJson(result.data!);
  }

  /// Returns non-hidden [Chat]s of the authenticated [MyUser] ordered
  /// descending by their last updating [DateTime].
  ///
  /// Use the [noFavorite] argument to exclude favorited [Chat]s from the
  /// returned result.
  ///
  /// Use the [archived] argument to only include archived [Chat]s into the
  /// returned result (`true`), or to exclude them (`false`).
  ///
  /// Use the [withOngoingCalls] argument to only include [Chat]s with ongoing
  /// [ChatCall]s into the returned result (`true`), or to exclude them
  /// (`false`).
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Sorting
  ///
  /// Returned [Chat]s are sorted primarily by their last updating [DateTime],
  /// and secondary by their IDs (if the last updating [DateTime] is the same),
  /// in descending order.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] counts at the same time,
  /// provided that [after] and [before] cursors are equal. In such case the
  /// returned page will include the [Chat] pointed by the cursor and the
  /// requested count of [Chat]s preceding and following it.
  ///
  /// If it's desired to receive the [Chat], pointed by the cursor, without
  /// querying in both directions, one can specify [first] or [last] count as 0.
  Future<RecentChats$Query> recentChats({
    int? first,
    RecentChatsCursor? after,
    int? last,
    RecentChatsCursor? before,
    bool noFavorite = false,
    bool archived = false,
    bool? withOngoingCalls,
  }) async {
    Log.debug(
      'recentChats($first, $after, $last, $before, $noFavorite, $archived, $withOngoingCalls)',
      '$runtimeType',
    );

    final variables = RecentChatsArguments(
      pagination: RecentChatsPagination(
        first: first,
        after: after,
        last: last,
        before: before,
      ),
      kw$with: RecentChatsFilter(
        noFavorite: noFavorite,
        archived: archived,
        ongoingCalls: withOngoingCalls,
      ),
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'RecentChats',
        document: RecentChatsQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return RecentChats$Query.fromJson(result.data!);
  }

  /// Returns favorite [Chat]s of the authenticated [MyUser] ordered by the
  /// custom order of [MyUser]'s favorites list (using [Chat.favoritePosition]
  /// field).
  ///
  /// Use [favoriteChat] to update the position of a [Chat] in [MyUser]'s
  /// favorites list.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Sorting
  ///
  /// Returned [Chat]s are sorted in the order specified by the authenticated
  /// [MyUser] in [favoriteChat] descending (starting from the highest
  /// [ChatFavoritePosition] and finishing at the lowest).
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] counts at the same time,
  /// provided that [after] and [before] cursors are equal. In such case the
  /// returned page will include the [Chat] pointed by the cursor and the
  /// requested count of [Chat]s preceding and following it.
  ///
  /// If it's desired to receive the [Chat], pointed by the cursor, without
  /// querying in both directions, one can specify [first] or [last] count as 0.
  Future<FavoriteChats$Query> favoriteChats({
    int? first,
    FavoriteChatsCursor? after,
    int? last,
    FavoriteChatsCursor? before,
  }) async {
    Log.debug('favoriteChats($first, $after, $last, $before)', '$runtimeType');

    final variables = FavoriteChatsArguments(
      first: first,
      after: after,
      last: last,
      before: before,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'FavoriteChats',
        document: FavoriteChatsQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return FavoriteChats$Query.fromJson(result.data!);
  }

  /// Creates a [Chat]-dialog with the provided [responderId] for the
  /// authenticated [MyUser].
  ///
  /// There can be only one [Chat]-dialog between two [User]s.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op if a [Chat] with the given responder [User] exists
  /// already, and returns this [Chat].
  Future<ChatMixin> createDialogChat(UserId responderId) async {
    Log.debug('createDialogChat($responderId)', '$runtimeType');

    final variables = CreateDialogArguments(responderId: responderId);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'CreateDialog',
        document: CreateDialogMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateDialogException(
        (CreateDialog$Mutation.fromJson(data).createDialogChat
                as CreateDialog$Mutation$CreateDialogChat$CreateDialogChatError)
            .code,
      ),
    );
    return (CreateDialog$Mutation.fromJson(result.data!).createDialogChat
        as ChatMixin);
  }

  /// Creates a [Chat]-group with the provided [User]s as members and the
  /// authenticated [MyUser].
  ///
  /// There can be many [Chat]-group between the same [User]s.
  Future<ChatMixin> createGroupChat(
    List<UserId> memberIds, {
    ChatName? name,
  }) async {
    Log.debug('createGroupChat($memberIds, $name)', '$runtimeType');

    final variables = CreateGroupChatArguments(
      memberIds: memberIds,
      name: name,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'CreateGroupChat',
        document: CreateGroupChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateGroupChatException(
        (CreateGroupChat$Mutation.fromJson(data).createGroupChat
                as CreateGroupChat$Mutation$CreateGroupChat$CreateGroupChatError)
            .code,
      ),
    );
    return (CreateGroupChat$Mutation.fromJson(result.data!).createGroupChat
        as CreateGroupChat$Mutation$CreateGroupChat$Chat);
  }

  /// Renames the specified [Chat] by authority of the authenticated [MyUser].
  ///
  /// Removes the [Chat.name] of the [Chat] if the provided [name] is `null`.
  ///
  /// Only [Chat]-groups can be named or renamed.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemPosted] ([ChatInfo] with [ChatInfoActionNameUpdated]).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] has
  /// the specified name already
  Future<ChatEventsVersionedMixin?> renameChat(
    ChatId id,
    ChatName? name,
  ) async {
    Log.debug('renameChat($id, $name)', '$runtimeType');

    RenameChatArguments variables = RenameChatArguments(id: id, name: name);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'RenameChat',
        document: RenameChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => RenameChatException(
        (RenameChat$Mutation.fromJson(data).renameChat
                as RenameChat$Mutation$RenameChat$RenameChatError)
            .code,
      ),
    );
    return (RenameChat$Mutation.fromJson(result.data!).renameChat
        as ChatEventsVersionedMixin?);
  }

  /// Fetches [ChatItem]s of a [Chat] identified by its [id] ordered by their
  /// posting time.
  ///
  /// It is allowed to specify both [first] and [last] at the same time provided
  /// that [after] and [before] are equal. In such cases the returned page will
  /// include the [ChatItem] pointed by the cursor and the requested number of
  /// [ChatItem]s preceding and following it.
  ///
  /// If it is desired to receive the [ChatItem] under the cursor without
  /// querying in both directions one can specify [first] or [last] as 0.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetMessages$Query> chatItems(
    ChatId id, {
    int? first,
    ChatItemsCursor? after,
    int? last,
    ChatItemsCursor? before,
    ChatItemsFilter? filter,
  }) async {
    Log.debug(
      'chatItems($id, first: $first, after: $after, last: $last, before: $before, filter: $filter)',
      '$runtimeType',
    );

    final variables = GetMessagesArguments(
      id: id,
      first: first,
      after: after,
      last: last,
      before: before,
      filter: filter,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetMessages',
        document: GetMessagesQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetMessages$Query.fromJson(result.data!);
  }

  /// Returns a [ChatItem] by its ID.
  ///
  /// The authenticated [MyUser] should be a member of the [Chat] the provided
  /// [ChatItem] belongs to, in order to view it.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetMessage$Query> chatItem(ChatItemId id) async {
    Log.debug('chatItem($id)', '$runtimeType');

    final variables = GetMessageArguments(id: id);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetMessage',
        document: GetMessageQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetMessage$Query.fromJson(result.data!);
  }

  /// Posts a new [ChatMessage] to the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// For the posted [ChatMessage] to be meaningful, at least one of [text] or
  /// [attachments] arguments must be specified and non-empty.
  ///
  /// To attach some [Attachment]s to the posted [ChatMessage], first, they
  /// should be uploaded with `Mutation.uploadAttachment`, and then use the
  /// returned [AttachmentId]s in [attachments] argument of this mutation.
  ///
  /// Specify [repliesTo] argument of this mutations if the posted [ChatMessage]
  /// is going to be a reply to some other [ChatItem].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemPosted].
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new unique [ChatMessage], producing a new [ChatEvent].
  Future<ChatEventsVersionedMixin?> postChatMessage(
    ChatId chatId, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
    List<ChatItemId> repliesTo = const [],
  }) async {
    Log.debug(
      'postChatMessage($chatId, $text, $attachments, $repliesTo)',
      '$runtimeType',
    );

    final variables = PostChatMessageArguments(
      chatId: chatId,
      text: text,
      attachments: attachments,
      repliesTo: repliesTo,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'PostChatMessage',
        document: PostChatMessageMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => PostChatMessageException(
        (PostChatMessage$Mutation.fromJson(data).postChatMessage
                as PostChatMessage$Mutation$PostChatMessage$PostChatMessageError)
            .code,
      ),
    );
    return PostChatMessage$Mutation.fromJson(result.data!).postChatMessage
        as PostChatMessage$Mutation$PostChatMessage$ChatEventsVersioned;
  }

  /// Adds an [User] to a [Chat]-group by the authority of the authenticated
  /// [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following ChatEvent may be produced on success:
  /// - [EventChatItemPosted] ([ChatInfo]).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [User] is
  /// a member of the specified [Chat] already.
  Future<ChatEventsVersionedMixin?> addChatMember(
    ChatId chatId,
    UserId userId,
  ) async {
    Log.debug('addChatMember($chatId, $userId)', '$runtimeType');

    final variables = AddChatMemberArguments(chatId: chatId, userId: userId);
    var result = await client.mutate(
      MutationOptions(
        operationName: 'AddChatMember',
        document: AddChatMemberMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => AddChatMemberException(
        (AddChatMember$Mutation.fromJson(data).addChatMember
                as AddChatMember$Mutation$AddChatMember$AddChatMemberError)
            .code,
      ),
    );
    return AddChatMember$Mutation.fromJson(result.data!).addChatMember
        as ChatEventsVersionedMixin?;
  }

  /// Removes an [User] from a [Chat]-group by the authority of the
  /// authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemPosted] ([ChatInfo]).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [User] is
  /// not a member of the specified [Chat] already.
  Future<ChatEventsVersionedMixin?> removeChatMember(
    ChatId chatId,
    UserId userId,
  ) async {
    Log.debug('removeChatMember($chatId, $userId)', '$runtimeType');

    RemoveChatMemberArguments variables = RemoveChatMemberArguments(
      chatId: chatId,
      userId: userId,
    );
    var result = await client.mutate(
      MutationOptions(
        operationName: 'RemoveChatMember',
        document: RemoveChatMemberMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => RemoveChatMemberException(
        (RemoveChatMember$Mutation.fromJson(data).removeChatMember
                as RemoveChatMember$Mutation$RemoveChatMember$RemoveChatMemberError)
            .code,
      ),
    );
    return (RemoveChatMember$Mutation.fromJson(result.data!).removeChatMember
        as ChatEventsVersionedMixin?);
  }

  /// Marks the specified [Chat] as hidden for the authenticated [MyUser].
  ///
  /// Hidden [Chat] is excluded from [recentChats], but preserves all its
  /// content. Once a new [ChatItem] posted in a [Chat] it becomes visible
  /// again, and so included into [recentChats] as well.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatHidden].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// already hidden by the authenticated [MyUser].
  Future<ChatEventsVersionedMixin?> hideChat(ChatId chatId) async {
    Log.debug('hideChat($chatId)', '$runtimeType');

    HideChatArguments variables = HideChatArguments(chatId: chatId);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'HideChat',
        document: HideChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => HideChatException(
        (HideChat$Mutation.fromJson(data).hideChat
                as HideChat$Mutation$HideChat$HideChatError)
            .code,
      ),
    );
    return (HideChat$Mutation.fromJson(result.data!).hideChat
        as ChatEventsVersionedMixin?);
  }

  /// Archive or unarchive the specified [Chat] for the authenticated [MyUser].
  ///
  /// Archived [Chat]s are excluded from the [recentChats] when its with
  /// [archive] argument is set to `false`.
  ///
  /// Once a new [ChatItem] is posted in an archived unmuted [Chat], it
  /// automatically becomes unarchived again, despite no [EventChatUnarchived]
  /// is emitted (which means manual unarchivation only). Muted [Chat]s,
  /// however, are not unarchived automatically once new [ChatItem]s are posted.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// One of the following [ChatEvent]s may be produced on success:
  /// - [EventChatArchived] (if [archive] argument is `true`);
  /// - [EventChatUnarchived] (if [archive] argument is `false`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// already archived (or unarchived) for the authenticated [MyUser].
  Future<ChatEventsVersionedMixin?> toggleChatArchivation(
    ChatId chatId,
    bool archive,
  ) async {
    Log.debug('toggleChatArchivation($chatId, $archive)', '$runtimeType');

    final variables = ToggleChatArchivationArguments(
      id: chatId,
      archive: archive,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ToggleChatArchivation',
        document: ToggleChatArchivationMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ToggleChatArchivationException(
        (ToggleChatArchivation$Mutation.fromJson(data).toggleChatArchivation
                as ToggleChatArchivation$Mutation$ToggleChatArchivation$ToggleChatArchivationError)
            .code,
      ),
    );

    return (ToggleChatArchivation$Mutation.fromJson(
          result.data!,
        ).toggleChatArchivation
        as ChatEventsVersionedMixin?);
  }

  /// Marks the specified [Chat] as read for the authenticated [MyUser] until
  /// the specified [ChatItem] inclusively.
  ///
  /// There is no notion of a single [ChatItem] being read or not separately in
  /// a [Chat]. Only a whole [Chat] as a sequence of [ChatItem]s can be read
  /// until some its position (concrete [ChatItem]). So, any [ChatItem] may be
  /// considered as read or not by comparing its [ChatItem.at] with the
  /// [LastChatRead.at] of the authenticated [MyUser]: if it's below (less or
  /// equal) then the [ChatItem] is read, otherwise it's unread.
  ///
  /// This mutation should be called whenever the authenticated [MyUser] reads
  /// new [ChatItem]s appeared in the Chat's UI and directly influences the
  /// [Chat.unreadCount] value.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatRead].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// already read by the authenticated [MyUser] until the specified [ChatItem].
  Future<ChatEventsVersionedMixin?> readChat(
    ChatId chatId,
    ChatItemId untilId,
  ) async {
    Log.debug('readChat($chatId, $untilId)', '$runtimeType');

    final variables = ReadChatArguments(id: chatId, untilId: untilId);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ReadChat',
        document: ReadChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ReadChatException(
        (ReadChat$Mutation.fromJson(data).readChat
                as ReadChat$Mutation$ReadChat$ReadChatError)
            .code,
      ),
    );
    return (ReadChat$Mutation.fromJson(result.data!).readChat
        as ChatEventsVersionedMixin?);
  }

  /// Subscribes to updates of top [count] items of [recentChats] list.
  ///
  /// Note, that [EventRecentChatsUpdated] informs about a [Chat] becoming the
  /// topmost in [recentChats] list, but never about a [Chat] being updated
  /// itself.
  ///
  /// Note, that [EventRecentChatsDeleted] informs about a [Chat] being removed
  /// from top [count] items of [recentChats] list, but never about a [Chat]
  /// being removed itself.
  ///
  /// Instead, use [chatEvents] for being informed correctly about [Chat]
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
  /// [RecentChatsTop] list (and they won't be emitted ever again until this
  /// subscription completes). Note, that emitting an empty list is possible
  /// valid.
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
  Stream<QueryResult> recentChatsTopEvents(
    int count, {
    bool noFavorite = true,
    bool archived = false,
    bool? withOngoingCalls,
  }) {
    Log.debug(
      'recentChatsTopEvents($count, $noFavorite, $withOngoingCalls)',
      '$runtimeType',
    );

    final variables = RecentChatsTopEventsArguments(
      count: count,
      kw$with: RecentChatsFilter(
        noFavorite: noFavorite,
        ongoingCalls: withOngoingCalls,
        archived: archived,
      ),
    );
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'RecentChatsTopEvents',
        document: RecentChatsTopEventsSubscription(
          variables: variables,
        ).document,
        variables: variables.toJson(),
      ),
    );
  }

  /// Subscribes to [ChatEvent]s of the specified [Chat].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized`, or immediately completes (without emitting
  /// anything) if such [Chat] doesn't exist or [MyUser] doesn't participate in
  /// it.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Result
  ///
  /// If [ver] argument is not specified (or is `null`) an initial state of the
  /// [Chat] will be emitted after `SubscriptionInitialized` and before any
  /// other [ChatEvent]s (and won't be emitted ever again until this
  /// subscription completes). This allows to skip doing [getChat] (or
  /// [recentChats]) before establishing this subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via [getChat] (or
  /// [recentChats]);
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh [ver] may be obtained in the emitted initial state of the
  /// [Chat]).
  ///
  /// ### Completion
  ///
  /// Finite.
  ///
  /// Completes without re-subscription necessity when:
  /// - The [Chat] does not exist (emits nothing, completes immediately after
  /// being established).
  /// - The authenticated [MyUser] is not a member of the [Chat] at the moment
  /// of subscribing (emits nothing, completes immediately after being
  /// established).
  /// - The authenticated [MyUser] is no longer a member of the [Chat] (emits
  /// [EventChatItemPosted] with [ChatInfo] of [MyUser] being removed and
  /// completes).
  ///
  /// Completes requiring a re-subscription when:
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization).
  Stream<QueryResult> chatEvents(
    ChatId id,
    ChatVersion? ver,
    FutureOr<ChatVersion?> Function() onVer, {
    int priority = -10,
  }) {
    Log.debug('chatEvents($id, $ver, onVer)', '$runtimeType');

    final variables = ChatEventsArguments(id: id, ver: ver);
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'ChatEvents',
        document: ChatEventsSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      priority: priority,
      ver: onVer,
    );
  }

  /// Hides the specified [ChatItem] for the authenticated [MyUser].
  ///
  /// Hidden [ChatItem] is not visible only for the one who hid it, remaining
  /// visible for other [User]s.
  ///
  /// Use this mutation for "deleting" a [ChatItem] for the authenticated
  /// [MyUser] in [Chat]'s UI in case [deleteChatMessage] (or
  /// [deleteChatForward]) returns `READ` (or `QUOTED`) error.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemHidden].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [ChatItem]
  /// is hidden by the authenticated [MyUser] already.
  Future<ChatEventsVersionedMixin?> hideChatItem(ChatItemId id) async {
    Log.debug('hideChatItem($id)', '$runtimeType');

    HideChatItemArguments variables = HideChatItemArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'HideChatItem',
        document: HideChatItemMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => HideChatItemException(
        (HideChatItem$Mutation.fromJson(data).hideChatItem
                as HideChatItem$Mutation$HideChatItem$HideChatItemError)
            .code,
      ),
    );
    return (HideChatItem$Mutation.fromJson(result.data!).hideChatItem
        as ChatEventsVersionedMixin?);
  }

  /// Deletes the specified [ChatMessage] posted by the authenticated [MyUser].
  ///
  /// [ChatMessage] is allowed to be deleted only when it's not read by any
  /// other [Chat] member and neither forwarded, nor replied. Once deleted,
  /// [ChatMessage] is not visible for anyone in the [Chat].
  ///
  /// If this mutation returns `READ` (or `QUOTED`) error, use [hideChatItem] to
  /// "remove" the [ChatMessage] for the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified
  /// [ChatMessage] is deleted already.
  Future<ChatEventsVersionedMixin?> deleteChatMessage(ChatItemId id) async {
    Log.debug('deleteChatMessage($id)', '$runtimeType');

    DeleteChatMessageArguments variables = DeleteChatMessageArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'DeleteChatMessage',
        document: DeleteChatMessageMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => DeleteChatMessageException(
        (DeleteChatMessage$Mutation.fromJson(data).deleteChatMessage
                as DeleteChatMessage$Mutation$DeleteChatMessage$DeleteChatMessageError)
            .code,
      ),
    );
    return (DeleteChatMessage$Mutation.fromJson(result.data!).deleteChatMessage
        as ChatEventsVersionedMixin?);
  }

  /// Deletes the specified [ChatForward] posted by the authenticated [MyUser].
  ///
  /// [ChatForward] is allowed to be deleted only when it's not read by any
  /// other [Chat] member and neither forwarded, nor replied. Once deleted,
  /// [ChatForward] is not visible for anyone in the [Chat].
  ///
  /// If this mutation returns `READ` (or `QUOTED`) error, use [hideChatItem] to
  /// "remove" the [ChatForward] for the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified
  /// [ChatForward] is deleted already.
  Future<ChatEventsVersionedMixin?> deleteChatForward(ChatItemId id) async {
    Log.debug('deleteChatForward($id)', '$runtimeType');

    DeleteChatForwardArguments variables = DeleteChatForwardArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'DeleteChatForward',
        document: DeleteChatForwardMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => DeleteChatForwardException(
        (DeleteChatForward$Mutation.fromJson(data).deleteChatForward
                as DeleteChatForward$Mutation$DeleteChatForward$DeleteChatForwardError)
            .code,
      ),
    );
    return (DeleteChatForward$Mutation.fromJson(result.data!).deleteChatForward
        as ChatEventsVersionedMixin?);
  }

  /// Creates a new [Attachment] linked to the authenticated [MyUser] for a
  /// later use in the [postChatMessage] mutation.
  ///
  /// HTTP request for this mutation must be `Content-Type: multipart/form-data`
  /// containing the uploaded file and the [attachment] argument must be `null`,
  /// otherwise this mutation will fail.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Non-idempotent
  ///
  /// Each time creates a new unique [Attachment].
  Future<UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk>
  uploadAttachment(
    dio.MultipartFile? attachment, {
    void Function(int count, int total)? onSendProgress,
    dio.CancelToken? cancelToken,
  }) async {
    Log.debug('uploadAttachment($attachment, onSendProgress)', '$runtimeType');

    final variables = UploadAttachmentArguments(file: null);
    final query = MutationOptions(
      operationName: 'UploadAttachment',
      document: UploadAttachmentMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    try {
      var response = await client.post(
        dio.FormData.fromMap({
          'operations': encodedBody,
          'map': '{ "file": ["variables.upload"] }',
          'file': attachment,
        }),
        options: dio.Options(contentType: 'multipart/form-data'),
        operationName: query.operationName,
        onSendProgress: onSendProgress,
        onException: (data) => UploadAttachmentException(
          (UploadAttachment$Mutation.fromJson(data).uploadAttachment
                  as UploadAttachment$Mutation$UploadAttachment$UploadAttachmentError)
              .code,
        ),
        cancelToken: cancelToken,
      );

      if (response.data['data'] == null) {
        throw GraphQlException([
          GraphQLError(message: response.data.toString()),
        ]);
      }

      return (UploadAttachment$Mutation.fromJson(
            response.data['data'],
          )).uploadAttachment
          as UploadAttachment$Mutation$UploadAttachment$UploadAttachmentOk;
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const UploadAttachmentException(
          UploadAttachmentErrorCode.invalidSize,
        );
      }

      switch (e.type) {
        case dio.DioExceptionType.cancel:
          // No-op.
          break;

        default:
          Log.error(
            'Failed to upload attachment: ${e.response}',
            '$runtimeType',
          );
      }

      rethrow;
    }
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the given [Chat]-group.
  ///
  /// Deleted [ChatDirectLink]s can be re-created again by the original owner
  /// only ([Chat]-group) and cannot leak to somebody else.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatDirectLinkUpdated].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the given [Chat]-group
  /// has an active [ChatDirectLink] with such [ChatDirectLinkSlug] already.
  Future<ChatEventsVersionedMixin?> createChatDirectLink(
    ChatDirectLinkSlug slug, {
    ChatId? groupId,
  }) async {
    Log.debug('createChatDirectLink($slug, $groupId)', '$runtimeType');

    final variables = CreateChatDirectLinkArguments(
      slug: slug,
      groupId: groupId,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'CreateChatDirectLink',
        document: CreateChatDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => CreateChatDirectLinkException(
        (CreateChatDirectLink$Mutation.fromJson(data).createChatDirectLink
                as CreateChatDirectLink$Mutation$CreateChatDirectLink$CreateChatDirectLinkError)
            .code,
      ),
    );
    return CreateChatDirectLink$Mutation.fromJson(
          result.data!,
        ).createChatDirectLink
        as ChatEventsVersionedMixin?;
  }

  /// Deletes the current [ChatDirectLink] of the given [Chat]-group.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatDirectLinkDeleted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the given [Chat]-group
  /// has no active [ChatDirectLink]s already.
  Future<ChatEventsVersionedMixin?> deleteChatDirectLink({
    ChatId? groupId,
  }) async {
    Log.debug('deleteChatDirectLink($groupId)', '$runtimeType');

    final variables = DeleteChatDirectLinkArguments(groupId: groupId);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'DeleteChatDirectLink',
        document: DeleteChatDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => DeleteChatDirectLinkException(
        DeleteChatDirectLink$Mutation.fromJson(data).deleteChatDirectLink
            as DeleteChatDirectLinkErrorCode,
      ),
    );
    return DeleteChatDirectLink$Mutation.fromJson(
          result.data!,
        ).deleteChatDirectLink
        as ChatEventsVersionedMixin?;
  }

  /// Uses the specified [ChatDirectLink] by the authenticated [MyUser] creating
  /// a new [Chat]-dialog or joining an existing [Chat]-group.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Always returns the created or modified [Chat].
  ///
  /// Only the following [ChatEvent] may be produced on success for the
  /// [Chat]-group:
  /// - [EventChatItemPosted].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the authenticated
  /// [MyUser] is already a member of the [Chat]-group or has already created
  /// the [Chat]-dialog by the specified [ChatDirectLink].
  Future<UseChatDirectLink$Mutation$UseChatDirectLink$UseChatDirectLinkOk>
  useChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('useChatDirectLink($slug)', '$runtimeType');

    final variables = UseChatDirectLinkArguments(slug: slug);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UseChatDirectLink',
        document: UseChatDirectLinkMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UseChatDirectLinkException(
        (UseChatDirectLink$Mutation.fromJson(data).useChatDirectLink
                as UseChatDirectLink$Mutation$UseChatDirectLink$UseChatDirectLinkError)
            .code,
      ),
    );
    return (UseChatDirectLink$Mutation.fromJson(result.data!).useChatDirectLink
        as UseChatDirectLink$Mutation$UseChatDirectLink$UseChatDirectLinkOk);
  }

  /// Notifies [ChatMember]s about the authenticated [MyUser] typing in the
  /// specified [Chat] at the moment.
  ///
  /// Keep this subscription up while the authenticated [MyUser] is typing. Once
  /// this subscription begins, [chatEvents] emit [EventChatTypingStarted], and
  /// [EventChatTypingStopped] once it ends.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized`.
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
  ///
  /// - Authenticated [Session] expires (`SESSION_EXPIRED` error is emitted).
  /// - An error occurs on the server (error is emitted).
  /// - The server is shutting down or becoming unreachable (unexpectedly
  /// completes after initialization)
  Stream<QueryResult> keepTyping(ChatId id) {
    Log.debug('keepTyping($id)', '$runtimeType');

    final variables = KeepTypingArguments(chatId: id);
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'KeepTyping',
        document: KeepTypingSubscription(variables: variables).document,
        variables: variables.toJson(),
      ),
      resubscribe: false,
    );
  }

  /// Edits a [ChatMessage] by the authenticated [MyUser] with the provided
  /// [text]/[attachments]/[repliesTo] (at least one of three must be
  /// specified).
  ///
  /// [ChatMessage] is allowed to be edited within 5 minutes since its creation
  /// or if it hasn't been read by any other [Chat] member yet.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatItemEdited].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]s) if the specified
  /// [ChatMessage] already has the specified [text], [attachments] and
  /// [repliesTo] in the same order.
  Future<ChatEventsVersionedMixin?> editChatMessage(
    ChatItemId id, {
    ChatMessageTextInput? text,
    ChatMessageAttachmentsInput? attachments,
    ChatMessageRepliesInput? repliesTo,
  }) async {
    Log.debug(
      'editChatMessage($id, $text, $attachments, $repliesTo)',
      '$runtimeType',
    );

    final variables = EditChatMessageArguments(
      id: id,
      text: text,
      attachments: attachments,
      repliesTo: repliesTo,
    );

    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'EditChatMessage',
        document: EditChatMessageMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => EditChatMessageException(
        (EditChatMessage$Mutation.fromJson(data).editChatMessage
                as EditChatMessage$Mutation$EditChatMessage$EditChatMessageError)
            .code,
      ),
    );
    return (EditChatMessage$Mutation.fromJson(result.data!).editChatMessage
        as ChatEventsVersionedMixin?);
  }

  /// Forwards [ChatItem]s to the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// Supported [ChatItem]s are [ChatMessage] and [ChatForward].
  ///
  /// If [text] or [attachments] argument is specified, then the forwarded
  /// [ChatItem]s will be followed with a posted [ChatMessage] containing that
  /// [text] and/or [attachments].
  ///
  /// The maximum number of forwarded [ChatItem]s at once is 100.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent]s may be produced on success:
  /// - [EventChatItemPosted] ([ChatForward] and optionally [ChatMessage]).
  ///
  /// ### Non-idempotent
  ///
  /// Each time posts a new [ChatForward].
  Future<ChatEventsVersionedMixin?> forwardChatItems(
    ChatId from,
    ChatId to,
    List<ChatItemQuoteInput> items, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
  }) async {
    Log.debug(
      'forwardChatItems($from, $to, $items, $text, $attachments)',
      '$runtimeType',
    );

    final variables = ForwardChatItemsArguments(
      from: from,
      to: to,
      items: items,
      message: text != null || attachments != null
          ? ForwardChatItemsMessageInput(attachments: attachments, text: text)
          : null,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ForwardChatItems',
        document: ForwardChatItemsMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ForwardChatItemsException(
        (ForwardChatItems$Mutation.fromJson(data).forwardChatItems
                as ForwardChatItems$Mutation$ForwardChatItems$ForwardChatItemsError)
            .code,
      ),
    );
    return ForwardChatItems$Mutation.fromJson(result.data!).forwardChatItems
        as ForwardChatItems$Mutation$ForwardChatItems$ChatEventsVersioned;
  }

  /// Mutes or unmutes the specified [Chat] for the authenticated [MyUser].
  /// Overrides an existing mute even if it's longer.
  ///
  /// Muted [Chat] implies that its events don't produce sounds and
  /// notifications on a client side. This, however, has nothing to do with a
  /// server and is the responsibility to be satisfied by a client side.
  ///
  /// Note, that `Mutation.toggleChatMute` doesn't correlate with
  /// `Mutation.toggleMyUserMute`. Muted [Chat] of unmuted [MyUser] should not
  /// produce any sounds, and so, unmuted [Chat] of muted [MyUser] should not
  /// produce any sounds too.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent]s may be produced on success:
  /// - [EventChatMuted] (if `until` argument is not `null`);
  /// - [EventChatUnmuted] (if `until` argument is `null`).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// already muted `until` the specified [DateTime] (or unmuted) for the
  /// authenticated [MyUser].
  Future<ChatEventsVersionedMixin?> toggleChatMute(
    ChatId id,
    Muting? mute,
  ) async {
    Log.debug('toggleChatMute($id, $mute)', '$runtimeType');

    final variables = ToggleChatMuteArguments(id: id, mute: mute);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ToggleChatMute',
        document: ToggleChatMuteMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ToggleChatMuteException(
        (ToggleChatMute$Mutation.fromJson(data).toggleChatMute
                as ToggleChatMute$Mutation$ToggleChatMute$ToggleChatMuteError)
            .code,
      ),
    );
    return ToggleChatMute$Mutation.fromJson(result.data!).toggleChatMute
        as ChatEventsVersionedMixin?;
  }

  /// Returns the [Attachment]s of a [ChatItem] identified by the provided [id].
  ///
  /// The authenticated [MyUser] should be a member of the [Chat] the provided
  /// [ChatItem] belongs to, in order to view it.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetAttachments$Query> attachments(ChatItemId id) async {
    Log.debug('attachments($id)', '$runtimeType');

    final variables = GetAttachmentsArguments(id: id);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetAttachments',
        document: GetAttachmentsQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetAttachments$Query.fromJson(result.data!);
  }

  /// Updates the [Chat.avatar] field with the provided image, or resets it to
  /// `null`, by authority of the authenticated [MyUser].
  ///
  /// HTTP request for this mutation must be `Content-Type: multipart/form-data`
  /// containing the uploaded file and the file argument itself must be `null`,
  /// otherwise this mutation will fail.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent]s may be produced on success:
  /// - [EventChatItemPosted] ([ChatInfo] with [ChatInfoActionAvatarUpdated]).
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat]
  /// uses the specified [file] already as an [avatar] with the same `crop`
  /// area.
  Future<ChatEventsVersionedMixin?> updateChatAvatar(
    ChatId id, {
    dio.MultipartFile? file,
    CropAreaInput? crop,
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug(
      'updateChatAvatar($id, $file, $crop, onSendProgress)',
      '$runtimeType',
    );

    final variables = UpdateChatAvatarArguments(
      chatId: id,
      file: null,
      crop: crop,
    );
    final query = MutationOptions(
      operationName: 'UpdateChatAvatar',
      document: UpdateChatAvatarMutation(variables: variables).document,
      variables: variables.toJson(),
    );

    if (file == null) {
      final QueryResult result = await client.mutate(
        query,
        onException: (data) => UpdateChatAvatarException(
          (UpdateChatAvatar$Mutation.fromJson(data).updateChatAvatar
                  as UpdateChatAvatar$Mutation$UpdateChatAvatar$UpdateChatAvatarError)
              .code,
        ),
      );

      return UpdateChatAvatar$Mutation.fromJson(result.data!).updateChatAvatar
          as UpdateChatAvatar$Mutation$UpdateChatAvatar$ChatEventsVersioned;
    }

    final request = query.asRequest;
    final body = const RequestSerializer().serializeRequest(request);
    final encodedBody = json.encode(body);

    try {
      var response = await client.post(
        dio.FormData.fromMap({
          'operations': encodedBody,
          'map': '{ "file": ["variables.upload"] }',
          'file': file,
        }),
        options: dio.Options(contentType: 'multipart/form-data'),
        operationName: query.operationName,
        onSendProgress: onSendProgress,
        onException: (data) => UpdateChatAvatarException(
          (UpdateChatAvatar$Mutation.fromJson(data).updateChatAvatar
                  as UpdateChatAvatar$Mutation$UpdateChatAvatar$UpdateChatAvatarError)
              .code,
        ),
      );

      return UpdateChatAvatar$Mutation.fromJson(
            response.data['data'],
          ).updateChatAvatar
          as ChatEventsVersionedMixin?;
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw const UpdateChatAvatarException(
          UpdateChatAvatarErrorCode.invalidSize,
        );
      }

      rethrow;
    }
  }

  /// Marks the specified [Chat] as favorited for the authenticated [MyUser] and
  /// sets its [position] in the favorites list.
  ///
  /// To move the [Chat] to a concrete position in a favorites list, provide the
  /// average value of two other [Chat]s positions surrounding it.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatFavorited]
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// already favorited at the same position.
  Future<ChatEventsVersionedMixin?> favoriteChat(
    ChatId id,
    ChatFavoritePosition position,
  ) async {
    Log.debug('favoriteChat($id, $position)', '$runtimeType');

    final variables = FavoriteChatArguments(id: id, pos: position);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'FavoriteChat',
        document: FavoriteChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => FavoriteChatException(
        (FavoriteChat$Mutation.fromJson(data).favoriteChat
                as FavoriteChat$Mutation$FavoriteChat$FavoriteChatError)
            .code,
      ),
    );
    return FavoriteChat$Mutation.fromJson(result.data!).favoriteChat
        as ChatEventsVersionedMixin?;
  }

  /// Removes the specified [Chat] from the favorites list of the authenticated
  /// [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatUnfavorited]
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// not in the favorites list already.
  Future<ChatEventsVersionedMixin?> unfavoriteChat(ChatId id) async {
    Log.debug('unfavoriteChat($id)', '$runtimeType');

    final variables = UnfavoriteChatArguments(id: id);
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'UnfavoriteChat',
        document: UnfavoriteChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => UnfavoriteChatException(
        (UnfavoriteChat$Mutation.fromJson(data).unfavoriteChat
                as UnfavoriteChat$Mutation$UnfavoriteChat$UnfavoriteChatError)
            .code,
      ),
    );
    return UnfavoriteChat$Mutation.fromJson(result.data!).unfavoriteChat
        as ChatEventsVersionedMixin?;
  }

  /// Subscribes to [FavoriteChatsEvent]s of all [Chat]s of the authenticated
  /// [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Initialization
  ///
  /// Once this subscription is initialized completely, it immediately emits
  /// `SubscriptionInitialized`.
  ///
  /// If nothing has been emitted for a long period of time after establishing
  /// this subscription (while not being completed), it should be considered as
  /// an unexpected server error. This fact can be used on a client side to
  /// decide whether this subscription has been initialized successfully.
  ///
  /// ### Result
  ///
  /// If [ver] argument is not specified (or is `null`) an initial state of the
  /// favorite [Chat]s list will be emitted after `SubscriptionInitialized` and
  /// before any other [FavoriteChatsEvents] (and won't be emitted ever again
  /// until this subscription completes). This allows to skip doing
  /// `Query.favoriteChats` before establishing this subscription.
  ///
  /// If the specified [ver] is not fresh (was queried quite a time ago), it may
  /// become stale, so this subscription will return `STALE_VERSION` error on
  /// initialization. In such case:
  /// - either a fresh version should be obtained via `Query.favoriteChats`;
  /// - or a re-subscription should be done without specifying a [ver] argument
  /// (so the fresh [ver] may be obtained in the emitted initial state of the
  /// favorite [Chat]s list).
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
  ///
  /// ### Idempotency
  ///
  /// It's possible that in rare scenarios this subscription could emit an event
  /// which have already been applied to the state of some [Chat], so a client
  /// side is expected to handle all the events idempotently considering the
  /// `Chat.ver`.
  Stream<QueryResult> favoriteChatsEvents(
    FavoriteChatsListVersion? Function() ver,
  ) {
    Log.debug('favoriteChatsEvents(ver)', '$runtimeType');

    final variables = FavoriteChatsEventsArguments(ver: ver());
    return client.subscribe(
      SubscriptionOptions(
        operationName: 'FavoriteChatsEvents',
        document: FavoriteChatsEventsSubscription(
          variables: variables,
        ).document,
        variables: variables.toJson(),
      ),
      ver: ver,
    );
  }

  /// Clears an existing [Chat] (hides all its [ChatItem]s) for the
  /// authenticated [MyUser] until the specified [ChatItem] inclusively.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Only the following [ChatEvent] may be produced on success:
  /// - [EventChatCleared].
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op (and returns no [ChatEvent]) if the specified [Chat] is
  /// already cleared until the specified [ChatItem].
  Future<ChatEventsVersionedMixin?> clearChat(
    ChatId id,
    ChatItemId untilId,
  ) async {
    Log.debug('clearChat($id, $untilId)', '$runtimeType');

    final ClearChatArguments variables = ClearChatArguments(
      id: id,
      untilId: untilId,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'ClearChat',
        document: ClearChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
      onException: (data) => ClearChatException(
        (ClearChat$Mutation.fromJson(data).clearChat
                as ClearChat$Mutation$ClearChat$ClearChatError)
            .code,
      ),
    );
    return ClearChat$Mutation.fromJson(result.data!).clearChat
        as ChatEventsVersionedMixin?;
  }

  /// Creates a [Chat]-monolog for the authenticated [MyUser].
  ///
  /// There can be only one [Chat]-monolog for the authenticated [MyUser].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Idempotent
  ///
  /// Succeeds as no-op if the [Chat]-monolog for the authenticated [MyUser]
  /// exists already, and returns it.
  Future<ChatMixin> createMonologChat({ChatName? name, bool? isHidden}) async {
    Log.debug('createMonologChat($name)', '$runtimeType');

    final variables = CreateMonologChatArguments(
      name: name,
      isHidden: isHidden,
    );
    final QueryResult result = await client.mutate(
      MutationOptions(
        operationName: 'CreateMonologChat',
        document: CreateMonologChatMutation(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return CreateMonologChat$Mutation.fromJson(result.data!).createMonologChat;
  }

  /// Returns the monolog [Chat] of the authenticated [MyUser].
  ///
  /// If there is no [Chat]-monolog, the one could be created via
  /// [createMonologChat].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  ///
  /// ### Result
  ///
  /// Query returns `null` when no [Chat]-monolog exists for the authenticated
  /// [MyUser].
  Future<ChatMixin?> getMonolog() async {
    Log.debug('getMonolog()', '$runtimeType');

    if (client.token == null) {
      return null;
    }

    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetMonolog',
        document: GetMonologQuery().document,
      ),
    );
    return GetMonolog$Query.fromJson(result.data!).monolog;
  }

  /// Returns the dialog [Chat] of the authenticated [MyUser] with a [User]
  /// identified by the provided [userId].
  Future<ChatMixin?> getDialog(UserId userId) async {
    Log.debug('getDialog($userId)', '$runtimeType');

    if (client.token == null) {
      return null;
    }

    final variables = GetDialogArguments(id: userId);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetDialog',
        document: GetDialogQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetDialog$Query.fromJson(result.data!).user?.dialog;
  }

  /// Fetches the [ChatAvatar]s of a [Chat] identified by the provided [id].
  ///
  /// The authenticated [MyUser] should be a member of the [Chat].
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetAvatar$Query> avatar(ChatId id) async {
    Log.debug('avatar($id)', '$runtimeType');

    final variables = GetAvatarArguments(id: id);
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetAvatar',
        document: GetAvatarQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetAvatar$Query.fromJson(result.data!);
  }

  /// Fetches [ChatMember]s of a [Chat] identified by its [id] ordered by their
  /// joining time.
  ///
  /// ### Sorting
  ///
  /// Returned [ChatMember]s are sorted primarily by their joining [DateTime],
  /// and secondary by their IDs (if the joining [DateTime] is the same), in
  /// ascending order.
  ///
  /// ### Pagination
  ///
  /// It's allowed to specify both [first] and [last] counts at the same time,
  /// provided that [after] and [before] cursors are equal. In such case the
  /// returned page will include the [ChatMember] pointed by the cursor and the
  /// requested count of [ChatMember]s preceding and following it.
  ///
  /// If it's desired to receive the [ChatMember], pointed by the cursor,
  /// without querying in both directions, one can specify [first] or [last]
  /// count as 0.
  ///
  /// ### Authentication
  ///
  /// Mandatory.
  Future<GetMembers$Query> chatMembers(
    ChatId id, {
    int? first,
    ChatMembersCursor? after,
    int? last,
    ChatMembersCursor? before,
  }) async {
    Log.debug(
      'chatMembers($id, $first, $after, $last, $before)',
      '$runtimeType',
    );

    final variables = GetMembersArguments(
      id: id,
      first: first,
      after: after,
      last: last,
      before: before,
    );
    final QueryResult result = await client.query(
      QueryOptions(
        operationName: 'GetMembers',
        document: GetMembersQuery(variables: variables).document,
        variables: variables.toJson(),
      ),
    );
    return GetMembers$Query.fromJson(result.data!);
  }
}
