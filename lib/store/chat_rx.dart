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

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/schema.dart'
    show ChatCallFinishReason, ChatKind, PostChatMessageErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show ConnectionException, PostChatMessageException, StaleVersionException;
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/draft.dart';
import '/store/model/chat_item.dart';
import '/store/pagination.dart';
import '/store/pagination/hive.dart';
import '/store/pagination/hive_graphql.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatViewExt;
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/stream_utils.dart';
import 'chat.dart';
import 'event/chat.dart';
import 'pagination/graphql.dart';

/// [RxChat] implementation backed by local [Hive] storage.
class HiveRxChat extends RxChat {
  HiveRxChat(
    this._chatRepository,
    this._chatLocal,
    this._draftLocal,
    HiveChat hiveChat,
  )   : chat = Rx<Chat>(hiveChat.value),
        _lastReadItemCursor = hiveChat.lastReadItemCursor,
        _local = ChatItemHiveProvider(hiveChat.value.id),
        draft = Rx<ChatMessage?>(_draftLocal.get(hiveChat.value.id)),
        unreadCount = RxInt(hiveChat.value.unreadCount);

  @override
  final Rx<Chat> chat;

  @override
  final RxObsList<Rx<ChatItem>> messages = RxObsList<Rx<ChatItem>>();

  @override
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  @override
  final RxList<User> typingUsers = RxList<User>([]);

  @override
  final RxObsMap<UserId, RxUser> members = RxObsMap<UserId, RxUser>();

  @override
  final RxString title = RxString('');

  @override
  final Rx<Avatar?> avatar = Rx<Avatar?>(null);

  @override
  final Rx<ChatMessage?> draft;

  /// Cursor of the last [ChatItem] read by the authenticated [MyUser].
  ChatItemsCursor? _lastReadItemCursor;

  @override
  final RxList<LastChatRead> reads = RxList();

  @override
  final RxInt unreadCount;

  /// [ChatRepository] used to cooperate with the other [HiveRxChat]s.
  final ChatRepository _chatRepository;

  /// [Chat]s local [Hive] storage.
  final ChatHiveProvider _chatLocal;

  /// [RxChat.draft]s local [Hive] storage.
  final DraftHiveProvider _draftLocal;

  /// [ChatItem]s local [Hive] storage.
  ChatItemHiveProvider _local;

  /// [Pagination] loading [messages] with pagination.
  late final Pagination<HiveChatItem, ChatItemsCursor, ChatItemKey> _pagination;

  /// [PageProvider] fetching pages of [HiveChatItem]s.
  late final HiveGraphQlPageProvider<HiveChatItem, ChatItemsCursor, ChatItemKey>
      _provider;

  /// Subscription to [User]s from the [members] list forming the [title].
  final Map<UserId, Worker> _userWorkers = {};

  /// [Worker] reacting on the [User] changes updating the [avatar].
  Worker? _userWorker;

  /// Subscription to the [Pagination.items] changes.
  StreamSubscription? _paginationSubscription;

  /// [Timer] unmuting the muted [chat] when its [MuteDuration.until] expires.
  Timer? _muteTimer;

  /// [ChatRepository.chatEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<ChatEvents>? _remoteSubscription;

  /// [Worker] reacting on the [chat] changes updating the [members].
  Worker? _worker;

  /// Indicator whether [_remoteSubscription] is initialized or is being
  /// initialized used in [subscribe].
  bool _remoteSubscriptionInitialized = false;

  /// [ChatItem]s in the [SendingStatus.sending] state.
  final List<ChatItem> _pending = [];

  /// [StreamSubscription] to [messages] recalculating the [reads] on removals.
  StreamSubscription? _messagesSubscription;

  /// [AwaitableTimer] executing a [ChatRepository.readUntil].
  AwaitableTimer? _readTimer;

  /// [Mutex]es guarding synchronized access to the [updateAttachments].
  final Map<ChatItemId, Mutex> _attachmentGuards = {};

  /// [CancelToken] for cancelling the [Pagination.around] query.
  final CancelToken _aroundToken = CancelToken();

  @override
  UserId? get me => _chatRepository.me;

  @override
  RxBool get hasNext => _pagination.hasNext;

  @override
  RxBool get nextLoading => _pagination.nextLoading;

  @override
  RxBool get hasPrevious => _pagination.hasPrevious;

  @override
  RxBool get previousLoading => _pagination.previousLoading;

  @override
  UserCallCover? get callCover {
    UserCallCover? callCover;

    switch (chat.value.kind) {
      case ChatKind.monolog:
        callCover = members.values.firstOrNull?.user.value.callCover;
        break;

      case ChatKind.dialog:
        callCover = members.values
            .firstWhereOrNull((e) => e.id != me)
            ?.user
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
    if (chat.value.unreadCount != 0) {
      PreciseDateTime? myRead =
          chat.value.lastReads.firstWhereOrNull((e) => e.memberId == me)?.at;

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

  /// Initializes this [HiveRxChat].
  Future<void> init() async {
    if (status.value.isSuccess) {
      return Future.value();
    }

    status.value = RxStatus.loading();

    reads.addAll(
      chat.value.lastReads.map((e) => LastChatRead(e.memberId, e.at)),
    );

    _updateTitle(chat.value.members.map((e) => e.user));
    _updateFields().then((_) => chat.value.isDialog ? _updateAvatar() : null);
    _worker = ever(chat, (_) => _updateFields());

    _messagesSubscription = messages.changes.listen((e) {
      switch (e.op) {
        case OperationKind.removed:
          for (LastChatRead i in reads) {
            // Recalculate the [LastChatRead]s pointing at the removed
            // [ChatItem], if any.
            if (e.element.value.at == i.at) {
              i.at = _lastReadAt(i.at) ?? i.at;
            }
          }
          break;

        case OperationKind.added:
        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    _provider = HiveGraphQlPageProvider(
      graphQlProvider: GraphQlPageProvider(
        reversed: true,
        fetch: ({after, before, first, last}) async {
          final Page<HiveChatItem, ChatItemsCursor> reversed =
              await _chatRepository.messages(
            chat.value.id,
            after: after,
            first: first,
            before: before,
            last: last,
          );

          final Page<HiveChatItem, ChatItemsCursor> page;
          if (_provider.graphQlProvider.reversed) {
            page = reversed.reversed();
          } else {
            page = reversed;
          }

          if (page.info.hasPrevious == false) {
            final HiveChat? chatEntity = await _chatLocal.get(id);
            final ChatItem? firstItem = page.edges.firstOrNull?.value;

            if (chatEntity != null && chatEntity.value.firstItem != firstItem) {
              chatEntity.value.firstItem = firstItem;
              _chatLocal.put(chatEntity);
            }
          }

          return reversed;
        },
      ),
      hiveProvider: HivePageProvider(
        _local,
        getCursor: (e) => e?.cursor,
        getKey: (e) => e.value.key,
        isFirst: (e) => chat.value.firstItem?.id == e.value.id,
        isLast: (e) => chat.value.lastItem?.id == e.value.id,
        strategy: PaginationStrategy.fromEnd,
      ),
    );

    _pagination = Pagination<HiveChatItem, ChatItemsCursor, ChatItemKey>(
      onKey: (e) => e.value.key,
      provider: _provider,
      compare: (a, b) => a.value.key.compareTo(b.value.key),
    );

    if (id.isLocal) {
      _pagination.hasNext.value = false;
      _pagination.hasPrevious.value = false;
      status.value = RxStatus.success();
    }

    _paginationSubscription = _pagination.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          _add(event.value!.value);
          break;

        case OperationKind.removed:
          messages.removeWhere((e) => e.value.id == event.value?.value.id);
          break;

        case OperationKind.updated:
          _add(event.value!.value);
          break;
      }
    });

    await _local.init(userId: me);

    HiveChatItem? item;
    if (chat.value.lastReadItem != null) {
      item = await get(chat.value.lastReadItem!);
    }

    await _pagination.init(item);

    if (id.isLocal) {
      _pagination.hasNext.value = false;
      _pagination.hasPrevious.value = false;
    }
  }

  /// Disposes this [HiveRxChat].
  Future<void> dispose() async {
    status.value = RxStatus.loading();
    messages.clear();
    reads.clear();
    _aroundToken.cancel();
    _muteTimer?.cancel();
    _readTimer?.cancel();
    _remoteSubscription?.close(immediate: true);
    _paginationSubscription?.cancel();
    _messagesSubscription?.cancel();
    _remoteSubscriptionInitialized = false;
    await _local.close();
    status.value = RxStatus.empty();
    _worker?.dispose();
    _userWorker?.dispose();
    for (var e in _userWorkers.values) {
      e.dispose();
    }
  }

  /// Subscribes to the remote updates of the [chat] if not subscribed already.
  void subscribe() {
    if (!_remoteSubscriptionInitialized && !id.isLocal) {
      _initRemoteSubscription();
    }
  }

  @override
  void setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  }) {
    ChatMessage? draft = _draftLocal.get(id);

    if (text == null && attachments.isEmpty && repliesTo.isEmpty) {
      if (draft != null) {
        _draftLocal.remove(id);
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
        _draftLocal.put(id, draft);
      }
    }
  }

  @override
  Future<void> around() async {
    if (id.isLocal || status.value.isSuccess) {
      return;
    }

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    HiveChatItem? item;
    if (chat.value.lastReadItem != null) {
      item = await get(chat.value.lastReadItem!);
    }

    await _pagination.around(cursor: _lastReadItemCursor, item: item);

    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);
  }

  @override
  Future<void> next() async {
    status.value = RxStatus.loadingMore();
    await _pagination.next();
    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);
  }

  @override
  Future<void> previous() async {
    status.value = RxStatus.loadingMore();
    await _pagination.previous();
    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);
  }

  @override
  Future<void> updateAttachments(ChatItem item) async {
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

      await _updateAttachments(item);
      _attachmentGuards.remove(item.id);
    });
  }

  /// Marks this [RxChat] as read until the provided [ChatItem] for the
  /// authenticated [MyUser],
  Future<void> read(ChatItemId untilId) async {
    int firstUnreadIndex = 0;

    if (firstUnread != null) {
      firstUnreadIndex = messages.indexOf(firstUnread!);
    }

    int lastReadIndex =
        messages.indexWhere((m) => m.value.id == untilId, firstUnreadIndex);

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
    HiveChatMessage message = HiveChatMessage.sending(
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
      messages.firstWhereOrNull((e) => e.value.id == existingId)?.value =
          message.value;
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
        List<Future> uploads = attachments
            .mapIndexed((i, e) {
              if (e is LocalAttachment) {
                return e.upload.value?.future.then(
                  (a) {
                    attachments[i] = a;

                    // Frequent [Hive] writes of byte data freezes the Web page.
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
            .whereNotNull()
            .toList();

        if (existingId == null) {
          List<Future> reads = attachments
              .whereType<LocalAttachment>()
              .map((e) => e.read.value?.future)
              .whereNotNull()
              .toList();
          if (reads.isNotEmpty) {
            await Future.wait(reads);
            put(message);
          }
        }

        await Future.wait(uploads);
      }

      if (attachments?.whereType<LocalAttachment>().isNotEmpty == true) {
        throw const ConnectionException(PostChatMessageException(
          PostChatMessageErrorCode.unknownAttachment,
        ));
      }

      var response = await _chatRepository.postChatMessage(
        id,
        text: text,
        attachments: attachments?.map((e) => e.id).toList(),
        repliesTo: repliesTo.map((e) => e.id).toList(),
      );

      var event = response?.events
              .map((e) => _chatRepository.chatEvent(e))
              .firstWhereOrNull((e) => e is EventChatItemPosted)
          as EventChatItemPosted?;

      if (event != null && event.item is HiveChatMessage) {
        remove(message.value.id, message.value.key);
        _pending.remove(message.value);
        message = event.item as HiveChatMessage;
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

  /// Adds the provided [item] to [Pagination] and [Hive].
  Future<void> put(HiveChatItem item) => _pagination.put(item);

  @override
  Future<void> remove(ChatItemId itemId, [ChatItemKey? key]) async {
    key ??= _local.keys.firstWhereOrNull((e) => e.id == itemId);

    if (key != null) {
      _pagination.remove(key);

      final HiveChat? chatEntity = await _chatLocal.get(id);
      if (chatEntity?.value.lastItem?.id == itemId) {
        var lastItem = messages.lastWhereOrNull((e) => e.value.id != itemId);

        if (lastItem != null) {
          chatEntity?.value.lastItem = lastItem.value;
          chatEntity?.lastItemCursor =
              (await _local.get(lastItem.value.key))?.cursor;
        } else {
          chatEntity?.value.lastItem = null;
          chatEntity?.lastItemCursor = null;
        }

        _chatLocal.put(chatEntity!);
      }
    }
  }

  /// Returns a stored [HiveChatItem] identified by the provided [itemId], if
  /// any.
  ///
  /// Optionally, a [key] may be specified, otherwise it will be fetched
  /// from the [_local] store.
  Future<HiveChatItem?> get(ChatItemId itemId, {ChatItemKey? key}) async {
    key ??= _local.keys.firstWhereOrNull((e) => e.id == itemId);

    if (key != null) {
      return await _local.get(key);
    }

    return null;
  }

  /// Recalculates the [reads] to represent the actual [messages].
  void updateReads() {
    for (LastChatRead e in chat.value.lastReads) {
      final PreciseDateTime? at = _lastReadAt(e.at);

      if (at != null) {
        final LastChatRead? read =
            reads.firstWhereOrNull((m) => m.memberId == e.memberId);

        if (read != null) {
          read.at = at;
        } else {
          reads.add(LastChatRead(e.memberId, at));
        }
      }
    }
  }

  /// Updates the [chat] and [chat]-related resources with the provided
  /// [newChat].
  Future<void> updateChat(Chat newChat) async {
    if (chat.value.id != newChat.id) {
      chat.value = newChat;

      subscribe();

      // Retrieve all the [HiveChatItem]s to put them in the [newChat].
      final Iterable<HiveChatItem> saved = await _local.values;

      // Clear and close the current [ChatItemHiveProvider].
      await _local.clear();
      _local.close();

      _local = ChatItemHiveProvider(id);
      await _local.init(userId: me);

      await _pagination.clear();
      _provider.hive = _local;

      for (var e in saved.whereType<HiveChatMessage>()) {
        // Copy the [HiveChatMessage] to the new [ChatItemHiveProvider].
        final HiveChatMessage copy = e.copyWith()..value.chatId = newChat.id;

        if (copy.value.status.value == SendingStatus.error) {
          copy.value.status.value = SendingStatus.sending;
        }

        _pagination.put(copy, ignoreBounds: true);
      }

      _pagination.around();
    }
  }

  /// Clears the [_pagination].
  Future<void> clear() => _pagination.clear();

  // TODO: Remove when backend supports welcome messages.
  @override
  Future<void> addMessage(ChatMessageText text) async {
    await put(
      HiveChatMessage(
        ChatMessage(
          ChatItemId.local(),
          id,
          User(const UserId('0'), UserNum('1234123412341234')),
          PreciseDateTime.now(),
          text: text,
        ),
        null,
        ChatItemVersion('0'),
        null,
      ),
    );
  }

  @override
  int compareTo(RxChat other) => chat.value.compareTo(other.chat.value, me);

  /// Adds the provided [ChatItem] to the [messages] list, initializing the
  /// [FileAttachment]s, if any.
  void _add(ChatItem item) {
    if (!PlatformUtils.isWeb) {
      if (item is ChatMessage) {
        for (var a in item.attachments.whereType<FileAttachment>()) {
          a.init();
        }
      } else if (item is ChatForward) {
        ChatItemQuote nested = item.quote;
        if (nested is ChatMessageQuote) {
          for (var a in nested.attachments.whereType<FileAttachment>()) {
            a.init();
          }
        }
      }
    }

    final int i = messages.indexWhere((e) => e.value.id == item.id);
    if (i == -1) {
      messages.insertAfter(
        Rx(item),
        (e) => item.key.compareTo(e.value.key) == 1,
      );
    } else {
      messages[i].value = item;
    }
  }

  /// Updates the [members] and [title] fields based on the [chat] state.
  Future<void> _updateFields() async {
    if (chat.value.name != null) {
      _updateTitle();
    }

    if (!chat.value.isDialog) {
      avatar.value = chat.value.avatar;
    }

    _muteTimer?.cancel();
    if (chat.value.muted?.until != null) {
      _muteTimer = Timer(
        chat.value.muted!.until!.val.difference(DateTime.now()),
        () async {
          final HiveChat? chat = await _chatLocal.get(id);
          if (chat != null) {
            chat.value.muted = null;
            _chatRepository.put(chat);
          }
        },
      );
    }

    // TODO: Users list can be huge, so we should implement pagination and
    //       loading on demand.
    for (var m in chat.value.members) {
      if (!members.containsKey(m.user.id)) {
        var user = await _chatRepository.getUser(m.user.id);
        if (user != null) {
          members[m.user.id] = user;
        }
      }
    }

    members
        .removeWhere((k, _) => chat.value.members.none((m) => m.user.id == k));

    if (chat.value.name == null) {
      var users = members.values.take(3);
      _userWorkers.removeWhere((k, v) {
        if (!users.any((u) => u.id == k)) {
          v.dispose();
          return true;
        }

        return false;
      });

      for (RxUser u in users) {
        if (!_userWorkers.containsKey(u.id)) {
          // TODO: Title should be updated only if [User.name] had actually
          // changed.
          _userWorkers[u.id] = ever(u.user, (_) => _updateTitle());
        }
      }

      _updateTitle();
    }

    if (chat.value.unreadCount < unreadCount.value || _readTimer == null) {
      unreadCount.value = chat.value.unreadCount;
    }
  }

  /// Updates the [title].
  void _updateTitle([Iterable<User>? users]) {
    title.value = chat.value.getTitle(
      users?.take(3) ?? members.values.take(3).map((e) => e.user.value),
      me,
    );
  }

  /// Updates the [avatar].
  void _updateAvatar() {
    RxUser? member;

    switch (chat.value.kind) {
      case ChatKind.dialog:
        member = members.values.firstWhereOrNull((e) => e.id != me);
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
      _userWorker = ever(member.user, (User u) => avatar.value = u.avatar);
    }
  }

  /// Returns the [ChatItem.at] being the predecessor of the provided [at].
  PreciseDateTime? _lastReadAt(PreciseDateTime at) {
    final Rx<ChatItem>? message = messages
        .lastWhereOrNull((e) => e.value is! ChatInfo && e.value.at <= at);

    // Return `null` if [hasNext] because the provided [at] can be actually
    // connected to another [message].
    if (message == null || hasNext.isTrue && messages.last == message) {
      return null;
    } else {
      return message.value.at;
    }
  }

  /// Re-fetches the [Attachment]s of the specified [item] to be up-to-date.
  Future<void> _updateAttachments(ChatItem item) async {
    final HiveChatItem? stored = await get(item.id, key: item.key);
    if (stored != null) {
      final List<Attachment> response =
          await _chatRepository.attachments(stored);

      void replace(Attachment a) {
        Attachment? fetched = response.firstWhereOrNull((e) => e.id == a.id);
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
      _pagination.put(stored);
    }
  }

  /// Initializes [ChatRepository.chatEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    _remoteSubscriptionInitialized = true;

    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = StreamQueue(
      _chatRepository.chatEvents(
        id,
        (await _chatLocal.get(id))?.ver,
        () async => (await _chatLocal.get(id))?.ver,
      ),
    );

    await _remoteSubscription!.execute(
      _chatEvent,
      onError: (e) async {
        if (e is StaleVersionException) {
          await _pagination.clear();

          await _pagination.around(cursor: _lastReadItemCursor);
        }
      },
    );

    _remoteSubscriptionInitialized = false;
  }

  /// Handles [ChatEvent]s from the [ChatRepository.chatEvents] subscription.
  Future<void> _chatEvent(ChatEvents event) async {
    switch (event.kind) {
      case ChatEventsKind.initialized:
        // No-op.
        break;

      case ChatEventsKind.chat:
        var node = event as ChatEventsChat;
        HiveChat? chatEntity = await _chatLocal.get(id);
        if (node.chat.chat.ver > chatEntity?.ver) {
          chatEntity = node.chat.chat;
          _chatRepository.put(chatEntity);
          _lastReadItemCursor = node.chat.chat.lastReadItemCursor;
        }
        break;

      case ChatEventsKind.event:
        final HiveChat? chatEntity = await _chatLocal.get(id);
        var versioned = (event as ChatEventsEvent).event;
        if (chatEntity == null || versioned.ver <= chatEntity.ver) {
          return;
        }

        chatEntity.ver = versioned.ver;

        bool putChat = _remoteSubscriptionInitialized;
        for (var event in versioned.events) {
          putChat = _remoteSubscriptionInitialized;

          // Subscription was already disposed while processing the events.
          if (!_remoteSubscriptionInitialized) {
            return;
          }

          switch (event.kind) {
            case ChatEventKind.redialed:
              // TODO: Implement EventChatCallMemberRedialed.
              break;

            case ChatEventKind.cleared:
              chatEntity.value.lastItem = null;
              chatEntity.value.lastReadItem = null;
              chatEntity.lastItemCursor = null;
              chatEntity.lastReadItemCursor = null;
              _lastReadItemCursor = null;
              await _pagination.clear();
              break;

            case ChatEventKind.itemHidden:
              event as EventChatItemHidden;
              await remove(event.itemId);
              break;

            case ChatEventKind.muted:
              event as EventChatMuted;
              chatEntity.value.muted = event.duration;
              break;

            case ChatEventKind.typingStarted:
              event as EventChatTypingStarted;
              typingUsers.addIf(
                !typingUsers.any((e) => e.id == event.user.id),
                event.user,
              );
              break;

            case ChatEventKind.unmuted:
              chatEntity.value.muted = null;
              break;

            case ChatEventKind.typingStopped:
              event as EventChatTypingStopped;
              typingUsers.removeWhere((e) => e.id == event.user.id);
              break;

            case ChatEventKind.hidden:
              event as EventChatHidden;
              _chatRepository.remove(event.chatId);
              putChat = false;
              continue;

            case ChatEventKind.itemDeleted:
              event as EventChatItemDeleted;
              await remove(event.itemId);
              break;

            case ChatEventKind.itemTextEdited:
              event as EventChatItemTextEdited;
              final message = await get(event.itemId);
              if (message != null) {
                (message.value as ChatMessage).text = event.text;
                put(message);
              }
              break;

            case ChatEventKind.callStarted:
              event as EventChatCallStarted;

              if (!chat.value.isDialog) {
                event.call.conversationStartedAt ??= PreciseDateTime.now();
              }

              chatEntity.value.ongoingCall = event.call;
              _chatRepository.addCall(event.call);

              final message = await get(event.call.id, key: event.call.key);

              if (message != null) {
                event.call.at = message.value.at;
                message.value = event.call;
                put(message);
              }
              break;

            case ChatEventKind.unreadItemsCountUpdated:
              event as EventChatUnreadItemsCountUpdated;
              if (event.count < unreadCount.value || _readTimer == null) {
                unreadCount.value = event.count;
              } else if (event.count > chatEntity.value.unreadCount) {
                unreadCount.value += event.count - chatEntity.value.unreadCount;
              }

              chatEntity.value.unreadCount = event.count;
              break;

            case ChatEventKind.callFinished:
              event as EventChatCallFinished;
              chatEntity.value.ongoingCall = null;
              if (chatEntity.value.lastItem?.id == event.call.id) {
                chatEntity.value.lastItem = event.call;
              }

              if (event.reason != ChatCallFinishReason.moved) {
                _chatRepository.removeCredentials(event.call.id);
                _chatRepository.endCall(event.call.chatId);
              }

              final message = await get(event.call.id, key: event.call.key);

              if (message != null) {
                event.call.at = message.value.at;
                message.value = event.call;
                put(message);
              }
              break;

            case ChatEventKind.callMemberLeft:
              event as EventChatCallMemberLeft;
              int? i = chatEntity.value.ongoingCall?.members
                      .indexWhere((e) => e.user.id == event.user.id) ??
                  -1;

              if (i != -1) {
                chatEntity.value.ongoingCall?.members.removeAt(i);
              }
              break;

            case ChatEventKind.callMemberJoined:
              event as EventChatCallMemberJoined;
              chatEntity.value.ongoingCall?.members.add(
                ChatCallMember(
                  user: event.user,
                  handRaised: false,
                  joinedAt: event.at,
                ),
              );

              if (chatEntity.value.ongoingCall?.conversationStartedAt == null &&
                  chat.value.isDialog) {
                final Set<UserId>? ids = chatEntity.value.ongoingCall?.members
                    .map((e) => e.user.id)
                    .toSet();

                if (ids != null && ids.length >= 2) {
                  chatEntity.value.ongoingCall?.conversationStartedAt =
                      event.call.conversationStartedAt ?? event.at;

                  if (chatEntity.value.ongoingCall != null) {
                    final call = chatEntity.value.ongoingCall!;
                    final message = await get(call.id, key: call.key);

                    if (message != null) {
                      call.at = message.value.at;
                      message.value = call;
                      put(message);
                    }
                  }
                }
              }
              break;

            case ChatEventKind.lastItemUpdated:
              event as EventChatLastItemUpdated;
              chatEntity.value.lastItem = event.lastItem?.value;

              // TODO [ChatCall.conversationStartedAt] shouldn't be `null` here
              //      when starting group or monolog [ChatCall].
              if (!chatEntity.value.isDialog &&
                  chatEntity.value.lastItem is ChatCall) {
                (chatEntity.value.lastItem as ChatCall).conversationStartedAt =
                    PreciseDateTime.now();
              }

              chatEntity.value.updatedAt =
                  event.lastItem?.value.at ?? chatEntity.value.updatedAt;
              if (event.lastItem != null) {
                await put(event.lastItem!);
              }
              break;

            case ChatEventKind.delivered:
              event as EventChatDelivered;
              chatEntity.value.lastDelivery = event.at;
              break;

            case ChatEventKind.read:
              event as EventChatRead;

              final PreciseDateTime? at = _lastReadAt(event.at);
              if (at != null) {
                final LastChatRead? read = reads
                    .firstWhereOrNull((e) => e.memberId == event.byUser.id);

                if (read == null) {
                  reads.add(LastChatRead(event.byUser.id, at));
                } else {
                  read.at = at;
                }

                if (event.byUser.id == me) {
                  final ChatItemKey? key =
                      _local.keys.lastWhereOrNull((e) => e.at == at);
                  if (key != null) {
                    final HiveChatItem? item = await _local.get(key);
                    if (item != null) {
                      chatEntity.lastReadItemCursor = item.cursor!;
                      chatEntity.value.lastReadItem = item.value.id;
                      _lastReadItemCursor = item.cursor!;
                    }
                  }
                }
              }

              LastChatRead? lastRead = chatEntity.value.lastReads
                  .firstWhereOrNull((e) => e.memberId == event.byUser.id);
              if (lastRead == null) {
                chatEntity.value.lastReads
                    .add(LastChatRead(event.byUser.id, event.at));
              } else {
                lastRead.at = event.at;
              }
              break;

            case ChatEventKind.callDeclined:
              // TODO: Implement EventChatCallDeclined.
              break;

            case ChatEventKind.itemPosted:
              event as EventChatItemPosted;
              final HiveChatItem item = event.item;

              if (chatEntity.value.isHidden) {
                chatEntity.value.isHidden = false;
              }

              if (item.value is ChatMessage && item.value.author.id == me) {
                ChatMessage? pending =
                    _pending.whereType<ChatMessage>().firstWhereOrNull(
                          (e) =>
                              e.status.value == SendingStatus.sending &&
                              (item.value as ChatMessage).isEquals(e),
                        );

                // If any [ChatMessage] sharing the same fields as the posted
                // one is found in the [_pending] messages, and this message
                // is not yet added to the store, then remove the [pending].
                if (pending != null &&
                    await get(item.value.id, key: item.value.key) == null) {
                  remove(pending.id, pending.key);
                  _pending.remove(pending);
                }
              }

              put(item);

              if (item.value is ChatInfo) {
                var msg = item.value as ChatInfo;

                switch (msg.action.kind) {
                  case ChatInfoActionKind.avatarUpdated:
                    final action = msg.action as ChatInfoActionAvatarUpdated;
                    chatEntity.value.avatar = action.avatar;
                    break;

                  case ChatInfoActionKind.created:
                    // No-op.
                    break;

                  case ChatInfoActionKind.memberAdded:
                    final action = msg.action as ChatInfoActionMemberAdded;
                    chatEntity.value.members
                        .add(ChatMember(action.user, msg.at));
                    break;

                  case ChatInfoActionKind.memberRemoved:
                    final action = msg.action as ChatInfoActionMemberRemoved;
                    chatEntity.value.members
                        .removeWhere((e) => e.user.id == action.user.id);
                    chatEntity.value.lastReads
                        .removeWhere((e) => e.memberId == action.user.id);
                    reads.removeWhere((e) => e.memberId == action.user.id);
                    await _chatRepository.onMemberRemoved(id, action.user.id);
                    break;

                  case ChatInfoActionKind.nameUpdated:
                    final action = msg.action as ChatInfoActionNameUpdated;
                    chatEntity.value.name = action.name;
                    break;
                }
              }
              break;

            case ChatEventKind.totalItemsCountUpdated:
              event as EventChatTotalItemsCountUpdated;
              chatEntity.value.totalCount = event.count;
              break;

            case ChatEventKind.directLinkUpdated:
              event as EventChatDirectLinkUpdated;
              chatEntity.value.directLink = event.link;
              break;

            case ChatEventKind.directLinkUsageCountUpdated:
              event as EventChatDirectLinkUsageCountUpdated;
              chatEntity.value.directLink?.usageCount = event.usageCount;
              break;

            case ChatEventKind.directLinkDeleted:
              chatEntity.value.directLink = null;
              break;

            case ChatEventKind.callMoved:
              // TODO: Implement EventChatCallMoved.
              break;

            case ChatEventKind.favorited:
              event as EventChatFavorited;
              chatEntity.value.favoritePosition = event.position;
              break;

            case ChatEventKind.unfavorited:
              chatEntity.value.favoritePosition = null;
              break;

            case ChatEventKind.callConversationStarted:
              event as EventChatCallConversationStarted;
              chatEntity.value.ongoingCall = event.call;
              break;
          }
        }

        if (putChat) {
          _chatRepository.put(chatEntity);
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

/// [Timer] exposing its [future] to be awaited.
class AwaitableTimer {
  AwaitableTimer(Duration d, FutureOr Function() callback) {
    _timer = Timer(d, () async {
      try {
        _completer.complete(await callback());
      } on StateError {
        // No-op, as [Future] is allowed to be completed.
      } catch (e, stackTrace) {
        _completer.completeError(e, stackTrace);
      }
    });
  }

  /// [Timer] executing the callback.
  late final Timer _timer;

  /// [Completer] completing when [_timer] is done executing.
  final _completer = Completer();

  /// [Future] completing when this [AwaitableTimer] is finished.
  Future get future => _completer.future;

  /// Cancels this [AwaitableTimer].
  void cancel() {
    _timer.cancel();
    _completer.complete();
  }
}
