// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/schema.dart'
    show
        ChatCallFinishReason,
        ChatKind,
        PostChatMessageErrorCode,
        ReadChatErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/provider/drift/chat_item.dart';
import '/provider/drift/chat_member.dart';
import '/provider/drift/chat.dart';
import '/provider/drift/draft.dart';
import '/provider/gql/exceptions.dart'
    show
        ConnectionException,
        PostChatMessageException,
        StaleVersionException,
        ReadChatException;
import '/store/model/chat.dart';
import '/store/model/chat_item.dart';
import '/store/pagination.dart';
import '/util/awaitable_timer.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'chat.dart';
import 'event/chat.dart';
import 'model/chat_member.dart';
import 'model/page_info.dart';
import 'paginated.dart';
import 'pagination/drift.dart';
import 'pagination/drift_graphql.dart';
import 'pagination/graphql.dart';

typedef MessagesPaginated =
    RxPaginatedImpl<ChatItemId, Rx<ChatItem>, DtoChatItem, ChatItemsCursor>;

typedef MembersPaginated =
    RxPaginatedImpl<UserId, RxChatMember, DtoChatMember, ChatMembersCursor>;

typedef AttachmentsPaginated =
    RxPaginatedImpl<ChatItemId, Rx<ChatItem>, DtoChatItem, ChatItemsCursor>;

/// [RxChat] implementation backed by local storage.
class RxChatImpl extends RxChat {
  RxChatImpl(
    this._chatRepository,
    this._driftChat,
    this._draftLocal,
    this._driftItems,
    this._driftMembers,
    this.dto,
  ) : chat = Rx<Chat>(dto.value),
      _lastReadItemCursor = dto.lastReadItemCursor,
      _lastReadItemKey = dto.value.lastReadItem,
      unreadCount = RxInt(dto.value.unreadCount),
      ver = dto.ver;

  @override
  final Rx<Chat> chat;

  @override
  final RxObsList<Rx<ChatItem>> messages = RxObsList<Rx<ChatItem>>();

  @override
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  @override
  final RxList<User> typingUsers = RxList<User>([]);

  @override
  late final MembersPaginated members;

  @override
  final Rx<Avatar?> avatar = Rx<Avatar?>(null);

  @override
  final Rx<ChatMessage?> draft = Rx(null);

  @override
  final RxList<LastChatRead> reads = RxList();

  @override
  final RxInt unreadCount;

  /// [ChatVersion] of this [RxChatImpl].
  ChatVersion? ver;

  /// [DtoChat] persisted and applied.
  DtoChat dto;

  @override
  late final RxBool inCall = RxBool(
    _chatRepository.calls[id] != null || WebUtils.containsCall(id),
  );

  /// [MessagesPaginated]s created by this [RxChatImpl].
  final List<MessagesPaginated> fragments = [];

  /// [ChatRepository] used to cooperate with the other [RxChatImpl]s.
  final ChatRepository _chatRepository;

  /// [Chat]s local storage.
  final ChatDriftProvider _driftChat;

  /// [RxChat.draft]s local storage.
  final DraftDriftProvider _draftLocal;

  /// [ChatItem]s local storage.
  final ChatItemDriftProvider _driftItems;

  /// [ChatMember]s local storage.
  final ChatMemberDriftProvider _driftMembers;

  /// [Pagination] loading [messages] with pagination.
  Pagination<DtoChatItem, ChatItemsCursor, ChatItemId>? _pagination;

  /// [AttachmentsPaginated]s created by this [RxChatImpl].
  final List<MessagesPaginated> _attachments = [];

  /// Subscriptions to the [RxPaginatedImpl.items] changes updating the [reads].
  final List<StreamSubscription> _fragmentSubscriptions = [];

  /// [Worker] reacting on the [User] changes updating the [avatar].
  Worker? _userWorker;

  /// Subscription to the [_pagination] changes.
  StreamSubscription? _paginationSubscription;

  /// [Timer] unmuting the muted [chat] when its [MuteDuration.until] expires.
  Timer? _muteTimer;

  /// [ChatRepository.chatEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<ChatEvents>? _remoteSubscription;

  /// [ChatDriftProvider.watch] subscription.
  StreamSubscription? _localSubscription;

  /// [DraftDriftProvider.watch] subscription.
  StreamSubscription? _draftSubscription;

  /// [StreamController] for [updates] of this [RxChat].
  ///
  /// Behaves like a reference counter: when [updates] are listened to, this
  /// invokes [_initRemoteSubscription], and when [updates] aren't listened,
  /// cancels it.
  late final StreamController<void> _controller = StreamController.broadcast(
    onListen: _initRemoteSubscription,
    onCancel: () {
      _remoteSubscription?.cancel();
      _remoteSubscription = null;
    },
  );

  /// [Worker] reacting on the [chat] changes updating the [members].
  Worker? _worker;

  /// [ChatItem]s in the [SendingStatus.sending] state.
  final List<ChatItem> _pending = [];

  /// [StreamSubscription] to [messages] recalculating the [reads] on removals.
  StreamSubscription? _messagesSubscription;

  /// Subscription for the [RxUser]s being the top 3 [members] changes.
  ///
  /// Used to keep [title] up-to-date.
  final Map<UserId, StreamSubscription> _userSubscriptions = {};

  /// [StreamSubscription] to [AbstractCallRepository.calls] and
  /// [WebUtils.onStorageChange] determining the [inCall] indicator.
  StreamSubscription? _callSubscription;

  /// [StreamSubscription] to [members] updating the [avatar].
  StreamSubscription? _membersPaginationSubscription;

  /// [AwaitableTimer] executing a [ChatRepository.readUntil].
  AwaitableTimer? _readTimer;

  /// [Mutex]es guarding synchronized access to the [updateAttachments].
  final Map<ChatItemId, Mutex> _attachmentGuards = {};

  /// [CancelToken] for cancelling the [Pagination.around] query.
  final CancelToken _aroundToken = CancelToken();

  /// Indicator whether this [RxChatImpl] has been disposed, meaning no requests
  /// should be made.
  bool _disposed = false;

  /// Cursor of the last [ChatItem] read by the authenticated [MyUser].
  ChatItemsCursor? _lastReadItemCursor;

  /// [ChatItemId] of the last [ChatItem] read by the authenticated [MyUser].
  ChatItemId? _lastReadItemKey;

  /// [Mutex] guarding reading of [draft] from local storage to [ensureDraft].
  final Mutex _draftGuard = Mutex();

  /// Indicator whether the first [ChatEventsVersioned] were not yet received
  /// since the [_initRemoteSubscription] was invoked.
  ///
  /// Used to determine whether the [ChatEventsVersioned]ed received should be
  /// added to the [_debouncedEvents] or be processed right away.
  bool _justSubscribed = false;

  /// [ChatEventsVersioned] that were debounced during [_eventsDebounce].
  final RxList<ChatEventsVersioned> _debouncedEvents = RxList();

  /// [debounce] adding [ChatEventsVersioned] to the [_debouncedEvents],
  /// whenever [_justSubscribed] is `true`.
  Worker? _eventsDebounce;

  @override
  UserId? get me => _chatRepository.me;

  @override
  RxBool get hasNext => _pagination!.hasNext;

  @override
  RxBool get nextLoading => _pagination!.nextLoading;

  @override
  RxBool get hasPrevious => _pagination!.hasPrevious;

  @override
  RxBool get previousLoading => _pagination!.previousLoading;

  @override
  UserCallCover? get callCover {
    Log.debug('get callCover', '$runtimeType($id)');

    UserCallCover? callCover;

    switch (chat.value.kind) {
      case ChatKind.monolog:
        callCover = members.values.firstOrNull?.user.user.value.callCover;
        break;

      case ChatKind.dialog:
        callCover = members.values
            .firstWhereOrNull((e) => e.user.id != me)
            ?.user
            .user
            .value
            .callCover;
        break;

      case ChatKind.group:
      case ChatKind.artemisUnknown:
        return null;
    }

    callCover ??= chat.value.getCallCover(me);
    return callCover;
  }

  @override
  Rx<ChatItem>? get firstUnread {
    Log.debug('get firstUnread', '$runtimeType($id)');

    if (chat.value.unreadCount != 0) {
      PreciseDateTime? myRead = chat.value.lastReads
          .firstWhereOrNull((e) => e.memberId == me)
          ?.at;

      if (myRead != null) {
        return messages.firstWhereOrNull(
          (e) => myRead.isBefore(e.value.at) && e.value.author.id != me,
        );
      } else {
        return messages.firstOrNull;
      }
    }

    return null;
  }

  @override
  ChatItem? get lastItem {
    ChatItem? item = chat.value.lastItem;
    if (messages.isNotEmpty) {
      final ChatItem last = messages.last.value;
      if (item?.at.isBefore(last.at) == true) {
        item = last;
      }
    }

    return item;
  }

  @override
  Stream<void> get updates => _controller.stream;

  /// Indicates whether this [RxChat] is listening to the remote updates.
  bool get subscribed => _remoteSubscription != null;

  /// Initializes this [RxChatImpl].
  Future<void> init() async {
    Log.debug('init()', '$runtimeType($id)');

    if (status.value.isSuccess) {
      return Future.value();
    }

    status.value = RxStatus.loading();

    reads.addAll(
      chat.value.lastReads.map((e) => LastChatRead(e.memberId, e.at)),
    );

    _initLocalSubscription();
    _initDraftSubscription();
    _initMessagesPagination();
    _initMembersPagination();

    _updateFields();
    _updateUsersSubscriptions();

    if (chat.value.isDialog) {
      _updateAvatar();
      _membersPaginationSubscription = members.items.changes.listen((e) async {
        _updateAvatar();
      });
    }

    Chat previous = chat.value;
    _worker = ever(chat, (_) {
      _updateFields(previous: previous);
      _updateUsersSubscriptions();
      previous = chat.value;
    });

    _messagesSubscription = messages.changes.listen((e) {
      switch (e.op) {
        case OperationKind.removed:
          _recalculateReadsFor(e.element.value);
          break;

        case OperationKind.added:
        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _callSubscription =
        StreamGroup.mergeBroadcast([
          _chatRepository.calls.changes,
          WebUtils.onStorageChange,
        ]).listen((_) {
          inCall.value =
              _chatRepository.calls[id] != null || WebUtils.containsCall(id);
        });

    await _draftGuard.protect(() async {
      draft.value = await _draftLocal.read(id);
    });
  }

  /// Disposes this [RxChatImpl].
  Future<void> dispose() async {
    Log.debug('dispose()', '$runtimeType($id)');

    _disposed = true;
    status.value = RxStatus.loading();
    messages.clear();
    reads.clear();
    members.dispose();
    _aroundToken.cancel();
    _muteTimer?.cancel();
    _readTimer?.cancel();
    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = null;
    _localSubscription?.cancel();
    _localSubscription = null;
    _draftSubscription?.cancel();
    _draftSubscription = null;
    _paginationSubscription?.cancel();
    _pagination?.dispose();
    _messagesSubscription?.cancel();
    _callSubscription?.cancel();
    _membersPaginationSubscription?.cancel();
    status.value = RxStatus.empty();
    _worker?.dispose();
    _userWorker?.dispose();

    for (StreamSubscription s in _userSubscriptions.values) {
      s.cancel();
    }
    for (var e in fragments.toList()) {
      e.dispose();
    }
    for (final s in _fragmentSubscriptions) {
      s.cancel();
    }
    for (var e in _attachments.toList()) {
      e.dispose();
    }
  }

  @override
  Future<void> ensureDraft() async {
    Log.debug('ensureDraft()', '$runtimeType($id)');

    if (_draftGuard.isLocked) {
      await _draftGuard.protect(() async {});
    }
  }

  @override
  Future<void> setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  }) async {
    Log.debug('setDraft($text, $attachments, $repliesTo)', '$runtimeType($id)');

    await _draftGuard.protect(() async {
      ChatMessage? draft = await _draftLocal.read(id);

      if (text == null && attachments.isEmpty && repliesTo.isEmpty) {
        if (draft != null) {
          await _draftLocal.delete(id);
        }
      } else {
        final bool repliesEqual = const IterableEquality().equals(
          (draft?.repliesTo ?? []).map((e) => e.original?.id),
          repliesTo.map((e) => e.id),
        );

        final bool attachmentsEqual = const IterableEquality().equals(
          (draft?.attachments ?? []).map((e) => [e.id, e.runtimeType]),
          attachments.map((e) => [e.id, e.runtimeType]),
        );

        if (draft?.text != text || !repliesEqual || !attachmentsEqual) {
          draft = ChatMessage(
            ChatItemId.local(),
            id,
            User(me ?? const UserId('dummy'), UserNum('1234123412341234')),
            PreciseDateTime.now(),
            text: text,
            repliesTo: repliesTo.map((e) => ChatItemQuote.from(e)).toList(),
            attachments: attachments,
          );
          _draftLocal.upsert(id, draft);
        }
      }
    });
  }

  @override
  Future<Paginated<ChatItemId, Rx<ChatItem>>?> around({
    ChatItemId? item,
    ChatItemId? reply,
    ChatItemId? forward,
    ChatMessageText? withText,
  }) async {
    Log.debug(
      'around(item: $item, reply: $reply, forward: $forward, withText: $withText)',
      '$runtimeType($id)',
    );

    // If [withText] is not `null`, then search the items with it.
    if (withText != null) {
      return _searchItems(withText);
    }

    // Even if the [item] is within [_local], still create a [MessageFragment],
    // at it handles such cases as well.
    if (item != null) {
      return _paginateAround(item, reply: reply, forward: forward);
    }

    if (id.isLocal || (hasNext.isFalse && hasPrevious.isFalse)) {
      return null;
    }

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    // TODO: Perhaps the [messages] should be in a [MessagesPaginated] as well?
    //       This will make it easy to dispose the messages, when they aren't
    //       needed, so that RAM is freed.
    await _pagination?.around(
      cursor: _lastReadItemCursor,
      key: _lastReadItemKey ?? chat.value.lastReadItem,
    );

    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);

    return null;
  }

  @override
  Future<Paginated<ChatItemId, Rx<ChatItem>>?> single(ChatItemId item) async {
    Log.debug('single($item)', '$runtimeType($id)');
    return await _paginateAround(item, perPage: 1);
  }

  @override
  Future<void> next() async {
    Log.debug('next()', '$runtimeType($id)');

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    await _pagination?.next();
    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);
  }

  @override
  Future<void> previous() async {
    Log.debug('previous()', '$runtimeType($id)');

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    await _pagination?.previous();
    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);
  }

  @override
  Future<void> updateAttachments(ChatItem item) async {
    Log.debug('updateAttachments($item)', '$runtimeType($id)');

    if (item.id.isLocal) {
      return;
    }

    Mutex? mutex = _attachmentGuards[item.id];
    if (mutex == null) {
      mutex = Mutex();
      _attachmentGuards[item.id] = mutex;
    }

    final bool isLocked = mutex.isLocked;
    await mutex.protect(() async {
      if (isLocked) {
        // Mutex has been already locked when tried to obtain it, thus the
        // [Attachment]s of the [item] were already updated, so no action is
        // required.
        return;
      }

      await _updateAttachments(item.id, item: item);
      _attachmentGuards.remove(item.id);
    });
  }

  /// Marks this [RxChat] as read until the provided [ChatItem] for the
  /// authenticated [MyUser],
  Future<void> read(ChatItemId untilId) async {
    Log.debug('read($untilId)', '$runtimeType($id)');

    if (untilId.isLocal) {
      return;
    }

    int firstUnreadIndex = 0;

    if (firstUnread != null) {
      firstUnreadIndex = messages.indexOf(firstUnread!);
    }

    int lastReadIndex = messages.indexWhere(
      (m) => m.value.id == untilId,
      firstUnreadIndex,
    );

    if (lastReadIndex != -1 && firstUnreadIndex != -1) {
      int read = messages
          .skip(firstUnreadIndex)
          .take(lastReadIndex - firstUnreadIndex + 1)
          .where((e) => !e.value.id.isLocal && e.value.author.id != me)
          .length;
      unreadCount.value = chat.value.unreadCount - read;
    }

    final ChatItemId? lastReadItem = chat.value.lastReadItem;
    if (lastReadItem != untilId) {
      chat.update((e) => e?..lastReadItem = untilId);

      _readTimer?.cancel();
      _readTimer = AwaitableTimer(
        chat.value.lastItem?.id == untilId
            ? Duration.zero
            : const Duration(seconds: 1),
        () async {
          try {
            await _chatRepository.readUntil(id, untilId);

            _lastReadItemKey = untilId;
            chat.value.lastReadItem = untilId;
            dto.value.lastReadItem = untilId;

            final DtoChatItem? item = await _driftItems.read(untilId);

            _lastReadItemCursor =
                item?.cursor ?? _lastReadItemCursor ?? dto.lastReadItemCursor;
            dto.lastReadItemCursor = _lastReadItemCursor;
          } on ReadChatException catch (e) {
            switch (e.code) {
              case ReadChatErrorCode.unknownChat:
                await _chatRepository.remove(id);
                break;

              case ReadChatErrorCode.unknownChatItem:
                if (!untilId.isLocal) {
                  await remove(untilId);
                }
                break;

              case ReadChatErrorCode.artemisUnknown:
                rethrow;
            }
          } catch (_) {
            chat.update((e) => e?..lastReadItem = lastReadItem);
            unreadCount.value = chat.value.unreadCount;
            rethrow;
          } finally {
            _readTimer = null;
          }
        },
      );

      await _readTimer?.future;
    }
  }

  /// Posts a new [ChatMessage] to the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// For the posted [ChatMessage] to be meaningful, at least one of [text] or
  /// [attachments] arguments must be specified and non-empty.
  ///
  /// Specify [repliesTo] argument if the posted [ChatMessage] is going to be a
  /// reply to some other [ChatItem].
  Future<ChatItem> postChatMessage({
    ChatItemId? existingId,
    PreciseDateTime? existingDateTime,
    ChatMessageText? text,
    List<Attachment>? attachments,
    List<ChatItem> repliesTo = const [],
  }) async {
    Log.debug(
      'postChatMessage($existingId, $existingDateTime, $text, $attachments, $repliesTo)',
      '$runtimeType($id)',
    );

    DtoChatMessage message = DtoChatMessage.sending(
      chatId: chat.value.id,
      me: me!,
      text: text,
      repliesTo: repliesTo.map((e) => ChatItemQuote.from(e)).toList(),
      attachments: attachments ?? [],
      existingId: existingId,
      existingDateTime: existingDateTime,
    );

    // Storing the already stored [ChatMessage] is meaningless as it creates
    // lag spikes, so update it's reactive value directly.
    if (existingId != null) {
      final Rx<ChatItem>? existing = messages.firstWhereOrNull(
        (e) => e.value.id == existingId,
      );
      existing?.value = message.value;
    } else {
      put(message);
    }

    // If the [ChatMessage] being posted is local, then no remote queries should
    // be performed, so return the constructed item right away.
    if (id.isLocal) {
      return message.value;
    }

    _pending.add(message.value);

    try {
      if (attachments != null) {
        final List<Future> uploads = attachments
            .mapIndexed((i, e) {
              if (e is LocalAttachment) {
                return e.upload.value?.future.then(
                  (a) {
                    attachments[i] = a;

                    // Frequent writes of byte data freezes the Web page.
                    if (!PlatformUtils.isWeb) {
                      put(message);
                    }
                  },
                  onError: (_) {
                    // No-op, as failed upload attempts are handled below.
                  },
                );
              }
            })
            .nonNulls
            .toList();

        if (existingId == null) {
          final List<Future> reads = attachments
              .whereType<LocalAttachment>()
              .map((e) => e.read.value?.future)
              .nonNulls
              .toList();
          if (reads.isNotEmpty) {
            await Future.wait(reads);
            put(message);
          }
        }

        await Future.wait(uploads);
      }

      if (attachments?.whereType<LocalAttachment>().isNotEmpty == true) {
        throw const ConnectionException(
          PostChatMessageException(PostChatMessageErrorCode.unknownAttachment),
        );
      }

      try {
        final response = await _chatRepository.postChatMessage(
          id,
          text: text,
          attachments: attachments?.map((e) => e.id).toList(),
          repliesTo: repliesTo.map((e) => e.id).toList(),
        );

        final event =
            response?.events
                    .map((e) => _chatRepository.chatEvent(e))
                    .firstWhereOrNull((e) => e is EventChatItemPosted)
                as EventChatItemPosted?;

        if (event != null && event.item is DtoChatMessage) {
          remove(message.value.id);
          _pending.remove(message.value);
          message = event.item as DtoChatMessage;
        }
      } on PostChatMessageException catch (e) {
        switch (e.code) {
          case PostChatMessageErrorCode.blocked:
          case PostChatMessageErrorCode.noTextAndNoAttachment:
          case PostChatMessageErrorCode.wrongAttachmentsCount:
          case PostChatMessageErrorCode.wrongReplyingChatItemsCount:
          case PostChatMessageErrorCode.unknownAttachment:
          case PostChatMessageErrorCode.unknownReplyingChatItem:
          case PostChatMessageErrorCode.unknownUser:
          case PostChatMessageErrorCode.artemisUnknown:
            rethrow;

          case PostChatMessageErrorCode.unknownChat:
            await _chatRepository.remove(id);
            break;
        }
      }
    } catch (e) {
      message.value.status.value = SendingStatus.error;
      _pending.remove(message.value);
      rethrow;
    } finally {
      put(message);
    }

    return message.value;
  }

  /// Adds the provided [item] to the [Pagination]s.
  Future<void> put(DtoChatItem item, {bool ignoreBounds = false}) async {
    Log.debug('put($item)', '$runtimeType($id)');

    await _pagination?.put(item, ignoreBounds: ignoreBounds);
    for (var e in fragments) {
      await e.pagination?.put(item, ignoreBounds: ignoreBounds);
    }

    for (var e in _attachments) {
      await e.pagination?.put(item, ignoreBounds: ignoreBounds);
    }
  }

  @override
  Future<void> remove(ChatItemId itemId) async {
    Log.debug('remove($itemId)', '$runtimeType($id)');

    _pagination?.remove(itemId);
    for (var e in fragments) {
      e.pagination?.remove(itemId);
    }

    if (dto.value.lastItem?.id == itemId) {
      var lastItem = messages.lastWhereOrNull((e) => e.value.id != itemId);

      if (lastItem != null) {
        dto.value.lastItem = lastItem.value;
        dto.lastItemCursor = (await _driftItems.read(
          lastItem.value.id,
        ))?.cursor;
      } else {
        dto.value.lastItem = null;
        dto.lastItemCursor = null;
      }

      await _driftChat.upsert(dto);
    }
  }

  /// Returns the stored or fetched [DtoChatItem] identified by the provided
  /// [itemId].
  Future<DtoChatItem?> get(ChatItemId itemId) async {
    Log.debug('get($itemId)', '$runtimeType($id)');

    DtoChatItem? item = _pagination?.items[itemId];
    item ??= fragments
        .firstWhereOrNull((e) => e.pagination?.items[itemId] != null)
        ?.pagination
        ?.items[itemId];
    item ??= await _driftItems.read(itemId);

    if (item == null) {
      try {
        item = await _chatRepository.message(itemId);
      } catch (_) {
        // No-op.
      }

      if (item != null) {
        // Don't await [put] here, as [get] should react as quick as possible.
        //
        // Also this may cause deadlocks during fetching around a [ChatItem] in
        // [CommonDriftProvider].
        put(item);
      }
    }

    return item;
  }

  /// Recalculates the [reads] to represent the actual [messages].
  void updateReads() {
    Log.debug('updateReads()', '$runtimeType($id)');

    for (LastChatRead e in chat.value.lastReads) {
      _updateReadFor(e.memberId, e.at);
    }
  }

  /// Updates the [chat] and [chat]-related resources with the provided
  /// [newChat].
  Future<void> updateChat(DtoChat newChat) async {
    Log.debug('updateChat($newChat)', '$runtimeType($id)');

    if (chat.value.id != newChat.value.id) {
      dto = newChat;
      chat.value = newChat.value;
      ver = newChat.ver;

      _initLocalSubscription();

      if (!_controller.isPaused && !_controller.isClosed) {
        _initRemoteSubscription();
      }

      // Retrieve all the [DtoChatItem]s to put them in the [newChat].
      final Iterable<DtoChatItem> saved = _pagination!.items.values.toList(
        growable: false,
      );

      await clear();

      for (var e in saved.whereType<DtoChatMessage>()) {
        // Copy the [DtoChatMessage] to the new [Pagination].
        final DtoChatMessage copy = e.copyWith()
          ..value.chatId = newChat.value.id;

        if (copy.value.status.value == SendingStatus.error) {
          copy.value.status.value = SendingStatus.sending;
        }

        await put(copy, ignoreBounds: true);
      }

      await _initMessagesPagination();
      await _pagination?.around();
    }
  }

  /// Clears the [_pagination] and [fragments].
  Future<void> clear() async {
    Log.debug('clear()', '$runtimeType($id)');

    for (var e in fragments) {
      e.dispose();
    }
    fragments.clear();

    await _pagination?.clear();

    // [Chat.members] don't change in dialogs or monologs, no need to clear it.
    if (chat.value.isGroup) {
      await members.clear();
    }
  }

  /// Updates the [avatar] of the [chat].
  ///
  /// Intended to be used to update the [StorageFile.relativeRef] links.
  @override
  Future<void> updateAvatar() async {
    Log.debug('updateAvatar()', '$runtimeType($id)');

    final ChatAvatar? avatar = await _chatRepository.avatar(id);

    dto.value.avatar = avatar;

    // TODO: Avatar should be updated by local subscription.
    this.avatar.value = avatar;

    await _driftChat.upsert(dto);
  }

  @override
  Paginated<ChatItemId, Rx<ChatItem>> attachments({ChatItemId? item}) {
    Log.debug('attachments(item: $item)', '$runtimeType($id)');

    ChatItemsCursor? cursor;
    ChatItemId? key = item;

    if (item != null) {
      final DtoChatItem? dto = _pagination?.items[item];
      cursor = dto?.cursor;
    }

    AttachmentsPaginated? fragment;

    _attachments.add(
      fragment = AttachmentsPaginated(
        initialKey: key,
        initialCursor: cursor,
        transform: ({required DtoChatItem data, Rx<ChatItem>? previous}) {
          if (previous != null) {
            return previous..value = data.value;
          }

          return Rx(data.value);
        },
        pagination: Pagination(
          onKey: (e) => e.value.id,
          fulfilled: (edges) {
            return edges.any((e) {
              if (e.value is ChatMessage) {
                final msg = e.value as ChatMessage;

                return msg.attachments.any((a) {
                  if (a is ImageAttachment) {
                    return true;
                  } else if (a is FileAttachment) {
                    return a.isVideo;
                  } else if (a is LocalAttachment) {
                    return a.file.isImage || a.file.isSvg || a.file.isVideo;
                  }

                  return false;
                });
              }

              return false;
            });
          },
          provider: DriftGraphQlPageProvider(
            graphQlProvider: GraphQlPageProvider(
              reversed: true,
              fetch: ({after, before, first, last}) async {
                if (id.isLocal) {
                  return Page([], PageInfo());
                }

                final Page<DtoChatItem, ChatItemsCursor> reversed =
                    await _chatRepository.messages(
                      chat.value.id,
                      after: after,
                      first: first,
                      before: before,
                      last: last,
                      onlyAttachments: true,
                    );

                return reversed;
              },
            ),
            driftProvider: DriftPageProvider(
              fetch:
                  ({
                    required after,
                    required before,
                    ChatItemId? around,
                  }) async {
                    PreciseDateTime? at;

                    if (around != null) {
                      final DtoChatItem? item = await get(around);
                      at = item?.value.at;
                    }

                    return await _driftItems.attachments(
                      id,
                      before: before,
                      after: after,
                      around: at,
                    );
                  },
              onKey: (e) => e.value.id,
              onCursor: (e) => e?.cursor,
              isFirst: (e, _) {
                if (e.value.id.isLocal) {
                  return null;
                }

                return chat.value.firstItem?.id == e.value.id;
              },
              isLast: (e, _) {
                if (e.value.id.isLocal) {
                  return null;
                }

                return chat.value.lastItem?.id == e.value.id;
              },
              compare: (a, b) => a.value.key.compareTo(b.value.key),
            ),
          ),
          compare: (a, b) => a.value.key.compareTo(b.value.key),
          perPage: 10,
        ),
        onDispose: () {
          _attachments.remove(fragment);
        },
      ),
    );

    return fragment;
  }

  @override
  int compareTo(RxChat other) => chat.value.compareTo(other.chat.value, me);

  @override
  String toString() =>
      'RxChatImpl($chat, ${messages.length} messages, ${members.length} members, $unreadCount unread)';

  /// Puts the provided [member] to the [members].
  Future<void> _putMember(DtoChatMember member, {bool ignoreBounds = false}) =>
      members.put(member, ignoreBounds: ignoreBounds);

  /// Initializes the messages [_pagination].
  Future<void> _initMessagesPagination() async {
    _pagination?.dispose();
    _pagination = Pagination(
      onKey: (e) => e.value.id,
      provider: DriftGraphQlPageProvider(
        graphQlProvider: GraphQlPageProvider(
          reversed: true,
          fetch: ({after, before, first, last}) async {
            if (id.isLocal) {
              return Page([], PageInfo());
            }

            final Page<DtoChatItem, ChatItemsCursor> reversed =
                await _chatRepository.messages(
                  chat.value.id,
                  after: after,
                  first: first,
                  before: before,
                  last: last,
                );

            final Page<DtoChatItem, ChatItemsCursor> page = reversed.reversed();

            if (page.info.hasPrevious == false) {
              // [PageInfo.hasPrevious] is `false`, when querying `before` only.
              if (before == null || after != null) {
                final ChatItem? firstItem = page.edges.firstOrNull?.value;

                if (firstItem != null && dto.value.firstItem != firstItem) {
                  dto.value.firstItem = firstItem;
                  await _driftChat.upsert(dto);
                }
              }
            }

            return reversed;
          },
        ),
        driftProvider: DriftPageProvider(
          fetch: ({int? after, int? before, ChatItemId? around}) async {
            PreciseDateTime? at;

            if (around != null) {
              final DtoChatItem? item = await get(around);
              at = item?.value.at;
            }

            return await _driftItems.view(
              id,
              before: before,
              after: after,
              around: at,
            );
          },
          watch: ({int? after, int? before, ChatItemId? around}) async {
            PreciseDateTime? at;

            if (around != null) {
              final DtoChatItem? item = await get(around);
              at = item?.value.at;
            }

            return _driftItems.watch(
              id,
              before: before,
              after: after,
              around: at,
            );
          },
          onAdded: (e) async {
            // If this [ChatItem] is stuck at `sending` status, then it's
            // probably won't finish, thus mark this message as errored.
            if (e.value.status.value == SendingStatus.sending) {
              e.value.status.value = SendingStatus.error;
            }

            await _pagination?.put(e, store: false);
          },
          onRemoved: (e) async {
            await _pagination?.remove(e.value.id, store: false);
          },
          onKey: (e) => e.value.id,
          onCursor: (e) => e?.cursor,
          add: (e, {bool toView = true}) async =>
              await _driftItems.upsertBulk(e, toView: toView),
          delete: (e) async => await _driftItems.delete(e),
          reset: () async => await _driftItems.clear(),
          isFirst: (e, _) {
            if (e.value.id.isLocal) {
              return null;
            }

            return chat.value.firstItem?.id == e.value.id;
          },
          isLast: (e, _) {
            if (e.value.id.isLocal) {
              return null;
            }

            return chat.value.lastItem?.id == e.value.id;
          },
          onNone: (k) async => await _driftItems.upsertView(id, k),
          compare: (a, b) => a.value.key.compareTo(b.value.key),
        ),
      ),
      compare: (a, b) => a.value.key.compareTo(b.value.key),
    );

    if (id.isLocal) {
      _pagination?.hasNext.value = false;
      _pagination?.hasPrevious.value = false;
      status.value = RxStatus.success();
    }

    _paginationSubscription?.cancel();
    _paginationSubscription = _pagination?.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          _add(event.value!.value);
          break;

        case OperationKind.removed:
          messages.removeWhere((e) => e.value.id == event.value?.value.id);
          break;
      }
    });

    DtoChatItem? item;

    if (chat.value.lastReadItem != null) {
      item = await get(chat.value.lastReadItem!);
      await _pagination?.init(
        chat.value.lastReadItem == chat.value.lastItem?.id
            ? null
            : item?.value.id,
      );
    }

    if (_pagination?.items.isNotEmpty == true) {
      status.value = RxStatus.success();
    }
  }

  /// Initializes the [members] pagination.
  Future<void> _initMembersPagination() async {
    members = MembersPaginated(
      transform: ({required DtoChatMember data, RxChatMember? previous}) {
        final FutureOr<RxUser?> userOrFuture = _chatRepository.getUser(data.id);

        if (userOrFuture is RxUser) {
          return RxChatMember(userOrFuture, data.joinedAt);
        } else {
          return Future(() async {
            final RxUser? user = await userOrFuture;

            if (user != null) {
              return RxChatMember(user, data.joinedAt);
            }

            return null;
          });
        }
      },
      pagination: Pagination(
        onKey: (e) => e.id,
        perPage: 15,
        provider: DriftGraphQlPageProvider(
          driftProvider: DriftPageProvider(
            fetch: ({required after, required before, UserId? around}) async {
              return await _driftMembers.members(id, limit: before + after);
            },
            onCursor: (DtoChatMember? item) => item?.cursor,
            onKey: (DtoChatMember item) => item.id,
            add: (e, {bool toView = true}) async =>
                await _driftMembers.upsertBulk(id, e),
            delete: (e) async => await _driftMembers.delete(id, e),
            reset: () async => await _driftMembers.clear(),
            isFirst: (_, i) => i >= chat.value.membersCount,
            isLast: (_, i) => i >= chat.value.membersCount,
            compare: (a, b) => a.compareTo(b),
          ),
          graphQlProvider:
              GraphQlPageProvider<DtoChatMember, ChatMembersCursor, UserId>(
                fetch: ({after, before, first, last}) async {
                  if (id.isLocal) {
                    return Page([], PageInfo());
                  }

                  return _chatRepository.members(
                    chat.value.id,
                    after: after,
                    first: first,
                    before: before,
                    last: last,
                  );
                },
              ),
        ),
        compare: (a, b) => a.compareTo(b),
      ),
    );

    // [Chat] always contains first 3 members (due to GraphQL query specifying
    // those in the fragment), so we can immediately put them.
    if (chat.value.members.isNotEmpty || id.isLocal) {
      for (ChatMember member in chat.value.members) {
        _putMember(
          DtoChatMember(member.user, member.joinedAt, null),
          ignoreBounds: true,
        );
      }

      if (members.rawLength == chat.value.membersCount) {
        members.pagination?.hasNext.value = false;
        members.pagination?.hasPrevious.value = false;
        members.status.value = RxStatus.success();
      }
    }
  }

  /// Constructs a [MessagesPaginated] around the specified [item], [reply] or
  /// [forward].
  Future<MessagesPaginated> _paginateAround(
    ChatItemId item, {
    ChatItemId? reply,
    ChatItemId? forward,
    int perPage = 50,
  }) async {
    Log.debug('_paginateAround($item, $reply, $forward)', '$runtimeType($id)');

    // Retrieve the [item] itself pointed around.
    final DtoChatItem? dto = await get(item);

    final ChatItemsCursor? cursor;
    final ChatItemId key = forward ?? reply ?? item;

    // If [reply] or [forward] is provided, then the [item] should contain it,
    // let's try to retrieve the key and cursor to paginate around it.
    if (reply != null) {
      if (dto is! DtoChatMessage) {
        throw ArgumentError.value(
          item,
          'item',
          'Should be `ChatMessage`\'s ID, if `reply` is provided.',
        );
      }

      final ChatMessage message = dto.value as ChatMessage;
      final int replyIndex = message.repliesTo.indexWhere(
        (e) => e.original?.id == reply,
      );
      if (replyIndex == -1) {
        throw ArgumentError.value(reply, 'reply', 'Not found.');
      }

      cursor = dto.repliesToCursors?.elementAt(replyIndex);
    } else if (forward != null) {
      if (dto is! DtoChatForward) {
        throw ArgumentError.value(
          item,
          'item',
          'Should be `ChatForward`\'s ID, if `forward` is provided.',
        );
      }

      cursor = dto.quoteCursor;
    } else {
      cursor = dto?.cursor;
    }

    // Try to find any [MessagesPaginated] already containing the item requested.
    MessagesPaginated? fragment = fragments.firstWhereOrNull(
      // Single-item fragments shouldn't be used to display messages in
      // pagination, as such fragments used only for [single]s.
      (e) => e.items[key] != null && e.items.length > 1,
    );

    // If found, then return it, or otherwise construct a new one.
    if (fragment != null) {
      return fragment;
    }

    if (cursor == null) {
      throw ArgumentError.value(item, 'item', 'Cursor not found.');
    }

    StreamSubscription? subscription;
    Timer? debounce;

    fragments.add(
      fragment = MessagesPaginated(
        initialKey: key,
        initialCursor: cursor,
        transform: ({required DtoChatItem data, Rx<ChatItem>? previous}) {
          if (previous != null) {
            return previous..value = data.value;
          }

          return Rx(data.value);
        },
        pagination: Pagination(
          onKey: (e) => e.value.id,
          provider: GraphQlPageProvider(
            reversed: true,
            fetch: ({after, before, first, last}) async {
              if (id.isLocal) {
                return Page([], PageInfo());
              }

              final Page<DtoChatItem, ChatItemsCursor> reversed =
                  await _chatRepository.messages(
                    chat.value.id,
                    after: after ?? before,
                    first: first,
                    before: before ?? after,
                    last: last,
                  );

              return reversed;
            },
          ),
          perPage: perPage,
          compare: (a, b) => a.value.key.compareTo(b.value.key),
        ),
        onDispose: () {
          fragments.remove(fragment);
          _fragmentSubscriptions.remove(subscription);
          subscription?.cancel();
          debounce?.cancel();
        },
      ),
    );

    _fragmentSubscriptions.add(
      subscription = fragment.items.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
          case OperationKind.updated:
            debounce?.cancel();

            // Debounce the [updateReads], when [event]s are adding items
            // rapidly.
            debounce = Timer(1.milliseconds, updateReads);
            break;

          case OperationKind.removed:
            _recalculateReadsFor(event.value!.value);
            break;
        }
      }),
    );

    return fragment;
  }

  /// Constructs a [MessagesPaginated] searching the [ChatItem]s containing the
  /// provided [text].
  Future<MessagesPaginated> _searchItems(
    ChatMessageText text, {
    int perPage = 50,
  }) async {
    Log.debug('_searchItems($text)', '$runtimeType($id)');

    MessagesPaginated? fragment;
    StreamSubscription? subscription;
    Timer? debounce;

    fragments.add(
      fragment = MessagesPaginated(
        transform: ({required DtoChatItem data, Rx<ChatItem>? previous}) {
          if (previous != null) {
            return previous..value = data.value;
          }

          return Rx(data.value);
        },
        pagination: Pagination(
          onKey: (e) => e.value.id,
          provider: DriftGraphQlPageProvider(
            graphQlProvider: GraphQlPageProvider(
              reversed: true,
              fetch: ({after, before, first, last}) async {
                if (id.isLocal) {
                  return Page([], PageInfo());
                }

                final Page<DtoChatItem, ChatItemsCursor> reversed =
                    await _chatRepository.messages(
                      chat.value.id,
                      after: after,
                      first: first,
                      before: before,
                      last: last,
                      withText: text,
                    );

                return reversed;
              },
            ),
            driftProvider: DriftPageProvider(
              fetch:
                  ({
                    required after,
                    required before,
                    ChatItemId? around,
                  }) async {
                    PreciseDateTime? at;

                    if (around != null) {
                      final DtoChatItem? item = await get(around);
                      at = item?.value.at;
                    }

                    return await _driftItems.view(
                      id,
                      before: before,
                      after: after,
                      around: at,
                      withText: text,
                    );
                  },
              onKey: (e) => e.value.id,
              onCursor: (e) => e?.cursor,
              isFirst: (e, _) {
                if (e.value.id.isLocal) {
                  return null;
                }

                return chat.value.firstItem?.id == e.value.id;
              },
              isLast: (e, _) {
                if (e.value.id.isLocal) {
                  return null;
                }

                return chat.value.lastItem?.id == e.value.id;
              },
              compare: (a, b) => a.value.key.compareTo(b.value.key),
            ),
          ),
          perPage: perPage,
          compare: (a, b) => a.value.key.compareTo(b.value.key),
        ),
        onDispose: () {
          fragments.remove(fragment);
          _fragmentSubscriptions.remove(subscription);
          subscription?.cancel();
          debounce?.cancel();
        },
      ),
    );

    _fragmentSubscriptions.add(
      subscription = fragment.items.changes.listen((event) {
        switch (event.op) {
          case OperationKind.added:
          case OperationKind.updated:
            debounce?.cancel();

            // Debounce the [updateReads], when [event]s are adding items
            // rapidly.
            debounce = Timer(1.milliseconds, updateReads);
            break;

          case OperationKind.removed:
            _recalculateReadsFor(event.value!.value);
            break;
        }
      }),
    );

    return fragment;
  }

  /// Adds the provided [ChatItem] to the [messages] list.
  void _add(ChatItem item) {
    final int i = messages.indexWhere((e) => e.value.id == item.id);

    Log.debug('_add($item) at i = $i', '$runtimeType($id)');

    if (i == -1) {
      messages.insertAfter(
        Rx(item),
        (e) => item.key.compareTo(e.value.key) == 1,
      );
    } else {
      messages[i].value = item;
      messages[i].refresh();
    }
  }

  /// Updates the [avatar] and [unreadCount] fields based on the [chat] state.
  void _updateFields({Chat? previous}) {
    Log.trace('_updateFields($previous)', '$runtimeType($id)');

    if (!chat.value.isDialog) {
      avatar.value = chat.value.avatar;
    }

    _muteTimer?.cancel();
    if (chat.value.muted?.until != null) {
      _muteTimer = Timer(
        chat.value.muted!.until!.val.difference(DateTime.now()),
        () async => await _driftChat.upsert(dto..value.muted = null),
      );
    }

    // Sync the [unreadCount], if [chat] has less, or is different, and there's
    // no [ChatRepository.readUntil] being executed ([_readTimer] is `null`).
    if (chat.value.unreadCount < unreadCount.value ||
        (chat.value.unreadCount != previous?.unreadCount &&
            _readTimer == null)) {
      unreadCount.value = chat.value.unreadCount;
    }
  }

  /// Updates the [_userSubscriptions].
  void _updateUsersSubscriptions() {
    switch (chat.value.kind) {
      case ChatKind.dialog:
        final RxUser? rxUser = members.values
            .firstWhereOrNull((u) => u.user.id != me)
            ?.user;

        if (rxUser != null) {
          if (_userSubscriptions[rxUser.id] == null) {
            _userSubscriptions[rxUser.id] = rxUser.updates.listen((_) {});
          }
        }
        break;

      case ChatKind.group:
        if (chat.value.name != null) {
          _userSubscriptions.removeWhere((k, v) {
            v.cancel();
            return true;
          });
        } else {
          final users = members.values.take(3).map((e) => e.user).toList();

          final bool membersEqual = const IterableEquality().equals(
            _userSubscriptions.keys,
            users.map((e) => e.id),
          );

          if (!membersEqual) {
            _userSubscriptions.removeWhere((k, v) {
              if (users.none((u) => u.id == k)) {
                v.cancel();
                return true;
              }

              return false;
            });

            for (final e in users) {
              if (_userSubscriptions[e.id] == null) {
                _userSubscriptions[e.id] = e.updates.listen((_) {});
              }
            }
          }
        }
        break;

      case ChatKind.monolog:
      case ChatKind.artemisUnknown:
        // No-op.
        break;
    }
  }

  /// Updates the [avatar].
  void _updateAvatar() {
    Log.debug('_updateAvatar()', '$runtimeType($id)');

    RxUser? member;

    switch (chat.value.kind) {
      case ChatKind.dialog:
        member = members.values.firstWhereOrNull((e) => e.user.id != me)?.user;
        break;

      case ChatKind.group:
      case ChatKind.monolog:
        avatar.value = chat.value.avatar;
        break;

      case ChatKind.artemisUnknown:
        // No-op.
        break;
    }

    if (member != null) {
      avatar.value = member.user.value.avatar;
      _userWorker?.dispose();
      _userWorker = ever(member.user, (User u) => avatar.value = u.avatar);
    }
  }

  /// Recalculates the [LastChatRead]s pointing at the [item], if any.
  ///
  /// Should be called when a [ChatItem] is removed from the [messages] or the
  /// [MessagesPaginated.items].
  void _recalculateReadsFor(ChatItem item) {
    for (LastChatRead i in reads) {
      if (item.at == i.at) {
        i.at = _lastReadAt(i.at) ?? i.at;
      }
    }
  }

  /// Returns the [ChatItem.at] being the predecessor of the provided [at].
  PreciseDateTime? _lastReadAt(PreciseDateTime at) {
    Log.debug('_lastReadAt($at)', '$runtimeType($id)');

    PreciseDateTime? lastReadAt = _lastReadAmong(
      at,
      messages: messages,
      hasNext: hasNext.isTrue,
    );

    for (var fragment in fragments) {
      lastReadAt ??= _lastReadAmong(
        at,
        messages: fragment.items.values,
        hasNext: fragment.hasNext.isTrue,
      );
    }

    return lastReadAt;
  }

  /// Returns the [ChatItem.at] being the predecessor of the provided [at] in
  /// the provided [messages] list.
  PreciseDateTime? _lastReadAmong(
    PreciseDateTime at, {
    required Iterable<Rx<ChatItem>> messages,
    required bool hasNext,
  }) {
    Log.debug('_lastReadAmong($at)', '$runtimeType($id)');

    messages = messages.sortedBy((e) => e.value.at);

    final Rx<ChatItem>? message = messages.lastWhereOrNull(
      (e) => e.value is! ChatInfo && e.value.at <= at,
    );

    // Return `null` if [hasNext] because the provided [at] can be actually
    // connected to another [message].
    if (message == null || hasNext && messages.last == message) {
      return null;
    } else {
      return message.value.at;
    }
  }

  /// Re-fetches the [Attachment]s of the specified [itemId] to be up-to-date.
  Future<void> _updateAttachments(ChatItemId itemId, {ChatItem? item}) async {
    Log.debug('_updateAttachments($itemId)', '$runtimeType($id)');

    final DtoChatItem? stored = await get(itemId);
    if (stored != null) {
      item ??= stored.value;

      final List<Attachment> response = await _chatRepository.attachments(
        stored.value.id,
      );

      void replace(Attachment a) {
        final Attachment? fetched = response.firstWhereOrNull(
          (e) => e.id == a.id,
        );
        if (fetched != null) {
          a.original = fetched.original;
          if (a is ImageAttachment && fetched is ImageAttachment) {
            a.big = fetched.big;
            a.medium = fetched.medium;
            a.small = fetched.small;
          }
        }
      }

      final List<Attachment> all = [];

      if (item is ChatMessage) {
        all.addAll(item.attachments);
        for (ChatItemQuote replied in item.repliesTo) {
          if (replied is ChatMessageQuote) {
            all.addAll(replied.attachments);
          }
        }
      } else if (item is ChatForward) {
        final ChatItemQuote nested = item.quote;
        if (nested is ChatMessageQuote) {
          all.addAll(nested.attachments);

          if (nested.original != null) {
            for (ChatItemQuote replied
                in (nested.original as ChatMessage).repliesTo) {
              if (replied is ChatMessageQuote) {
                all.addAll(replied.attachments);
              }
            }
          }
        }
      }

      for (Attachment a in all) {
        replace(a);
      }

      stored.value = item;
      put(stored);
    }
  }

  /// Recalculates the [LastChatRead] for the provided [readId] member.
  void _updateReadFor(UserId readId, PreciseDateTime readAt) {
    final PreciseDateTime? at = _lastReadAt(readAt);
    if (at != null) {
      final LastChatRead? read = reads.firstWhereOrNull(
        (e) => e.memberId == readId,
      );

      final RxChatMember? member = members.values.firstWhereOrNull(
        (e) => e.user.id == readId,
      );

      // Only proceed, if the [ChatMember] this event represents
      // joined earlier than latest acquired message.
      if (member?.joinedAt.isAfter(at) != true) {
        if (read == null) {
          reads.add(LastChatRead(readId, at));
        } else {
          read.at = at;
          reads.refresh();
        }
      }
    }
  }

  /// Initializes the [_localSubscription].
  void _initLocalSubscription() {
    _localSubscription?.cancel();
    _localSubscription = _driftChat.watch(id).listen((db) {
      if (db != null && db.ver > dto.ver) {
        _setChat(db, false);
      }
    });
  }

  /// Updates the reactive [chat] to the provided [DtoChat], if any.
  DtoChat? _setChat(DtoChat? e, [bool anyway = true]) {
    if (!anyway) {
      if (dto.value == e?.value) {
        return null;
      }

      dto = e ?? dto;
    } else {
      dto = e ?? dto;

      if (chat.value == e?.value) {
        chat.refresh();
        return null;
      }
    }

    Log.trace('_setChat($e)', '$runtimeType');

    if (e != null) {
      final ChatItem? first = chat.value.firstItem;

      final bool positionChanged =
          e.value.favoritePosition != chat.value.favoritePosition;

      chat.value = e.value.copyWith();
      chat.value.firstItem = first ?? chat.value.firstItem;
      _lastReadItemCursor = e.lastReadItemCursor ?? _lastReadItemCursor;
      _lastReadItemKey = e.value.lastReadItem ?? _lastReadItemKey;
      ver = e.ver;

      if (positionChanged) {
        _chatRepository.paginated.emit(
          MapChangeNotification.updated(id, id, this),
        );
      }
    }

    return e;
  }

  /// Initializes the [_draftSubscription].
  void _initDraftSubscription() {
    _draftSubscription?.cancel();
    _draftSubscription = _draftLocal.watch(id).listen((e) => draft.value = e);
  }

  /// Initializes [ChatRepository.chatEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    if (_disposed) {
      return;
    }

    Log.debug('_initRemoteSubscription()', '$runtimeType($id)');

    if (!id.isLocal) {
      _remoteSubscription?.close(immediate: true);

      await WebUtils.protect(() async {
        if (ver != null) {
          _justSubscribed = true;
          _eventsDebounce = debounce(_debouncedEvents, (events) {
            if (_eventsDebounce?.disposed == false) {
              Log.debug(
                '_initRemoteSubscription(): debounced with ${events.expand((e) => e.events).map((e) => e.kind)}',
                '$runtimeType($id)',
              );

              _eventsDebounce?.dispose();
              _eventsDebounce = null;
              _justSubscribed = false;

              if (events.isNotEmpty) {
                _chatEvent(
                  ChatEventsEvent(
                    ChatEventsVersioned(
                      events.expand((e) => e.events).toList(),
                      events.first.ver,
                    ),
                  ),
                );
              }
            }
          });
        }

        _remoteSubscription = StreamQueue(
          _chatRepository.chatEvents(id, ver, () => ver),
        );

        await _remoteSubscription!.execute(
          _chatEvent,
          onError: (e) async {
            if (e is StaleVersionException) {
              await clear();
              await _pagination?.around(cursor: _lastReadItemCursor);
            }
          },
        );
      }, tag: 'chatEvents($id)');

      _remoteSubscription = null;
    }
  }

  /// Handles [ChatEvent]s from the [ChatRepository.chatEvents] subscription.
  Future<void> _chatEvent(ChatEvents event) async {
    switch (event.kind) {
      case ChatEventsKind.initialized:
        Log.debug('_chatEvent(${event.kind})', '$runtimeType($id)');
        break;

      case ChatEventsKind.chat:
        Log.debug('_chatEvent(${event.kind})', '$runtimeType($id)');
        final node = event as ChatEventsChat;
        dto.value = node.chat.value;
        dto.ver = node.chat.ver;
        ver = node.chat.ver;
        await _driftChat.upsert(dto);

        _lastReadItemCursor = node.chat.lastReadItemCursor;
        break;

      case ChatEventsKind.event:
        final List<DtoChatItem> itemsToPut = [];

        final ChatEventsVersioned versioned = (event as ChatEventsEvent).event;
        if (!subscribed) {
          Log.debug(
            '_chatEvent(${event.kind}): ignored ${versioned.events.map((e) => e.kind)}, because: ${!subscribed}',
            '$runtimeType($id)',
          );

          return;
        }

        if (_justSubscribed) {
          Log.debug(
            '_chatEvent(${event.kind}): added to debounced ${versioned.events.map((e) => e.kind)}',
            '$runtimeType($id)',
          );
          _debouncedEvents.add(versioned);
          return;
        }

        Log.debug(
          '_chatEvent(${event.kind}): ${versioned.events.map((e) => e.kind)}',
          '$runtimeType($id)',
        );

        bool shouldPutChat = subscribed && versioned.ver >= dto.ver;

        // Version ending with zeros mean it was received and persisted via
        // remote pagination.
        bool versionAccounted =
            versioned.ver > (ver ?? dto.ver) &&
            (ver ?? dto.ver).val.endsWith('000000000');

        ver = versioned.ver;
        if (dto.ver < versioned.ver) {
          dto.ver = versioned.ver;
        }

        // Marks the [DtoChat] as needed to be written to the database.
        void write(void Function(DtoChat) handle) {
          handle(dto);
          shouldPutChat = true;
        }

        for (var event in versioned.events) {
          // Subscription was already disposed while processing the events.
          if (!subscribed) {
            return;
          }

          switch (event.kind) {
            case ChatEventKind.redialed:
              event as EventChatCallMemberRedialed;
              _chatRepository.addCall(event.call);
              break;

            case ChatEventKind.cleared:
              write((chat) {
                chat.value.firstItem = null;
                chat.value.lastItem = null;
                chat.value.lastReadItem = null;
                chat.lastItemCursor = null;
                chat.lastReadItemCursor = null;
              });
              _lastReadItemKey = null;
              _lastReadItemCursor = null;
              await clear();
              break;

            case ChatEventKind.itemHidden:
              event as EventChatItemHidden;
              remove(event.itemId);
              break;

            case ChatEventKind.muted:
              event as EventChatMuted;
              write((chat) => chat.value.muted = event.duration);
              break;

            case ChatEventKind.typingStarted:
              event as EventChatTypingStarted;
              typingUsers.addIf(
                !typingUsers.any((e) => e.id == event.user.id),
                event.user,
              );
              break;

            case ChatEventKind.unmuted:
              write((chat) => chat.value.muted = null);
              break;

            case ChatEventKind.typingStopped:
              event as EventChatTypingStopped;
              typingUsers.removeWhere((e) => e.id == event.user.id);
              break;

            case ChatEventKind.hidden:
              event as EventChatHidden;
              write((chat) => chat.value.isHidden = true);
              continue;

            case ChatEventKind.archived:
              event as EventChatArchived;
              write((chat) => chat.value.isArchived = true);
              break;

            case ChatEventKind.unarchived:
              event as EventChatUnarchived;
              write((chat) => chat.value.isArchived = false);
              break;

            case ChatEventKind.itemDeleted:
              event as EventChatItemDeleted;
              remove(event.itemId);
              break;

            case ChatEventKind.itemEdited:
              event as EventChatItemEdited;
              final item = await get(event.itemId);
              if (item != null) {
                final message = item.value as ChatMessage;
                message.text = event.text != null
                    ? event.text!.newText
                    : message.text;
                message.attachments = event.attachments ?? message.attachments;
                message.repliesTo =
                    event.quotes?.map((e) => e.value).toList() ??
                    message.repliesTo;
                (item as DtoChatMessage).repliesToCursors =
                    event.quotes?.map((e) => e.cursor).toList() ??
                    item.repliesToCursors;
                itemsToPut.add(item);
              }

              if (dto.value.lastItem?.id == event.itemId) {
                final message = dto.value.lastItem as ChatMessage;
                message.text = event.text != null
                    ? event.text!.newText
                    : message.text;
                message.attachments = event.attachments ?? message.attachments;
                message.repliesTo =
                    event.quotes?.map((e) => e.value).toList() ??
                    message.repliesTo;
              }
              break;

            case ChatEventKind.callStarted:
              event as EventChatCallStarted;

              if (!chat.value.isDialog) {
                event.call.conversationStartedAt ??= PreciseDateTime.now();
              }

              // Call is already finished, no reason to try adding it.
              if (event.call.finishReason == null) {
                write((chat) => chat.value.ongoingCall = event.call);
                _chatRepository.addCall(event.call);
              }

              final message = await get(event.call.id);

              if (message != null) {
                event.call.at = message.value.at;
                message.value = event.call;
                itemsToPut.add(message);
              }
              break;

            case ChatEventKind.unreadItemsCountUpdated:
              event as EventChatUnreadItemsCountUpdated;
              if (event.count < unreadCount.value || _readTimer == null) {
                unreadCount.value = event.count;
              } else if (event.count > dto.value.unreadCount) {
                unreadCount.value += event.count - dto.value.unreadCount;
              }

              write((chat) => chat.value.unreadCount = event.count);
              break;

            case ChatEventKind.callFinished:
              event as EventChatCallFinished;

              if (dto.value.ongoingCall?.id == event.call.id) {
                write((chat) => chat.value.ongoingCall = null);
              }

              if (dto.value.lastItem?.id == event.call.id) {
                write((chat) => chat.value.lastItem = event.call);
              }

              if (event.reason != ChatCallFinishReason.moved) {
                _chatRepository.removeCredentials(
                  event.call.chatId,
                  event.call.id,
                );

                final Rx<OngoingCall>? existing =
                    _chatRepository.calls[event.call.chatId];
                if (existing?.value.callChatItemId == event.call.id) {
                  _chatRepository.endCall(event.call.chatId);
                }
              }

              final message = await get(event.call.id);

              if (message != null) {
                event.call.at = message.value.at;
                message.value = event.call;
                itemsToPut.add(message);
              }
              break;

            case ChatEventKind.callMemberLeft:
              event as EventChatCallMemberLeft;
              int? i =
                  dto.value.ongoingCall?.members.indexWhere(
                    (e) => e.user.id == event.user.id,
                  ) ??
                  -1;

              if (i != -1) {
                write((chat) => chat.value.ongoingCall?.members.removeAt(i));
              }
              break;

            case ChatEventKind.callMemberJoined:
              event as EventChatCallMemberJoined;

              write(
                (chat) => chat.value.ongoingCall?.members.add(
                  ChatCallMember(
                    user: event.user,
                    handRaised: false,
                    joinedAt: event.at,
                  ),
                ),
              );

              if (dto.value.ongoingCall?.conversationStartedAt == null &&
                  chat.value.isDialog) {
                final Set<UserId>? ids = dto.value.ongoingCall?.members
                    .map((e) => e.user.id)
                    .toSet();

                if (ids != null && ids.length >= 2) {
                  write(
                    (chat) => chat.value.ongoingCall?.conversationStartedAt =
                        event.call.conversationStartedAt ?? event.at,
                  );

                  if (dto.value.ongoingCall != null) {
                    final call = dto.value.ongoingCall!;
                    final message = await get(call.id);

                    if (message != null) {
                      call.at = message.value.at;
                      message.value = call;
                      itemsToPut.add(message);
                    }
                  }
                }
              }
              break;

            case ChatEventKind.lastItemUpdated:
              event as EventChatLastItemUpdated;
              write((chat) => chat.value.lastItem = event.lastItem?.value);

              // TODO: [ChatCall.conversationStartedAt] shouldn't be `null`
              //       here when starting group or monolog [ChatCall].
              if (dto.value.lastItem is ChatCall) {
                final ChatCall call = dto.value.lastItem as ChatCall;

                if (!dto.value.isDialog) {
                  call.conversationStartedAt ??= PreciseDateTime.now();
                  write(
                    (chat) =>
                        (chat.value.lastItem as ChatCall)
                                .conversationStartedAt ??=
                            PreciseDateTime.now(),
                  );
                }

                // Call is already finished, no reason to try adding it.
                if (call.finishReason == null) {
                  write((chat) => chat.value.ongoingCall = call);
                }
              }

              write(
                (chat) => chat.value.updatedAt =
                    event.lastItem?.value.at ?? dto.value.updatedAt,
              );
              if (event.lastItem != null) {
                itemsToPut.add(event.lastItem!);
              }
              break;

            case ChatEventKind.delivered:
              event as EventChatDelivered;
              write((chat) => chat.value.lastDelivery = event.until);
              break;

            case ChatEventKind.read:
              event as EventChatRead;

              _updateReadFor(event.byUser.id, event.at);

              final LastChatRead? lastRead = dto.value.lastReads
                  .firstWhereOrNull((e) => e.memberId == event.byUser.id);
              if (lastRead == null) {
                write(
                  (chat) => chat.value.lastReads = [
                    ...dto.value.lastReads,
                    LastChatRead(event.byUser.id, event.at),
                  ],
                );
              } else {
                lastRead.at = event.at;
              }

              if (event.byUser.id == me) {
                final DtoChatItem? item = await _driftItems.readAt(event.at);
                _lastReadItemCursor = item?.cursor ?? _lastReadItemCursor;
                _lastReadItemKey = item?.value.id ?? _lastReadItemKey;
                write(
                  (chat) => chat
                    ..lastReadItemCursor = _lastReadItemCursor
                    ..value.lastItem = item?.value ?? chat.value.lastItem,
                );
              }
              break;

            case ChatEventKind.callDeclined:
              // TODO: Implement EventChatCallDeclined.
              break;

            case ChatEventKind.itemPosted:
              event as EventChatItemPosted;
              final DtoChatItem item = event.item;

              if (dto.value.isHidden) {
                write((chat) => chat.value.isHidden = false);
              }

              // When muted, archived `Chat`s get unarchived.
              if (dto.value.isArchived && dto.value.muted != null) {
                write((chat) => chat.value.isArchived = false);
              }

              if (item.value is ChatMessage && item.value.author.id == me) {
                final ChatMessage? pending = _pending
                    .whereType<ChatMessage>()
                    .firstWhereOrNull(
                      (e) =>
                          e.status.value == SendingStatus.sending &&
                          (item.value as ChatMessage).isEquals(e),
                    );

                // If any [ChatMessage] sharing the same fields as the posted
                // one is found in the [_pending] messages, and this message
                // is not yet added to the store, then remove the [pending].
                if (pending != null &&
                    await _driftItems.read(item.value.id) == null) {
                  remove(pending.id);
                  _pending.remove(pending);
                }
              }

              itemsToPut.add(item);

              if (item.value is ChatInfo) {
                final msg = item.value as ChatInfo;

                switch (msg.action.kind) {
                  case ChatInfoActionKind.avatarUpdated:
                    final action = msg.action as ChatInfoActionAvatarUpdated;
                    write((chat) => chat.value.avatar = action.avatar);
                    avatar.value = action.avatar;
                    break;

                  case ChatInfoActionKind.created:
                    // No-op.
                    break;

                  case ChatInfoActionKind.memberAdded:
                    final action = msg.action as ChatInfoActionMemberAdded;

                    if (!versionAccounted) {
                      dto.value.membersCount++;

                      // Store the first 3 [ChatMember]s in the [Chat.members]
                      // to display the default [Chat] name.
                      if (dto.value.members.length < 3) {
                        dto.value.members.add(ChatMember(action.user, msg.at));
                      }
                    }

                    _putMember(DtoChatMember(action.user, msg.at, null));
                    shouldPutChat = true;
                    break;

                  case ChatInfoActionKind.memberRemoved:
                    final action = msg.action as ChatInfoActionMemberRemoved;

                    if (!versionAccounted) {
                      dto.value.membersCount--;
                      dto.value.members.removeWhere(
                        (e) => e.user.id == action.user.id,
                      );
                    }

                    await members.remove(action.user.id);

                    if (dto.value.members.length < 3) {
                      if (members.rawLength < 3) {
                        await members.next();
                      }

                      dto.value.members.clear();
                      for (var m in members.pagination!.items.values.take(3)) {
                        if (m.user != null) {
                          dto.value.members.add(
                            ChatMember(m.user!, m.joinedAt),
                          );
                        }
                      }
                    }

                    _chatRepository.onMemberRemoved?.call(id, action.user.id);
                    shouldPutChat = true;
                    break;

                  case ChatInfoActionKind.nameUpdated:
                    final action = msg.action as ChatInfoActionNameUpdated;
                    write((chat) => chat.value.name = action.name);
                    break;
                }
              }
              break;

            case ChatEventKind.totalItemsCountUpdated:
              event as EventChatTotalItemsCountUpdated;
              write((chat) => chat.value.totalCount = event.count);
              break;

            case ChatEventKind.directLinkUpdated:
              event as EventChatDirectLinkUpdated;
              write((chat) => chat.value.directLink = event.link);
              break;

            case ChatEventKind.directLinkUsageCountUpdated:
              event as EventChatDirectLinkUsageCountUpdated;
              write(
                (chat) => chat.value.directLink?.usageCount = event.usageCount,
              );
              break;

            case ChatEventKind.directLinkDeleted:
              write((chat) => chat.value.directLink = null);
              break;

            case ChatEventKind.callMoved:
              // TODO: Implement EventChatCallMoved.
              break;

            case ChatEventKind.favorited:
              event as EventChatFavorited;
              write((chat) => chat.value.favoritePosition = event.position);
              break;

            case ChatEventKind.unfavorited:
              write((chat) => chat.value.favoritePosition = null);
              break;

            case ChatEventKind.callConversationStarted:
              event as EventChatCallConversationStarted;

              // Call is already finished, no reason to try adding it.
              if (event.call.finishReason == null) {
                if (!chat.value.isDialog) {
                  event.call.conversationStartedAt ??= PreciseDateTime.now();
                }

                write((chat) => chat.value.ongoingCall = event.call);
                _chatRepository.addCall(event.call, dontAddIfAccounted: true);
              }
              break;

            case ChatEventKind.callAnswerTimeoutPassed:
              event as EventChatCallAnswerTimeoutPassed;

              if (event.callId == chat.value.ongoingCall?.id) {
                write((chat) => chat.value.ongoingCall?.dialed = null);
              }
              break;
          }
        }

        for (var e in itemsToPut) {
          await put(e);
        }

        if (shouldPutChat) {
          await _driftChat.upsert(_setChat(dto) ?? dto);
        }

        break;
    }
  }
}

/// Extension adding an ability to insert the element based on some condition to
/// [List].
extension ListInsertAfter<T> on List<T> {
  /// Inserts the [element] after the [test] condition becomes `true`.
  ///
  /// Only meaningful, if this [List] is sorted in some way, as this method
  /// iterates it from the [first] til the [last].
  void insertAfter(T element, bool Function(T) test) {
    if (isEmpty || !test(this[0])) {
      insert(0, element);
      return;
    }

    for (var i = length - 1; i > -1; --i) {
      if (test(this[i])) {
        insert(i + 1, element);
        return;
      }
    }
  }
}
