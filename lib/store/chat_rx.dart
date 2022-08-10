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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/schema.dart' show ChatMemberInfoAction, ChatKind;
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show
        NotChatMemberException,
        ResubscriptionRequiredException,
        StaleVersionException;
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatViewExt;
import '/util/new_type.dart';
import 'chat.dart';
import 'event/chat.dart';

/// [RxChat] implementation backed by local [Hive] storage.
class HiveRxChat implements RxChat {
  HiveRxChat(
    this._chatRepository,
    this._chatLocal,
    HiveChat hiveChat,
  )   : chat = Rx<Chat>(hiveChat.value),
        _local = ChatItemHiveProvider(hiveChat.value.id);

  @override
  final Rx<Chat> chat;

  @override
  final RxList<Rx<ChatItem>> messages = RxList<Rx<ChatItem>>();

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

  /// [ChatRepository] used to cooperate with the other [HiveRxChat]s.
  final ChatRepository _chatRepository;

  /// [Chat]s local [Hive] storage.
  final ChatHiveProvider _chatLocal;

  /// [ChatItem]s local [Hive] storage.
  final ChatItemHiveProvider _local;

  /// Guard used to guarantee synchronous access to the [_local] storage.
  final Mutex _guard = Mutex();

  /// Subscription to [User]s from the [members] list forming the [title].
  final Map<UserId, Worker> _userWorkers = {};

  /// [Worker] reacting on the [User] changes updating the [avatar].
  Worker? _userWorker;

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

  /// Returns [ChatId] of the [chat].
  ChatId get id => chat.value.id;

  /// Initializes this [HiveRxChat].
  Future<void> init() {
    if (status.value.isSuccess) {
      return Future.value();
    }

    status.value = RxStatus.loading();

    _updateTitle(chat.value.members.map((e) => e.user));
    _updateFields().then((_) => chat.value.isGroup ? null : _updateAvatar());
    _worker = ever(chat, (_) => _updateFields());

    return _guard.protect(() async {
      await _local.init(userId: me);
      if (!_local.isEmpty) {
        for (HiveChatItem i in _local.messages) {
          messages.add(Rx<ChatItem>(i.value));
        }
      }

      _initLocalSubscription();
      status.value = RxStatus.success();
    });
  }

  /// Disposes this [HiveRxChat].
  Future<void> dispose() {
    return _guard.protect(() async {
      status.value = RxStatus.loading();
      messages.clear();
      _localSubscription?.cancel();
      _remoteSubscription?.cancel();
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
    if (!_remoteSubscriptionInitialized) {
      _initRemoteSubscription(id);
    }
  }

  @override
  Future<void> fetchMessages(ChatId chatItemId) {
    return _guard.protect(() async {
      status.value = RxStatus.loadingMore();

      List<HiveChatItem> items = await _chatRepository.messages(chatItemId);
      for (HiveChatItem item in _local.messages) {
        var i = items.indexWhere((e) => e.value.id == item.value.id);
        if (i == -1) {
          _local.remove(item.value.timestamp);
        }
      }

      for (HiveChatItem item in items) {
        if (item.value.chatId == id) {
          put(item);
        } else {
          _chatRepository.putChatItem(item);
        }
      }

      status.value = RxStatus.success();
    });
  }

  /// Puts the provided [item] to [Hive].
  Future<void> put(HiveChatItem item) {
    return _guard.protect(
      () => Future.sync(() {
        if (!_local.isReady) {
          return;
        }

        var saved = _local.get(item.value.timestamp);
        if (saved == null) {
          _local.put(item);
        } else {
          if (saved.value.id.val != item.value.id.val) {
            // If there's collision, then decrease timestamp with 1 millisecond
            // offset and save this item again.
            item.value.at = item.value.at.subtract(1.milliseconds);
            put(item);
          } else if (saved.ver < item.ver) {
            _local.put(item);
          }
        }
      }),
    );
  }

  @override
  Future<void> remove(ChatItemId itemId) {
    return _guard.protect(
      () => Future.sync(() {
        if (!_local.isReady) {
          return;
        }

        // TODO: Implement `ChatItemId` to timestamp lookup table.
        ChatItem? message =
            messages.firstWhereOrNull((e) => e.value.id == itemId)?.value;
        if (message != null) {
          _local.remove(message.timestamp);

          HiveChat? chatEntity = _chatLocal.get(id);
          if (chatEntity?.value.lastItem?.id == message.id) {
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

  /// Updates the [members] and [title] fields based on the [chat] state.
  Future<void> _updateFields() async {
    if (chat.value.name != null) {
      _updateTitle();
    }

    if (chat.value.isGroup) {
      avatar.value = chat.value.avatar;
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
        .removeWhere((k, _) => !chat.value.members.any((m) => m.user.id == k));

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

  /// Initializes [ChatItemHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_local.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      var i = messages.indexWhere((e) => e.value.timestamp == event.key);
      if (event.deleted) {
        messages.removeAt(i);
      } else {
        if (i == -1) {
          messages.insertAfter(
            Rx<ChatItem>(event.value.value),
            (p0, p1) => p0.value.at.compareTo(p1.value.at),
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
              chatEntity.value.currentCall = event.call;
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
              chatEntity.value.currentCall = null;
              if (chatEntity.value.lastItem?.id == event.call.id) {
                chatEntity.value.lastItem = event.call;
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
              // TODO: Implement EventChatCallMemberLeft.
              break;

            case ChatEventKind.callMemberJoined:
              // TODO: Implement EventChatCallMemberJoined.
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
          }
        }

        if (putChat) {
          _chatLocal.put(chatEntity);
        }
        break;
    }
  }
}
