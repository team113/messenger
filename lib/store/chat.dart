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

import 'package:async/async.dart';
import 'package:collection/collection.dart';
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
import '/domain/model/chat_item_quote_input.dart' as model;
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/provider/gql/exceptions.dart'
    show ConnectionException, UploadAttachmentException;
import '/provider/gql/graphql.dart';
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/provider/hive/draft.dart';
import '/provider/hive/monolog.dart';
import '/provider/hive/session.dart';
import '/store/event/recent_chat.dart';
import '/store/user.dart';
import '/util/backoff.dart';
import '/util/new_type.dart';
import '/util/obs/obs.dart';
import '/util/stream_utils.dart';
import 'chat_rx.dart';
import 'event/chat.dart';
import 'event/favorite_chat.dart';
import 'model/chat.dart';

/// Implementation of an [AbstractChatRepository].
class ChatRepository extends DisposableInterface
    implements AbstractChatRepository {
  ChatRepository(
    this._graphQlProvider,
    this._chatLocal,
    this._callRepo,
    this._draftLocal,
    this._userRepo,
    this._sessionLocal,
    this._monologLocal, {
    required this.me,
  });

  /// Callback, called when an [User] identified by the provided [userId] is
  /// removed from the specified [Chat].
  late final Future<void> Function(ChatId id, UserId userId) onMemberRemoved;

  /// [UserId] of the currently authenticated [MyUser].
  final UserId me;

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

  /// [chats] value.
  final RxObsMap<ChatId, HiveRxChat> _chats = RxObsMap<ChatId, HiveRxChat>();

  /// [SessionDataHiveProvider] storing a [FavoriteChatsListVersion].
  final SessionDataHiveProvider _sessionLocal;

  /// [MonologHiveProvider] storing a [ChatId] of the [Chat]-monolog.
  final MonologHiveProvider _monologLocal;

  /// [ChatHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _localSubscription;

  /// [DraftHiveProvider.boxEvents] subscription.
  StreamIterator<BoxEvent>? _draftSubscription;

  /// [_recentChatsRemoteEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<RecentChatsEvent>? _remoteSubscription;

  /// [_favoriteChatsEvents] subscription.
  ///
  /// May be uninitialized since connection establishment may fail.
  StreamQueue<FavoriteChatsEvents>? _favoriteChatsSubscription;

  /// [Mutex]es guarding access to the [get] method.
  final Map<ChatId, Mutex> _getGuards = {};

  /// [Mutex]es guarding synchronized access to the [_putEntry].
  final Map<ChatId, Mutex> _putEntryGuards = {};

  /// [dio.CancelToken] for cancelling the [_recentChats] query.
  final dio.CancelToken _cancelToken = dio.CancelToken();

  /// Indicator whether a local [Chat]-monolog has been hidden.
  ///
  /// Used to prevent the [Chat]-monolog from re-appearing if the local
  /// [Chat]-monolog was hidden.
  bool _monologShouldBeHidden = false;

  /// [ChatFavoritePosition] of the local [Chat]-monolog.
  ///
  /// Used to prevent [Chat]-monolog from being displayed as unfavorited after
  /// adding a local [Chat]-monolog to favorites.
  ChatFavoritePosition? _localMonologFavoritePosition;

  @override
  RxObsMap<ChatId, HiveRxChat> get chats => _chats;

  @override
  ChatId get monolog => _monologLocal.get() ?? ChatId.local(me);

  @override
  Future<void> init({
    required Future<void> Function(ChatId, UserId) onMemberRemoved,
  }) async {
    this.onMemberRemoved = onMemberRemoved;

    if (!_chatLocal.isEmpty) {
      for (HiveChat c in _chatLocal.chats) {
        if (!c.value.id.isLocal || c.value.isMonolog) {
          final HiveRxChat entry = HiveRxChat(this, _chatLocal, _draftLocal, c);
          _chats[c.value.id] = entry;
          entry.init();
        }
      }
    }

    status.value =
        _chatLocal.isEmpty ? RxStatus.loading() : RxStatus.loadingMore();

    _initLocalSubscription();
    _initDraftSubscription();

    try {
      // TODO: [chats] should consist of 3 lists:
      //       - with [OngoingCall]s;
      //       - favorite [Chat]s;
      //       - recent [Chat]s.
      HashMap<ChatId, ChatData> chats =
          await Backoff.run(_recentChats, _cancelToken);

      for (HiveChat c in _chatLocal.chats) {
        if (!c.value.id.isLocal && !chats.containsKey(c.value.id)) {
          _chatLocal.remove(c.value.id);
        }
      }

      for (ChatData c in chats.values) {
        _chats[c.chat.value.id]?.subscribe();
        _putEntry(c);
      }

      _initMonolog();
      _initRemoteSubscription();
      _initFavoriteChatsSubscription();

      status.value = RxStatus.success();
    } on OperationCanceledException catch (_) {
      // No-op.
    }
  }

  @override
  void onClose() {
    for (var c in _chats.entries) {
      c.value.dispose();
    }

    _cancelToken.cancel();
    _localSubscription?.cancel();
    _draftSubscription?.cancel();
    _remoteSubscription?.close(immediate: true);
    _favoriteChatsSubscription?.cancel();

    super.onClose();
  }

  @override
  Future<void> clearCache() => _chatLocal.clear();

  @override
  Future<HiveRxChat?> get(ChatId id) async {
    Mutex? mutex = _getGuards[id];
    if (mutex == null) {
      mutex = Mutex();
      _getGuards[id] = mutex;
    }

    return mutex.protect(() async {
      HiveRxChat? chat = _chats[id];
      if (chat == null) {
        if (!id.isLocal) {
          var query = (await _graphQlProvider.getChat(id)).chat;
          if (query != null) {
            return _putEntry(_chat(query));
          }
        } else {
          final HiveChat? hiveChat = _chatLocal.get(id);
          if (hiveChat != null) {
            chat = HiveRxChat(this, _chatLocal, _draftLocal, hiveChat);
            chat.init();
          }

          chat ??= await _createLocalDialog(id.userId);

          _chats[id] = chat;
        }
      }

      return chat;
    });
  }

  @override
  Future<void> remove(ChatId id) => _chatLocal.remove(id);

  /// Ensures the provided [Chat] is remotely accessible.
  Future<HiveRxChat?> ensureRemoteDialog(ChatId chatId) async {
    if (chatId.isLocal) {
      if (chatId.isLocalWith(me)) {
        return await ensureRemoteMonolog();
      }

      final ChatData chat = _chat(
        await _graphQlProvider.createDialogChat(chatId.userId),
      );

      return _putEntry(chat);
    }

    return await get(chatId);
  }

  /// Ensures the provided [Chat]-monolog is remotely accessible.
  Future<HiveRxChat> ensureRemoteMonolog([ChatName? name]) async {
    final ChatData chatData = _chat(
      await _graphQlProvider.createMonologChat(name),
    );
    final HiveRxChat chat = await _putEntry(chatData);

    if (!isClosed) {
      await _monologLocal.set(chat.id);
    }

    return chat;
  }

  @override
  Future<HiveRxChat> createGroupChat(
    List<UserId> memberIds, {
    ChatName? name,
  }) async {
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
  }) =>
      _graphQlProvider.postChatMessage(
        chatId,
        text: text,
        attachments: attachments,
        repliesTo: repliesTo,
      );

  @override
  Future<void> resendChatItem(ChatItem item) async {
    HiveRxChat? rxChat = _chats[item.chatId];

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

      // If this [item] is posted in a local [Chat], then make it remote first.
      if (item.chatId.isLocal) {
        rxChat = await ensureRemoteDialog(item.chatId);
      }

      await rxChat?.postChatMessage(
        existingId: item.id,
        existingDateTime: item.at,
        text: item.text,
        attachments: item.attachments,
        repliesTo:
            item.repliesTo.map((e) => e.original).whereNotNull().toList(),
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
    if (id.isLocalWith(me)) {
      await ensureRemoteMonolog(name);
      return;
    }

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
    ChatData? monolog;

    try {
      if (id.isLocalWith(me)) {
        _monologShouldBeHidden = true;
        monolog = _chat(await _graphQlProvider.createMonologChat(null));

        // Delete the local [Chat]-monolog from [Hive], since it won't be
        // removed as is will be hidden right away.
        await remove(id);

        id = monolog.chat.value.id;
        await _monologLocal.set(id);
      }

      await _graphQlProvider.hideChat(id);
    } catch (_) {
      if (id == monolog?.chat.value.id) {
        _monologShouldBeHidden = false;
        _chats[id] = await _putEntry(monolog!);
      } else if (chat != null) {
        _chats[id] = chat;
      }

      rethrow;
    }
  }

  @override
  Future<void> readChat(ChatId chatId, ChatItemId untilId) async {
    await _chats[chatId]?.read(untilId);
  }

  /// Marks the specified [Chat] as read until the provided [ChatItemId] for the
  /// authenticated [MyUser].
  Future<void> readUntil(ChatId chatId, ChatItemId untilId) async {
    await _graphQlProvider.readChat(chatId, untilId);
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
      chat?.remove(message.id, message.key);
    } else {
      Rx<ChatItem>? item =
          chat?.messages.firstWhereOrNull((e) => e.value.id == message.id);
      if (item != null) {
        chat?.messages.remove(item);
      }

      try {
        await _graphQlProvider.deleteChatMessage(message.id);

        if (item != null) {
          chat?.remove(item.value.id, item.value.key);
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
          chat?.remove(item.value.id, item.value.key);
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
        chat?.remove(item.value.id, item.value.key);
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
    List<model.ChatItemQuoteInput> items, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
  }) async {
    if (to.isLocal) {
      to = (await ensureRemoteDialog(to))!.id;
    }

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
  }

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

    if (id.isLocalWith(me)) {
      id = (await ensureRemoteMonolog()).id;
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
    return query.chat?.items.edges.map((e) => e.toHive()).toList() ?? [];
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
  Stream<ChatEvents> chatEvents(ChatId chatId, ChatVersion? Function() ver) =>
      _graphQlProvider.chatEvents(chatId, ver).asyncExpand((event) async* {
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
  Stream<dynamic> keepTyping(ChatId chatId) {
    if (chatId.isLocal) {
      return const Stream.empty();
    }

    return _graphQlProvider.keepTyping(chatId);
  }

  /// Returns an [User] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userRepo.get(id);

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
      if (id.isLocalWith(me)) {
        _localMonologFavoritePosition = newPosition;
        final ChatData monolog =
            _chat(await _graphQlProvider.createMonologChat(null));

        id = monolog.chat.value.id;
        await _monologLocal.set(id);
      }

      await _graphQlProvider.favoriteChat(id, newPosition);
    } catch (e) {
      if (chat?.chat.value.isMonolog == true) {
        _localMonologFavoritePosition = null;
      }

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

  @override
  Future<void> clearChat(ChatId id, [ChatItemId? untilId]) async {
    if (id.isLocal) {
      await _chats[id]?.clear();
      return;
    }

    final HiveRxChat? chat = _chats[id];
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

        final ChatItem? last =
            chat.messages.isNotEmpty ? chat.messages.last.value : null;
        chat.chat.update((c) => c?.lastItem = last);
      }
    }

    try {
      await _graphQlProvider.clearChat(id, until);
    } catch (_) {
      if (chat != null) {
        chat.messages.insertAll(0, items ?? []);
        chat.chat.update((c) => c?.lastItem = lastItem);
      }
      rethrow;
    }
  }

  /// Constructs a [ChatEvent] from the [ChatEventsVersionedMixin$Events].
  ChatEvent chatEvent(ChatEventsVersionedMixin$Events e) {
    if (e.$$typename == 'EventChatCleared') {
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
        node.call.toModel(),
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
    } else if (e.$$typename == 'EventChatCallConversationStarted') {
      var node =
          e as ChatEventsVersionedMixin$Events$EventChatCallConversationStarted;
      return EventChatCallConversationStarted(
        e.chatId,
        node.callId,
        node.at,
        node.call.toModel(),
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
      final BoxEvent event = _localSubscription!.current;
      final ChatId chatId = ChatId(event.key);

      if (event.deleted) {
        await _chats.remove(chatId)?.dispose();
      } else {
        HiveRxChat? chat = _chats[chatId];
        if (chat == null) {
          HiveRxChat entry =
              HiveRxChat(this, _chatLocal, _draftLocal, event.value);
          _chats[chatId] = entry;
          entry.init();
          entry.subscribe();
        } else {
          if (chat.chat.value.isMonolog) {
            if (_localMonologFavoritePosition != null) {
              event.value.value.favoritePosition =
                  _localMonologFavoritePosition;
              _localMonologFavoritePosition = null;
            }

            if (_monologShouldBeHidden) {
              event.value.value.isHidden = _monologShouldBeHidden;
              _monologShouldBeHidden = false;
            }
          }

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
      final BoxEvent event = _draftSubscription!.current;
      final ChatId chatId = ChatId(event.key);

      if (event.deleted) {
        _chats[chatId]?.draft.value = null;
      } else {
        final HiveRxChat? chat = _chats[chatId];
        if (chat != null) {
          chat.draft.value = event.value;
          chat.draft.refresh();
        }
      }
    }
  }

  /// Initializes [_recentChatsRemoteEvents] subscription.
  Future<void> _initRemoteSubscription() async {
    _remoteSubscription?.close(immediate: true);
    _remoteSubscription = StreamQueue(_recentChatsRemoteEvents());
    await _remoteSubscription!.execute(_recentChatsRemoteEvent);
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
  Stream<RecentChatsEvent> _recentChatsRemoteEvents() =>
      _graphQlProvider.recentChatsTopEvents(3).asyncExpand((event) async* {
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
    Mutex? mutex = _putEntryGuards[data.chat.value.id];
    if (mutex == null) {
      mutex = Mutex();
      _putEntryGuards[data.chat.value.id] = mutex;
    }

    return await mutex.protect(() async {
      HiveRxChat? entry = chats[data.chat.value.id];

      if (entry == null) {
        // If [data] is a remote [Chat]-dialog, then try to replace the existing
        // local [Chat], if any is associated with this [data].
        if (!data.chat.value.isGroup && !data.chat.value.id.isLocal) {
          final ChatMember? member = data.chat.value.members.firstWhereOrNull(
            (m) => data.chat.value.isMonolog || m.user.id != me,
          );

          if (member != null) {
            final ChatId localId = ChatId.local(member.user.id);
            final HiveRxChat? localChat = chats[localId];

            if (localChat != null) {
              chats.move(localId, data.chat.value.id);
              await localChat.updateChat(data.chat.value);
              entry = localChat;
            }

            _draftLocal.move(localId, data.chat.value.id);
            remove(localId);
          }
        }

        _putChat(data.chat);

        if (entry == null) {
          entry = HiveRxChat(this, _chatLocal, _draftLocal, data.chat);
          _chats[data.chat.value.id] = entry;
          entry.init();
          entry.subscribe();
        }
      } else {
        _putChat(data.chat);
      }

      for (var item in [
        if (data.lastItem != null) data.lastItem!,
        if (data.lastReadItem != null) data.lastReadItem!,
      ]) {
        entry.put(item);
      }

      _putEntryGuards.remove(data.chat.value.id);
      return entry;
    });
  }

  /// Constructs a new [ChatData] from the given [ChatMixin] fragment.
  ChatData _chat(ChatMixin q) {
    for (var m in q.members.nodes) {
      _userRepo.put(m.user.toHive());
    }

    return q.toData();
  }

  /// Initializes [_favoriteChatsEvents] subscription.
  Future<void> _initFavoriteChatsSubscription() async {
    _favoriteChatsSubscription?.cancel();
    _favoriteChatsSubscription = StreamQueue(
      _favoriteChatsEvents(_sessionLocal.getFavoriteChatsListVersion),
    );
    await _favoriteChatsSubscription!.execute(_favoriteChatsEvent);
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
  Stream<FavoriteChatsEvents> _favoriteChatsEvents(
    FavoriteChatsListVersion? Function() ver,
  ) =>
      _graphQlProvider.favoriteChatsEvents(ver).asyncExpand((event) async* {
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

  /// Returns a [HiveRxChat] being a local [Chat]-dialog between the given
  /// [responderId] and the authenticated [MyUser].
  Future<HiveRxChat> _createLocalDialog(UserId responderId) async {
    final ChatId chatId = ChatId.local(responderId);

    final List<RxUser?> users = [
      await _userRepo.get(me),
      if (responderId != me) await _userRepo.get(responderId)
    ];

    final ChatData chatData = ChatData(
      HiveChat(
        Chat(
          chatId,
          members: users
              .whereNotNull()
              .map((e) => ChatMember(e.user.value, PreciseDateTime.now()))
              .toList(),
          kindIndex: ChatKind.values
              .indexOf(responderId == me ? ChatKind.monolog : ChatKind.dialog),
        ),
        ChatVersion('0'),
        null,
        null,
      ),
      null,
      null,
    );

    return _putEntry(chatData);
  }

  /// Initializes the [monolog], fetching it from remote, if none is known.
  Future<void> _initMonolog() async {
    if (monolog.isLocal) {
      final ChatMixin? query = await _graphQlProvider.getMonolog();
      if (query == null) {
        await _createLocalDialog(me);
      } else {
        _monologLocal.set(query.id);
      }
    }
  }
}

/// Result of fetching a [Chat].
class ChatData {
  const ChatData(this.chat, this.lastItem, this.lastReadItem);

  /// [HiveChat] returned from the [Chat] fetching.
  final HiveChat chat;

  /// [HiveChatItem] of a [Chat.lastItem] returned from the [Chat] fetching.
  final HiveChatItem? lastItem;

  /// [HiveChatItem] of a [Chat.lastReadItem] returned from the [Chat] fetching.
  final HiveChatItem? lastReadItem;
}
