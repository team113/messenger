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

import 'package:get/get.dart';

import '/api/backend/schema.dart'
    show CropAreaInput, DeleteChatForwardErrorCode, DeleteChatMessageErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/chat_message_input.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/native_file.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import 'auth.dart';
import 'disposable_service.dart';

/// Service responsible for [Chat]s related functionality.
class ChatService extends Dependency {
  ChatService(this._chatRepository, this._authService);

  /// Repository to fetch [Chat]s from.
  final AbstractChatRepository _chatRepository;

  /// [AuthService] to get an authorized user.
  final AuthService _authService;

  /// Returns the [RxStatus] of the [paginated] initialization.
  Rx<RxStatus> get status => _chatRepository.status;

  /// Returns the reactive map of the currently paginated [RxChat]s.
  RxObsMap<ChatId, RxChat> get paginated => _chatRepository.paginated;

  /// Returns the [Paginated] of archived [RxChat]s.
  Paginated<ChatId, RxChat> get archived => _chatRepository.archived;

  /// Returns the current reactive map of all [RxChat]s available.
  RxObsMap<ChatId, RxChat> get chats => _chatRepository.chats;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  /// Indicates whether the [paginated] have next page.
  RxBool get hasNext => _chatRepository.hasNext;

  /// Indicates whether a next page of the [paginated] is loading.
  RxBool get nextLoading => _chatRepository.nextLoading;

  /// Returns [ChatId] of the [Chat]-monolog of the currently authenticated
  /// [MyUser], if any.
  ChatId get monolog => _chatRepository.monolog;

  /// Returns [ChatId] of the [Chat]-support of the currently authenticated
  /// [MyUser], if any.
  ChatId get support => _chatRepository.support;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    _chatRepository.init(onMemberRemoved: _onMemberRemoved);
    super.onInit();
  }

  /// Ensures the [chats] are initialized.
  void ensureInitialized() {
    _chatRepository.init(onMemberRemoved: _onMemberRemoved, pagination: true);
  }

  /// Creates a group [Chat] with the provided members and the authenticated
  /// [MyUser], optionally [name]d.
  Future<RxChat> createGroupChat(
    List<UserId> memberIds, {
    ChatName? name,
  }) async {
    Log.debug('createGroupChat($memberIds, $name)', '$runtimeType');
    return await _chatRepository.createGroupChat(memberIds, name: name);
  }

  /// Returns a [RxChat] by the provided [id].
  FutureOr<RxChat?> get(ChatId id) {
    Log.debug('get($id)', '$runtimeType');
    return _chatRepository.get(id);
  }

  /// Returns a [ChatItem] by the provided [id].
  FutureOr<ChatItem?> getItem(ChatItemId id) {
    Log.debug('getItem($id)', '$runtimeType');
    return _chatRepository.getItem(id);
  }

  /// Fetches the next [paginated] page.
  FutureOr<void> next() async {
    if (_chatRepository.hasNext.value) {
      Log.debug('next()', '$runtimeType');
      await _chatRepository.next();
    }
  }

  /// Renames the specified [Chat] by the authority of authenticated [MyUser].
  ///
  /// Removes the [Chat.name] of the [Chat] if the provided [name] is `null`.
  ///
  /// Only [Chat]-groups can be named or renamed.
  Future<void> renameChat(ChatId id, ChatName? name) async {
    Log.debug('renameChat($id, $name)', '$runtimeType');
    await _chatRepository.renameChat(id, name);
  }

  /// Posts a new [ChatMessage] to the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// For the posted [ChatMessage] to be meaningful, at least one of [text] or
  /// [attachments] arguments must be specified and non-empty.
  ///
  /// Specify [repliesTo] argument if the posted [ChatMessage] is going to be a
  /// reply to some other [ChatItem].
  Future<void> sendChatMessage(
    ChatId chatId, {
    ChatMessageText? text,
    List<Attachment>? attachments,
    List<ChatItem> repliesTo = const [],
  }) {
    Log.debug(
      'sendChatMessage($chatId, $text, $attachments, $repliesTo)',
      '$runtimeType',
    );

    if (text?.val.isNotEmpty != true &&
        attachments?.isNotEmpty != true &&
        repliesTo.isNotEmpty) {
      text ??= const ChatMessageText(' ');
    } else if (text != null) {
      text = ChatMessageText(text.val.trim());

      if (text.val.length > ChatMessageText.maxLength) {
        final List<ChatMessageText> chunks = text.split();
        int i = 0;

        return Future.forEach<ChatMessageText>(
          chunks,
          (text) => _chatRepository.sendChatMessage(
            chatId,
            text: text,
            attachments: i++ != chunks.length - 1 ? null : attachments,
            repliesTo: repliesTo,
          ),
        );
      }
    }

    return _chatRepository.sendChatMessage(
      chatId,
      text: text?.val.isEmpty == true ? null : text,
      attachments: attachments,
      repliesTo: repliesTo,
    );
  }

  /// Resends the specified [item].
  Future<void> resendChatItem(ChatItem item) async {
    Log.debug('resendChatItem($item)', '$runtimeType');
    await _chatRepository.resendChatItem(item);
  }

  /// Marks the specified [Chat] as hidden for the authenticated [MyUser].
  Future<void> hideChat(ChatId id) {
    Log.debug('hideChat($id)', '$runtimeType');

    final Chat? chat = chats[id]?.chat.value;
    if (chat != null) {
      router.removeWhere((e) => chat.isRoute(e, me));
    }

    return _chatRepository.hideChat(id);
  }

  /// Archives or unarchives the specified [Chat] for the authenticated
  /// [MyUser].
  Future<void> archiveChat(ChatId id, bool archive) {
    Log.debug('archiveChat($id, $archive)', '$runtimeType');
    return _chatRepository.archiveChat(id, archive);
  }

  /// Adds an [User] to a [Chat]-group by the authority of the authenticated
  /// [MyUser].
  Future<void> addChatMember(ChatId chatId, UserId userId) async {
    Log.debug('addChatMember($chatId, $userId)', '$runtimeType');
    await _chatRepository.addChatMember(chatId, userId);
  }

  /// Removes an [User] from a [Chat]-group by the authority of the
  /// authenticated [MyUser].
  Future<void> removeChatMember(ChatId chatId, UserId userId) async {
    Log.debug('removeChatMember($chatId, $userId)', '$runtimeType');

    RxChat? chat;

    if (userId == me) {
      chat = chats[chatId];
      if (router.route.startsWith('${Routes.chats}/$chatId')) {
        router.home();
      }
    }

    try {
      await _chatRepository.removeChatMember(chatId, userId);
    } catch (_) {
      if (chat != null) {
        chats[chatId] = chat;
      }

      rethrow;
    }
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
  /// This method should be called whenever the authenticated [MyUser] reads
  /// new [ChatItem]s appeared in the Chat's UI and directly influences the
  /// [Chat.unreadCount] value.
  Future<void> readChat(ChatId chatId, ChatItemId untilId) async {
    Log.debug('readChat($chatId, $untilId)', '$runtimeType');
    await _chatRepository.readChat(chatId, untilId);
  }

  /// Marks all the [chats] as read for the authenticated [MyUser] until their
  /// [Chat.lastItem]s available.
  Future<void> readAll(List<ChatId>? ids) async {
    Log.debug('readAll()', '$runtimeType');
    await _chatRepository.readAll(ids);
  }

  /// Edits the specified [ChatMessage] posted by the authenticated [MyUser].
  Future<void> editChatMessage(
    ChatMessage item, {
    ChatMessageTextInput? text,
    ChatMessageAttachmentsInput? attachments,
    ChatMessageRepliesInput? repliesTo,
  }) {
    Log.debug('editChatMessage($item, $text)', '$runtimeType');

    if (text?.changed?.val.trim() == item.text?.val.trim()) {
      text = null;
    } else if (text != null) {
      text = ChatMessageTextInput(
        text.changed == null ? null : ChatMessageText(text.changed!.val.trim()),
      );
    }

    if (item.attachments
        .map((e) => e.id)
        .sameAs(attachments?.changed.map((e) => e.id))) {
      attachments = null;
    }

    if (item.repliesTo
        .map((e) => e.original?.id)
        .sameAs(repliesTo?.changed.map((e) => e))) {
      repliesTo = null;
    }

    if ((text?.changed ?? item.text)?.val.isEmpty != false &&
        (attachments?.changed ?? item.attachments).isEmpty &&
        (repliesTo?.changed ?? item.repliesTo).isNotEmpty) {
      text = const ChatMessageTextInput(ChatMessageText(' '));
    }

    if (text != null || attachments != null || repliesTo != null) {
      return _chatRepository.editChatMessage(
        item,
        text: text,
        attachments: attachments,
        repliesTo: repliesTo,
      );
    }

    return Future.value();
  }

  /// Deletes the specified [ChatItem] posted by the authenticated [MyUser].
  Future<void> deleteChatItem(ChatItem item) async {
    Log.debug('deleteChatItem($item)', '$runtimeType');

    if (item is! ChatMessage && item is! ChatForward) {
      throw UnimplementedError('Deletion of $item is not implemented.');
    }

    Chat? chat = chats[item.chatId]?.chat.value;

    if (item is ChatMessage) {
      if (item.status.value != SendingStatus.error) {
        if (item.author.id != me) {
          throw const DeleteChatMessageException(
            DeleteChatMessageErrorCode.notAuthor,
          );
        }

        if (me != null && chat?.isRead(item, me!) == true) {
          throw const DeleteChatMessageException(
            DeleteChatMessageErrorCode.uneditable,
          );
        }
      }

      await _chatRepository.deleteChatMessage(item);
    } else if (item is ChatForward) {
      if (item.status.value != SendingStatus.error) {
        if (item.author.id != me) {
          throw const DeleteChatForwardException(
            DeleteChatForwardErrorCode.notAuthor,
          );
        }

        if (me != null && chat?.isRead(item, me!) == true) {
          throw const DeleteChatForwardException(
            DeleteChatForwardErrorCode.uneditable,
          );
        }
      }

      await _chatRepository.deleteChatForward(item);
    }
  }

  /// Hides the specified [ChatItem] for the authenticated [MyUser].
  Future<void> hideChatItem(ChatItem item) async {
    Log.debug('hideChatItem($item)', '$runtimeType');
    await _chatRepository.hideChatItem(item.chatId, item.id);
  }

  /// Creates a new [Attachment] from the provided [LocalAttachment] linked to
  /// the authenticated [MyUser] for a later use in the [sendChatMessage]
  /// method.
  Future<Attachment?> uploadAttachment(LocalAttachment attachment) async {
    Log.debug('uploadAttachment($attachment)', '$runtimeType');
    return await _chatRepository.uploadAttachment(attachment);
  }

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the given [Chat]-group (if
  /// any).
  Future<void> createChatDirectLink(
    ChatId chatId,
    ChatDirectLinkSlug slug,
  ) async {
    Log.debug('createChatDirectLink($chatId, $slug)', '$runtimeType');
    await _chatRepository.createChatDirectLink(chatId, slug);
  }

  /// Deletes the current [ChatDirectLink] of the given [Chat]-group.
  Future<void> deleteChatDirectLink(ChatId chatId) async {
    Log.debug('deleteChatDirectLink($chatId)', '$runtimeType');
    await _chatRepository.deleteChatDirectLink(chatId);
  }

  /// Notifies [ChatMember]s about the authenticated [MyUser] typing in the
  /// specified [Chat] at the moment.
  Stream<dynamic> keepTyping(ChatId chatId) {
    Log.debug('keepTyping($chatId)', '$runtimeType');
    return _chatRepository.keepTyping(chatId);
  }

  /// Forwards [ChatItem]s to the specified [Chat] by the authenticated
  /// [MyUser].
  ///
  /// Supported [ChatItem]s are [ChatMessage] and [ChatForward].
  ///
  /// If [text] or [attachments] argument is specified, then the forwarded
  /// [ChatItem]s will be followed with a posted [ChatMessage] containing that
  /// [text] and/or [attachments].
  Future<void> forwardChatItems(
    ChatId from,
    ChatId to,
    List<ChatItemQuoteInput> items, {
    ChatMessageText? text,
    List<AttachmentId>? attachments,
  }) {
    Log.debug(
      'forwardChatItems($from, $to, $items, $text, $attachments)',
      '$runtimeType',
    );

    if (text != null) {
      text = ChatMessageText(text.val.trim());
    }

    return _chatRepository.forwardChatItems(
      from,
      to,
      items,
      text: text?.val.isEmpty == true ? null : text,
      attachments: attachments,
    );
  }

  /// Updates the [Chat.avatar] field with the provided image, or resets it to
  /// `null`, by authority of the authenticated [MyUser].
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

    await _chatRepository.updateChatAvatar(
      id,
      file: file,
      crop: crop,
      onSendProgress: onSendProgress,
    );
  }

  /// Mutes or unmutes the specified [Chat] for the authenticated [MyUser].
  /// Overrides an existing mute even if it's longer.
  Future<void> toggleChatMute(ChatId id, MuteDuration? mute) async {
    Log.debug('toggleChatMute($id, $mute)', '$runtimeType');
    await _chatRepository.toggleChatMute(id, mute);
  }

  /// Callback, called when a [User] identified by the provided [userId] gets
  /// removed from the specified [Chat].
  ///
  /// If [userId] is [me], then removes the specified [Chat] from the [chats].
  Future<void> _onMemberRemoved(ChatId id, UserId userId) async {
    Log.debug('_onMemberRemoved($id, $userId)', '$runtimeType');

    if (userId == me) {
      if (router.route.startsWith('${Routes.chats}/$id')) {
        router.home();
      }
      await _chatRepository.remove(id);
    }
  }

  /// Marks the specified [Chat] as favorited for the authenticated [MyUser] and
  /// sets its [position] in the favorites list.
  Future<void> favoriteChat(ChatId id, [ChatFavoritePosition? position]) async {
    Log.debug('favoriteChat($id, $position)', '$runtimeType');
    await _chatRepository.favoriteChat(id, position);
  }

  /// Removes the specified [Chat] from the favorites list of the authenticated
  /// [MyUser].
  Future<void> unfavoriteChat(ChatId id) async {
    Log.debug('unfavoriteChat($id)', '$runtimeType');
    await _chatRepository.unfavoriteChat(id);
  }

  /// Clears an existing [Chat] (hides all its [ChatItem]s) for the
  /// authenticated [MyUser] until the specified [ChatItem] inclusively.
  ///
  /// Clears all [ChatItem]s in the specified [Chat], if [untilId] if not
  /// provided.
  Future<void> clearChat(ChatId id, [ChatItemId? untilId]) async {
    Log.debug('clearChat($id, $untilId)', '$runtimeType');
    await _chatRepository.clearChat(id, untilId);
  }
}

/// Extension adding a route from the [router] comparison with a [Chat].
extension ChatIsRoute on Chat {
  /// Indicates whether the provided [route] represents this [Chat].
  bool isRoute(String route, UserId? me) {
    final UserId? member = members
        .firstWhereOrNull((e) => e.user.id != me)
        ?.user
        .id;

    final bool byId = route.startsWith('${Routes.chats}/$id');
    final bool byUser =
        isDialog &&
        member != null &&
        route.startsWith('${Routes.chats}/${ChatId.local(member)}');
    final bool byMonolog =
        isMonolog &&
        me != null &&
        route.startsWith('${Routes.chats}/${ChatId.local(me)}');

    return byId || byUser || byMonolog;
  }
}

/// Extension adding an ability to compare equality of two [List]s.
extension CompareListsExtension<T> on Iterable<T> {
  /// Indicates whether the provided [list] is the same as this.
  bool sameAs(Iterable<T>? list) {
    if (list == null || list.length != length) {
      return false;
    }

    for (int i = 0; i < length; i++) {
      if (list.elementAt(i) != elementAt(i)) {
        return false;
      }
    }

    return true;
  }
}
