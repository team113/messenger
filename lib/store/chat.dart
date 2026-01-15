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

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';
import 'package:synchronized/synchronized.dart';

import '/api/backend/extension/call.dart';
import '/api/backend/extension/chat.dart';
import '/api/backend/extension/page_info.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/config.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item_quote_input.dart' as model;
import '/domain/model/chat_item_quote.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_message_input.dart' as model;
import '/domain/model/chat.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/disposable_service.dart';
import '/provider/drift/chat_item.dart';
import '/provider/drift/chat_member.dart';
import '/provider/drift/chat.dart';
import '/provider/drift/draft.dart';
import '/provider/drift/monolog.dart';
import '/provider/drift/slugs.dart';
import '/provider/drift/version.dart';
import '/provider/gql/exceptions.dart'
    show
        AddChatMemberException,
        ClearChatException,
        ConnectionException,
        DeleteChatDirectLinkException,
        DeleteChatForwardException,
        DeleteChatMessageException,
        EditChatMessageException,
        FavoriteChatException,
        ForwardChatItemsException,
        HideChatException,
        HideChatItemException,
        ToggleChatArchivationException,
        RemoveChatMemberException,
        RenameChatException,
        StaleVersionException,
        ToggleChatMuteException,
        UnfavoriteChatException,
        UpdateChatAvatarException,
        UploadAttachmentException,
        CreateChatDirectLinkException,
        CreateDialogException;
import '/provider/gql/graphql.dart';
import '/store/event/recent_chat.dart';
import '/store/model/chat_item.dart';
import '/store/pagination/combined_pagination.dart';
import '/store/pagination/graphql.dart';
import '/store/user.dart';
import '/util/backoff.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'chat_rx.dart';
import 'event/chat.dart';
import 'event/favorite_chat.dart';
import 'model/chat.dart';
import 'model/chat_member.dart';
import 'model/page_info.dart';
import 'paginated.dart';
import 'pagination.dart';
import 'pagination/drift.dart';
import 'pagination/drift_graphql.dart';

typedef ArchivedPaginated =
    RxPaginatedImpl<ChatId, RxChatImpl, DtoChat, RecentChatsCursor>;

/// Implementation of an [AbstractChatRepository].
class ChatRepository extends IdentityDependency
    implements AbstractChatRepository {
  ChatRepository(
    this._graphQlProvider,
    this._chatLocal,
    this._itemsLocal,
    this._membersLocal,
    this._callRepo,
    this._draftLocal,
    this._userRepo,
    this._sessionLocal,
    this._monologLocal,
    this._slugProvider, {
    required super.me,
  });

  /// Callback, called when an [User] identified by the provided [UserId] is
  /// removed from the specified [Chat].
  Future<void> Function(ChatId id, UserId userId)? onMemberRemoved;

  @override
  final Rx<RxStatus> status = Rx(RxStatus.loading());

  @override
  final RxObsMap<ChatId, RxChatImpl> chats = RxObsMap<ChatId, RxChatImpl>();

  @override
  final RxObsMap<ChatId, RxChatImpl> paginated = RxObsMap<ChatId, RxChatImpl>();

  @override
  late final ArchivedPaginated archived = ArchivedPaginated(
    pagination: Pagination(
      onKey: (e) => e.id,
      perPage: 15,
      provider: DriftGraphQlPageProvider(
        alwaysFetch: true,
        driftProvider: DriftPageProvider(
          watch: ({int? after, int? before, ChatId? around}) {
            final int limit = (after ?? 0) + (before ?? 0) + 1;
            return _chatLocal.watchArchive(limit: limit > 1 ? limit : null);
          },
          watchUpdates: (a, b) => a.value.isArchived != b.value.isArchived,
          onAdded: (e) async {
            final ChatVersion? stored = archived.items[e.id]?.ver;

            Log.debug(
              'archived.onAdded -> $e -> stored == null(${stored == null}) || e.ver > stored(${e.ver > stored})',
              '$runtimeType',
            );

            if (stored == null || e.ver > stored) {
              await archived.pagination?.put(
                e,
                ignoreBounds: true,
                store: false,
              );
            }
          },
          onRemoved: (e) async {
            Log.debug('archived.onRemoved -> $e', '$runtimeType');
            await archived.pagination?.remove(e.value.id, store: false);
          },
          onKey: (e) => e.value.id,
          onCursor: (e) => e?.recentCursor,
          add: (e, {bool toView = true}) async {
            if (toView) {
              await _chatLocal.upsertBulk(e);
            }
          },
          delete: (e) async => await _chatLocal.delete(e),
          reset: () async => await _chatLocal.clear(),
          isLast: (_, _) => false,
          isFirst: (_, _) => false,
          fulfilledWhenNone: true,
          compare: (a, b) => a.value.compareTo(b.value),
        ),
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) => _recentChats(
            after: after,
            before: before,
            first: first,
            last: last,
            archived: true,
          ),
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    ),
    transform: ({required DtoChat data, RxChatImpl? previous}) {
      return previous ?? get(data.id);
    },
  );

  @override
  late ChatId monolog = ChatId.local(me);

  @override
  late ChatId support = ChatId.local(_supportId);

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [Chat]s local [DriftProvider] storage.
  final ChatDriftProvider _chatLocal;

  /// [ChatItem]s local storage.
  final ChatItemDriftProvider _itemsLocal;

  /// [ChatMember]s local storage.
  final ChatMemberDriftProvider _membersLocal;

  /// [OngoingCall]s repository, used to put the fetched [ChatCall]s into it.
  final AbstractCallRepository _callRepo;

  /// [RxChat.draft] local storage.
  final DraftDriftProvider _draftLocal;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepo;

  /// [VersionDriftProvider] storing a [FavoriteChatsListVersion].
  final VersionDriftProvider _sessionLocal;

  /// [MonologDriftProvider] storing a [ChatId] of the [Chat]-monolog.
  final MonologDriftProvider _monologLocal;

  /// [SlugDriftProvider] for retrieving affiliate [ChatDirectLinkSlug].
  final SlugDriftProvider _slugProvider;

  /// [CombinedPagination] loading [chats] with pagination.
  CombinedPagination<DtoChat, ChatId>? _pagination;

  /// [CombinedPagination] loading local [chats] with pagination.
  CombinedPagination<DtoChat, ChatId>? _localPagination;

  /// Subscription to the [_pagination] changes.
  StreamSubscription? _paginationSubscription;

  /// [_recentChatsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<RecentChatsEvent>? _remoteSubscription;

  /// [_archiveChatsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<RecentChatsEvent>? _remoteArchiveSubscription;

  /// [DateTime] when the [_remoteSubscription] initializing has started.
  DateTime? _subscribedAt;

  /// [DateTime] when the [_remoteArchiveSubscription] initializing has started.
  DateTime? _archiveSubscribedAt;

  /// [_favoriteChatsEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<FavoriteChatsEvents>? _favoriteChatsSubscription;

  /// Subscriptions for the [paginated] chats changes.
  final Map<ChatId, StreamSubscription> _subscriptions = {};

  /// Subscriptions for the [paginated] chats changes.
  final Map<ChatId, StreamSubscription> _archiveSubscriptions = {};

  /// Subscriptions for the [paginated] changes populating the [_subscriptions].
  StreamSubscription? _paginatedSubscription;

  /// Subscriptions for the [archived] changes populating the [_subscriptions].
  StreamSubscription? _archivedSubscription;

  /// [Mutex]es guarding access to the [get] method.
  final Map<ChatId, Mutex> _getGuards = {};

  /// [Mutex]es guarding synchronized access to the [_putEntry].
  final Map<ChatId, Mutex> _putEntryGuards = {};

  /// [Lock] guarding synchronized access to the [GraphQlProvider.getMonolog].
  final Lock _monologGuard = Lock();

  /// [Lock] guarding synchronized access to the [_initSupport].
  final Lock _supportGuard = Lock();

  /// [ChatFavoritePosition] of the local [Chat]-monolog.
  ///
  /// Used to prevent [Chat]-monolog from being displayed as unfavorited after
  /// adding a local [Chat]-monolog to favorites.
  ChatFavoritePosition? _localMonologFavoritePosition;

  /// Indicator whether this [ChatRepository] should keep pagination up to date.
  bool _hasPagination = false;

  /// [UserId] of the [support] chat.
  static final UserId _supportId = UserId(Config.supportId);

  @override
  RxBool get hasNext =>
      _pagination?.hasNext ?? _localPagination?.hasNext ?? RxBool(false);

  @override
  RxBool get nextLoading =>
      _localPagination?.nextLoading ??
      _pagination?.nextLoading ??
      RxBool(false);

  /// Indicates whether this [ChatRepository] uses a remote pagination.
  @visibleForTesting
  bool get isRemote => _localPagination == null && _pagination != null;

  /// Returns the map of the current [OngoingCall]s.
  ///
  /// Used for [RxChat.inCall] indicator.
  RxObsMap<ChatId, Rx<OngoingCall>> get calls => _callRepo.calls;

  @override
  void init({
    Future<void> Function(ChatId, UserId)? onMemberRemoved,
    bool? pagination,
  }) {
    Log.debug('init(onMemberRemoved) for $me', '$runtimeType');

    this.onMemberRemoved = onMemberRemoved ?? this.onMemberRemoved;

    final bool hasPagination = pagination ?? !WebUtils.isPopup;
    if (hasPagination != _hasPagination) {
      _hasPagination = hasPagination;
      _ensurePagination();
    }
  }

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    chats.forEach((_, v) => v.dispose());
    _subscriptions.forEach((_, v) => v.cancel());
    _pagination?.dispose();
    _localPagination?.dispose();
    _remoteSubscription?.close(immediate: true);
    _remoteArchiveSubscription?.close(immediate: true);
    _favoriteChatsSubscription?.close(immediate: true);
    _paginationSubscription?.cancel();
    _paginatedSubscription?.cancel();
    _archivedSubscription?.cancel();

    super.onClose();
  }

  @override
  void onIdentityChanged(UserId me) {
    super.onIdentityChanged(me);

    Log.debug('onIdentityChanged($me) -> ${me.isLocal}', '$runtimeType');

    paginated.clear();
    archived.clear();

    chats.forEach((_, v) => v.dispose());
    chats.clear();
    _subscriptions.forEach((_, v) => v.cancel());
    _subscriptions.clear();
    _pagination?.dispose();
    _pagination = null;
    _localPagination?.dispose();
    _localPagination = null;
    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = null;
    _remoteArchiveSubscription?.close(immediate: true);
    _remoteArchiveSubscription = null;
    _favoriteChatsSubscription?.close(immediate: true);
    _favoriteChatsSubscription = null;
    _paginationSubscription?.cancel();
    _paginationSubscription = null;

    status.value = RxStatus.loading();

    Log.debug('onIdentityChanged() -> status is `loading`', '$runtimeType');

    // Set the initial values to local ones, however those will be redefined
    // during `_ensurePagination()` method, which invokes `_initSupport()` and
    // `_initMonolog()`.
    monolog = ChatId.local(me);
    support = ChatId.local(_supportId);

    if (!me.isLocal) {
      _monologGuard.synchronized(() async {
        if (isClosed) {
          return;
        }

        monolog = (await _graphQlProvider.getMonolog())?.id ?? ChatId.local(me);

        if (isClosed) {
          return;
        }

        support =
            (await _graphQlProvider.getDialog(UserId(Config.supportId)))?.id ??
            ChatId.local(_supportId);
      }, timeout: const Duration(minutes: 1));
    }

    // Popup shouldn't listen to recent chats remote updates, as it's happening
    // inside single [Chat].
    if (!WebUtils.isPopup && _remoteSubscription == null && !me.isLocal) {
      _initRemoteSubscription();
      _initFavoriteSubscription();
      _initArchiveSubscription();
    }

    _ensurePagination();
  }

  @override
  Future<void> next() async {
    Log.debug('next()', '$runtimeType');

    if (_localPagination?.hasNext.value == true) {
      await _localPagination?.next();
    } else {
      await _pagination?.next();
    }

    _initMonolog();
    _initSupport();
  }

  @override
  Future<void> clear() {
    Log.debug('clear()', '$runtimeType');

    for (var c in chats.entries) {
      c.value.dispose();
    }

    chats.clear();
    paginated.clear();

    return _chatLocal.clear();
  }

  @override
  FutureOr<RxChatImpl?> get(ChatId id) {
    Log.debug('get($id)', '$runtimeType');

    if (id.isLocalWith(me)) {
      id = monolog;
    }

    RxChatImpl? chat = chats[id];
    if (chat != null) {
      return chat;
    }

    // If [chat] doesn't exists, we should lock the [mutex] to avoid remote
    // double invoking.
    Mutex? mutex = _getGuards[id];
    if (mutex == null) {
      mutex = Mutex();
      _getGuards[id] = mutex;
    }

    return mutex.protect(() async {
      chat = chats[id];
      if (chat == null) {
        final DtoChat? dto = await _chatLocal.read(id);
        if (dto != null) {
          chat = RxChatImpl(
            this,
            _chatLocal,
            _draftLocal,
            _itemsLocal,
            _membersLocal,
            dto,
          );
          chat!.init();
        }

        if (id.isLocal) {
          chat ??= await _createLocalDialog(id.userId);
        } else if (chat == null) {
          var query = (await _graphQlProvider.getChat(id)).chat;
          if (query != null) {
            chat = await _putEntry(_chat(query));
          }
        }

        if (chat != null) {
          chats[id] = chat!;
        }
      }

      return chat;
    });
  }

  @override
  FutureOr<ChatItem?> getItem(ChatItemId id) {
    Log.debug('getItem($id)', '$runtimeType');

    final FutureOr<DtoChatItem?> dtoOrFuture = _itemsLocal.read(id);
    if (dtoOrFuture is DtoChatItem) {
      return dtoOrFuture.value;
    }

    return Future(() async => (await dtoOrFuture ?? await message(id))?.value);
  }

  @override
  Future<void> remove(ChatId id, {bool force = false}) async {
    Log.debug('remove($id)', '$runtimeType');

    archived.remove(id);
    paginated.remove(id)?.dispose();
    chats.remove(id)?.dispose();
    _pagination?.remove(id);
    await _chatLocal.delete(id);
  }

  /// Ensures the provided [Chat] is remotely accessible.
  Future<RxChatImpl?> ensureRemoteDialog(ChatId chatId) async {
    Log.debug('ensureRemoteDialog($chatId)', '$runtimeType');

    if (chatId.isLocal) {
      if (chatId.isLocalWith(me)) {
        return await ensureRemoteMonolog();
      }

      try {
        final ChatData chat = _chat(
          await _graphQlProvider.createDialogChat(chatId.userId),
        );

        if (chat.chat.value.isSupport) {
          _monologLocal.upsert(MonologKind.support, support = chat.chat.id);
        }

        return _putEntry(chat);
      } on CreateDialogException catch (e) {
        switch (e.code) {
          case CreateDialogChatErrorCode.artemisUnknown:
          case CreateDialogChatErrorCode.blocked:
            rethrow;

          case CreateDialogChatErrorCode.unknownUser:
            return null;

          case CreateDialogChatErrorCode.useMonolog:
            // No-op, should be retrieved via [get] below.
            break;
        }
      }
    }

    return await get(chatId);
  }

  /// Ensures the provided [Chat]-monolog is remotely accessible.
  Future<RxChatImpl> ensureRemoteMonolog({
    ChatName? name,
    bool? isHidden,
  }) async {
    Log.debug('ensureRemoteMonolog($name)', '$runtimeType');

    final ChatData chatData = _chat(
      await Backoff.run(
        () async {
          return await _graphQlProvider.createMonologChat(name: name);
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      ),
    );
    final RxChatImpl chat = await _putEntry(chatData);

    if (!isClosed) {
      await _monologLocal.upsert(MonologKind.notes, monolog = chat.id);
    }

    return chat;
  }

  @override
  Future<RxChatImpl> createGroupChat(
    List<UserId> memberIds, {
    ChatName? name,
  }) async {
    Log.debug('createGroupChat($memberIds, $name)', '$runtimeType');

    final ChatData chat = _chat(
      await _graphQlProvider.createGroupChat(memberIds, name: name),
    );

    return _putEntry(chat);
  }

  @override
  Future<void> sendChatMessage(
    ChatId chatId, {
    ChatMessageText? text,
    List<Attachment>? attachments,
    List<ChatItem> repliesTo = const [],
  }) async {
    Log.debug(
      'sendChatMessage($chatId, $text, $attachments, $repliesTo)',
      '$runtimeType',
    );

    RxChatImpl? rxChat = chats[chatId] ?? await get(chatId);
    ChatItem? local;

    if (chatId.isLocal) {
      local = await rxChat?.postChatMessage(
        existingDateTime: PreciseDateTime.now().add(10.seconds),
        text: text,
        attachments: attachments,
        repliesTo: repliesTo,
      );

      try {
        rxChat = await ensureRemoteDialog(chatId);
      } catch (_) {
        local?.status.value = SendingStatus.error;
      }
    }

    await rxChat?.postChatMessage(
      existingId: local?.id,
      existingDateTime: local?.at,
      text: text,
      attachments: attachments,
      repliesTo: repliesTo,
    );
  }

  /// Posts a new [ChatMessage] to the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// For the posted [ChatMessage] to be meaningful, at least one of [text] or
  /// [attachments] arguments must be specified and non-empty.
  ///
  /// To attach some [Attachment]s to the posted [ChatMessage], first, they
  /// should be uploaded with [uploadAttachment], and only then, the returned
  /// [Attachment.id]s may be used as the [attachments] argument of this method.
  ///
  /// Specify [repliesTo] argument if the posted [ChatMessage] is going to be a
  /// reply to some other [ChatItem].
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

    return await _graphQlProvider.postChatMessage(
      chatId,
      text: text,
      attachments: attachments,
      repliesTo: repliesTo,
    );
  }

  @override
  Future<void> resendChatItem(ChatItem item) async {
    Log.debug('resendChatItem($item)', '$runtimeType');

    RxChatImpl? rxChat = chats[item.chatId];

    // TODO: Account [ChatForward]s.
    if (item is ChatMessage) {
      for (var e in item.attachments.whereType<LocalAttachment>()) {
        if (e.status.value == SendingStatus.error &&
            (e.upload.value == null || e.upload.value?.isCompleted == true)) {
          uploadAttachment(e)
              .onError<UploadAttachmentException>((_, _) => e)
              .onError<ConnectionException>((_, _) => e);
        }
      }

      // If this [item] is posted in a local [Chat], then make it remote first.
      if (item.chatId.isLocal) {
        rxChat = await ensureRemoteDialog(item.chatId);
      }

      await rxChat?.postChatMessage(
        existingId: item.id,
        existingDateTime: item.at,
        text: item.text?.nullIfEmpty,
        attachments: item.attachments,
        repliesTo: item.repliesTo.map((e) => e.original).nonNulls.toList(),
      );
    }
  }

  @override
  Future<void> renameChat(ChatId id, ChatName? name) async {
    Log.debug('renameChat($id, $name)', '$runtimeType');

    if (id.isLocalWith(me)) {
      await ensureRemoteMonolog(name: name);
      return;
    }

    final RxChatImpl? chat = chats[id];
    final ChatName? previous = chat?.chat.value.name;

    chat?.chat.update((c) => c?.name = name);

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.renameChat(id, name);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on RenameChatException catch (e) {
        switch (e.code) {
          case RenameChatErrorCode.unknownChat:
            await remove(id);
            break;

          case RenameChatErrorCode.artemisUnknown:
            rethrow;

          case RenameChatErrorCode.dialog:
            chat?.chat.update((c) => c?.name = previous);
            break;
        }
      }
    } catch (_) {
      chat?.chat.update((c) => c?.name = previous);
      rethrow;
    }
  }

  @override
  Future<void> addChatMember(ChatId chatId, UserId userId) async {
    Log.debug('addChatMember($chatId, $userId)', '$runtimeType');

    final RxChatImpl? chat = chats[chatId];
    final FutureOr<RxUser?> userOrFuture = _userRepo.get(userId);
    final RxUser? user = userOrFuture is RxUser?
        ? userOrFuture
        : await userOrFuture;

    if (user != null) {
      final member = DtoChatMember(
        user.user.value,
        PreciseDateTime.now(),
        null,
      );

      chat?.members.put(member);
    }

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.addChatMember(chatId, userId);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on AddChatMemberException catch (e) {
        switch (e.code) {
          case AddChatMemberErrorCode.artemisUnknown:
          case AddChatMemberErrorCode.blocked:
            rethrow;

          case AddChatMemberErrorCode.unknownUser:
          case AddChatMemberErrorCode.notGroup:
            if (user != null) {
              chat?.members.remove(user.id);
            }

          case AddChatMemberErrorCode.unknownChat:
            await remove(chatId);
            break;
        }
      }
    } catch (_) {
      if (user != null) {
        chat?.members.remove(user.id);
      }

      rethrow;
    }

    // Redial the added member, if [Chat] has an [OngoingCall] happening in it.
    if (chats[chatId]?.chat.value.ongoingCall != null) {
      await _callRepo.redialChatCallMember(chatId, userId);
    }
  }

  @override
  Future<void> removeChatMember(ChatId chatId, UserId userId) async {
    Log.debug('removeChatMember($chatId, $userId)', '$runtimeType');

    final RxChatImpl? chat = chats[chatId];
    final DtoChatMember? member = chat?.members.pagination?.items[userId];

    if (chat?.chat.value.isGroup == false) {
      // No-op.
      return;
    }

    chat?.members.remove(userId);

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.removeChatMember(chatId, userId);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on RemoveChatMemberException catch (e) {
        switch (e.code) {
          case RemoveChatMemberErrorCode.artemisUnknown:
            rethrow;

          case RemoveChatMemberErrorCode.notGroup:
            if (member != null) {
              chat?.members.put(member);
            }
            break;

          case RemoveChatMemberErrorCode.unknownChat:
            await remove(chatId);
            break;
        }
      }
    } catch (_) {
      if (member != null) {
        chat?.members.put(member);
      }

      rethrow;
    }

    await onMemberRemoved?.call(chatId, userId);
  }

  @override
  Future<void> hideChat(ChatId id) async {
    Log.debug('hideChat($id)', '$runtimeType');

    RxChatImpl? chat = chats[id];
    ChatData? monologData;

    chat?.chat.update((c) => c?.isHidden = true);

    try {
      // If this [Chat] is local monolog, make it remote first.
      if (id.isLocalWith(me)) {
        monologData = _chat(
          await _graphQlProvider.createMonologChat(isHidden: true),
        );

        // Dispose and delete local monolog, since it's just been replaced with
        // a remote one.
        await remove(id);

        id = monologData.chat.value.id;
        await _monologLocal.upsert(MonologKind.notes, monolog = id);
      }

      if (chat == null || chat.chat.value.favoritePosition != null) {
        await unfavoriteChat(id);
      }

      // [Chat.isHidden] will be changed by [RxChatImpl]'s own remote event
      // handler. Chat will be removed from [paginated] via [RxChatImpl].
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.hideChat(id);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on HideChatException catch (e) {
        switch (e.code) {
          case HideChatErrorCode.artemisUnknown:
            rethrow;

          case HideChatErrorCode.unknownChat:
            // No-op.
            break;
        }
      }
    } catch (_) {
      chat?.chat.update((c) => c?.isHidden = false);

      rethrow;
    }
  }

  @override
  Future<void> archiveChat(ChatId id, bool archive) async {
    Log.debug('archiveChat($id, $archive)', '$runtimeType');

    RxChatImpl? chat = chats[id];
    ChatData? monologData;

    // [Chat.isArchived] will be changed by [RxChatImpl]'s own remote event
    // handler. Chat will be moved from [paginated] to [archived]
    // via [RxChatImpl].
    chat?.chat.update((c) => c?.isArchived = archive);

    try {
      // If this [Chat] is local monolog, make it remote first.
      if (id.isLocalWith(me)) {
        monologData = _chat(
          await _graphQlProvider.createMonologChat(isHidden: true),
        );

        // Dispose and delete local monolog, since it's just been replaced with
        // a remote one.
        await remove(id);

        id = monologData.chat.value.id;
        await _monologLocal.upsert(MonologKind.notes, monolog = id);
      }

      if (archive && chat?.chat.value.favoritePosition != null) {
        await unfavoriteChat(id);
      }

      // [Chat.isArchived] will be changed by [RxChatImpl]'s own remote event
      // handler. Chat will be moved from [paginated] to [archived]
      // via [RxChatImpl].
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.toggleChatArchivation(id, archive);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on ToggleChatArchivationException catch (e) {
        switch (e.code) {
          case ToggleChatArchivationErrorCode.artemisUnknown:
            rethrow;

          case ToggleChatArchivationErrorCode.unknownChat:
            // No-op.
            break;
        }
      }
    } catch (_) {
      chat?.chat.update((c) => c?.isArchived = !archive);

      rethrow;
    }
  }

  @override
  Future<void> readChat(ChatId chatId, ChatItemId untilId) async {
    Log.debug('readChat($chatId, $untilId)', '$runtimeType');
    await chats[chatId]?.read(untilId);
  }

  @override
  Future<void> readAll(List<ChatId>? ids) async {
    Log.debug('readAll($ids)', '$runtimeType');

    final List<Future> futures = [];

    for (var e in chats.values) {
      if (ids?.contains(e.id) == false) {
        continue;
      }

      final ChatItem? last = e.lastItem ?? e.chat.value.lastItem;
      final int unread = e.unreadCount.value;

      if (unread != 0 && last != null) {
        futures.add(e.read(last.id));
      }
    }

    await Future.wait(futures);
  }

  /// Marks the specified [Chat] as read until the provided [ChatItemId] for the
  /// authenticated [MyUser].
  Future<void> readUntil(ChatId chatId, ChatItemId untilId) async {
    Log.debug('readUntil($chatId, $untilId)', '$runtimeType');

    await Backoff.run(
      () async {
        await _graphQlProvider.readChat(chatId, untilId);
      },
      retryIf: (e) => e.isNetworkRelated,
      retries: 10,
    );
  }

  @override
  Future<void> editChatMessage(
    ChatMessage message, {
    model.ChatMessageTextInput? text,
    model.ChatMessageAttachmentsInput? attachments,
    model.ChatMessageRepliesInput? repliesTo,
  }) async {
    Log.debug(
      'editChatMessage($message, text: ${text?.changed}, attachments: ${attachments?.changed}, repliesTo: ${repliesTo?.changed})',
      '$runtimeType',
    );

    final Rx<ChatItem>? item = chats[message.chatId]?.messages.firstWhereOrNull(
      (e) => e.value.id == message.id,
    );

    ChatMessageText? previousText;
    List<Attachment>? previousAttachments;
    List<ChatItemQuote>? previousReplies;

    if (item?.value is ChatMessage) {
      previousText = (item?.value as ChatMessage).text;
      previousAttachments = (item?.value as ChatMessage).attachments;
      previousReplies = (item?.value as ChatMessage).repliesTo;

      item?.update((c) {
        c as ChatMessage;

        c.text = text != null ? text.changed : previousText;
        c.attachments = attachments?.changed ?? previousAttachments!;
        c.repliesTo =
            repliesTo?.changed
                .map(
                  (e) =>
                      c.repliesTo.firstWhereOrNull((a) => a.original?.id == e),
                )
                .nonNulls
                .toList() ??
            previousReplies!;
      });
    }

    // Don't upload the [Attachment]s and don't proceed with `editChatMessage`
    // if the message's status is [SendingStatus.error].
    if (message.status.value == SendingStatus.error) {
      return;
    }

    final List<Future>? uploads = attachments?.changed
        .map((e) {
          if (e is LocalAttachment) {
            return e.upload.value?.future.then(
              (a) {
                final index = attachments.changed.indexOf(e);

                // If `Attachment` returned is `null`, then it was canceled.
                if (a == null) {
                  attachments.changed.removeAt(index);
                } else {
                  attachments.changed[index] = a;
                }

                item?.update((_) {});
              },
              onError: (_) {
                // No-op, as failed upload attempts are handled below.
              },
            );
          }
        })
        .nonNulls
        .toList();

    await Future.wait(uploads ?? []);

    try {
      if (attachments?.changed.whereType<LocalAttachment>().isNotEmpty ==
          true) {
        throw const ConnectionException(
          EditChatMessageException(EditChatMessageErrorCode.unknownAttachment),
        );
      }

      final bool hasText =
          (text?.changed ?? message.text)?.val.isNotEmpty == true;
      final bool hasAttachments =
          (attachments?.changed ?? message.attachments).isNotEmpty;
      final bool hasReplies =
          (repliesTo?.changed ?? message.repliesTo).isNotEmpty;

      // If after editing the message contains no content, then delete it.
      if (!hasText && !hasAttachments && !hasReplies) {
        return await deleteChatMessage(message);
      }

      await Backoff.run(
        () async {
          await _graphQlProvider.editChatMessage(
            message.id,
            text: text == null
                ? null
                : ChatMessageTextInput(kw$new: text.changed?.nullIfEmpty),
            attachments: attachments == null
                ? null
                : ChatMessageAttachmentsInput(
                    kw$new: attachments.changed.map((e) => e.id).toList(),
                  ),
            repliesTo: repliesTo == null
                ? null
                : ChatMessageRepliesInput(kw$new: repliesTo.changed),
          );
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      );
    } on EditChatMessageException catch (e) {
      switch (e.code) {
        case EditChatMessageErrorCode.uneditable:
        case EditChatMessageErrorCode.blocked:
        case EditChatMessageErrorCode.unknownAttachment:
        case EditChatMessageErrorCode.artemisUnknown:
        case EditChatMessageErrorCode.wrongAttachmentsCount:
        case EditChatMessageErrorCode.unknownReplyingChatItem:
        case EditChatMessageErrorCode.wrongReplyingChatItemsCount:
          rethrow;

        case EditChatMessageErrorCode.unknownChatItem:
          chats[message.chatId]?.remove(message.id);
          break;

        case EditChatMessageErrorCode.notAuthor:
        case EditChatMessageErrorCode.noContent:
          // No-op.
          break;
      }
    } catch (_) {
      if (item?.value is ChatMessage) {
        item?.update((c) {
          (c as ChatMessage).text = previousText;
          c.attachments = previousAttachments ?? [];
          c.repliesTo = previousReplies ?? [];
        });
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteChatMessage(ChatMessage message) async {
    Log.debug('deleteChatMessage($message)', '$runtimeType');

    final RxChatImpl? chat = chats[message.chatId];

    if (message.status.value != SendingStatus.sent) {
      chat?.remove(message.id);
    } else {
      final Rx<ChatItem>? item = chat?.messages.firstWhereOrNull(
        (e) => e.value.id == message.id,
      );
      if (item != null) {
        chat?.messages.remove(item);
      }

      try {
        try {
          if (!message.id.isLocal) {
            await Backoff.run(
              () async {
                await _graphQlProvider.deleteChatMessage(message.id);
              },
              retryIf: (e) => e.isNetworkRelated,
              retries: 10,
            );
          }
        } on DeleteChatMessageException catch (e) {
          switch (e.code) {
            case DeleteChatMessageErrorCode.notAuthor:
            case DeleteChatMessageErrorCode.quoted:
            case DeleteChatMessageErrorCode.uneditable:
              rethrow;

            case DeleteChatMessageErrorCode.unknownChatItem:
              // No-op.
              break;

            case DeleteChatMessageErrorCode.artemisUnknown:
              rethrow;
          }
        }

        if (item != null) {
          chat?.remove(item.value.id);
        }
      } catch (_) {
        if (item != null) {
          chat?.messages.insertAfter(
            item,
            (e) => item.value.at.compareTo(e.value.at) == 1,
          );
          chat?.updateReads();
        }

        rethrow;
      }
    }
  }

  @override
  Future<void> deleteChatForward(ChatForward forward) async {
    Log.debug('deleteChatForward($forward)', '$runtimeType');

    final RxChatImpl? chat = chats[forward.chatId];

    if (forward.status.value != SendingStatus.sent) {
      chat?.remove(forward.id);
    } else {
      final Rx<ChatItem>? item = chat?.messages.firstWhereOrNull(
        (e) => e.value.id == forward.id,
      );
      if (item != null) {
        chat?.messages.remove(item);
      }

      try {
        try {
          if (!forward.id.isLocal) {
            await Backoff.run(
              () async {
                await _graphQlProvider.deleteChatForward(forward.id);
              },
              retryIf: (e) => e.isNetworkRelated,
              retries: 10,
            );
          }
        } on DeleteChatForwardException catch (e) {
          switch (e.code) {
            case DeleteChatForwardErrorCode.artemisUnknown:
            case DeleteChatForwardErrorCode.notAuthor:
            case DeleteChatForwardErrorCode.quoted:
            case DeleteChatForwardErrorCode.uneditable:
              rethrow;

            case DeleteChatForwardErrorCode.unknownChatItem:
              // No-op.
              break;
          }
        }

        if (item != null) {
          chat?.remove(item.value.id);
        }
      } catch (_) {
        if (item != null) {
          chat?.messages.insertAfter(
            item,
            (e) => item.value.at.compareTo(e.value.at) == 1,
          );
          chat?.updateReads();
        }

        rethrow;
      }
    }
  }

  @override
  Future<void> hideChatItem(ChatId chatId, ChatItemId id) async {
    Log.debug('hideChatItem($chatId, $id)', '$runtimeType');

    final RxChatImpl? chat = chats[chatId];

    final Rx<ChatItem>? item = chat?.messages.firstWhereOrNull(
      (e) => e.value.id == id,
    );
    if (item != null) {
      chat?.messages.remove(item);
    }

    try {
      try {
        if (!id.isLocal) {
          await Backoff.run(
            () async {
              await _graphQlProvider.hideChatItem(id);
            },
            retryIf: (e) => e.isNetworkRelated,
            retries: 10,
          );
        }
      } on HideChatItemException catch (e) {
        switch (e.code) {
          case HideChatItemErrorCode.unknownChatItem:
            // No-op.
            break;

          case HideChatItemErrorCode.artemisUnknown:
            rethrow;
        }
      }

      if (item != null) {
        chat?.remove(item.value.id);
      }
    } catch (_) {
      if (item != null) {
        chat?.messages.insertAfter(
          item,
          (e) => item.value.at.compareTo(e.value.at) == 1,
        );
        chat?.updateReads();
      }

      rethrow;
    }
  }

  @override
  Future<Attachment?> uploadAttachment(LocalAttachment attachment) async {
    Log.debug('uploadAttachment($attachment)', '$runtimeType');

    if (attachment.upload.value?.isCompleted != false) {
      attachment.upload.value = Completer();
    }

    if (attachment.read.value?.isCompleted != false) {
      attachment.read.value = Completer();
    }

    attachment.status.value = SendingStatus.sending;
    await attachment.file.ensureCorrectMediaType();

    try {
      await attachment.file.readFile();
      attachment.read.value?.complete(null);
      attachment.status.refresh();

      var response = await _graphQlProvider.uploadAttachment(
        await attachment.file.toMultipartFile(),
        onSendProgress: (now, max) => attachment.progress.value = now / max,
        cancelToken: attachment.cancelToken,
      );

      var model = response.attachment.toModel();
      attachment.id = model.id;
      attachment.filename = model.filename;
      attachment.original = model.original;
      attachment.upload.value?.complete(model);
      attachment.status.value = SendingStatus.sent;
      attachment.progress.value = 1;
      return model;
    } on dio.DioException {
      if (attachment.isCanceled) {
        attachment.upload.value?.complete(null);
        return null;
      }

      rethrow;
    } catch (e) {
      if (attachment.read.value?.isCompleted == false) {
        attachment.read.value?.complete(null);
      }
      attachment.upload.value?.completeError(e);
      attachment.status.value = SendingStatus.error;
      attachment.progress.value = 0;
      rethrow;
    }
  }

  @override
  Future<void> createChatDirectLink(
    ChatId chatId,
    ChatDirectLinkSlug slug,
  ) async {
    Log.debug('createChatDirectLink($chatId, $slug)', '$runtimeType');

    try {
      // Don't do optimism, as [slug] might be occupied, thus shouldn't set the
      // link right away.
      await Backoff.run(
        () async {
          await _graphQlProvider.createChatDirectLink(slug, groupId: chatId);
        },
        retryIf: (e) => e.isNetworkRelated,
        retries: 10,
      );
    } on CreateChatDirectLinkException catch (e) {
      switch (e.code) {
        case CreateChatDirectLinkErrorCode.artemisUnknown:
        case CreateChatDirectLinkErrorCode.occupied:
          rethrow;

        case CreateChatDirectLinkErrorCode.notGroup:
          // No-op.
          return;

        case CreateChatDirectLinkErrorCode.unknownChat:
          await remove(chatId);
          return;
      }
    }

    final RxChatImpl? chat = chats[chatId];
    chat?.chat.update(
      (c) => c?.directLink = ChatDirectLink(
        slug: slug,
        createdAt: PreciseDateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteChatDirectLink(ChatId groupId) async {
    Log.debug('deleteChatDirectLink($groupId)', '$runtimeType');

    final RxChatImpl? chat = chats[groupId];
    final ChatDirectLink? link = chat?.chat.value.directLink;

    chat?.chat.update((c) => c?.directLink = null);

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.deleteChatDirectLink(groupId: groupId);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on DeleteChatDirectLinkException catch (e) {
        switch (e.code) {
          case DeleteChatDirectLinkErrorCode.artemisUnknown:
            rethrow;

          case DeleteChatDirectLinkErrorCode.notGroup:
            // No-op.
            break;

          case DeleteChatDirectLinkErrorCode.unknownChat:
            await remove(groupId);
            break;
        }
      }
    } catch (_) {
      chat?.chat.update((c) => c?.directLink = link);
      rethrow;
    }
  }

  // TODO: Make [ChatForward]s to post like [ChatMessage]s.
  @override
  Future<void> forwardChatItems(
    ChatId from,
    ChatId to,
    List<model.ChatItemQuoteInput> items, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
  }) async {
    Log.debug(
      'forwardChatItems($from, $to, $items, $text, $attachments)',
      '$runtimeType',
    );

    if (to.isLocal) {
      to = (await ensureRemoteDialog(to))!.id;
    }

    try {
      // TODO: Implement posting local [ChatForward]s with sending status:
      //       https://github.com/team113/messenger/issues/1347
      await _graphQlProvider.forwardChatItems(
        from,
        to,
        items
            .map(
              (i) => ChatItemQuoteInput(
                id: i.item.id,
                attachments: i.attachments,
                withText: i.withText,
              ),
            )
            .toList(),
        text: text,
        attachments: attachments,
      );
    } on ForwardChatItemsException catch (e) {
      switch (e.code) {
        case ForwardChatItemsErrorCode.blocked:
        case ForwardChatItemsErrorCode.noQuotedContent:
        case ForwardChatItemsErrorCode.unknownForwardedDonation:
        case ForwardChatItemsErrorCode.notEnoughFunds:
        case ForwardChatItemsErrorCode.unallowedDonation:
        case ForwardChatItemsErrorCode.unknownUser:
        case ForwardChatItemsErrorCode.unknownForwardedAttachment:
        case ForwardChatItemsErrorCode.wrongItemsCount:
        case ForwardChatItemsErrorCode.unsupportedForwardedItem:
        case ForwardChatItemsErrorCode.unknownForwardedItem:
        case ForwardChatItemsErrorCode.unknownAttachment:
        case ForwardChatItemsErrorCode.artemisUnknown:
          rethrow;

        case ForwardChatItemsErrorCode.unknownChat:
          // No-op, as either `from` or `to` chat doesn't exist - which one is
          // unknown.
          break;
      }
    }
  }

  @override
  Future<void> updateChatAvatar(
    ChatId id, {
    NativeFile? file,
    CropAreaInput? crop,
    void Function(int count, int total)? onSendProgress,
  }) async {
    Log.debug(
      'updateChatAvatar($id, $file, crop: $crop, onSendProgress)',
      '$runtimeType',
    );

    late dio.MultipartFile upload;

    if (file != null) {
      await file.ensureCorrectMediaType();

      upload = await file.toMultipartFile();
    }

    final RxChatImpl? chat = chats[id];
    final ChatAvatar? avatar = chat?.chat.value.avatar;

    if (file == null) {
      chat?.chat.update((c) => c?.avatar = null);
    }

    if (id.isLocalWith(me)) {
      id = (await ensureRemoteMonolog()).id;
    }

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.updateChatAvatar(
              id,
              file: file == null ? null : upload,
              crop: crop,
              onSendProgress: onSendProgress,
            );
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on UpdateChatAvatarException catch (e) {
        switch (e.code) {
          case UpdateChatAvatarErrorCode.unknownChat:
            await remove(id);
            break;

          case UpdateChatAvatarErrorCode.invalidCropCoordinates:
          case UpdateChatAvatarErrorCode.invalidCropPoints:
          case UpdateChatAvatarErrorCode.malformed:
          case UpdateChatAvatarErrorCode.unsupportedFormat:
          case UpdateChatAvatarErrorCode.invalidSize:
          case UpdateChatAvatarErrorCode.invalidDimensions:
          case UpdateChatAvatarErrorCode.artemisUnknown:
          case UpdateChatAvatarErrorCode.dialog:
            rethrow;
        }
      }
    } catch (e) {
      if (file == null) {
        chat?.chat.update((c) => c?.avatar = avatar);
      }
      rethrow;
    }
  }

  @override
  Future<void> toggleChatMute(ChatId id, MuteDuration? mute) async {
    Log.debug('toggleChatMute($id, $mute)', '$runtimeType');

    final RxChatImpl? chat = chats[id];
    final MuteDuration? muted = chat?.chat.value.muted;

    final Muting? muting = mute == null
        ? null
        : Muting(duration: mute.forever == true ? null : mute.until);

    chat?.chat.update((c) => c?.muted = muting?.toModel());

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.toggleChatMute(id, muting);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on ToggleChatMuteException catch (e) {
        switch (e.code) {
          case ToggleChatMuteErrorCode.tooShort:
          case ToggleChatMuteErrorCode.artemisUnknown:
            rethrow;

          case ToggleChatMuteErrorCode.unknownChat:
            await remove(id);
            break;

          case ToggleChatMuteErrorCode.monolog:
            // No-op.
            break;
        }
      }
    } catch (e) {
      chat?.chat.update((c) => c?.muted = muted);
      rethrow;
    }
  }

  /// Fetches [ChatItem]s of the [Chat] with the provided [id] ordered by their
  /// posting time with pagination.
  Future<Page<DtoChatItem, ChatItemsCursor>> messages(
    ChatId id, {
    int? first,
    ChatItemsCursor? after,
    int? last,
    ChatItemsCursor? before,
    bool onlyAttachments = false,
    ChatMessageText? withText,
  }) async {
    Log.debug(
      'messages($id, $first, $after, $last, $before, onlyAttachments: $onlyAttachments)',
      '$runtimeType',
    );

    final query = await _graphQlProvider.chatItems(
      id,
      first: first,
      after: after,
      last: last,
      before: before,
      filter: onlyAttachments || withText != null
          ? ChatItemsFilter(
              onlyAttachments: onlyAttachments,
              withText: withText,
            )
          : null,
    );

    return Page(
      RxList(query.chat!.items.edges.map((e) => e.toDto()).toList()),
      query.chat!.items.pageInfo.toModel((c) => ChatItemsCursor(c)),
    );
  }

  /// Fetches [ChatMember]s of the [Chat] with the provided [id] ordered by
  /// their joining time with pagination.
  Future<Page<DtoChatMember, ChatMembersCursor>> members(
    ChatId id, {
    int? first,
    ChatMembersCursor? after,
    int? last,
    ChatMembersCursor? before,
  }) async {
    Log.debug('members($id, $first, $after, $last, $before)', '$runtimeType');

    final query = await _graphQlProvider.chatMembers(
      id,
      first: first,
      after: after,
      last: last,
      before: before,
    );

    for (var e in query.chat!.members.edges) {
      _userRepo.put(e.node.user.toDto());
    }

    return Page(
      RxList(
        query.chat!.members.edges.map((e) => e.node.toDto(e.cursor)).toList(),
      ),
      query.chat!.members.pageInfo.toModel((c) => ChatMembersCursor(c)),
    );
  }

  /// Fetches the [DtoChatItem] with the provided [id].
  Future<DtoChatItem?> message(ChatItemId id) async {
    Log.debug('message($id)', '$runtimeType');
    return (await _graphQlProvider.chatItem(id)).chatItem?.toDto();
  }

  /// Fetches the [Attachment]s of a [ChatItem] with the provided [id].
  Future<List<Attachment>> attachments(ChatItemId id) async {
    Log.debug('attachments($id)', '$runtimeType');

    final response = await _graphQlProvider.attachments(id);
    return response.chatItem?.toModel() ?? [];
  }

  /// Fetches the [ChatAvatar]s of the provided [RxChat].
  Future<ChatAvatar?> avatar(ChatId id) async {
    Log.debug('avatar($id)', '$runtimeType');

    final response = await _graphQlProvider.avatar(id);
    return response.chat?.avatar?.toModel();
  }

  /// Removes the [ChatCallCredentials] of an [OngoingCall] identified by the
  /// provided [id].
  Future<void> removeCredentials(ChatId chatId, ChatItemId callId) {
    Log.debug('removeCredentials($callId)', '$runtimeType');
    return _callRepo.removeCredentials(chatId, callId);
  }

  /// Adds the provided [ChatCall] to the [AbstractCallRepository].
  void addCall(ChatCall call, {bool dontAddIfAccounted = false}) {
    Log.debug('addCall($call, $dontAddIfAccounted)', '$runtimeType');
    _callRepo.add(call, dontAddIfAccounted: dontAddIfAccounted);
  }

  /// Ends an [OngoingCall] happening in the [Chat] identified by the provided
  /// [chatId], if any.
  void endCall(ChatId chatId) {
    Log.debug('endCall($chatId)', '$runtimeType');
    _callRepo.remove(chatId);
  }

  /// Subscribes to [ChatEvent]s of the specified [Chat].
  Stream<ChatEvents> chatEvents(
    ChatId chatId,
    ChatVersion? ver,
    FutureOr<ChatVersion?> Function() onVer, {
    int priority = -10,
  }) {
    Log.debug('chatEvents($chatId)', '$runtimeType');

    return _graphQlProvider
        .chatEvents(chatId, ver, onVer, priority: priority)
        .asyncExpand((event) async* {
          Log.trace('chatEvents($chatId): ${event.data}', '$runtimeType');

          var events = ChatEvents$Subscription.fromJson(event.data!).chatEvents;
          if (events.$$typename == 'SubscriptionInitialized') {
            events
                as ChatEvents$Subscription$ChatEvents$SubscriptionInitialized;
            yield const ChatEventsInitialized();
          } else if (events.$$typename == 'Chat') {
            final chat = events as ChatEvents$Subscription$ChatEvents$Chat;
            final data = _chat(chat);
            yield ChatEventsChat(data.chat);
          } else if (events.$$typename == 'ChatEventsVersioned') {
            var mixin =
                events
                    as ChatEvents$Subscription$ChatEvents$ChatEventsVersioned;
            yield ChatEventsEvent(
              ChatEventsVersioned(
                mixin.events.map(chatEvent).toList(),
                mixin.ver,
              ),
            );
          }
        });
  }

  @override
  Stream<dynamic> keepTyping(ChatId chatId) {
    Log.debug('keepTyping($chatId)', '$runtimeType');

    if (chatId.isLocal) {
      return const Stream.empty();
    }

    return _graphQlProvider.keepTyping(chatId);
  }

  /// Returns an [User] by the provided [id].
  FutureOr<RxUser?> getUser(UserId id) {
    Log.debug('getUser($id)', '$runtimeType');
    return _userRepo.get(id);
  }

  @override
  Future<void> favoriteChat(ChatId id, ChatFavoritePosition? position) async {
    Log.debug('favoriteChat($id, $position)', '$runtimeType');

    final RxChatImpl? chat = chats[id];
    final ChatFavoritePosition? oldPosition = chat?.chat.value.favoritePosition;
    final ChatFavoritePosition newPosition;

    if (position == null) {
      final List<RxChatImpl> favorites = chats.values
          .where((e) => e.chat.value.favoritePosition != null)
          .toList();

      favorites.sort(
        (a, b) => b.chat.value.favoritePosition!.compareTo(
          a.chat.value.favoritePosition!,
        ),
      );

      final double? highestFavorite = favorites.isEmpty
          ? null
          : favorites.first.chat.value.favoritePosition!.val;

      newPosition = ChatFavoritePosition(
        highestFavorite == null ? 1 : highestFavorite * 2,
      );
    } else {
      newPosition = position;
    }

    chat?.chat.update((c) => c?.favoritePosition = newPosition);
    paginated.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));

    try {
      if (id.isLocalWith(me)) {
        _localMonologFavoritePosition = newPosition;
        final ChatData monolog = _chat(
          await Backoff.run(
            () async {
              return await _graphQlProvider.createMonologChat();
            },
            retryIf: (e) => e.isNetworkRelated,
            retries: 10,
          ),
        );

        id = monolog.chat.value.id;

        await Future.wait([
          _monologLocal.upsert(MonologKind.notes, this.monolog = id),
          _putEntry(monolog, ignoreVersion: true),
        ]);
      } else if (id.isLocal) {
        final RxChatImpl? chat = await ensureRemoteDialog(id);
        if (chat != null) {
          id = chat.id;
        }
      }

      if (!id.isLocal) {
        try {
          await _graphQlProvider.favoriteChat(id, newPosition);
        } on FavoriteChatException catch (e) {
          switch (e.code) {
            case FavoriteChatErrorCode.unknownChat:
              await remove(id);
              break;

            case FavoriteChatErrorCode.artemisUnknown:
              rethrow;
          }
        }
      }
    } catch (e) {
      if (chat?.chat.value.isMonolog == true) {
        _localMonologFavoritePosition = null;
      }

      chat?.chat.update((c) => c?.favoritePosition = oldPosition);
      paginated.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));
      rethrow;
    }
  }

  @override
  Future<void> unfavoriteChat(ChatId id) async {
    Log.debug('unfavoriteChat($id)', '$runtimeType');

    if (id.isLocal) {
      return;
    }

    final RxChatImpl? chat = chats[id];
    final ChatFavoritePosition? oldPosition = chat?.chat.value.favoritePosition;

    chat?.chat.update((c) => c?.favoritePosition = null);
    paginated.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.unfavoriteChat(id);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on UnfavoriteChatException catch (e) {
        switch (e.code) {
          case UnfavoriteChatErrorCode.unknownChat:
            await remove(id);
            break;

          case UnfavoriteChatErrorCode.artemisUnknown:
            rethrow;
        }
      }
    } catch (e) {
      chat?.chat.update((c) => c?.favoritePosition = oldPosition);
      paginated.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));
      rethrow;
    }
  }

  @override
  Future<void> clearChat(ChatId id, [ChatItemId? untilId]) async {
    Log.debug('clearChat($id, $untilId)', '$runtimeType');

    if (id.isLocal) {
      await chats[id]?.clear();
      return;
    }

    final RxChatImpl? chat = chats[id];
    final ChatItem? lastItem = chat?.chat.value.lastItem;
    final ChatItemId? until = untilId ?? lastItem?.id;

    if (until == null) {
      // No-op, as there's nothing to clear until.
      return;
    }

    Iterable<Rx<ChatItem>>? items;

    if (chat != null) {
      final int index = chat.messages.indexWhere((c) => c.value.id == until);

      if (index != -1) {
        items = chat.messages.toList().getRange(0, index + 1);
        chat.messages.removeRange(0, index + 1);

        final ChatItem? last = chat.messages.isNotEmpty
            ? chat.messages.last.value
            : null;
        chat.chat.update((c) => c?.lastItem = last);
      }
    }

    try {
      try {
        await Backoff.run(
          () async {
            await _graphQlProvider.clearChat(id, until);
          },
          retryIf: (e) => e.isNetworkRelated,
          retries: 10,
        );
      } on ClearChatException catch (e) {
        switch (e.code) {
          case ClearChatErrorCode.artemisUnknown:
            rethrow;

          case ClearChatErrorCode.unknownChat:
            await remove(id);
            return;

          case ClearChatErrorCode.unknownChatItem:
            rethrow;
        }
      }
    } catch (_) {
      if (chat != null) {
        chat.messages.insertAll(0, items ?? []);
        chat.chat.update((c) => c?.lastItem = lastItem);
      }
      rethrow;
    }
  }

  @override
  Future<ChatId> useChatDirectLink(ChatDirectLinkSlug slug) async {
    Log.debug('useChatDirectLink($slug)', '$runtimeType');

    if (me.isLocal) {
      final query = await _graphQlProvider.searchLink(slug);
      final User? user = query.searchUsers.edges.firstOrNull?.node.toModel();
      if (user == null) {
        return support;
      }

      // Store the transition only if [User] found by [slug] exists.
      await _slugProvider.upsert(slug);

      return ChatId.local(user.id);
    }

    final response = await Backoff.run(
      () async => await _graphQlProvider.useChatDirectLink(slug),
      retryIf: (e) => e.isNetworkRelated,
      retries: 10,
    );

    return response.chat.id;
  }

  /// Constructs a [ChatEvent] from the [ChatEventsVersionedMixin$Events].
  ChatEvent chatEvent(ChatEventsVersionedMixin$Events e) {
    Log.trace('chatEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventChatCleared') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCleared;
      return EventChatCleared(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatUnreadItemsCountUpdated') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatUnreadItemsCountUpdated;
      return EventChatUnreadItemsCountUpdated(e.chatId, node.count);
    } else if (e.$$typename == 'EventChatItemPosted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemPosted;
      return EventChatItemPosted(e.chatId, node.item.toDto());
    } else if (e.$$typename == 'EventChatLastItemUpdated') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatLastItemUpdated;
      return EventChatLastItemUpdated(e.chatId, node.lastItem?.toDto());
    } else if (e.$$typename == 'EventChatItemHidden') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemHidden;
      return EventChatItemHidden(e.chatId, node.itemId);
    } else if (e.$$typename == 'EventChatMuted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatMuted;
      return EventChatMuted(e.chatId, node.duration.toModel());
    } else if (e.$$typename == 'EventChatTypingStarted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatTypingStarted;
      _userRepo.put(node.user.toDto());
      return EventChatTypingStarted(e.chatId, node.user.toModel());
    } else if (e.$$typename == 'EventChatUnmuted') {
      return EventChatUnmuted(e.chatId);
    } else if (e.$$typename == 'EventChatTypingStopped') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatTypingStopped;
      _userRepo.put(node.user.toDto());
      return EventChatTypingStopped(e.chatId, node.user.toModel());
    } else if (e.$$typename == 'EventChatHidden') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatHidden;
      return EventChatHidden(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatItemDeleted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemDeleted;
      return EventChatItemDeleted(e.chatId, node.itemId);
    } else if (e.$$typename == 'EventChatItemEdited') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemEdited;
      return EventChatItemEdited(
        e.chatId,
        node.itemId,
        node.text == null ? null : EditedMessageText(node.text!.changed),
        node.attachments?.changed.map((e) => e.toModel()).toList(),
        node.repliesTo?.changed.map((e) => e.toDto()).toList(),
      );
    } else if (e.$$typename == 'EventChatCallStarted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallStarted;
      return EventChatCallStarted(e.chatId, node.call.toModel());
    } else if (e.$$typename == 'EventChatDirectLinkUsageCountUpdated') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatDirectLinkUsageCountUpdated;
      return EventChatDirectLinkUsageCountUpdated(e.chatId, node.usageCount);
    } else if (e.$$typename == 'EventChatCallFinished') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallFinished;
      return EventChatCallFinished(e.chatId, node.call.toModel(), node.reason);
    } else if (e.$$typename == 'EventChatCallMemberLeft') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMemberLeft;
      _userRepo.put(node.user.toDto());
      return EventChatCallMemberLeft(e.chatId, node.user.toModel(), node.at);
    } else if (e.$$typename == 'EventChatCallMemberJoined') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
      _userRepo.put(node.user.toDto());
      return EventChatCallMemberJoined(
        e.chatId,
        node.call.toModel(),
        node.user.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatCallMemberRedialed') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatCallMemberRedialed;
      _userRepo.put(node.user.toDto());
      return EventChatCallMemberRedialed(
        e.chatId,
        node.at,
        node.callId,
        node.call.toModel(),
        node.user.toModel(),
        node.byUser.toModel(),
      );
    } else if (e.$$typename == 'EventChatDelivered') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatDelivered;
      return EventChatDelivered(e.chatId, node.until);
    } else if (e.$$typename == 'EventChatRead') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatRead;
      _userRepo.put(node.byUser.toDto());
      return EventChatRead(e.chatId, node.byUser.toModel(), node.at);
    } else if (e.$$typename == 'EventChatCallDeclined') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallDeclined;
      _userRepo.put(node.user.toDto());
      return EventChatCallDeclined(
        e.chatId,
        node.callId,
        node.call.toModel(),
        node.user.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatTotalItemsCountUpdated') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatTotalItemsCountUpdated;
      return EventChatTotalItemsCountUpdated(e.chatId, node.count);
    } else if (e.$$typename == 'EventChatDirectLinkDeleted') {
      return EventChatDirectLinkDeleted(e.chatId);
    } else if (e.$$typename == 'EventChatDirectLinkUpdated') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatDirectLinkUpdated;
      return EventChatDirectLinkUpdated(
        e.chatId,
        ChatDirectLink(
          slug: node.directLink.slug,
          usageCount: node.directLink.usageCount,
          createdAt: node.directLink.createdAt,
        ),
      );
    } else if (e.$$typename == 'EventChatCallMoved') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMoved;
      _userRepo.put(node.user.toDto());
      return EventChatCallMoved(
        e.chatId,
        node.callId,
        node.call.toModel(),
        node.newChatId,
        node.newChat.toModel(),
        node.newCallId,
        node.newCall.toModel(),
        node.user.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatArchived') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatArchived;
      return EventChatArchived(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatUnarchived') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatUnarchived;
      return EventChatUnarchived(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatFavorited') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatFavorited;
      return EventChatFavorited(e.chatId, node.at, node.position);
    } else if (e.$$typename == 'EventChatUnfavorited') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatUnfavorited;
      return EventChatUnfavorited(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatCallConversationStarted') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatCallConversationStarted;
      return EventChatCallConversationStarted(
        e.chatId,
        node.callId,
        node.at,
        node.call.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallAnswerTimeoutPassed') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatCallAnswerTimeoutPassed;
      return EventChatCallAnswerTimeoutPassed(e.chatId, node.callId);
    } else {
      throw UnimplementedError('Unknown ChatEvent: ${e.$$typename}');
    }
  }

  // TODO: Put the members of the [Chat]s to the [UserRepository].
  /// Puts the provided [chat] to [Pagination] and local storage.
  ///
  /// Puts it always, if [ignoreVersion] is `true`, or otherwise compares the
  /// stored version with the provided one.
  ///
  /// Overwrites the stored version with the provided, if [updateVersion] is
  /// `true`. Disabling it makes the [chat] update its fields, if version is
  /// lower, yet doesn't update the version.
  ///
  /// Note, that if [chat] isn't stored, then this always puts it and stores the
  /// version, despite the parameters.
  Future<RxChatImpl> put(
    DtoChat chat, {
    bool pagination = false,
    bool updateVersion = true,
    bool ignoreVersion = false,
  }) async {
    Log.debug(
      'put($chat, $pagination, $updateVersion, $ignoreVersion)',
      '$runtimeType',
    );

    final ChatId chatId = chat.value.id;
    final RxChatImpl? saved = chats[chatId];

    // [Chat.firstItem] is maintained locally only for [Pagination] reasons.
    chat.value.firstItem ??= saved?.chat.value.firstItem;

    // Check the versions first, if [ignoreVersion] is `false`.
    if (saved != null && !ignoreVersion) {
      if (saved.ver != null && saved.ver! > chat.ver) {
        if (pagination) {
          paginated[chatId] ??= saved;
        } else {
          await _pagination?.put(chat);
        }

        return saved;
      }
    }

    final RxChatImpl rxChat = _add(chat, pagination: pagination);

    // Favorite [DtoChat]s will be put to local storage through
    // [DriftGraphQlPageProvider].
    if (chat.value.favoritePosition == null) {
      await _chatLocal.txn(() async {
        DtoChat? saved;

        // If version is ignored, there's no need to retrieve the stored chat.
        if (!ignoreVersion || !updateVersion) {
          saved = await _chatLocal.read(chatId, force: true);
        }

        // [Chat.firstItem] is maintained locally only for [Pagination] reasons.
        chat.value.firstItem ??=
            saved?.value.firstItem ?? rxChat.chat.value.firstItem;

        if (saved == null ||
            (saved.ver < chat.ver ||
                ignoreVersion ||
                (saved.ver == chat.ver && saved != chat))) {
          // Set the version to the [saved] one, if not [updateVersion].
          if (saved != null && !updateVersion) {
            chat.ver = saved.ver;

            // [Chat.membersCount] shouldn't be updated, if [updateVersion] is
            // `false`, as it gets updated during [ChatEventKind.itemPosted]
            // event processing.
            chat.value.membersCount = saved.value.membersCount;
          }

          await _chatLocal.upsert(chat, force: true);
        }
      });
    }

    // [pagination] is `true`, if the [chat] is received from [Pagination],
    // thus otherwise we should try putting it to it.
    if (!pagination && !chat.value.isHidden && !chat.value.isArchived) {
      await (_pagination ?? _localPagination)?.put(chat);
    }

    return rxChat;
  }

  /// Adds the provided [DtoChat] to the [chats] and optionally to the
  /// [paginated].
  RxChatImpl _add(DtoChat chat, {bool pagination = false}) {
    Log.trace('_add($chat, $pagination)', '$runtimeType');

    final ChatId chatId = chat.value.id;
    RxChatImpl? entry = chats[chatId];

    if (entry == null) {
      entry = RxChatImpl(
        this,
        _chatLocal,
        _draftLocal,
        _itemsLocal,
        _membersLocal,
        chat,
      )..init();
      chats[chatId] = entry;
    } else {
      if (entry.chat.value.isMonolog) {
        if (_localMonologFavoritePosition != null) {
          chat.value.favoritePosition = _localMonologFavoritePosition;
          _localMonologFavoritePosition = null;
        }
      }

      if (entry.chat.value.favoritePosition != chat.value.favoritePosition) {
        entry.chat.value.favoritePosition = chat.value.favoritePosition;
        paginated.emit(
          MapChangeNotification.updated(chat.value.id, chat.value.id, entry),
        );
      }

      entry.chat.value = chat.value;
      entry.chat.refresh();
    }

    if (pagination && !entry.chat.value.isHidden) {
      if (entry.chat.value.isArchived) {
        archived.put(entry.dto);
      } else {
        paginated[chatId] ??= entry;
      }
    }

    return entry;
  }

  /// Initializes [_recentChatsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    if (isClosed) {
      return;
    }

    Log.debug('_initRemoteSubscription()', '$runtimeType');

    _subscribedAt = DateTime.now();

    _remoteSubscription?.close(immediate: true);

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      _remoteSubscription = StreamQueue(_recentChatsRemoteEvents());
      await _remoteSubscription!.execute(
        _recentChatsRemoteEvent,
        onError: (_) => _subscribedAt = DateTime.now(),
      );
    }, tag: 'recentChatsEvents');
  }

  /// Initializes [_archiveChatsRemoteEvents] subscription.
  Future<void> _initArchiveSubscription() async {
    if (isClosed || me.isLocal) {
      return;
    }

    Log.debug('_initArchiveSubscription()', '$runtimeType');

    _archiveSubscribedAt = DateTime.now();

    _remoteArchiveSubscription?.close(immediate: true);

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      _remoteArchiveSubscription = StreamQueue(_archiveChatsRemoteEvents());
      await _remoteArchiveSubscription!.execute(
        _archiveChatsRemoteEvent,
        onError: (_) => _archiveSubscribedAt = DateTime.now(),
      );
    }, tag: 'archiveChatsEvents');
  }

  /// Handles [RecentChatsEvent] from the [_recentChatsRemoteEvents]
  /// subscription.
  Future<void> _recentChatsRemoteEvent(RecentChatsEvent event) async {
    switch (event.kind) {
      case RecentChatsEventKind.initialized:
        Log.debug('_recentChatsRemoteEvent(${event.kind})', '$runtimeType');

        // If more than 1 minute has passed, recreate [Pagination].
        if (_subscribedAt?.isBefore(
              DateTime.now().subtract(const Duration(minutes: 1)),
            ) ==
            true) {
          await _initRemotePagination();
        }
        break;

      case RecentChatsEventKind.list:
        final node = event as RecentChatsTop;

        Log.debug(
          '_recentChatsRemoteEvent(${event.kind}) -> ${node.list.map((e) => '${e.chat}')}',
          '$runtimeType',
        );

        for (ChatData c in node.list) {
          if (chats[c.chat.value.id] == null) {
            _putEntry(c, updateVersion: false);
          }
        }
        break;

      case RecentChatsEventKind.updated:
        event as EventRecentChatsUpdated;

        final bool isSubscribed =
            chats[event.chat.chat.value.id]?.subscribed == true;

        Log.debug(
          '_recentChatsRemoteEvent(${event.kind}) -> ${event.chat.chat} -> isSubscribed($isSubscribed)',
          '$runtimeType',
        );

        // Update the chat only if its state is not maintained by itself via
        // [chatEvents].
        if (!isSubscribed) {
          final ChatData data = event.chat;
          final Chat chat = data.chat.value;

          if (chat.isMonolog) {
            if (monolog.isLocal) {
              // Keep track of the [monolog]'s [isLocal] status.
              await _monologLocal.upsert(MonologKind.notes, monolog = chat.id);
            }
          }

          if (chat.isSupport) {
            if (support.isLocal) {
              // Keep track of the [support]'s [isLocal] status.
              await _monologLocal.upsert(
                MonologKind.support,
                support = chat.id,
              );
            }
          }

          _putEntry(data, updateVersion: false);
        }
        break;

      case RecentChatsEventKind.deleted:
        event as EventRecentChatsDeleted;

        Log.debug(
          '_recentChatsRemoteEvent(${event.kind}) -> ${event.chatId}',
          '$runtimeType',
        );

        break;
    }
  }

  /// Handles [RecentChatsEvent] from the [_archiveChatsRemoteEvents]
  /// subscription.
  Future<void> _archiveChatsRemoteEvent(RecentChatsEvent event) async {
    Log.debug('_archiveChatsRemoteEvent(${event.kind})', '$runtimeType');

    switch (event.kind) {
      case RecentChatsEventKind.initialized:
        // If more than 1 minute has passed, recreate [Pagination].
        if (_archiveSubscribedAt?.isBefore(
              DateTime.now().subtract(const Duration(minutes: 1)),
            ) ==
            true) {
          await archived.clear();
          await archived.around();
        }
        break;

      case RecentChatsEventKind.list:
        var node = event as RecentChatsTop;
        for (ChatData c in node.list) {
          if (chats[c.chat.value.id] == null) {
            _putEntry(c, updateVersion: false);
          }
        }
        break;

      case RecentChatsEventKind.updated:
        event as EventRecentChatsUpdated;
        // Update the chat only if its state is not maintained by itself via
        // [chatEvents].
        if (chats[event.chat.chat.value.id]?.subscribed != true) {
          final ChatData data = event.chat;
          final Chat chat = data.chat.value;

          if (chat.isMonolog) {
            if (monolog.isLocal) {
              // Keep track of the [monolog]'s [isLocal] status.
              await _monologLocal.upsert(MonologKind.notes, monolog = chat.id);
            }
          }

          if (chat.isSupport) {
            if (support.isLocal) {
              // Keep track of the [support]'s [isLocal] status.
              await _monologLocal.upsert(
                MonologKind.support,
                support = chat.id,
              );
            }
          }

          _putEntry(data, updateVersion: false);
        }
        break;

      case RecentChatsEventKind.deleted:
        event as EventRecentChatsDeleted;
        // No-op.
        break;
    }
  }

  /// Initializes the [_localPagination].
  Future<void> _initLocalPagination() async {
    Log.debug('_initLocalPagination()', '$runtimeType');

    final Pagination<DtoChat, FavoriteChatsCursor, ChatId> favoritePagination =
        Pagination(
          onKey: (e) => e.value.id,
          perPage: 15,
          provider: DriftPageProvider(
            fetch: ({required after, required before, ChatId? around}) async {
              return await _chatLocal.favorite(limit: after + before + 1);
            },
            onKey: (e) => e.value.id,
            onCursor: (e) => e?.favoriteCursor,
            add: (e, {bool toView = true}) async {
              if (toView) {
                await _chatLocal.upsertBulk(e);
              }
            },
            delete: (e) async => await _chatLocal.delete(e),
            reset: () async => await _chatLocal.clear(),
            isLast: (_, _) => true,
            isFirst: (_, _) => true,
            fulfilledWhenNone: true,
            compare: (a, b) => a.value.compareTo(b.value),
          ),
          compare: (a, b) => a.value.compareTo(b.value),
        );

    final Pagination<DtoChat, RecentChatsCursor, ChatId> recentPagination =
        Pagination(
          onKey: (e) => e.value.id,
          perPage: 15,
          provider: DriftPageProvider(
            fetch: ({required after, required before, ChatId? around}) async {
              return await _chatLocal.recent(limit: after + before + 1);
            },
            onKey: (e) => e.value.id,
            onCursor: (e) => e?.recentCursor,
            add: (e, {bool toView = true}) async {
              if (toView) {
                await _chatLocal.upsertBulk(e);
              }
            },
            delete: (e) async => await _chatLocal.delete(e),
            reset: () async => await _chatLocal.clear(),
            isLast: (_, _) => false,
            isFirst: (_, _) => true,
            fulfilledWhenNone: true,
            compare: (a, b) => a.value.compareTo(b.value),
          ),
          compare: (a, b) => a.value.compareTo(b.value),
        );

    _localPagination = CombinedPagination([
      CombinedPaginationEntry(
        favoritePagination,
        addIf: (e) => e.value.favoritePosition != null,
      ),
      CombinedPaginationEntry(
        recentPagination,
        addIf: (e) => e.value.favoritePosition == null,
      ),
    ]);

    await _paginationSubscription?.cancel();
    _paginationSubscription = _localPagination!.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          await _putEntry(ChatData(event.value!, null, null), pagination: true);
          break;

        case OperationKind.removed:
          await remove(event.value!.value.id);
          break;
      }
    });

    await _localPagination!.around();

    await Future.delayed(1.milliseconds);

    if (me.isLocal) {
      await _initSupport();
      await _initMonolog();
    }

    if (paginated.isNotEmpty && !status.value.isSuccess) {
      status.value = RxStatus.loadingMore();

      Log.debug(
        '_initLocalPagination() -> status is `loadingMore`',
        '$runtimeType',
      );
    }
  }

  /// Initializes the [_pagination].
  Future<void> _initRemotePagination() async {
    if (isClosed || me.isLocal) {
      status.value = RxStatus.success();
      return;
    }

    Log.debug('_initRemotePagination()', '$runtimeType');

    final Pagination<DtoChat, RecentChatsCursor, ChatId> calls = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: GraphQlPageProvider(
        fetch: ({after, before, first, last}) => _recentChats(
          after: after,
          first: first,
          before: before,
          last: last,
          withOngoingCalls: true,
          noFavorite: false,
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    );

    Pagination<DtoChat, FavoriteChatsCursor, ChatId>? favorites;
    favorites = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: DriftGraphQlPageProvider(
        driftProvider: DriftPageProvider(
          watch: ({int? after, int? before, ChatId? around}) async {
            final int limit = (after ?? 0) + (before ?? 0) + 1;
            return _chatLocal.watchFavorite(limit: limit > 1 ? limit : null);
          },
          watchUpdates: (a, b) =>
              a.value.favoritePosition != b.value.favoritePosition,
          onAdded: (e) async {
            await favorites?.put(e, store: false);
          },
          onRemoved: (e) async {
            await favorites?.remove(e.id, store: false);
          },
          onKey: (e) => e.value.id,
          onCursor: (e) => e?.favoriteCursor,
          add: (e, {bool toView = true}) async {
            if (toView) {
              await _chatLocal.upsertBulk(e);
            }
          },
          delete: (e) async => await _chatLocal.delete(e),
          reset: () async => await _chatLocal.clear(),
          isLast: (_, _) =>
              _sessionLocal.data[me]?.favoriteChatsSynchronized ?? false,
          isFirst: (_, _) =>
              _sessionLocal.data[me]?.favoriteChatsSynchronized ?? false,
          compare: (a, b) => a.value.compareTo(b.value),
        ),
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) async {
            final Page<DtoChat, FavoriteChatsCursor> page =
                await _favoriteChats(
                  after: after,
                  first: first,
                  before: before,
                  last: last,
                );

            if (!page.info.hasNext) {
              _sessionLocal.upsert(
                me,
                favoriteChatsSynchronized: NewType(true),
              );
            }

            return page;
          },
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    );

    Pagination<DtoChat, RecentChatsCursor, ChatId>? recent;
    recent = Pagination(
      onKey: (e) => e.value.id,
      perPage: 15,
      provider: DriftGraphQlPageProvider(
        alwaysFetch: true,
        graphQlProvider: GraphQlPageProvider(
          fetch: ({after, before, first, last}) => _recentChats(
            after: after,
            first: first,
            before: before,
            last: last,
          ),
        ),
        driftProvider: DriftPageProvider(
          watch: ({int? after, int? before, ChatId? around}) async {
            final int limit = (after ?? 0) + (before ?? 0) + 1;
            return _chatLocal.watchRecent(limit: limit > 1 ? limit : null);
          },
          watchUpdates: (a, b) =>
              a.value.favoritePosition == null &&
              b.value.favoritePosition == null &&
              a.value.isArchived != b.value.isArchived,
          onAdded: (e) async {
            final ChatVersion? stored = paginated[e.id]?.ver;

            Log.debug(
              'recent.onAdded -> $e -> stored == null(${stored == null}) || e.ver > stored(${e.ver > stored})',
              '$runtimeType',
            );

            if (stored == null || e.ver > stored) {
              await recent?.put(e, store: false);
            }
          },
          onRemoved: (e) async {
            Log.debug('recent.onRemoved -> $e', '$runtimeType');
            await recent?.remove(e.value.id, store: false);
          },
          onKey: (e) => e.value.id,
          onCursor: (e) => e?.recentCursor,
          add: (e, {bool toView = true}) async {
            if (toView) {
              await _chatLocal.upsertBulk(e);
            }
          },
          delete: (e) async => await _chatLocal.delete(e),
          reset: () async => await _chatLocal.clear(),
          isLast: (_, _) => false,
          isFirst: (_, _) => false,
          fulfilledWhenNone: true,
          compare: (a, b) => a.value.compareTo(b.value),
        ),
      ),
      compare: (a, b) => a.value.compareTo(b.value),
    );

    _pagination?.dispose();
    _pagination = CombinedPagination([
      CombinedPaginationEntry(calls, addIf: (e) => e.value.ongoingCall != null),
      CombinedPaginationEntry(
        favorites,
        addIf: (e) => e.value.favoritePosition != null && !e.value.isArchived,
      ),
      CombinedPaginationEntry(
        recent,
        addIf: (e) =>
            e.value.ongoingCall == null &&
            e.value.favoritePosition == null &&
            !e.value.isArchived,
      ),
    ]);

    Log.debug('_initRemotePagination() -> around()...', '$runtimeType');
    await _pagination!.around();
    Log.debug('_initRemotePagination() -> around()... done!', '$runtimeType');

    await _paginationSubscription?.cancel();
    _paginationSubscription = _pagination!.changes.listen((event) async {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          final ChatData chatData = ChatData(event.value!, null, null);
          await _putEntry(
            chatData,
            pagination: true,
            ignoreVersion: event.op == OperationKind.added,
            updateVersion: false,
          );
          break;

        case OperationKind.removed:
          // Don't remove a chat that is still present in the pagination, as it
          // might've been only remove from a concrete pagination: recent only
          // or favorites only, not the whole list.
          if (_pagination?.items.where((e) => e.id == event.key).isEmpty ==
              true) {
            remove(event.value!.value.id);
          }
          break;
      }
    });

    if (_localPagination != null) {
      // Remove the [DtoChat]s missing in local pagination from the database.
      for (var e in _localPagination!.items.take(_pagination!.items.length)) {
        if (_pagination?.items.none((b) => b.id == e.id) == true) {
          remove(e.id);
        }
      }
    }

    // Clear the [paginated] and the [_localPagination] populating it, as
    // [CombinedPagination.around] has fetched its results.
    paginated.removeWhere(
      (key, _) => _pagination?.items.none((e) => e.value.id == key) == true,
    );
    _localPagination?.dispose();
    _localPagination = null;

    // Add the received in [CombinedPagination.around] items to the
    // [paginated].
    _pagination?.items.forEach(
      (e) => _putEntry(
        ChatData(e, null, null),
        pagination: true,
        ignoreVersion: true,
        updateVersion: false,
      ),
    );

    try {
      Log.debug(
        '_initRemotePagination() -> await _initMonolog()...',
        '$runtimeType',
      );

      await _initMonolog();

      Log.debug(
        '_initRemotePagination() -> await _initMonolog()... done!',
        '$runtimeType',
      );
    } catch (_) {
      // Still proceed with initialization.
    }

    try {
      Log.debug(
        '_initRemotePagination() -> await _initSupport()...',
        '$runtimeType',
      );

      await _initSupport();

      Log.debug(
        '_initRemotePagination() -> await _initSupport()... done!',
        '$runtimeType',
      );
    } catch (_) {
      // Still proceed with initialization.
    }

    status.value = RxStatus.success();

    Log.debug('_initRemotePagination() -> status is `success`', '$runtimeType');
  }

  /// Subscribes to the remote updates of the [chats].
  Stream<RecentChatsEvent> _recentChatsRemoteEvents() {
    Log.debug('_recentChatsRemoteEvents()', '$runtimeType');

    return _graphQlProvider.recentChatsTopEvents(3).asyncExpand((event) async* {
      Log.trace('_recentChatsRemoteEvents(): ${event.data}', '$runtimeType');

      var events = RecentChatsTopEvents$Subscription.fromJson(
        event.data!,
      ).recentChatsTopEvents;

      if (events.$$typename == 'SubscriptionInitialized') {
        yield const RecentChatsTopInitialized();
      } else if (events.$$typename == 'RecentChatsTop') {
        var list =
            (events
                    as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$RecentChatsTop)
                .list;
        yield RecentChatsTop(
          list.map((e) => _chat(e.node)..chat.recentCursor = e.cursor).toList(),
        );
      } else if (events.$$typename == 'EventRecentChatsTopChatUpdated') {
        var mixin =
            events
                as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$EventRecentChatsTopChatUpdated;
        yield EventRecentChatsUpdated(
          _chat(mixin.chat.node)..chat.recentCursor = mixin.chat.cursor,
        );
      } else if (events.$$typename == 'EventRecentChatsTopChatRemoved') {
        var mixin =
            events
                as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$EventRecentChatsTopChatRemoved;
        yield EventRecentChatsDeleted(mixin.chatId);
      }
    });
  }

  /// Subscribes to the remote updates of the archived [chats].
  Stream<RecentChatsEvent> _archiveChatsRemoteEvents() {
    Log.debug('_archiveChatsRemoteEvents()', '$runtimeType');

    // TODO: Remove when multiple [_graphQlProvider.recentChatsTopEvents] are
    //       not interfering with each other.
    return const Stream.empty();

    // return _graphQlProvider.recentChatsTopEvents(1, archived: true).asyncExpand((
    //   event,
    // ) async* {
    //   Log.trace('_archiveChatsRemoteEvents(): ${event.data}', '$runtimeType');

    //   var events = RecentChatsTopEvents$Subscription.fromJson(
    //     event.data!,
    //   ).recentChatsTopEvents;

    //   if (events.$$typename == 'SubscriptionInitialized') {
    //     yield const RecentChatsTopInitialized();
    //   } else if (events.$$typename == 'RecentChatsTop') {
    //     var list =
    //         (events
    //                 as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$RecentChatsTop)
    //             .list;
    //     yield RecentChatsTop(
    //       list.map((e) => _chat(e.node)..chat.recentCursor = e.cursor).toList(),
    //     );
    //   } else if (events.$$typename == 'EventRecentChatsTopChatUpdated') {
    //     var mixin =
    //         events
    //             as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$EventRecentChatsTopChatUpdated;
    //     yield EventRecentChatsUpdated(
    //       _chat(mixin.chat.node)..chat.recentCursor = mixin.chat.cursor,
    //     );
    //   } else if (events.$$typename == 'EventRecentChatsTopChatRemoved') {
    //     var mixin =
    //         events
    //             as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$EventRecentChatsTopChatRemoved;
    //     yield EventRecentChatsDeleted(mixin.chatId);
    //   }
    // });
  }

  /// Fetches [DtoChat]s ordered by their last updating time with pagination.
  Future<Page<DtoChat, RecentChatsCursor>> _recentChats({
    int? first,
    RecentChatsCursor? after,
    int? last,
    RecentChatsCursor? before,
    bool withOngoingCalls = false,
    bool noFavorite = true,
    bool archived = false,
  }) async {
    Log.debug(
      '_recentChats($first, $after, $last, $before, $withOngoingCalls)',
      '$runtimeType',
    );

    if (me.isLocal) {
      return Page([], PageInfo());
    }

    final query = (await _graphQlProvider.recentChats(
      first: first,
      after: after,
      last: last,
      before: before,
      withOngoingCalls: withOngoingCalls,
      noFavorite: noFavorite,
      archived: archived,
    )).recentChats;

    return Page(
      RxList(
        query.edges
            .map((e) => _chat(e.node, recentCursor: e.cursor).chat)
            .toList(),
      ),
      query.pageInfo.toModel(RecentChatsCursor.new),
    );
  }

  /// Fetches favorite [DtoChat]s ordered by their [Chat.favoritePosition] with
  /// pagination.
  Future<Page<DtoChat, FavoriteChatsCursor>> _favoriteChats({
    int? first,
    FavoriteChatsCursor? after,
    int? last,
    FavoriteChatsCursor? before,
  }) async {
    Log.debug('_favoriteChats($first, $after, $last, $before)', '$runtimeType');

    FavoriteChats$Query$FavoriteChats query =
        (await _graphQlProvider.favoriteChats(
          first: first,
          after: after,
          last: last,
          before: before,
        )).favoriteChats;

    _sessionLocal.upsert(me, favoriteChatsListVersion: NewType(query.ver));

    return Page(
      RxList(
        query.edges
            .map((e) => _chat(e.node, favoriteCursor: e.cursor).chat)
            .toList(),
      ),
      query.pageInfo.toModel((c) => FavoriteChatsCursor(c)),
    );
  }

  /// Puts the provided [data] to the local storage.
  ///
  /// Puts it always, if [ignoreVersion] is `true`, or otherwise compares the
  /// stored version with the provided one.
  ///
  /// Overwrites the stored version with the provided, if [updateVersion] is
  /// `true`. Disabling it makes the [chat] update its fields, if version is
  /// lower, yet doesn't update the version.
  ///
  /// Note, that if [data] isn't stored, then this always puts it and stores the
  /// version, despite the parameters.
  Future<RxChatImpl> _putEntry(
    ChatData data, {
    bool pagination = false,
    bool updateVersion = true,
    bool ignoreVersion = false,
  }) async {
    Log.trace(
      '_putEntry($data, $pagination, $updateVersion, $ignoreVersion)',
      '$runtimeType',
    );

    final ChatId chatId = data.chat.value.id;

    Mutex? mutex = _putEntryGuards[chatId];

    if (mutex != null) {
      await Future.delayed(Duration.zero);
    }

    // If the [data] is already in [chats], then don't invoke [_putEntry] again.
    final RxChatImpl? saved = chats[chatId];
    if (saved != null) {
      if (!updateVersion) {
        Log.debug(
          '_putEntry($data, pagination: $pagination, updateVersion: $updateVersion, ignoreVersion: $ignoreVersion) -> doing `put()`, because saved is `${chats[chatId]}`',
          '$runtimeType',
        );
      }

      return put(
        data.chat,
        pagination: pagination,
        updateVersion: updateVersion,
        ignoreVersion: ignoreVersion,
      );
    }

    if (mutex == null) {
      mutex = Mutex();
      _putEntryGuards[chatId] = mutex;
    }

    return await mutex.protect(() async {
      RxChatImpl? entry = chats[chatId];

      if (entry == null) {
        if (!updateVersion) {
          Log.debug(
            '_putEntry($data, pagination: $pagination, updateVersion: $updateVersion, ignoreVersion: $ignoreVersion) -> await mutex.protect() succeeded, and `entry` is `null` -> data.chat.value.isGroup(${data.chat.value.isGroup}), chatId.isLocal(${chatId.isLocal})',
            '$runtimeType',
          );
        }

        // If [data] is a remote [Chat]-dialog, then try to replace the existing
        // local [Chat], if any is associated with this [data].
        if (!data.chat.value.isGroup && !chatId.isLocal) {
          final ChatMember? member = data.chat.value.members.firstWhereOrNull(
            (m) => data.chat.value.isMonolog || m.user.id != me,
          );

          if (member != null) {
            final ChatId localId = ChatId.local(member.user.id);
            final RxChatImpl? localChat = chats[localId];

            if (localChat != null) {
              await localChat.updateChat(data.chat);

              chats.move(localId, chatId);
              paginated.move(localId, chatId);

              entry = localChat;
            }

            await _draftLocal.move(localId, chatId);
            remove(localId);
          }
        }
      }

      entry = await put(
        data.chat,
        pagination: pagination,
        updateVersion: updateVersion,
        ignoreVersion: ignoreVersion,
      );

      if (data.lastReadItem != null) {
        entry.put(data.lastReadItem!, ignoreBounds: true);
      }
      if (data.lastItem != null) {
        entry.put(data.lastItem!);
      }

      _putEntryGuards.remove(chatId);

      if (!updateVersion) {
        Log.debug(
          '_putEntry($data, pagination: $pagination, updateVersion: $updateVersion, ignoreVersion: $ignoreVersion) -> `await put()` is done, thus entry is fulfilled: `$entry`',
          '$runtimeType',
        );
      }

      return entry;
    });
  }

  /// Constructs a new [ChatData] from the given [ChatMixin] fragment.
  ChatData _chat(
    ChatMixin q, {
    RecentChatsCursor? recentCursor,
    FavoriteChatsCursor? favoriteCursor,
  }) {
    Log.trace('_chat($q, $recentCursor, $favoriteCursor)', '$runtimeType');

    for (var m in q.members.nodes) {
      _userRepo.put(m.user.toDto());
    }

    if (q.lastReadItem != null) {
      _itemsLocal.upsert(q.lastReadItem!.toDto());
    }

    if (q.lastItem != null) {
      _itemsLocal.upsert(q.lastItem!.toDto());
    }

    return q.toData(recentCursor, favoriteCursor);
  }

  /// Initializes [_favoriteChatsEvents] subscription.
  Future<void> _initFavoriteSubscription() async {
    if (isClosed || me.isLocal) {
      return;
    }

    Log.debug('_initFavoriteSubscription()', '$runtimeType');

    _favoriteChatsSubscription?.cancel();

    await WebUtils.protect(() async {
      if (isClosed) {
        return;
      }

      _favoriteChatsSubscription = StreamQueue(
        _favoriteChatsEvents(
          () => _sessionLocal.data[me]?.favoriteChatsListVersion,
        ),
      );
      await _favoriteChatsSubscription!.execute(
        _favoriteChatsEvent,
        onError: (e) async {
          if (e is StaleVersionException) {
            status.value = RxStatus.loading();

            try {
              await _pagination?.clear();
              await _sessionLocal.upsert(
                me,
                favoriteChatsSynchronized: NewType(false),
                favoriteChatsListVersion: NewType(null),
              );

              await _pagination?.around();
            } finally {
              status.value = RxStatus.success();
            }
          }
        },
      );
    }, tag: 'favoriteChatsEvents');
  }

  /// Handles a [FavoriteChatsEvent] from the [_favoriteChatsEvents]
  /// subscription.
  Future<void> _favoriteChatsEvent(FavoriteChatsEvents event) async {
    switch (event.kind) {
      case FavoriteChatsEventsKind.initialized:
        Log.debug('_favoriteChatsEvent(${event.kind})', '$runtimeType');
        break;

      case FavoriteChatsEventsKind.event:
        var versioned = (event as FavoriteChatsEventsEvent).event;
        final listVer = _sessionLocal.data[me]?.favoriteChatsListVersion;

        if (versioned.ver >= listVer) {
          _sessionLocal.upsert(
            me,
            favoriteChatsListVersion: NewType(versioned.ver),
          );

          Log.debug(
            '_favoriteChatsEvent(${event.kind}): ${versioned.events.map((e) => e.kind)}',
            '$runtimeType',
          );

          for (var event in versioned.events) {
            switch (event.kind) {
              case ChatEventKind.favorited:
                // If we got an event about [Chat] that we don't have in
                // [paginated], then fetch it and store appropriately with its
                // favorite position.
                if (paginated[event.chatId] == null || !isRemote) {
                  event as EventChatFavorited;

                  final DtoChat? dto = await _chatLocal.read(event.chatId);
                  if (dto != null) {
                    dto.value.favoritePosition = event.position;
                    await _putEntry(ChatData(dto, null, null));
                  } else {
                    // If there is no [Chat] in local storage, [get] will fetch
                    // it from the remote already up-to-date and store it.
                    await get(event.chatId);
                  }
                }
                break;

              case ChatEventKind.unfavorited:
                // No-op.
                break;

              default:
                // No-op.
                break;
            }
          }
          break;
        }
    }
  }

  /// Subscribes to the [FavoriteChatsEvent]s of all [chats].
  Stream<FavoriteChatsEvents> _favoriteChatsEvents(
    FavoriteChatsListVersion? Function() ver,
  ) {
    Log.debug('_favoriteChatsEvents(ver)', '$runtimeType');

    return _graphQlProvider.favoriteChatsEvents(ver).asyncExpand((
      event,
    ) async* {
      Log.trace('_favoriteChatsEvents: ${event.data}', '$runtimeType');

      var events = FavoriteChatsEvents$Subscription.fromJson(
        event.data!,
      ).favoriteChatsEvents;
      if (events.$$typename == 'SubscriptionInitialized') {
        events
            as FavoriteChatsEvents$Subscription$FavoriteChatsEvents$SubscriptionInitialized;
        yield const FavoriteChatsEventsInitialized();
      } else if (events.$$typename == 'FavoriteChatsList') {
        // No-op, as favorite chats are fetched through [Pagination].
      } else if (events.$$typename == 'FavoriteChatsEventsVersioned') {
        var mixin =
            events
                as FavoriteChatsEvents$Subscription$FavoriteChatsEvents$FavoriteChatsEventsVersioned;
        yield FavoriteChatsEventsEvent(
          FavoriteChatsEventsVersioned(
            mixin.events.map((e) => _favoriteChatsVersionedEvent(e)).toList(),
            mixin.ver,
          ),
        );
      }
    });
  }

  /// Constructs a [ChatEvents] from the
  /// [FavoriteChatsEventsVersionedMixin$Events].
  ChatEvent _favoriteChatsVersionedEvent(
    FavoriteChatsEventsVersionedMixin$Events e,
  ) {
    Log.trace('_favoriteChatsVersionedEvent($e)', '$runtimeType');

    if (e.$$typename == 'EventChatFavorited') {
      var node =
          e as FavoriteChatsEventsVersionedMixin$Events$EventChatFavorited;
      return EventChatFavorited(e.chatId, e.at, node.position);
    } else if (e.$$typename == 'EventChatUnfavorited') {
      return EventChatUnfavorited(e.chatId, e.at);
    } else {
      throw UnimplementedError('Unknown FavoriteChatsEvent: ${e.$$typename}');
    }
  }

  /// Returns a [RxChatImpl] being a local [Chat]-dialog between the given
  /// [responderId] and the authenticated [MyUser].
  Future<RxChatImpl> _createLocalDialog(UserId responderId) async {
    Log.debug('_createLocalDialog($responderId)', '$runtimeType');

    final ChatId chatId = ChatId.local(responderId);

    final FutureOr<RxUser?> myUser = _userRepo.get(me);
    final FutureOr<RxUser?> responder = _userRepo.get(responderId);

    final List<RxUser?> users = [
      myUser is RxUser? ? myUser : await myUser,
      if (responderId != me) responder is RxUser? ? responder : await responder,
    ];

    final ChatData chatData = ChatData(
      DtoChat(
        Chat(
          chatId,
          members: users.nonNulls
              .map((e) => ChatMember(e.user.value, PreciseDateTime.now()))
              .toList(),
          kindIndex: ChatKind.values.indexOf(
            responderId == me ? ChatKind.monolog : ChatKind.dialog,
          ),
          updatedAt: PreciseDateTime.fromMicrosecondsSinceEpoch(0),
        ),
        ChatVersion('0'),
        null,
        null,
        null,
        null,
      ),
      null,
      null,
    );

    return _putEntry(chatData);
  }

  /// Bootstraps [_paginatedSubscription] and [_archivedSubscription].
  void _ensurePagination() {
    Log.debug('_ensurePagination() -> $_hasPagination', '$runtimeType');

    _paginatedSubscription?.cancel();
    _paginatedSubscription = null;
    _archivedSubscription?.cancel();
    _archivedSubscription = null;

    if (_hasPagination) {
      _initRemotePagination();

      if (me.isLocal) {
        _initSupport();
        _initMonolog();
      }

      _paginatedSubscription = paginated.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            _subscriptions[e.key!] ??= e.value!.updates.listen((_) {});
            break;

          case OperationKind.updated:
            if (e.oldKey != e.key) {
              final StreamSubscription? subscription = _subscriptions[e.oldKey];
              if (subscription != null) {
                _subscriptions[e.key!] = subscription;
                _subscriptions.remove(e.oldKey);
              }
            }
            break;

          case OperationKind.removed:
            _subscriptions.remove(e.key!)?.cancel();
            break;
        }
      });

      _initLocalPagination();

      _archivedSubscription = archived.items.changes.listen((e) {
        switch (e.op) {
          case OperationKind.added:
            _archiveSubscriptions[e.key!] ??= e.value!.updates.listen((_) {});
            break;

          case OperationKind.updated:
            if (e.oldKey != e.key) {
              final StreamSubscription? subscription =
                  _archiveSubscriptions[e.oldKey];
              if (subscription != null) {
                _archiveSubscriptions[e.key!] = subscription;
                _archiveSubscriptions.remove(e.oldKey);
              }
            }
            break;

          case OperationKind.removed:
            _archiveSubscriptions.remove(e.key!)?.cancel();
            break;
        }
      });

      archived.around();
    }
  }

  /// Initializes the local [monolog] if none is known.
  Future<void> _initMonolog() async {
    Log.debug('_initMonolog()', '$runtimeType');

    if (me.isLocal) {
      Log.debug('_initMonolog() -> `me.isLocal` is `true`', '$runtimeType');
      monolog = (await _createLocalDialog(me)).id;
      return;
    }

    try {
      Log.debug('_initMonolog() -> _monologGuard.protect()...', '$runtimeType');

      await _monologGuard.synchronized(() async {
        Log.debug(
          '_initMonolog() -> _monologGuard.protect()... done!',
          '$runtimeType',
        );

        if (isClosed) {
          return;
        }

        final bool isLocal = monolog.isLocal;
        final bool isPaginated = paginated[monolog] != null;
        final bool canFetchMore =
            !me.isLocal && (_pagination?.hasNext.value ?? true);

        Log.debug(
          '_initMonolog() -> isLocal($isLocal), isPaginated($isPaginated), canFetchMore($canFetchMore)',
          '$runtimeType',
        );

        // If a non-local [monolog] isn't stored and it won't appear from the
        // [Pagination], then initialize local monolog or get a remote one.
        if (isLocal && !isPaginated && !canFetchMore) {
          Log.debug(
            '_initMonolog() -> await _monologLocal.read()...',
            '$runtimeType',
          );

          // Whether [ChatId] of [MyUser]'s monolog is known for the given device.
          final ChatId? stored = await _monologLocal.read(MonologKind.notes);

          Log.debug('_initMonolog() -> stored($stored)', '$runtimeType');

          if (stored == null) {
            // If remote chat doesn't exist and local one is not stored, then
            // create it.
            await _monologLocal.upsert(
              MonologKind.notes,
              monolog = (await _createLocalDialog(me)).id,
            );
          } else {
            // Check if there's a remote update (monolog could've been hidden)
            // before creating a local chat.
            final ChatMixin? maybeMonolog = await _graphQlProvider.getMonolog();

            Log.debug(
              '_initMonolog() -> maybeMonolog($maybeMonolog)',
              '$runtimeType',
            );

            if (maybeMonolog != null) {
              // If the [monolog] was fetched, then update [_monologLocal].
              // final ChatData monologChatData = _chat(maybeMonolog);
              // final RxChatImpl monolog = await _putEntry(monologChatData);

              await _monologLocal.upsert(
                MonologKind.notes,
                monolog = maybeMonolog.id,
              );
            } else {
              monolog = stored;
            }

            if (monolog.isLocal) {
              // If remote monolog doesn't exist and local one is not stored, then
              // create it.
              monolog = (await _createLocalDialog(me)).id;
            }
          }
        }

        Log.debug('_initMonolog()... done!', '$runtimeType');
      }, timeout: const Duration(minutes: 1));
    } catch (e) {
      Log.error('Unable to `_initMonolog()` due to: $e');
      rethrow;
    }
  }

  /// Initializes the local [support] chat, if none is known.
  Future<void> _initSupport() async {
    Log.debug('_initSupport()', '$runtimeType');

    if (_supportId.val.isEmpty) {
      return;
    }

    if (me.isLocal) {
      Log.debug('_initSupport() -> `me.isLocal` is `true`', '$runtimeType');
      support = (await _createLocalDialog(_supportId)).id;
      return;
    }

    try {
      Log.debug('_initSupport() -> _supportGuard.protect()...', '$runtimeType');

      await _supportGuard.synchronized(() async {
        Log.debug(
          '_initSupport() -> _supportGuard.protect()... done!',
          '$runtimeType',
        );

        final bool isLocal = support.isLocal;
        final bool isPaginated = paginated[support] != null;
        final bool canFetchMore =
            !me.isLocal && (_pagination?.hasNext.value ?? true);

        Log.debug(
          '_initSupport() -> isLocal($isLocal), isPaginated($isPaginated), canFetchMore($canFetchMore)',
          '$runtimeType',
        );

        // If a non-local [support] isn't stored and it won't appear from the
        // [Pagination], then initialize local monolog or get a remote one.
        if (isLocal && !isPaginated && !canFetchMore) {
          // Whether [ChatId] of [MyUser]'s support is known for the given device.
          final ChatId? stored = await _monologLocal.read(MonologKind.support);

          if (stored == null) {
            Log.debug(
              '_initSupport() -> `stored` is `null`, thus creating new dialog...',
              '$runtimeType',
            );

            // If remote chat doesn't exist and local one is not stored, then
            // create it.
            //
            // Doing `await` here might for some reason hang the E2E tests?
            _monologLocal.upsert(
              MonologKind.support,
              support = (await _createLocalDialog(_supportId)).id,
            );

            Log.debug(
              '_initSupport() -> `stored` is `null`, thus creating new dialog... done with `$support` ID',
              '$runtimeType',
            );
          } else {
            // Check if there's a remote update (support could've been hidden)
            // before creating a local chat.
            final ChatMixin? maybeSupport = await _graphQlProvider.getDialog(
              UserId(Config.supportId),
            );

            Log.debug(
              '_initSupport() -> `stored` is `$stored`, thus `maybeSupport` queried is: `${maybeSupport?.id}`',
              '$runtimeType',
            );

            if (maybeSupport != null) {
              // Doing `await` here might for some reason hang the E2E tests?
              _monologLocal.upsert(
                MonologKind.support,
                support = maybeSupport.id,
              );
            } else {
              support = stored;
            }

            if (support.isLocal) {
              Log.debug(
                '_initSupport() -> `support` is still local, thus creating new dialog from `$support`',
                '$runtimeType',
              );

              await _createLocalDialog(support.userId);
            }
          }
        }
      }, timeout: const Duration(minutes: 1));
    } catch (e) {
      Log.error('Unable to `_initSupport()` due to: $e');
      rethrow;
    }
  }
}

/// Result of fetching a [Chat].
class ChatData {
  const ChatData(this.chat, this.lastItem, this.lastReadItem);

  /// [DtoChat] returned from the [Chat] fetching.
  final DtoChat chat;

  /// [DtoChatItem] of a [Chat.lastItem] returned from the [Chat] fetching.
  final DtoChatItem? lastItem;

  /// [DtoChatItem] of a [Chat.lastReadItem] returned from the [Chat] fetching.
  final DtoChatItem? lastReadItem;

  @override
  String toString() =>
      '$runtimeType(chat: $chat, lastItem: $lastItem, lastReadItem: $lastReadItem)';
}

/// Extension adding `null`ify methods to empty `ChatMessageText`s.
extension on ChatMessageText {
  /// Returns `null`, if this [ChatMessageText] is empty, or returns itself
  /// otherwise.
  ChatMessageText? get nullIfEmpty {
    if (val.isEmpty) {
      return null;
    }

    return this;
  }
}
