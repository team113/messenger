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
import 'dart:collection';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '/api/backend/extension/call.dart';
import '/api/backend/extension/chat.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show GraphQlProviderExceptions, ResubscriptionRequiredException;
import '/provider/gql/graphql.dart';
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/store/event/recent_chat.dart';
import '/store/user.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import 'chat_rx.dart';
import 'event/chat.dart';
import 'model/chat.dart';

/// Implementation of an [AbstractChatRepository].
class ChatRepository implements AbstractChatRepository {
  ChatRepository(
    this._graphQlProvider,
    this._chatLocal,
    this._userRepo, {
    this.me,
  });

  /// Callback, called when an [User] identified by the provided [userId] is
  /// removed from the specified [Chat].
  late final Future<void> Function(ChatId id, UserId userId) onMemberRemoved;

  /// [UserId] of the currently authenticated [MyUser].
  final UserId? me;

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [Chat]s local [Hive] storage.
  final ChatHiveProvider _chatLocal;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepo;

  /// [isReady] value.
  final RxBool _isReady = RxBool(false);

  /// [chats] value.
  final RxObsMap<ChatId, HiveRxChat> _chats = RxObsMap<ChatId, HiveRxChat>();

  /// [ChatHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// [_recentChatsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamIterator? _remoteSubscription;

  @override
  RxObsMap<ChatId, HiveRxChat> get chats => _chats;

  @override
  RxBool get isReady => _isReady;

  @override
  Future<void> init({
    required Future<void> Function(ChatId, UserId) onMemberRemoved,
  }) async {
    this.onMemberRemoved = onMemberRemoved;

    if (!_chatLocal.isEmpty) {
      for (HiveChat c in _chatLocal.chats) {
        var entry = HiveRxChat(this, _chatLocal, c);
        _chats[c.value.id] = entry;
        entry.init();
      }
      _isReady.value = true;
    }

    _initLocalSubscription();

    HashMap<ChatId, ChatData> chats = await _recentChats();

    for (HiveChat c in _chatLocal.chats) {
      if (!chats.containsKey(c.value.id)) {
        _chatLocal.remove(c.value.id);
      }
    }

    for (ChatData c in chats.values) {
      _chats[c.chat.value.id]?.subscribe();
      _putEntry(c);
    }

    _initRemoteSubscription();

    _isReady.value = true;
  }

  @override
  void dispose() {
    for (var c in _chats.entries) {
      c.value.dispose();
    }

    _localSubscription?.cancel();
    _remoteSubscription?.cancel();
  }

  @override
  Future<void> clearCache() => _chatLocal.clear();

  @override
  Future<HiveRxChat?> get(ChatId id) async {
    HiveRxChat? chat = _chats[id];
    if (chat == null) {
      var query = (await _graphQlProvider.getChat(id)).chat;
      if (query != null) {
        return _putEntry(_chat(query));
      }
    }

    return chat;
  }

  @override
  Future<void> remove(ChatId id) => _chatLocal.remove(id);

  @override
  Future<HiveRxChat> createDialogChat(UserId responderId) async {
    var chat = _chat(await _graphQlProvider.createDialogChat(responderId));
    return _putEntry(chat);
  }

  @override
  Future<HiveRxChat> createGroupChat(List<UserId> memberIds,
      {ChatName? name}) async {
    var chat =
        _chat(await _graphQlProvider.createGroupChat(memberIds, name: name));
    return _putEntry(chat);
  }

  @override
  Future<void> postChatMessage(
    ChatId chatId, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
    ChatItemId? repliesTo,
  }) =>
      _graphQlProvider.postChatMessage(
        chatId,
        text: text,
        attachments: attachments,
        repliesTo: repliesTo,
      );

  /// Puts the provided [item] to [Hive].
  Future<void> putChatItem(HiveChatItem item) async {
    HiveRxChat? entry =
        _chats[item.value.chatId] ?? (await get(item.value.chatId));
    if (entry != null) {
      await entry.put(item);
    }
  }

  @override
  Future<void> renameChat(ChatId id, ChatName? name) async {
    HiveRxChat? chat = _chats[id];
    ChatName? previous = chat?.chat.value.name;
    if (chat != null) {
      chat.chat.update((c) {
        c?.name = name;
      });
    }
    try {
      await _graphQlProvider.renameChat(id, name);
    } catch (_) {
      if (chat != null) {
        chat.chat.update((c) {
          c?.name = previous;
        });
      }

      rethrow;
    }
  }

  @override
  Future<void> addChatMember(ChatId chatId, UserId userId) =>
      _graphQlProvider.addChatMember(chatId, userId);

  @override
  Future<void> removeChatMember(ChatId chatId, UserId userId) async {
    HiveRxChat? chat = _chats[chatId];
    ChatMember? previous =
        chat?.chat.value.members.firstWhereOrNull((m) => m.user.id == userId);

    if (chat != null && previous != null) {
      chat.chat.update((c) {
        c?.members.remove(previous);
      });
    }

    try {
      var response = await _graphQlProvider.removeChatMember(chatId, userId);
      // Response is `null` if [MyUser] removed himself (left the chat).
      if (response == null) {
        _chatLocal.remove(chatId);
      }
    } catch (_) {
      if (chat != null && previous != null) {
        chat.chat.update((c) {
          c?.members.add(previous);
        });
      }

      rethrow;
    }
  }

  @override
  Future<void> hideChat(ChatId id) async {
    var chat = _chats[id];
    _chats.remove(id);
    try {
      await _graphQlProvider.hideChat(id);
    } catch (_) {
      if (chat != null) {
        _chats[id] = chat;
      }

      rethrow;
    }
  }

  @override
  Future<void> readChat(ChatId chatId, ChatItemId untilId) async {
    HiveRxChat? chat = _chats[chatId];

    int? previous = chat?.chat.value.unreadCount;

    if (chat != null) {
      int lastReadIndex = chat.messages.reversed
          .toList()
          .indexWhere((m) => m.value.id == untilId);
      if (lastReadIndex != -1) {
        // If user has his own unread messages, they will be included.
        Iterable<Rx<ChatItem>> unreadAll =
            chat.messages.skip(chat.messages.length - lastReadIndex - 1);

        chat.chat.update((c) {
          c?.unreadCount = unreadAll.length -
              unreadAll.where((m) => m.value.authorId == me).length -
              1;
        });
      }
    }
    try {
      await _graphQlProvider.readChat(chatId, untilId);
    } catch (_) {
      if (chat != null && previous != null) {
        chat.chat.update((c) {
          c?.unreadCount = previous;
        });
      }
      rethrow;
    }
  }

  @override
  Future<void> editChatMessageText(
      ChatItem chatItem, ChatMessageText? text) async {
    HiveRxChat? chat = _chats[chatItem.chatId];
    Rx<ChatItem>? item =
        chat?.messages.firstWhereOrNull((item) => item.value.id == chatItem.id);
    ChatMessageText? previous;
    if (item?.value is ChatMessage) {
      final msg = item!.value as ChatMessage;
      previous = msg.text;
      item.update((i) {
        (item.value as ChatMessage).text = text;
      });
    }

    try {
      await _graphQlProvider.editChatMessageText(chatItem.id, text);
    } catch (_) {
      if (item?.value is ChatMessage) {
        item!.update((i) {
          (item.value as ChatMessage).text = previous;
        });
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteChatMessage(ChatId chatId, ChatItemId id) async {
    HiveRxChat? chat = _chats[chatId];
    Rx<ChatItem>? item =
        chat?.messages.firstWhereOrNull((item) => item.value.id == id);

    if (chat != null && item != null) {
      chat.remove(id);
    }

    try {
      await _graphQlProvider.deleteChatMessage(id);
    } catch (_) {
      if (chat != null && item != null) {
        chat.messages.add(item);
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteChatForward(ChatId chatId, ChatItemId id) async {
    HiveRxChat? chat = _chats[chatId];
    Rx<ChatItem>? item =
        chat?.messages.firstWhereOrNull((item) => item.value.id == id);

    if (chat != null && item != null) {
      chat.messages.remove(item);
    }

    try {
      await _graphQlProvider.deleteChatForward(id);
    } catch (_) {
      if (chat != null && item != null) {
        chat.messages.add(item);
      }

      rethrow;
    }
  }

  @override
  Future<void> hideChatItem(ChatId chatId, ChatItemId id) async {
    HiveRxChat? chat = _chats[chatId];
    Rx<ChatItem>? item =
        chat?.messages.firstWhereOrNull((item) => item.value.id == id);

    if (chat != null && item != null) {
      chat.messages.remove(item);
    }
    try {
      await _graphQlProvider.hideChatItem(id);
    } catch (_) {
      if (chat != null && item != null) {
        chat.messages.add(item);
      }

      rethrow;
    }
  }

  @override
  Future<Attachment> uploadAttachment(
    NativeFile attachment, {
    void Function(int count, int total)? onSendProgress,
  }) async {
    dio.MultipartFile upload;

    if (attachment.stream != null) {
      upload = dio.MultipartFile(
        attachment.stream!,
        attachment.size,
        filename: attachment.name,
        contentType: attachment.mime,
      );
    } else if (attachment.bytes != null) {
      upload = dio.MultipartFile.fromBytes(
        attachment.bytes!,
        filename: attachment.name,
        contentType: attachment.mime,
      );
    } else if (attachment.path != null) {
      upload = await dio.MultipartFile.fromFile(
        attachment.path!,
        filename: attachment.name,
        contentType: attachment.mime,
      );
    } else {
      throw ArgumentError(
        'At least stream, bytes or path should be specified.',
      );
    }

    var response = await _graphQlProvider.uploadAttachment(
      upload,
      onSendProgress: onSendProgress,
    );

    return response.attachment.toModel();
  }

  @override
  Future<void> createChatDirectLink(ChatId chatId, ChatDirectLinkSlug slug) =>
      _graphQlProvider.createChatDirectLink(slug, groupId: chatId);

  @override
  Future<void> deleteChatDirectLink(ChatId groupId) =>
      _graphQlProvider.deleteChatDirectLink(groupId: groupId);

  // TODO: Messages list can be huge, so we should implement pagination and
  //       loading on demand.
  /// Fetches __all__ [ChatItem]s of the [chat] ordered by their posting time.
  Future<List<HiveChatItem>> messages(ChatId chatItemId) async {
    const maxInt = 120;
    var query = await _graphQlProvider.chatItems(chatItemId, first: maxInt);
    return query.chat?.items.edges
            .map((e) => e.toHive())
            .expand((e) => e)
            .toList() ??
        [];
  }

  /// Subscribes to [ChatEvent]s of the specified [Chat].
  Future<Stream<ChatEvents>> chatEvents(
          ChatId chatId, ChatVersion? ver) async =>
      (await _graphQlProvider.chatEvents(chatId, ver))
          .asyncExpand((event) async* {
        var events = ChatEvents$Subscription.fromJson(event.data!).chatEvents;
        if (events.$$typename == 'SubscriptionInitialized') {
          events as ChatEvents$Subscription$ChatEvents$SubscriptionInitialized;
          yield const ChatEventsInitialized();
        } else if (events.$$typename == 'Chat') {
          var chat = events as ChatEvents$Subscription$ChatEvents$Chat;
          var data = _chat(chat);
          yield ChatEventsChat(data.chat);
        } else if (events.$$typename == 'ChatEventsVersioned') {
          var mixin =
              events as ChatEvents$Subscription$ChatEvents$ChatEventsVersioned;
          yield ChatEventsEvent(
            ChatEventsVersioned(
              mixin.events.map((e) => _chatEvent(e)).toList(),
              mixin.ver,
            ),
          );
        }
      });

  @override
  Future<Stream<dynamic>> keepTyping(ChatId chatId) =>
      _graphQlProvider.keepTyping(chatId);

  /// Returns an [User] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userRepo.get(id);

  /// Constructs a [ChatEvent] from the [ChatEventsVersionedMixin$Events].
  ChatEvent _chatEvent(ChatEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventChatRenamed') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatRenamed;
      _userRepo.put(node.byUser.toHive());
      return EventChatRenamed(
        e.chatId,
        node.name,
        node.byUser.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatCleared') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCleared;
      return EventChatCleared(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatUnreadItemsCountUpdated') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatUnreadItemsCountUpdated;
      return EventChatUnreadItemsCountUpdated(
        e.chatId,
        node.count,
      );
    } else if (e.$$typename == 'EventChatItemPosted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemPosted;
      return EventChatItemPosted(
        e.chatId,
        node.item.toHive(),
      );
    } else if (e.$$typename == 'EventChatLastItemUpdated') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatLastItemUpdated;
      return EventChatLastItemUpdated(
        e.chatId,
        node.lastItem?.toHive(),
      );
    } else if (e.$$typename == 'EventChatItemHidden') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemHidden;
      return EventChatItemHidden(
        e.chatId,
        node.itemId,
      );
    } else if (e.$$typename == 'EventChatMuted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatMuted;
      return EventChatMuted(
        e.chatId,
        node.duration as MuteDuration,
      );
    } else if (e.$$typename == 'EventChatAvatarDeleted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatAvatarDeleted;
      _userRepo.put(node.byUser.toHive());
      return EventChatAvatarDeleted(
        e.chatId,
        node.byUser.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatTypingStarted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatTypingStarted;
      _userRepo.put(node.user.toHive());
      return EventChatTypingStarted(e.chatId, node.user.toModel());
    } else if (e.$$typename == 'EventChatUnmuted') {
      return EventChatUnmuted(e.chatId);
    } else if (e.$$typename == 'EventChatTypingStopped') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatTypingStopped;
      _userRepo.put(node.user.toHive());
      return EventChatTypingStopped(
        e.chatId,
        node.user.toModel(),
      );
    } else if (e.$$typename == 'EventChatHidden') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatHidden;
      return EventChatHidden(e.chatId, node.at);
    } else if (e.$$typename == 'EventChatItemDeleted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemDeleted;
      return EventChatItemDeleted(
        e.chatId,
        node.itemId,
      );
    } else if (e.$$typename == 'EventChatItemTextEdited') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatItemTextEdited;
      return EventChatItemTextEdited(
        e.chatId,
        node.itemId,
        node.text,
      );
    } else if (e.$$typename == 'EventChatCallStarted') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallStarted;
      return EventChatCallStarted(
        e.chatId,
        node.call.toModel(),
      );
    } else if (e.$$typename == 'EventChatAvatarUpdated') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatAvatarUpdated;
      _userRepo.put(node.byUser.toHive());
      return EventChatAvatarUpdated(
        e.chatId,
        node.avatar.toModel(),
        node.byUser.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatDirectLinkUsageCountUpdated') {
      var node = e
          as ChatEventsVersionedMixin$Events$EventChatDirectLinkUsageCountUpdated;
      return EventChatDirectLinkUsageCountUpdated(
        e.chatId,
        node.usageCount,
      );
    } else if (e.$$typename == 'EventChatCallFinished') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallFinished;
      return EventChatCallFinished(
        e.chatId,
        node.call.toModel(),
      );
    } else if (e.$$typename == 'EventChatCallMemberLeft') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMemberLeft;
      _userRepo.put(node.user.toHive());
      return EventChatCallMemberLeft(
        e.chatId,
        node.user.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatCallMemberJoined') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMemberJoined;
      _userRepo.put(node.user.toHive());
      return EventChatCallMemberJoined(
        e.chatId,
        node.user.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatDelivered') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatDelivered;
      return EventChatDelivered(
        e.chatId,
        node.at,
      );
    } else if (e.$$typename == 'EventChatRead') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatRead;
      _userRepo.put(node.byUser.toHive());
      return EventChatRead(
        e.chatId,
        node.byUser.toModel(),
        node.at,
      );
    } else if (e.$$typename == 'EventChatCallDeclined') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallDeclined;
      _userRepo.put(node.user.toHive());
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
        ),
      );
    } else if (e.$$typename == 'EventChatCallMoved') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatCallMoved;
      _userRepo.put(node.user.toHive());
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
    } else {
      throw UnimplementedError('Unknown ChatEvent: ${e.$$typename}');
    }
  }

  // TODO: Put the members of the [Chat]s to the [UserRepository].
  /// Puts the provided [chat] to [Hive].
  Future<void> _putChat(HiveChat chat) async {
    var saved = _chatLocal.get(chat.value.id);
    if (saved == null || saved.ver < chat.ver) {
      await _chatLocal.put(chat);
    }
  }

  /// Initializes [ChatHiveProvider.boxEvents] subscription.
  Future<void> _initLocalSubscription() async {
    _localSubscription = StreamIterator(_chatLocal.boxEvents);
    while (await _localSubscription!.moveNext()) {
      BoxEvent event = _localSubscription!.current;
      if (event.deleted) {
        await _chats.remove(ChatId(event.key))?.dispose();
      } else {
        HiveRxChat? chat = _chats[ChatId(event.key)];
        if (chat == null) {
          HiveRxChat entry = HiveRxChat(this, _chatLocal, event.value);
          _chats[ChatId(event.key)] = entry;
          entry.init();
          entry.subscribe();
        } else {
          chat.chat.value = event.value.value;
          chat.chat.refresh();
        }
      }
    }
  }

  /// Initializes [_recentChatsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    _remoteSubscription?.cancel();
    _remoteSubscription = StreamIterator(await _recentChatsRemoteEvents());
    while (await _remoteSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      _initRemoteSubscription();
      return false;
    })) {
      await _recentChatsRemoteEvent(_remoteSubscription!.current);
    }
  }

  /// Handles [RecentChatsEvent] from the [_recentChatsRemoteEvents]
  /// subscription.
  Future<void> _recentChatsRemoteEvent(RecentChatsEvent event) async {
    switch (event.kind) {
      case RecentChatsEventKind.initialized:
        // No-op.
        break;

      case RecentChatsEventKind.list:
        var node = event as RecentChatsTop;
        for (ChatData c in node.list) {
          if (chats[c.chat.value.id] == null) {
            _putEntry(c);
          }
        }
        break;

      case RecentChatsEventKind.updated:
        event as EventRecentChatsUpdated;
        // Update the chat only if it's new since, otherwise its state is
        // maintained by itself via [chatEvents].
        if (chats[event.chat.chat.value.id] == null) {
          _putEntry(event.chat);
        }
        break;

      case RecentChatsEventKind.deleted:
        // No-op.
        break;
    }
  }

  /// Subscribes to the remote updates of the [chats].
  Future<Stream<RecentChatsEvent>> _recentChatsRemoteEvents() async =>
      (await _graphQlProvider.recentChatsTopEvents(3))
          .asyncExpand((event) async* {
        GraphQlProviderExceptions.fire(event);
        var events = RecentChatsTopEvents$Subscription.fromJson(event.data!)
            .recentChatsTopEvents;

        if (events.$$typename == 'SubscriptionInitialized') {
          yield const RecentChatsTopInitialized();
        } else if (events.$$typename == 'RecentChatsTop') {
          var list = (events
                  as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$RecentChatsTop)
              .list;
          yield RecentChatsTop(list.map((e) => _chat(e)).toList());
        } else if (events.$$typename == 'EventRecentChatsTopChatUpdated') {
          var mixin = events
              as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$EventRecentChatsTopChatUpdated;
          yield EventRecentChatsUpdated(_chat(mixin.chat));
        } else if (events.$$typename == 'EventRecentChatsTopChatDeleted') {
          var mixin = events
              as RecentChatsTopEvents$Subscription$RecentChatsTopEvents$EventRecentChatsTopChatDeleted;
          yield EventRecentChatsDeleted(mixin.chatId);
        }
      });

  // TODO: Chat list can be huge, so we should implement pagination and
  //       loading on demand.
  /// Fetches __all__ [HiveChat]s from the remote.
  Future<HashMap<ChatId, ChatData>> _recentChats() async {
    const maxInt = 120;
    RecentChats$Query$RecentChats query =
        (await _graphQlProvider.recentChats(first: maxInt)).recentChats;

    HashMap<ChatId, ChatData> chats = HashMap();
    for (var c in query.nodes) {
      ChatData data = _chat(c);
      chats[data.chat.value.id] = data;
    }

    return chats;
  }

  /// Puts the provided [data] to [Hive].
  Future<HiveRxChat> _putEntry(ChatData data) async {
    HiveRxChat? entry = chats[data.chat.value.id];

    _putChat(data.chat);

    if (entry == null) {
      entry = HiveRxChat(this, _chatLocal, data.chat);
      _chats[data.chat.value.id] = entry;
      entry.init();
      entry.subscribe();
    }

    for (var item in [
      if (data.lastItem != null) ...data.lastItem!,
      if (data.lastReadItem != null) ...data.lastReadItem!,
    ]) {
      entry.put(item);
    }

    return entry;
  }

  /// Constructs a new [ChatData] from the given [ChatMixin] fragment.
  ChatData _chat(ChatMixin q) {
    for (var m in q.members.nodes) {
      _userRepo.put(m.user.toHive());
    }

    return q.toData();
  }
}

/// Result of fetching a [Chat].
class ChatData {
  const ChatData(this.chat, this.lastItem, this.lastReadItem);

  /// [HiveChat] returned from the [Chat] fetching.
  final HiveChat chat;

  /// [HiveChatItem]s of a [Chat.lastItem] returned from the [Chat] fetching.
  final List<HiveChatItem>? lastItem;

  /// [HiveChatItem]s of a [Chat.lastReadItem] returned from the [Chat]
  /// fetching.
  final List<HiveChatItem>? lastReadItem;
}

/// Extension adding an ability to insert the element based on some condition to
/// [List].
extension ListInsertAfter<T> on List<T> {
  /// Inserts the [element] after the [compare] condition becomes `false`.
  void insertAfter(T element, int Function(T, T) compare) {
    bool done = false;
    for (var i = 0; i < length && !done; ++i) {
      if (compare(element, this[i]) < 0) {
        insert(i, element);
        done = true;
      }
    }

    if (!done) {
      add(element);
    }
  }
}
