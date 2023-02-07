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
import 'dart:collection';

import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';

import '/api/backend/extension/call.dart';
import '/api/backend/extension/chat.dart';
import '/api/backend/extension/user.dart';
import '/api/backend/schema.dart';
import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show
        ConnectionException,
        GraphQlProviderExceptions,
        ResubscriptionRequiredException,
        StaleVersionException,
        UploadAttachmentException;
import '/provider/gql/graphql.dart';
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/draft.dart';
import '/provider/hive/session.dart';
import '/store/event/recent_chat.dart';
import '/store/user.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import 'chat_rx.dart';
import 'event/chat.dart';
import 'event/favorite_chat.dart';
import 'model/chat.dart';

/// Implementation of an [AbstractChatRepository].
class ChatRepository implements AbstractChatRepository {
  ChatRepository(
    this._graphQlProvider,
    this._chatLocal,
    this._callRepo,
    this._draftLocal,
    this._userRepo,
    this._sessionLocal, {
    this.me,
  });

  /// Callback, called when an [User] identified by the provided [userId] is
  /// removed from the specified [Chat].
  late final Future<void> Function(ChatId id, UserId userId) onMemberRemoved;

  /// [UserId] of the currently authenticated [MyUser].
  final UserId? me;

  @override
  final Rx<RxStatus> status = Rx(RxStatus.empty());

  /// GraphQL API provider.
  final GraphQlProvider _graphQlProvider;

  /// [Chat]s local [Hive] storage.
  final ChatHiveProvider _chatLocal;

  /// [OngoingCall]s repository, used to put the fetched [ChatCall]s into it.
  final AbstractCallRepository _callRepo;

  /// [RxChat.draft] local [Hive] storage.
  final DraftHiveProvider _draftLocal;

  /// [User]s repository, used to put the fetched [User]s into it.
  final UserRepository _userRepo;

  /// [isReady] value.
  final RxBool _isReady = RxBool(false);

  /// [chats] value.
  final RxObsMap<ChatId, HiveRxChat> _chats = RxObsMap<ChatId, HiveRxChat>();

  /// [SessionDataHiveProvider] storing a [FavoriteChatsListVersion].
  final SessionDataHiveProvider _sessionLocal;

  /// [ChatHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// [DraftHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _draftSubscription;

  /// [_recentChatsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamIterator? _remoteSubscription;

  /// [_favoriteChatsEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamIterator? _favoriteChatsSubscription;

  /// [Mutex]es guarding access to the [get] method.
  final Map<ChatId, Mutex> _locks = {};

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
        final HiveRxChat entry = HiveRxChat(this, _chatLocal, _draftLocal, c);
        _chats[c.value.id] = entry;
        entry.init();
      }
      _isReady.value = true;
    }

    status.value =
        _chatLocal.isEmpty ? RxStatus.loading() : RxStatus.loadingMore();

    _initLocalSubscription();
    _initDraftSubscription();

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
    _initFavoriteChatsSubscription();

    _isReady.value = true;
    status.value = RxStatus.success();
  }

  @override
  void dispose() {
    for (var c in _chats.entries) {
      c.value.dispose();
    }

    _localSubscription?.cancel();
    _draftSubscription?.cancel();
    _remoteSubscription?.cancel();
    _favoriteChatsSubscription?.cancel();
  }

  @override
  Future<void> clearCache() => _chatLocal.clear();

  @override
  Future<HiveRxChat?> get(ChatId id) async {
    Mutex? mutex = _locks[id];
    if (mutex == null) {
      mutex = Mutex();
      _locks[id] = mutex;
    }

    return mutex.protect(() async {
      HiveRxChat? chat = _chats[id];
      if (chat == null) {
        var query = (await _graphQlProvider.getChat(id)).chat;
        if (query != null) {
          return _putEntry(_chat(query));
        }
      }

      return chat;
    });
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
  Future<void> sendChatMessage(
    ChatId chatId, {
    ChatMessageText? text,
    List<Attachment>? attachments,
    List<ChatItem> repliesTo = const [],
  }) async {
    HiveRxChat? rxChat = _chats[chatId] ?? (await get(chatId));
    await rxChat?.postChatMessage(
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
  }) =>
      _graphQlProvider.postChatMessage(
        chatId,
        text: text,
        attachments: attachments,
        repliesTo: repliesTo,
      );

  @override
  Future<void> resendChatItem(ChatItem item) async {
    HiveRxChat? rxChat = _chats[item.chatId] ?? (await get(item.chatId));

    // TODO: Account [ChatForward]s.
    if (item is ChatMessage) {
      for (var e in item.attachments.whereType<LocalAttachment>()) {
        if (e.status.value == SendingStatus.error &&
            (e.upload.value == null || e.upload.value?.isCompleted == true)) {
          uploadAttachment(e)
              .onError<UploadAttachmentException>((_, __) => e)
              .onError<ConnectionException>((_, __) => e);
        }
      }

      return rxChat?.postChatMessage(
        existingId: item.id,
        existingDateTime: item.at,
        text: item.text,
        attachments: item.attachments,
        repliesTo: item.repliesTo,
      );
    }
  }

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

    chat?.chat.update((c) => c?.name = name);

    try {
      await _graphQlProvider.renameChat(id, name);
    } catch (_) {
      chat?.chat.update((c) => c?.name = previous);
      rethrow;
    }
  }

  @override
  Future<void> addChatMember(ChatId chatId, UserId userId) =>
      _graphQlProvider.addChatMember(chatId, userId);

  @override
  Future<void> removeChatMember(ChatId chatId, UserId userId) async {
    HiveRxChat? chat = _chats[chatId];
    ChatMember? member =
        chat?.chat.value.members.firstWhereOrNull((m) => m.user.id == userId);

    if (member != null) {
      chat?.chat.update((c) => c?.members.remove(member));
    }

    try {
      await _graphQlProvider.removeChatMember(chatId, userId);
      await onMemberRemoved.call(chatId, userId);
    } catch (_) {
      if (member != null) {
        chat?.chat.update((c) => c?.members.add(member));
      }

      rethrow;
    }
  }

  @override
  Future<void> hideChat(ChatId id) async {
    HiveRxChat? chat = _chats.remove(id);

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
        Iterable<Rx<ChatItem>> unread =
            chat.messages.skip(chat.messages.length - lastReadIndex - 1);
        chat.chat.update((c) => c?.unreadCount = unread.length - 1);
      }
    }
    try {
      await _graphQlProvider.readChat(chatId, untilId);
    } catch (_) {
      chat?.chat.update((c) => c?.unreadCount = previous!);
      rethrow;
    }
  }

  @override
  Future<void> editChatMessageText(
    ChatMessage message,
    ChatMessageText? text,
  ) async {
    Rx<ChatItem>? item = _chats[message.chatId]
        ?.messages
        .firstWhereOrNull((e) => e.value.id == message.id);

    ChatMessageText? previous;
    if (item?.value is ChatMessage) {
      previous = (item?.value as ChatMessage).text;
      item?.update((c) => (c as ChatMessage?)?.text = text);
    }

    try {
      await _graphQlProvider.editChatMessageText(message.id, text);
    } catch (_) {
      if (item?.value is ChatMessage) {
        item?.update((c) => (c as ChatMessage?)?.text = previous);
      }

      rethrow;
    }
  }

  @override
  Future<void> deleteChatMessage(ChatMessage message) async {
    HiveRxChat? chat = _chats[message.chatId];

    if (message.status.value != SendingStatus.sent) {
      chat?.remove(message.id, message.timestamp);
    } else {
      Rx<ChatItem>? item =
          chat?.messages.firstWhereOrNull((e) => e.value.id == message.id);
      if (item != null) {
        chat?.messages.remove(item);
      }

      try {
        await _graphQlProvider.deleteChatMessage(message.id);

        if (item != null) {
          chat?.remove(item.value.id, item.value.timestamp);
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
    HiveRxChat? chat = _chats[forward.chatId];

    if (forward.status.value != SendingStatus.sent) {
      chat?.remove(forward.id);
    } else {
      Rx<ChatItem>? item =
          chat?.messages.firstWhereOrNull((e) => e.value.id == forward.id);
      if (item != null) {
        chat?.messages.remove(item);
      }

      try {
        await _graphQlProvider.deleteChatForward(forward.id);

        if (item != null) {
          chat?.remove(item.value.id, item.value.timestamp);
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
    HiveRxChat? chat = _chats[chatId];

    Rx<ChatItem>? item =
        chat?.messages.firstWhereOrNull((e) => e.value.id == id);
    if (item != null) {
      chat?.messages.remove(item);
    }

    try {
      await _graphQlProvider.hideChatItem(id);

      if (item != null) {
        chat?.remove(item.value.id, item.value.timestamp);
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
  Future<Attachment> uploadAttachment(LocalAttachment attachment) async {
    if (attachment.upload.value?.isCompleted != false) {
      attachment.upload.value = Completer();
    }

    if (attachment.read.value?.isCompleted != false) {
      attachment.read.value = Completer();
    }

    attachment.status.value = SendingStatus.sending;
    await attachment.file.ensureCorrectMediaType();

    try {
      dio.MultipartFile upload;

      if (attachment.file.path != null) {
        attachment.file
            .readFile()
            .then((_) => attachment.read.value?.complete(null));
        upload = await dio.MultipartFile.fromFile(
          attachment.file.path!,
          filename: attachment.file.name,
          contentType: attachment.file.mime,
        );
      } else if (attachment.file.stream != null ||
          attachment.file.bytes.value != null) {
        await attachment.file.readFile();
        attachment.read.value?.complete(null);
        attachment.status.refresh();
        upload = dio.MultipartFile.fromBytes(
          attachment.file.bytes.value!,
          filename: attachment.file.name,
          contentType: attachment.file.mime,
        );
      } else {
        throw ArgumentError(
          'At least stream, bytes or path should be specified.',
        );
      }

      var response = await _graphQlProvider.uploadAttachment(
        upload,
        onSendProgress: (now, max) => attachment.progress.value = now / max,
      );

      var model = response.attachment.toModel();
      attachment.id = model.id;
      attachment.filename = model.filename;
      attachment.original = model.original;
      attachment.upload.value?.complete(model);
      attachment.status.value = SendingStatus.sent;
      attachment.progress.value = 1;
      return model;
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
    HiveRxChat? chat = _chats[chatId];
    ChatDirectLink? link = chat?.chat.value.directLink;

    chat?.chat.update((c) => c?.directLink = ChatDirectLink(slug: slug));

    try {
      _graphQlProvider.createChatDirectLink(slug, groupId: chatId);
    } catch (_) {
      chat?.chat.update((c) => c?.directLink = link);
      rethrow;
    }
  }

  @override
  Future<void> deleteChatDirectLink(ChatId groupId) async {
    HiveRxChat? chat = _chats[groupId];
    ChatDirectLink? link = chat?.chat.value.directLink;

    chat?.chat.update((c) => c?.directLink = null);

    try {
      _graphQlProvider.deleteChatDirectLink(groupId: groupId);
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
    List<ChatItemQuote> items, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
  }) =>
      _graphQlProvider.forwardChatItems(
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

  @override
  Future<void> updateChatAvatar(
    ChatId id, {
    NativeFile? file,
    void Function(int count, int total)? onSendProgress,
  }) async {
    late dio.MultipartFile upload;

    if (file != null) {
      await file.ensureCorrectMediaType();

      if (file.stream != null) {
        upload = dio.MultipartFile(
          file.stream!,
          file.size,
          filename: file.name,
          contentType: file.mime,
        );
      } else if (file.bytes.value != null) {
        upload = dio.MultipartFile.fromBytes(
          file.bytes.value!,
          filename: file.name,
          contentType: file.mime,
        );
      } else if (file.path != null) {
        upload = await dio.MultipartFile.fromFile(
          file.path!,
          filename: file.name,
          contentType: file.mime,
        );
      } else {
        throw ArgumentError(
          'At least stream, bytes or path should be specified.',
        );
      }
    }

    HiveRxChat? chat = _chats[id];
    ChatAvatar? avatar = chat?.chat.value.avatar;

    if (file == null) {
      chat?.chat.update((c) => c?.avatar = null);
    }

    try {
      await _graphQlProvider.updateChatAvatar(
        id,
        file: file == null ? null : upload,
        onSendProgress: onSendProgress,
      );
    } catch (e) {
      if (file == null) {
        chat?.chat.update((c) => c?.avatar = avatar);
      }
      rethrow;
    }
  }

  @override
  Future<void> toggleChatMute(ChatId id, MuteDuration? mute) async {
    final HiveRxChat? chat = _chats[id];
    final MuteDuration? muted = chat?.chat.value.muted;

    final Muting? muting = mute == null
        ? null
        : Muting(duration: mute.forever == true ? null : mute.until);

    chat?.chat.update((c) => c?.muted = muting?.toModel());

    try {
      await _graphQlProvider.toggleChatMute(id, muting);
    } catch (e) {
      chat?.chat.update((c) => c?.muted = muted);
      rethrow;
    }
  }

  // TODO: Messages list can be huge, so we should implement pagination and
  //       loading on demand.
  /// Fetches __all__ [ChatItem]s of the [chat] ordered by their posting time.
  Future<List<HiveChatItem>> messages(ChatId id) async {
    const maxInt = 120;
    var query = await _graphQlProvider.chatItems(id, first: maxInt);
    return query.chat?.items.edges
            .map((e) => e.toHive())
            .expand((e) => e)
            .toList() ??
        [];
  }

  /// Fetches the [Attachment]s of the provided [item].
  Future<List<Attachment>> attachments(HiveChatItem item) async {
    var response = await _graphQlProvider.attachments(item.value.id);
    return response.chatItem?.toModel() ?? [];
  }

  /// Removes the [ChatCallCredentials] of an [OngoingCall] identified by the
  /// provided [id].
  Future<void> removeCredentials(ChatItemId id) =>
      _callRepo.removeCredentials(id);

  /// Adds the provided [ChatCall] to the [AbstractCallRepository].
  void addCall(ChatCall call) => _callRepo.add(call);

  /// Ends an [OngoingCall] happening in the [Chat] identified by the provided
  /// [chatId], if any.
  void endCall(ChatId chatId) => _callRepo.remove(chatId);

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
              mixin.events.map((e) => chatEvent(e)).toList(),
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
  ChatEvent chatEvent(ChatEventsVersionedMixin$Events e) {
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
        node.duration.toModel(),
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
        node.reason,
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
    } else if (e.$$typename == 'EventChatCallMemberRedialed') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatCallMemberRedialed;
      _userRepo.put(node.user.toHive());
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
    } else if (e.$$typename == 'EventChatFavorited') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatFavorited;
      return EventChatFavorited(e.chatId, node.at, node.position);
    } else if (e.$$typename == 'EventChatUnfavorited') {
      var node = e as ChatEventsVersionedMixin$Events$EventChatUnfavorited;
      return EventChatUnfavorited(e.chatId, node.at);
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
          HiveRxChat entry =
              HiveRxChat(this, _chatLocal, _draftLocal, event.value);
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

  /// Initializes [DraftHiveProvider.boxEvents] subscription.
  Future<void> _initDraftSubscription() async {
    _draftSubscription = StreamIterator(_draftLocal.boxEvents);
    while (await _draftSubscription!.moveNext()) {
      BoxEvent event = _draftSubscription!.current;
      if (event.deleted) {
        _chats[ChatId(event.key)]?.draft.value = null;
      } else {
        HiveRxChat? chat = _chats[ChatId(event.key)];
        if (chat != null) {
          chat.draft.value = event.value;
          chat.draft.refresh();
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
      entry = HiveRxChat(this, _chatLocal, _draftLocal, data.chat);
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

  @override
  Future<void> favoriteChat(ChatId id, ChatFavoritePosition? position) async {
    final HiveRxChat? chat = _chats[id];
    final ChatFavoritePosition? oldPosition = chat?.chat.value.favoritePosition;
    final ChatFavoritePosition newPosition;

    if (position == null) {
      final List<HiveRxChat> favorites = _chats.values
          .where((e) => e.chat.value.favoritePosition != null)
          .toList();

      favorites.sort(
        (a, b) => a.chat.value.favoritePosition!
            .compareTo(b.chat.value.favoritePosition!),
      );

      final double? lowestFavorite = favorites.isEmpty
          ? null
          : favorites.first.chat.value.favoritePosition!.val;

      newPosition = ChatFavoritePosition(
        lowestFavorite == null ? 9007199254740991 : lowestFavorite / 2,
      );
    } else {
      newPosition = position;
    }

    chat?.chat.update((c) => c?.favoritePosition = newPosition);
    chats.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));

    try {
      await _graphQlProvider.favoriteChat(id, newPosition);
    } catch (e) {
      chat?.chat.update((c) => c?.favoritePosition = oldPosition);
      chats.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));
      rethrow;
    }
  }

  @override
  Future<void> unfavoriteChat(ChatId id) async {
    final HiveRxChat? chat = _chats[id];
    final ChatFavoritePosition? oldPosition = chat?.chat.value.favoritePosition;

    chat?.chat.update((c) => c?.favoritePosition = null);
    chats.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));

    try {
      await _graphQlProvider.unfavoriteChat(id);
    } catch (e) {
      chat?.chat.update((c) => c?.favoritePosition = oldPosition);
      chats.emit(MapChangeNotification.updated(chat?.id, chat?.id, chat));
      rethrow;
    }
  }

  /// Initializes [_favoriteChatsEvents] subscription.
  Future<void> _initFavoriteChatsSubscription({bool noVersion = false}) async {
    var ver = noVersion ? null : _sessionLocal.getFavoriteChatsListVersion();
    _favoriteChatsSubscription?.cancel();
    _favoriteChatsSubscription =
        StreamIterator(await _favoriteChatsEvents(ver));
    while (await _favoriteChatsSubscription!
        .moveNext()
        .onError<ResubscriptionRequiredException>((_, __) {
      _initFavoriteChatsSubscription();
      return false;
    }).onError<StaleVersionException>((_, __) {
      _initFavoriteChatsSubscription(noVersion: true);
      return false;
    })) {
      await _favoriteChatsEvent(_favoriteChatsSubscription!.current);
    }
  }

  /// Handles a [FavoriteChatsEvent] from the [_favoriteChatsEvents]
  /// subscription.
  Future<void> _favoriteChatsEvent(FavoriteChatsEvents event) async {
    switch (event.kind) {
      case FavoriteChatsEventsKind.initialized:
        // No-op.
        break;

      case FavoriteChatsEventsKind.chatsList:
        var node = event as FavoriteChatsEventsChatsList;
        _sessionLocal.setFavoriteChatsListVersion(node.ver);
        for (ChatData data in node.chatList) {
          if (_chats[data.chat.value.id] == null) {
            _putEntry(data);
          }
        }
        break;

      case FavoriteChatsEventsKind.event:
        var versioned = (event as FavoriteChatsEventsEvent).event;
        if (versioned.ver > _sessionLocal.getFavoriteChatsListVersion()) {
          _sessionLocal.setFavoriteChatsListVersion(versioned.ver);

          for (var event in versioned.events) {
            switch (event.kind) {
              case ChatEventKind.favorited:
                if (_chats[event.chatId] == null) {
                  get(event.chatId);
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
  Future<Stream<FavoriteChatsEvents>> _favoriteChatsEvents(
          FavoriteChatsListVersion? ver) async =>
      (await _graphQlProvider.favoriteChatsEvents(ver))
          .asyncExpand((event) async* {
        GraphQlProviderExceptions.fire(event);
        var events = FavoriteChatsEvents$Subscription.fromJson(event.data!)
            .favoriteChatsEvents;
        if (events.$$typename == 'SubscriptionInitialized') {
          events
              as FavoriteChatsEvents$Subscription$FavoriteChatsEvents$SubscriptionInitialized;
          yield const FavoriteChatsEventsInitialized();
        } else if (events.$$typename == 'FavoriteChatsList') {
          var chatsList = events
              as FavoriteChatsEvents$Subscription$FavoriteChatsEvents$FavoriteChatsList;
          var data = chatsList.chats.nodes.map((e) => e.toData()).toList();
          yield FavoriteChatsEventsChatsList(data, chatsList.chats.ver);
        } else if (events.$$typename == 'FavoriteChatsEventsVersioned') {
          var mixin = events
              as FavoriteChatsEvents$Subscription$FavoriteChatsEvents$FavoriteChatsEventsVersioned;
          yield FavoriteChatsEventsEvent(
            FavoriteChatsEventsVersioned(
              mixin.events.map((e) => _favoriteChatsVersionedEvent(e)).toList(),
              mixin.ver,
            ),
          );
        }
      });

  /// Constructs a [ChatEvents] from the
  /// [FavoriteChatsEventsVersionedMixin$Events].
  ChatEvent _favoriteChatsVersionedEvent(
      FavoriteChatsEventsVersionedMixin$Events e) {
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
