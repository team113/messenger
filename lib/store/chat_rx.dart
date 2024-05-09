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
import 'dart:ui';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:mutex/mutex.dart';

import '../util/get.dart';
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
import '/domain/repository/paginated.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show ConnectionException, PostChatMessageException, StaleVersionException;
import '/provider/hive/base.dart';
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/chat_item_sorting.dart';
import '/provider/hive/chat_member.dart';
import '/provider/hive/chat_member_sorting.dart';
import '/provider/hive/draft.dart';
import '/store/model/chat.dart';
import '/store/model/chat_item.dart';
import '/store/pagination.dart';
import '/store/pagination/hive.dart';
import '/store/pagination/hive_graphql.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatViewExt;
import '/util/awaitable_timer.dart';
import '/util/log.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/stream_utils.dart';
import '/util/web/web_utils.dart';
import 'chat.dart';
import 'event/chat.dart';
import 'paginated.dart';
import 'pagination/graphql.dart';

typedef MessagesPaginated
    = RxPaginatedImpl<ChatItemId, Rx<ChatItem>, HiveChatItem, ChatItemsCursor>;

typedef MembersPaginated
    = RxPaginatedImpl<UserId, RxChatMember, HiveChatMember, ChatMembersCursor>;

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
        _sorting = ChatItemSortingHiveProvider(hiveChat.value.id),
        _membersLocal = ChatMemberHiveProvider(hiveChat.value.id),
        _membersSorting = ChatMemberSortingHiveProvider(hiveChat.value.id),
        draft = Rx<ChatMessage?>(_draftLocal.get(hiveChat.value.id)),
        unreadCount = RxInt(hiveChat.value.unreadCount),
        ver = hiveChat.ver;

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
  final Rx<ChatMessage?> draft;

  @override
  final RxList<LastChatRead> reads = RxList();

  @override
  final RxInt unreadCount;

  /// [ChatVersion] of this [HiveRxChat].
  ChatVersion? ver;

  @override
  late final RxBool inCall =
      RxBool(_chatRepository.calls[id] != null || WebUtils.containsCall(id));

  /// [ChatRepository] used to cooperate with the other [HiveRxChat]s.
  final ChatRepository _chatRepository;

  /// [Chat]s local [Hive] storage.
  final ChatHiveProvider _chatLocal;

  /// [RxChat.draft]s local [Hive] storage.
  final DraftHiveProvider _draftLocal;

  /// [ChatItem]s local [Hive] storage.
  ChatItemHiveProvider _local;

  /// [Hive] storage for [ChatItemId]s sorted by [ChatItem.at].
  ChatItemSortingHiveProvider _sorting;

  /// [ChatMember]s local [Hive] storage.
  final ChatMemberHiveProvider _membersLocal;

  /// [Hive] storage of [UserId]s sorted by [PreciseDateTime] used for sorting
  /// [ChatMember]s from [_membersLocal].
  final ChatMemberSortingHiveProvider _membersSorting;

  /// [Pagination] loading [messages] with pagination.
  late final Pagination<HiveChatItem, ChatItemsCursor, ChatItemId> _pagination;

  /// [MessagesPaginated]s created by this [HiveRxChat].
  final List<MessagesPaginated> _fragments = [];

  /// Subscriptions to the [MessagesPaginated.items] changes updating the
  /// [reads].
  final List<StreamSubscription> _fragmentSubscriptions = [];

  /// [PageProvider] fetching pages of [HiveChatItem]s.
  late final HiveGraphQlPageProvider<HiveChatItem, ChatItemsCursor, ChatItemId>
      _provider;

  /// [Worker] reacting on the [User] changes updating the [avatar].
  Worker? _userWorker;

  /// Subscription to the [_pagination] changes.
  StreamSubscription? _paginationSubscription;

  /// [ChatMemberHiveProvider.boxEvents] subscription.
  StreamIterator? _membersSubscription;

  /// [Timer] unmuting the muted [chat] when its [MuteDuration.until] expires.
  Timer? _muteTimer;

  /// [ChatRepository.chatEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<ChatEvents>? _remoteSubscription;

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

  /// Indicator whether this [HiveRxChat] has been disposed, meaning no requests
  /// should be made.
  bool _disposed = false;

  /// Cursor of the last [ChatItem] read by the authenticated [MyUser].
  ChatItemsCursor? _lastReadItemCursor;

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
      final ChatItem last = messages.lastWhere((e) => !e.value.isCommand).value;
      if (item?.at.isBefore(last.at) == true || item?.isCommand == true) {
        item = last;
      }
    }

    return item;
  }

  @override
  Stream<void> get updates => _controller.stream;

  /// Indicates whether this [RxChat] is listening to the remote updates.
  bool get subscribed => _remoteSubscription != null;

  @override
  String get title {
    // [RxUser]s taking part in the [title] formation.
    //
    // Used to subscribe to the [RxUser.updates] to keep these [users]
    // up-to-date.
    final List<RxUser> users = [];

    switch (chat.value.kind) {
      case ChatKind.dialog:
        final RxUser? rxUser =
            members.values.firstWhereOrNull((u) => u.user.id != me)?.user;

        if (rxUser != null) {
          users.add(rxUser);
        }
        break;

      case ChatKind.group:
        if (chat.value.name == null) {
          users.addAll(members.values.take(3).map((e) => e.user));
        }
        break;

      case ChatKind.monolog:
      case ChatKind.artemisUnknown:
        // No-op.
        break;
    }

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

    return chat.value.getTitle(users, me);
  }

  /// Initializes this [HiveRxChat].
  Future<void> init() async {
    Log.debug('init()', '$runtimeType($id)');

    if (status.value.isSuccess) {
      return Future.value();
    }

    status.value = RxStatus.loading();

    reads.addAll(
      chat.value.lastReads.map((e) => LastChatRead(e.memberId, e.at)),
    );

    _initMessagesPagination();
    _initMembersPagination();

    _updateFields();

    if (chat.value.isDialog) {
      _updateAvatar();
      _membersPaginationSubscription = members.items.changes.listen((e) async {
        _updateAvatar();
      });
    }

    Chat previous = chat.value;
    _worker = ever(chat, (_) {
      _updateFields(previous: previous);
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

    _callSubscription = StreamGroup.mergeBroadcast([
      _chatRepository.calls.changes,
      WebUtils.onStorageChange,
    ]).listen((_) {
      inCall.value =
          _chatRepository.calls[id] != null || WebUtils.containsCall(id);
    });
  }

  /// Disposes this [HiveRxChat].
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
    _paginationSubscription?.cancel();
    _pagination.dispose();
    _messagesSubscription?.cancel();
    _callSubscription?.cancel();
    _membersSubscription?.cancel();
    _membersPaginationSubscription?.cancel();
    await _local.close();
    await _sorting.close();
    status.value = RxStatus.empty();
    _worker?.dispose();
    _userWorker?.dispose();

    for (StreamSubscription s in _userSubscriptions.values) {
      s.cancel();
    }
    for (var e in _fragments.toList()) {
      e.dispose();
    }
    for (final s in _fragmentSubscriptions) {
      s.cancel();
    }
  }

  @override
  void setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  }) {
    Log.debug(
      'setDraft($text, $attachments, $repliesTo)',
      '$runtimeType($id)',
    );

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
  Future<Paginated<ChatItemId, Rx<ChatItem>>?> around({
    ChatItemId? item,
    ChatItemId? reply,
    ChatItemId? forward,
  }) async {
    Log.debug(
      'around(item: $item, reply: $reply, forward: $forward)',
      '$runtimeType($id)',
    );

    // Even if the [item] is within [_local], still create a [MessageFragment],
    // at it handles such cases as well.
    if (item != null) {
      return _paginateAround(item, reply: reply, forward: forward);
    }

    if (id.isLocal ||
        status.value.isSuccess ||
        (hasNext.isFalse && hasPrevious.isFalse)) {
      return null;
    }

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    // Ensure [_local] and [_sorting] storages are initialized.
    await _local.init(userId: me);
    await _sorting.init(userId: me);

    // TODO: Perhaps the [messages] should be in a [MessagesPaginated] as well?
    //       This will make it easy to dispose the messages, when they aren't
    //       needed, so that RAM is freed.
    await _pagination.around(
      cursor: _lastReadItemCursor,
      key: chat.value.lastReadItem,
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

    await _pagination.next();
    status.value = RxStatus.success();

    Future.delayed(Duration.zero, updateReads);
  }

  @override
  Future<void> previous() async {
    Log.debug('previous()', '$runtimeType($id)');

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    await _pagination.previous();
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

      await _updateAttachments(item);
      _attachmentGuards.remove(item.id);
    });
  }

  /// Marks this [RxChat] as read until the provided [ChatItem] for the
  /// authenticated [MyUser],
  Future<void> read(ChatItemId untilId) async {
    Log.debug('read($untilId)', '$runtimeType($id)');

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
    Log.debug(
      'postChatMessage($existingId, $existingDateTime, $text, $attachments, $repliesTo)',
      '$runtimeType($id)',
    );

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
        remove(message.value.id);
        _pending.remove(message.value);
        message = event.item as HiveChatMessage;

        if (text?.val.startsWith('/') == false &&
            text?.val.startsWith('[@bot]') == false &&
            text?.val.contains('[no-bot]') == false) {
          if (bots.isNotEmpty) {
            final msg = message.value as ChatMessage;

            postChatMessage(
              text: ChatMessageText.bot(
                localized: {
                  const Locale('en', 'US'): ChatBotText(
                    title: 'Translation',
                    actions: [
                      const BotAction(text: 'Send', command: '/resend'),
                      BotAction(
                        text:
                            'Translate and send for \$${(1.1 / 100 * (msg.text?.val.length ?? 0)).toStringAsFixed(2)}',
                        command: '/proceed',
                      ),
                    ],
                  ),
                  const Locale('ru', 'RU'): ChatBotText(
                    title: 'Перевод',
                    actions: [
                      const BotAction(text: 'Отправить', command: '/resend'),
                      BotAction(
                        text:
                            'Перевести и отправить за \$${(1.1 / 100 * (msg.text?.val.length ?? 0)).toStringAsFixed(2)}',
                        command: '/proceed',
                      ),
                    ],
                  ),
                },
              ),
              repliesTo: [msg],
            );
          }
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
  Future<void> put(HiveChatItem item, {bool ignoreBounds = false}) async {
    Log.debug('put($item)', '$runtimeType($id)');
    await _pagination.put(item, ignoreBounds: ignoreBounds);
    for (var e in _fragments) {
      await e.pagination?.put(item, ignoreBounds: ignoreBounds);
    }

    // Put [item] to the [_local] storage if it's not stored there yet.
    if (!_local.keys.contains(item.value.id)) {
      await _local.put(item);
    }
  }

  @override
  Future<void> remove(ChatItemId itemId) async {
    Log.debug('remove($itemId)', '$runtimeType($id)');

    _pagination.remove(itemId);
    for (var e in _fragments) {
      e.pagination?.remove(itemId);
    }
    for (var e in _sorting.keys.where((e) => e.id == itemId)) {
      _sorting.remove(e);
    }

    _chatLocal.txn((txn) async {
      final HiveChat? chatEntity = await txn.get(id.val);
      if (chatEntity?.value.lastItem?.id == itemId) {
        var lastItem = messages.lastWhereOrNull((e) => e.value.id != itemId);

        if (lastItem != null) {
          chatEntity?.value.lastItem = lastItem.value;
          chatEntity?.lastItemCursor =
              (await _local.get(lastItem.value.id))?.cursor;
        } else {
          chatEntity?.value.lastItem = null;
          chatEntity?.lastItemCursor = null;
        }

        await _putChat(chatEntity!, txn);
      }
    });
  }

  /// Returns the stored or fetched [HiveChatItem] identified by the provided
  /// [itemId].
  Future<HiveChatItem?> get(ChatItemId itemId) async {
    Log.debug('get($itemId)', '$runtimeType($id)');

    HiveChatItem? item = _pagination.items[itemId];
    item ??= _fragments
        .firstWhereOrNull((e) => e.pagination?.items[itemId] != null)
        ?.pagination
        ?.items[itemId];
    item ??= await _local.get(itemId);

    if (item == null) {
      try {
        item = await _chatRepository.message(itemId);
      } catch (_) {
        // No-op.
      }

      if (item != null) {
        await put(item);
      }
    }

    return item;
  }

  /// Recalculates the [reads] to represent the actual [messages].
  void updateReads() {
    Log.debug('updateReads()', '$runtimeType($id)');

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
  Future<void> updateChat(HiveChat newChat) async {
    Log.debug('updateChat($newChat)', '$runtimeType($id)');

    if (chat.value.id != newChat.value.id) {
      chat.value = newChat.value;
      ver = newChat.ver;

      if (!_controller.isPaused && !_controller.isClosed) {
        _initRemoteSubscription();
      }

      // Retrieve all the [HiveChatItem]s to put them in the [newChat].
      final Iterable<HiveChatItem> saved = await _local.values;

      final local = ChatItemHiveProvider(id);
      await local.init(userId: me);

      final sorting = ChatItemSortingHiveProvider(id);
      await sorting.init(userId: me);

      // Clear and close the current [Hive] providers.
      await _local.clear();
      await _sorting.clear();
      _local.close();
      _sorting.close();

      await clear();

      _local = local;
      _sorting = sorting;
      _provider.hive = _local;

      for (var e in saved.whereType<HiveChatMessage>()) {
        // Copy the [HiveChatMessage] to the new [ChatItemHiveProvider].
        final HiveChatMessage copy = e.copyWith()
          ..value.chatId = newChat.value.id;

        if (copy.value.status.value == SendingStatus.error) {
          copy.value.status.value = SendingStatus.sending;
        }

        put(copy, ignoreBounds: true);
      }

      await _pagination.around();
    }
  }

  /// Clears the [_pagination] and [_fragments].
  Future<void> clear() async {
    Log.debug('clear()', '$runtimeType($id)');

    for (var e in _fragments) {
      e.dispose();
    }
    _fragments.clear();

    await _pagination.clear();

    await _local.clear();
    await _sorting.clear();

    // [Chat.members] don't change in dialogs or monologs, no need to clear it.
    if (chat.value.isGroup) {
      await members.clear();
    }
  }

  // TODO: Remove when backend supports welcome messages.
  @override
  Future<void> addMessage(ChatMessageText text) async {
    Log.debug('addMessage($text)', '$runtimeType($id)');

    await put(
      HiveChatMessage(
        ChatMessage(
          ChatItemId.local(),
          id,
          chat.value.members.firstWhereOrNull((e) => e.user.id != me)?.user ??
              User(
                const UserId('a0960769-d44a-46e9-ba43-cb41e045318a'),
                UserNum('1234123412341234'),
              ),
          PreciseDateTime.now(),
          text: text,
        ),
        null,
        ChatItemVersion('0'),
        null,
      ),
    );
  }

  /// Updates the [avatar] of the [chat].
  ///
  /// Intended to be used to update the [StorageFile.relativeRef] links.
  @override
  Future<void> updateAvatar() async {
    Log.debug('updateAvatar()', '$runtimeType($id)');

    final ChatAvatar? avatar = await _chatRepository.avatar(id);

    await _chatLocal.txn((txn) async {
      final HiveChat? chatEntity = await txn.get(id.val);
      if (chatEntity != null) {
        chatEntity.value.avatar = avatar;

        // TODO: Avatar should be updated by [Hive] subscription.
        this.avatar.value = avatar;

        await _putChat(chatEntity, txn);
      }
    });
  }

  @override
  final RxObsList<RxUser> bots = RxObsList();

  @override
  Future<void> addBot(RxUser user, {bool first = true}) async {
    if (first) {
      await postChatMessage(
        text: ChatMessageText.bot(
          localized: {
            const Locale('en', 'US'): const ChatBotText(
              title: 'Translation',
              text:
                  'Translation service is enabled. Certificated translators in real-time. [Terms and services](https://google.com)',
            ),
            const Locale('ru', 'RU'): const ChatBotText(
              title: 'Перевод',
              text:
                  'Подключен переводческий сервис. Сертифицированные переводчики в режиме реального времени. [Условия использования](https://google.com)',
            ),
          },
        ),
      );
    }

    bots.addIf(!bots.contains(user), user);
  }

  @override
  Future<void> removeBot(RxUser user) async {
    bots.remove(user);

    await postChatMessage(text: ChatMessageText('/kick @${user.id}'));
  }

  @override
  int compareTo(RxChat other) => chat.value.compareTo(other.chat.value, me);

  /// Puts the provided [member] to the [members].
  Future<void> _putMember(
    HiveChatMember member, {
    bool ignoreBounds = false,
  }) =>
      members.put(member, ignoreBounds: ignoreBounds);

  /// Initializes the messages [_pagination].
  Future<void> _initMessagesPagination() async {
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
            _chatLocal.txn((txn) async {
              final HiveChat? chatEntity = await txn.get(id.val);
              final ChatItem? firstItem = page.edges.firstOrNull?.value;

              if (chatEntity != null &&
                  firstItem != null &&
                  chatEntity.value.firstItem != firstItem) {
                chatEntity.value.firstItem = firstItem;
                await _putChat(chatEntity, txn);
              }
            });
          }

          return reversed;
        },
      ),
      hiveProvider: HivePageProvider(
        _local,
        getCursor: (e) => e?.cursor,
        getKey: (e) => e.value.id,
        orderBy: (_) => _sorting.values,
        isFirst: (e) =>
            id.isLocal || (e != null && chat.value.firstItem?.id == e.value.id),
        isLast: (e) =>
            id.isLocal || (e != null && chat.value.lastItem?.id == e.value.id),
        strategy: PaginationStrategy.fromEnd,
      ),
    );

    _pagination = Pagination(
      onKey: (e) => e.value.id,
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
        case OperationKind.updated:
          final ChatItem item = event.value!.value;
          _add(item);

          if (!_sorting.keys.contains(item.key)) {
            _sorting.put(item.key);
          }
          break;

        case OperationKind.removed:
          messages.removeWhere((e) => e.value.id == event.value?.value.id);
          break;
      }
    });

    await _local.init(userId: me);
    await _sorting.init(userId: me);

    HiveChatItem? item;

    // If [_local] storage is empty, then there's no need to initialize the
    // [_pagination], as it fetches its items from [_local] by this method.
    if (chat.value.lastReadItem != null && _local.keys.isNotEmpty) {
      item = await get(chat.value.lastReadItem!);
      await _pagination.init(item?.value.id);
    }

    if (_pagination.items.isNotEmpty) {
      status.value = RxStatus.success();
    }
  }

  /// Initializes the [members] pagination.
  Future<void> _initMembersPagination() async {
    members = MembersPaginated(
      transform: ({
        required HiveChatMember data,
        RxChatMember? previous,
      }) {
        final FutureOr<RxUser?> userOrFuture =
            _chatRepository.getUser(data.value.user.id);

        if (userOrFuture is RxUser) {
          return RxChatMember(userOrFuture, data.value.joinedAt);
        } else {
          return Future(() async {
            final RxUser? user = await userOrFuture;

            if (user != null) {
              return RxChatMember(user, data.value.joinedAt);
            }

            return null;
          });
        }
      },
      pagination: Pagination(
        onKey: (e) => e.value.user.id,
        perPage: 15,
        provider: HiveGraphQlPageProvider(
          hiveProvider: HivePageProvider(
            _membersLocal,
            getCursor: (HiveChatMember? item) => item?.cursor,
            getKey: (HiveChatMember item) => item.value.user.id,
            orderBy: (_) => _membersSorting.values,
            isFirst: (_) =>
                _membersSorting.values.length >= chat.value.membersCount,
            isLast: (_) =>
                _membersSorting.values.length >= chat.value.membersCount,
          ),
          graphQlProvider:
              GraphQlPageProvider<HiveChatMember, ChatMembersCursor, UserId>(
            fetch: ({after, before, first, last}) async {
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
        compare: (a, b) => a.value.compareTo(b.value),
      ),
      initial: [
        // Ensure [_membersLocal] and [_membersSorting] storages are
        // initialized.
        Future(() async {
          await _membersLocal.init(userId: me);
          await _membersSorting.init(userId: me);

          return {};
        }),
      ],
    );

    // [Chat] always contains first 3 members (due to GraphQL query specifying
    // those in the fragment), so we can immediately put them.
    if (chat.value.members.isNotEmpty || id.isLocal) {
      for (ChatMember member in chat.value.members) {
        _putMember(HiveChatMember(member, null), ignoreBounds: true);
      }

      if (members.rawLength == chat.value.membersCount) {
        members.pagination?.hasNext.value = false; // TODO: Still displayed?
        members.pagination?.hasPrevious.value = false;
        members.status.value = RxStatus.success();
      }
    }

    await _membersLocal.init(userId: me);
    await _membersSorting.init(userId: me);

    _initMembersLocalSubscription();
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
    final HiveChatItem? hiveItem = await get(item);

    final ChatItemsCursor? cursor;
    final ChatItemId key = forward ?? reply ?? item;

    // If [reply] or [forward] is provided, then the [item] should contain it,
    // let's try to retrieve the key and cursor to paginate around it.
    if (reply != null) {
      if (hiveItem is! HiveChatMessage) {
        throw ArgumentError.value(
          item,
          'item',
          'Should be `ChatMessage`\'s ID, if `reply` is provided.',
        );
      }

      final ChatMessage message = hiveItem.value as ChatMessage;
      final int replyIndex =
          message.repliesTo.indexWhere((e) => e.original?.id == reply);
      if (replyIndex == -1) {
        throw ArgumentError.value(reply, 'reply', 'Not found.');
      }

      cursor = hiveItem.repliesToCursors?.elementAt(replyIndex);
    } else if (forward != null) {
      if (hiveItem is! HiveChatForward) {
        throw ArgumentError.value(
          item,
          'item',
          'Should be `ChatForward`\'s ID, if `forward` is provided.',
        );
      }

      cursor = hiveItem.quoteCursor;
    } else {
      cursor = hiveItem?.cursor;
    }

    // Try to find any [MessagesPaginated] already containing the item requested.
    MessagesPaginated? fragment = _fragments.firstWhereOrNull(
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

    _fragments.add(
      fragment = MessagesPaginated(
        initialKey: key,
        initialCursor: cursor,
        transform: ({required HiveChatItem data, Rx<ChatItem>? previous}) {
          if (previous != null) {
            return previous..value = data.value;
          }

          return Rx(data.value);
        },
        pagination: Pagination(
          onKey: (e) => e.value.id,
          provider: _provider,
          perPage: perPage,
          compare: (a, b) => a.value.key.compareTo(b.value.key),
        ),
        onDispose: () {
          _fragments.remove(fragment);
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
    Log.debug('_add($item)', '$runtimeType($id)');

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
        () async {
          await _chatLocal.txn((txn) async {
            final HiveChat? chat = await txn.get(id.val);
            if (chat != null) {
              chat.value.muted = null;
              await _putChat(chat, txn);
            }
          });
        },
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

    PreciseDateTime? lastReadAt =
        _lastReadAmong(at, messages: messages, hasNext: hasNext.isTrue);

    for (var fragment in _fragments) {
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

    final Rx<ChatItem>? message = messages
        .lastWhereOrNull((e) => e.value is! ChatInfo && e.value.at <= at);

    // Return `null` if [hasNext] because the provided [at] can be actually
    // connected to another [message].
    if (message == null || hasNext && messages.last == message) {
      return null;
    } else {
      return message.value.at;
    }
  }

  /// Re-fetches the [Attachment]s of the specified [item] to be up-to-date.
  Future<void> _updateAttachments(ChatItem item) async {
    Log.debug('_updateAttachments($item)', '$runtimeType($id)');

    final HiveChatItem? stored = await get(item.id);
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
      put(stored);
    }
  }

  /// Initializes [ChatMemberHiveProvider.boxEvents] subscription.
  Future<void> _initMembersLocalSubscription() async {
    Log.debug('_initMembersLocalSubscription()', '$runtimeType');

    _membersSubscription = StreamIterator(_membersLocal.boxEvents);
    while (await _membersSubscription!.moveNext()) {
      final BoxEvent event = _membersSubscription!.current;
      final UserId userId = UserId(event.key);

      if (event.deleted) {
        _membersSorting.remove(userId);
      } else {
        final HiveChatMember value = event.value;
        _membersSorting.put(value.value.joinedAt, userId);
      }
    }
  }

  /// Initializes [ChatRepository.chatEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    if (_disposed) {
      return;
    }

    Log.debug('_initRemoteSubscription()', '$runtimeType($id)');

    if (!id.isLocal) {
      _remoteSubscription?.close(immediate: true);
      _remoteSubscription = StreamQueue(
        _chatRepository.chatEvents(id, ver, () => ver),
      );

      await _remoteSubscription!.execute(
        _chatEvent,
        onError: (e) async {
          if (e is StaleVersionException) {
            await clear();
            await _pagination.around(cursor: _lastReadItemCursor);
          }
        },
      );

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
        await _chatLocal.txn((txn) async {
          final HiveChat? chatEntity = await txn.get(id.val);
          if (chatEntity != null) {
            chatEntity.value = node.chat.value;
            chatEntity.ver = node.chat.ver;
            await _putChat(chatEntity, txn);
          } else {
            await _putChat(node.chat, txn);
          }
        });

        _lastReadItemCursor = node.chat.lastReadItemCursor;
        break;

      case ChatEventsKind.event:
        await _chatLocal.txn((txn) async {
          final HiveChat? chatEntity = await txn.get(id.val);
          final ChatEventsVersioned versioned =
              (event as ChatEventsEvent).event;
          if (chatEntity == null ||
              versioned.ver < chatEntity.ver ||
              !subscribed) {
            Log.debug(
              '_chatEvent(${event.kind}): ignored ${versioned.events.map((e) => e.kind)}',
              '$runtimeType($id)',
            );

            // Be sure to keep the [chat] up to date with the [chatEntity], when
            // in [WebUtils.isPopup], as in such cases local Hive subscriptions
            // might not work due to Hive restrictions in multiple Web tabs.
            if (WebUtils.isPopup) {
              chat.value = chatEntity?.value ?? chat.value;
            }

            return;
          }

          Log.debug(
            '_chatEvent(${event.kind}): ${versioned.events.map((e) => e.kind)}',
            '$runtimeType($id)',
          );

          chatEntity.ver = versioned.ver;

          // Use the [chat] value instead of [chatEntity], when in
          // [WebUtils.isPopup], as in such cases we can't rely on [Hive] having
          // actual data (especially when multiple events are received one after
          // another).
          if (WebUtils.isPopup) {
            chatEntity.value = chat.value;
          }

          bool shouldPutChat = subscribed;

          for (var event in versioned.events) {
            shouldPutChat = subscribed;

            // Subscription was already disposed while processing the events.
            if (!subscribed) {
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
                await clear();
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
                chatEntity.value.isHidden = true;
                continue;

              case ChatEventKind.itemDeleted:
                event as EventChatItemDeleted;
                await remove(event.itemId);
                break;

              case ChatEventKind.itemEdited:
                event as EventChatItemEdited;
                final item = await get(event.itemId);
                if (item != null) {
                  final message = item.value as ChatMessage;
                  message.text =
                      event.text != null ? event.text!.newText : message.text;
                  message.attachments =
                      event.attachments ?? message.attachments;
                  message.repliesTo =
                      event.quotes?.map((e) => e.value).toList() ??
                          message.repliesTo;
                  (item as HiveChatMessage).repliesToCursors =
                      event.quotes?.map((e) => e.cursor).toList() ??
                          item.repliesToCursors;
                  put(item);
                }

                if (chatEntity.value.lastItem?.id == event.itemId) {
                  final message = chatEntity.value.lastItem as ChatMessage;
                  message.text =
                      event.text != null ? event.text!.newText : message.text;
                  message.attachments =
                      event.attachments ?? message.attachments;
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
                  chatEntity.value.ongoingCall = event.call;
                  _chatRepository.addCall(event.call);
                }

                final message = await get(event.call.id);

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
                  unreadCount.value +=
                      event.count - chatEntity.value.unreadCount;
                }

                chatEntity.value.unreadCount = event.count;
                break;

              case ChatEventKind.callFinished:
                event as EventChatCallFinished;

                if (chatEntity.value.ongoingCall?.id == event.call.id) {
                  chatEntity.value.ongoingCall = null;
                }

                if (chatEntity.value.lastItem?.id == event.call.id) {
                  chatEntity.value.lastItem = event.call;
                }

                if (event.reason != ChatCallFinishReason.moved) {
                  _chatRepository.removeCredentials(
                    event.call.chatId,
                    event.call.id,
                  );
                  _chatRepository.endCall(event.call.chatId);
                }

                final message = await get(event.call.id);

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

                if (chatEntity.value.ongoingCall?.conversationStartedAt ==
                        null &&
                    chat.value.isDialog) {
                  final Set<UserId>? ids = chatEntity.value.ongoingCall?.members
                      .map((e) => e.user.id)
                      .toSet();

                  if (ids != null && ids.length >= 2) {
                    chatEntity.value.ongoingCall?.conversationStartedAt =
                        event.call.conversationStartedAt ?? event.at;

                    if (chatEntity.value.ongoingCall != null) {
                      final call = chatEntity.value.ongoingCall!;
                      final message = await get(call.id);

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

                // TODO: [ChatCall.conversationStartedAt] shouldn't be `null`
                //       here when starting group or monolog [ChatCall].
                if (!chatEntity.value.isDialog &&
                    chatEntity.value.lastItem is ChatCall) {
                  (chatEntity.value.lastItem as ChatCall)
                      .conversationStartedAt ??= PreciseDateTime.now();
                }

                chatEntity.value.updatedAt =
                    event.lastItem?.value.at ?? chatEntity.value.updatedAt;
                if (event.lastItem != null) {
                  await put(event.lastItem!);
                }
                break;

              case ChatEventKind.delivered:
                event as EventChatDelivered;
                chatEntity.value.lastDelivery = event.until;
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
                        _sorting.keys.lastWhereOrNull((e) => e.at == at);
                    if (key != null) {
                      final HiveChatItem? item = await _local.get(key.id);
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
                  final ChatMessage? pending =
                      _pending.whereType<ChatMessage>().firstWhereOrNull(
                            (e) =>
                                e.status.value == SendingStatus.sending &&
                                (item.value as ChatMessage).isEquals(e),
                          );

                  // If any [ChatMessage] sharing the same fields as the posted
                  // one is found in the [_pending] messages, and this message
                  // is not yet added to the store, then remove the [pending].
                  if (pending != null &&
                      await _local.get(item.value.id) == null) {
                    remove(pending.id);
                    _pending.remove(pending);
                  }
                }

                put(item);

                if (item.value is ChatInfo) {
                  final msg = item.value as ChatInfo;

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

                      chatEntity.value.membersCount++;

                      // Store the first 3 [ChatMember]s in the [Chat.members]
                      // to display default [Chat]s name.
                      if (chatEntity.value.members.length < 3) {
                        chatEntity.value.members.add(
                          ChatMember(action.user, msg.at),
                        );
                      }

                      _putMember(
                        HiveChatMember(ChatMember(action.user, msg.at), null),
                      );
                      break;

                    case ChatInfoActionKind.memberRemoved:
                      final action = msg.action as ChatInfoActionMemberRemoved;

                      chatEntity.value.membersCount--;

                      await members.remove(action.user.id);

                      chatEntity.value.members
                          .removeWhere((e) => e.user.id == action.user.id);

                      if (chatEntity.value.members.length < 3) {
                        if (members.rawLength < 3) {
                          await members.next();
                        }

                        chatEntity.value.members.clear();
                        for (var m
                            in members.pagination!.items.values.take(3)) {
                          chatEntity.value.members.add(m.value);
                        }
                      }

                      _chatRepository.onMemberRemoved(id, action.user.id);
                      break;

                    case ChatInfoActionKind.nameUpdated:
                      final action = msg.action as ChatInfoActionNameUpdated;
                      chatEntity.value.name = action.name;
                      break;
                  }
                }

                if (item is HiveChatMessage) {
                  final msg = item.value as ChatMessage;

                  if (bots.isEmpty) {
                    if (msg.text?.val.startsWith('[@bot]') == true) {
                      final userService = Get.findOrNull<UserService>();

                      if (userService != null) {
                        final search =
                            userService.search(login: UserLogin('translateit'));
                        search.around().then((_) {
                          final user = search.items.values.firstOrNull;
                          if (user?.isBot ?? false) {
                            addBot(user!, first: false);
                          }
                        });
                      }
                    }
                  } else {
                    if (msg.text?.val.startsWith('/kick @') == true) {
                      final id = msg.text!.val.replaceFirst('/kick @', '');
                      bots.removeWhere((e) => e.id.val == id);
                    }
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

          if (shouldPutChat) {
            await _putChat(chatEntity, txn);
          }
        });
        break;
    }
  }

  /// Puts the provided [chat] to the [Hive] using the provided [txn].
  Future<void> _putChat(HiveChat chat, HiveTransaction<HiveChat> txn) async {
    // TODO: Don't write to [Hive] from popup, as [Hive] doesn't support isolate
    //       synchronization, thus writes from multiple applications may lead to
    //       missing events:
    //       https://github.com/team113/messenger/issues/27
    if (WebUtils.isPopup) {
      this.chat.value = chat.value;
      this.chat.refresh();
    } else {
      await txn.put(chat.value.id.val, chat);
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
