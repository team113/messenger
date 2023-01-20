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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/schema.dart'
    show
        ChatCallFinishReason,
        ChatKind,
        ChatMemberInfoAction,
        PostChatMessageErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show
        ConnectionException,
        NotChatMemberException,
        PostChatMessageException,
        ResubscriptionRequiredException,
        StaleVersionException;
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/draft.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatViewExt;
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import 'chat.dart';
import 'event/chat.dart';

/// [RxChat] implementation backed by local [Hive] storage.
class HiveRxChat extends RxChat {
  HiveRxChat(
    this._chatRepository,
    this._chatLocal,
    this._draftLocal,
    HiveChat hiveChat,
  )   : chat = Rx<Chat>(hiveChat.value),
        _local = ChatItemHiveProvider(hiveChat.value.id),
        draft = Rx<ChatMessage?>(_draftLocal.get(hiveChat.value.id));

  @override
  final Rx<Chat> chat;

  @override
  final RxObsList<Rx<ChatItem>> messages = RxObsList<Rx<ChatItem>>();

  @override
  final Rx<RxStatus> status = Rx<RxStatus>(RxStatus.empty());

  @override
  final RxList<User> typingUsers = RxList<User>([]);

  @override
  final RxMap<UserId, RxUser> members = RxMap<UserId, RxUser>();

  @override
  final RxString title = RxString('');

  @override
  final Rx<Avatar?> avatar = Rx<Avatar?>(null);

  @override
  final Rx<ChatMessage?> draft;

  @override
  final RxList<LastChatRead> reads = RxList();

  /// [ChatRepository] used to cooperate with the other [HiveRxChat]s.
  final ChatRepository _chatRepository;

  /// [Chat]s local [Hive] storage.
  final ChatHiveProvider _chatLocal;

  /// [RxChat.draft]s local [Hive] storage.
  final DraftHiveProvider _draftLocal;

  /// [ChatItem]s local [Hive] storage.
  ChatItemHiveProvider _local;

  /// Guard used to guarantee synchronous access to the [_local] storage.
  final Mutex _guard = Mutex();

  /// Subscription to [User]s from the [members] list forming the [title].
  final Map<UserId, Worker> _userWorkers = {};

  /// [Worker] reacting on the [User] changes updating the [avatar].
  Worker? _userWorker;

  /// [Timer] unmutting the muted [chat] when its [MuteDuration.until] expires.
  Timer? _muteTimer;

  /// [ChatItemHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// [ChatRepository.chatEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamIterator<ChatEvents>? _remoteSubscription;

  /// [Worker] reacting on the [chat] changes updating the [members].
  Worker? _worker;

  /// Indicator whether [_remoteSubscription] is initialized or is being
  /// initialized used in [subscribe].
  bool _remoteSubscriptionInitialized = false;

  /// [ChatItem]s in the [SendingStatus.sending] state.
  final List<ChatItem> _pending = [];

  /// [StreamSubscription] to [messages] recalculating the [reads] on removals.
  StreamSubscription? _messagesSubscription;

  @override
  UserId? get me => _chatRepository.me;

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

  /// Initializes this [HiveRxChat].
  Future<void> init() {
    if (status.value.isSuccess) {
      return Future.value();
    }

    status.value = RxStatus.loading();

    reads.addAll(
      chat.value.lastReads.map((e) => LastChatRead(e.memberId, e.at)),
    );

    _updateTitle(chat.value.members.map((e) => e.user));
    _updateFields().then((_) => chat.value.isGroup ? null : _updateAvatar());
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

    return _guard.protect(() async {
      await _local.init(userId: me);
      if (!_local.isEmpty) {
        for (HiveChatItem i in _local.messages) {
          messages.add(Rx<ChatItem>(i.value));
        }

        updateReads();
      }

      _initLocalSubscription();

      if (!PlatformUtils.isWeb) {
        final List<Future> futures = [];

        for (ChatItem item in messages.map((e) => e.value)) {
          if (item is ChatMessage) {
            futures.addAll(item.attachments
                .whereType<FileAttachment>()
                .map((e) => e.init()));
          } else if (item is ChatForward) {
            ChatItem nested = item.item;
            if (nested is ChatMessage) {
              futures.addAll(nested.attachments
                  .whereType<FileAttachment>()
                  .map((e) => e.init()));
            }
          }
        }

        await Future.wait(futures);
      }

      status.value = RxStatus.success();
    });
  }

  /// Disposes this [HiveRxChat].
  Future<void> dispose() {
    return _guard.protect(() async {
      status.value = RxStatus.loading();
      messages.clear();
      reads.clear();
      _muteTimer?.cancel();
      _localSubscription?.cancel();
      _remoteSubscription?.cancel();
      _messagesSubscription?.cancel();
      _remoteSubscriptionInitialized = false;
      await _local.close();
      status.value = RxStatus.empty();
      _worker?.dispose();
      _userWorker?.dispose();
      for (var e in _userWorkers.values) {
        e.dispose();
      }
    });
  }

  /// Subscribes to the remote updates of the [chat] if not subscribed already.
  void subscribe() {
    if (!_remoteSubscriptionInitialized && !id.isLocal) {
      _initRemoteSubscription(id);
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
        (draft?.repliesTo ?? []).map((e) => e.id),
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
          me ?? const UserId('dummy'),
          PreciseDateTime.now(),
          text: text,
          repliesTo: repliesTo,
          attachments: attachments,
        );
        _draftLocal.put(id, draft);
      }
    }
  }

  @override
  Future<void> fetchMessages() async {
    if (id.isLocal) {
      return;
    }

    if (!status.value.isLoading) {
      status.value = RxStatus.loadingMore();
    }

    List<HiveChatItem> items = await _chatRepository.messages(chat.value.id);

    return _guard.protect(() async {
      for (HiveChatItem item in _local.messages) {
        if (item.value.status.value == SendingStatus.sent) {
          int i = items.indexWhere((e) => e.value.id == item.value.id);
          if (i == -1) {
            _local.remove(item.value.timestamp);
          }
        }
      }

      for (HiveChatItem item in items) {
        if (item.value.chatId == id) {
          put(item);
        } else {
          _chatRepository.putChatItem(item);
        }
      }

      Future.delayed(Duration.zero, updateReads);
      status.value = RxStatus.success();
    });
  }

  @override
  Future<void> updateAttachments(ChatItem item) async {
    if (item.id.isLocal) {
      return;
    }

    HiveChatItem? stored = await get(item.id, timestamp: item.timestamp);
    if (stored != null) {
      List<Attachment> response = await _chatRepository.attachments(stored);

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
        for (ChatItem replied in item.repliesTo) {
          if (replied is ChatMessage) {
            all.addAll(replied.attachments);
          }
        }
      } else if (item is ChatForward) {
        ChatItem nested = item.item;
        if (nested is ChatMessage) {
          all.addAll(nested.attachments);
          for (ChatItem replied in nested.repliesTo) {
            if (replied is ChatMessage) {
              all.addAll(replied.attachments);
            }
          }
        }
      }

      for (Attachment a in all) {
        replace(a);
      }

      put(stored, ignoreVersion: true);
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
  Future<void> postChatMessage({
    ChatItemId? existingId,
    PreciseDateTime? existingDateTime,
    ChatMessageText? text,
    List<Attachment>? attachments,
    List<ChatItem> repliesTo = const [],
  }) async {
    // Copy the [attachments] list since we're going to manipulate it here.
    List<Attachment> uploaded = List.from(attachments ?? []);
    List<ChatItem> replies = List.from(repliesTo, growable: false);

    HiveChatMessage message = HiveChatMessage.sending(
      chatId: chat.value.id,
      me: me!,
      text: text,
      repliesTo: replies,
      attachments: uploaded,
      existingId: existingId,
      existingDateTime: existingDateTime,
    );

    // Storing the already stored [ChatMessage] is meaningless as it creates
    // lag spikes, so update it's reactive value directly.
    if (existingId != null) {
      messages.firstWhere((e) => e.value.id == existingId).value =
          message.value;
    } else {
      put(message, ignoreVersion: true);
    }

    _pending.add(message.value);

    try {
      if (attachments != null) {
        List<Future> uploads = attachments
            .mapIndexed((i, e) {
              if (e is LocalAttachment) {
                return e.upload.value?.future.then(
                  (a) {
                    uploaded[i] = a;

                    // Frequent [Hive] writes of byte data freezes the Web page.
                    if (!PlatformUtils.isWeb) {
                      put(message, ignoreVersion: true);
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
            put(message, ignoreVersion: true);
          }
        }

        await Future.wait(uploads);
      }

      if (uploaded.whereType<LocalAttachment>().isNotEmpty) {
        throw const ConnectionException(PostChatMessageException(
          PostChatMessageErrorCode.unknownAttachment,
        ));
      }

      var response = await _chatRepository.postChatMessage(
        id,
        text: text,
        attachments:
            uploaded.isNotEmpty ? uploaded.map((e) => e.id).toList() : null,
        repliesTo: replies.map((e) => e.id).toList(),
      );

      var event = response?.events
              .map((e) => _chatRepository.chatEvent(e))
              .firstWhereOrNull((e) => e is EventChatItemPosted)
          as EventChatItemPosted?;

      if (event != null && event.item.firstOrNull is HiveChatMessage) {
        remove(message.value.id, message.value.timestamp);
        _pending.remove(message.value);
        message = event.item.first as HiveChatMessage;
      }
    } catch (e) {
      message.value.status.value = SendingStatus.error;
      _pending.remove(message.value);
      rethrow;
    } finally {
      put(message, ignoreVersion: true);
    }
  }

  /// Updates the [chat] value with provided.
  ///
  /// Intended to be used to update a local dialog with a remote.
  Future<void> updateChat(Chat chat) async {
    this.chat.value = chat;

    _initRemoteSubscription(chat.id);

    _local = ChatItemHiveProvider(chat.id);
    await _local.init(userId: me);
    _localSubscription?.cancel();
    _initLocalSubscription();
  }

  /// Puts the provided [item] to [Hive].
  Future<void> put(HiveChatItem item, {bool ignoreVersion = false}) {
    return _guard.protect(
      () => Future.sync(() {
        if (!_local.isReady) {
          return;
        }

        HiveChatItem? saved = _local.get(item.value.timestamp);
        if (saved == null) {
          _local.put(item);
        } else {
          if (saved.value.id.val != item.value.id.val) {
            // TODO: Sort items by their [DateTime] and their [ID]s (if the
            //       posting [DateTime] is the same).
            // If there's collision, then decrease timestamp with 1 millisecond
            // offset and save this item again.
            item.value.at =
                item.value.at.subtract(const Duration(milliseconds: 1));
            put(item);
          } else if (saved.ver < item.ver || ignoreVersion) {
            _local.put(item);
          }
        }
      }),
    );
  }

  @override
  Future<void> remove(ChatItemId itemId, [String? timestamp]) {
    return _guard.protect(
      () => Future.sync(() {
        if (!_local.isReady) {
          return;
        }

        // TODO: Implement `ChatItemId` to timestamp lookup table.
        timestamp ??= messages
            .firstWhereOrNull((e) => e.value.id == itemId)
            ?.value
            .timestamp;
        if (timestamp != null) {
          _local.remove(timestamp!);

          HiveChat? chatEntity = _chatLocal.get(id);
          if (chatEntity?.value.lastItem?.id == itemId) {
            var lastItem =
                messages.lastWhereOrNull((e) => e.value.id != itemId);
            chatEntity!.value.lastItem = lastItem?.value;
            if (lastItem != null) {
              chatEntity.lastItemCursor =
                  _local.get(lastItem.value.timestamp)?.cursor;
            } else {
              chatEntity.lastItemCursor = null;
            }
            chatEntity.save();
          }
        }
      }),
    );
  }

  /// Returns a stored [HiveChatItem] identified by the provided [id], if any.
  ///
  /// Optionally, a [timestamp] may be specified, otherwise it will be fetched
  /// from the [messages] list.
  Future<HiveChatItem?> get(ChatItemId id, {String? timestamp}) async {
    return _guard.protect(
      () => Future.sync(() {
        if (!_local.isReady) {
          return null;
        }

        timestamp ??=
            messages.firstWhereOrNull((e) => e.value.id == id)?.value.timestamp;

        HiveChatItem? result;
        if (timestamp != null) {
          while (true) {
            var saved = _local.get(timestamp!);
            if (saved == null) {
              result = null;
              break;
            } else {
              if (saved.value.id == id) {
                result = saved;
                break;
              } else {
                timestamp =
                    DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp!))
                        .subtract(const Duration(milliseconds: 1))
                        .millisecondsSinceEpoch
                        .toString();
              }
            }
          }
        }

        return result;
      }),
    );
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

  /// Updates the [members] and [title] fields based on the [chat] state.
  Future<void> _updateFields() async {
    if (chat.value.name != null) {
      _updateTitle();
    }

    if (chat.value.isGroup) {
      avatar.value = chat.value.avatar;
    }

    _muteTimer?.cancel();
    if (chat.value.muted?.until != null) {
      _muteTimer = Timer(
        chat.value.muted!.until!.val.difference(DateTime.now()),
        () {
          final HiveChat? chat = _chatLocal.get(id);
          if (chat != null) {
            chat.value.muted = null;
            _chatLocal.put(chat);
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
      case ChatKind.monolog:
        member = members.values.firstOrNull;
        break;

      case ChatKind.dialog:
        member = members.values.firstWhereOrNull((e) => e.id != me);
        break;

      case ChatKind.group:
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
    return messages
        .lastWhereOrNull((e) => e.value is! ChatMemberInfo && e.value.at <= at)
        ?.value
        .at;
  }

  /// Initializes [ChatItemHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_local.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      int i = messages.indexWhere((e) => e.value.timestamp == event.key);
      if (event.deleted) {
        if (i != -1) {
          messages.removeAt(i);
        }
      } else {
        if (!PlatformUtils.isWeb) {
          ChatItem item = event.value.value;
          if (item is ChatMessage) {
            for (var a in item.attachments.whereType<FileAttachment>()) {
              a.init();
            }
          } else if (item is ChatForward) {
            ChatItem nested = item.item;
            if (nested is ChatMessage) {
              for (var a in nested.attachments.whereType<FileAttachment>()) {
                a.init();
              }
            }
          }
        }

        if (i == -1) {
          Rx<ChatItem> item = Rx<ChatItem>(event.value.value);
          messages.insertAfter(
            item,
            (e) => item.value.at.compareTo(e.value.at) == 1,
          );
        } else {
          messages[i].value = event.value.value;
          messages[i].refresh();
        }
      }
    }
  }

  /// Initializes [ChatRepository.chatEvents] subscription.
  Future<void> _initRemoteSubscription(
    ChatId chatId, {
    bool noVersion = false,
  }) async {
    _remoteSubscriptionInitialized = true;
    var ver = noVersion ? null : _chatLocal.get(id)?.ver;

    _remoteSubscription?.cancel();
    _remoteSubscription =
        StreamIterator(await _chatRepository.chatEvents(chatId, ver));
    while (await _remoteSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      Future.delayed(Duration.zero, () => _initRemoteSubscription(chatId));
      return false;
    }).onError<NotChatMemberException>((_, __) {
      _chatRepository.remove(id);
      return false;
    }).onError<StaleVersionException>((_, __) {
      Future.delayed(
        Duration.zero,
        () => _initRemoteSubscription(chatId, noVersion: true),
      );
      return false;
    })) {
      await _chatEvent(_remoteSubscription!.current);
    }

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
        HiveChat? chatEntity = _chatLocal.get(id);
        if (node.chat.ver > chatEntity?.ver) {
          chatEntity = node.chat;
          _chatLocal.put(chatEntity);
        }
        break;

      case ChatEventsKind.event:
        HiveChat? chatEntity = _chatLocal.get(id);
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
            case ChatEventKind.renamed:
              event as EventChatRenamed;
              chatEntity.value.name = event.chatName;
              break;

            case ChatEventKind.redialed:
              // TODO: Implement EventChatCallMemberRedialed.
              break;

            case ChatEventKind.cleared:
              await _guard.protect(_local.clear);
              break;

            case ChatEventKind.itemHidden:
              event as EventChatItemHidden;
              await remove(event.itemId);
              break;

            case ChatEventKind.muted:
              event as EventChatMuted;
              chatEntity.value.muted = event.duration;
              break;

            case ChatEventKind.avatarDeleted:
              chatEntity.value.avatar = null;
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
              await _guard.protect(
                () => Future.sync(() {
                  // TODO: Implement `ChatItemId` to timestamp lookup table.
                  var message = _local.messages
                      .firstWhereOrNull((e) => e.value.id == event.itemId);
                  if (message != null) {
                    (message.value as ChatMessage).text = event.text;
                    message.save();
                  }
                }),
              );
              break;

            case ChatEventKind.callStarted:
              event as EventChatCallStarted;
              chatEntity.value.ongoingCall = event.call;

              if (chat.value.isGroup) {
                chatEntity.value.ongoingCall!.conversationStartedAt =
                    PreciseDateTime.now();
              }

              _chatRepository.addCall(event.call);
              break;

            case ChatEventKind.unreadItemsCountUpdated:
              event as EventChatUnreadItemsCountUpdated;
              chatEntity.value.unreadCount = event.count;
              break;

            case ChatEventKind.avatarUpdated:
              event as EventChatAvatarUpdated;
              chatEntity.value.avatar = event.avatar;
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

              var message =
                  await get(event.call.id, timestamp: event.call.timestamp);

              if (message != null) {
                event.call.at = message.value.at;
                message.value = event.call;
                message.save();
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
                      PreciseDateTime.now();
                }
              }
              break;

            case ChatEventKind.lastItemUpdated:
              event as EventChatLastItemUpdated;
              chatEntity.value.lastItem = event.lastItem?.firstOrNull?.value;
              chatEntity.value.updatedAt =
                  event.lastItem?.firstOrNull?.value.at ??
                      chatEntity.value.updatedAt;
              for (var item in [
                if (event.lastItem != null) ...event.lastItem!,
              ]) {
                await put(item);
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
              for (var item in event.item) {
                if (item.value is ChatMessage && item.value.authorId == me) {
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
                      await get(
                            item.value.id,
                            timestamp: item.value.timestamp,
                          ) ==
                          null) {
                    remove(pending.id, pending.timestamp);
                    _pending.remove(pending);
                  }
                }

                put(item);

                if (item.value is ChatMemberInfo) {
                  var msg = item.value as ChatMemberInfo;
                  switch (msg.action) {
                    case ChatMemberInfoAction.added:
                      // TODO: Put the [ChatMemberInfo.user] to the [UserRepository].
                      chatEntity.value.members
                          .add(ChatMember(msg.user, msg.at));
                      break;

                    case ChatMemberInfoAction.removed:
                      chatEntity.value.members
                          .removeWhere((e) => e.user.id == msg.user.id);
                      await _chatRepository.onMemberRemoved(id, msg.user.id);
                      break;

                    case ChatMemberInfoAction.created:
                      // No-op.
                      break;

                    case ChatMemberInfoAction.artemisUnknown:
                      // No-op.
                      break;
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
              _chatRepository.chats.emit(
                MapChangeNotification.updated(
                  chatEntity.value.id,
                  chatEntity.value.id,
                  _chatRepository.chats[chatEntity.value.id],
                ),
              );
              break;

            case ChatEventKind.unfavorited:
              chatEntity.value.favoritePosition = null;
              _chatRepository.chats.emit(
                MapChangeNotification.updated(
                  chatEntity.value.id,
                  chatEntity.value.id,
                  _chatRepository.chats[chatEntity.value.id],
                ),
              );
              break;
          }
        }

        if (putChat) {
          _chatLocal.put(chatEntity);
        }
        break;
    }
  }
}

/// Extension adding an ability to insert the element based on some condition to
/// [List].
extension ListInsertAfter<T> on List<T> {
  /// Inserts the [element] after the [test] condition becomes `true`.
  void insertAfter(T element, bool Function(T) test) {
    bool done = false;
    for (var i = length - 1; i > -1 && !done; --i) {
      if (test(this[i])) {
        insert(i + 1, element);
        done = true;
      }
    }

    if (!done) {
      insert(0, element);
    }
  }
}
