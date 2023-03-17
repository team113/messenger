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

import 'package:get/get.dart';

import '../model/attachment.dart';
import '../model/chat.dart';
import '../model/chat_item.dart';
import '../model/chat_item_quote_input.dart';
import '../model/mute_duration.dart';
import '../model/native_file.dart';
import '../model/user.dart';
import '../repository/chat.dart';
import '/api/backend/schema.dart'
    show DeleteChatMessageErrorCode, DeleteChatForwardErrorCode;
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/obs/obs.dart';
import 'auth.dart';
import 'disposable_service.dart';

/// Service responsible for [Chat]s related functionality.
class ChatService extends DisposableService {
  ChatService(this._chatRepository, this._authService);

  /// Repository to fetch [Chat]s from.
  final AbstractChatRepository _chatRepository;

  /// [AuthService] to get an authorized user.
  final AuthService _authService;

  /// Changes to `true` once the underlying data storage is initialized and
  /// [chats] value is fetched.
  RxBool get isReady => _chatRepository.isReady;

  /// Returns the current reactive map of [RxChat]s.
  RxObsMap<ChatId, RxChat> get chats => _chatRepository.chats;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _authService.userId;

  @override
  void onInit() {
    _chatRepository.init(onMemberRemoved: _onMemberRemoved);
    super.onInit();
  }

  @override
  void onClose() {
    _chatRepository.dispose();
    super.onClose();
  }

  /// Creates a group [Chat] with the provided members and the authenticated
  /// [MyUser], optionally [name]d.
  Future<RxChat> createGroupChat(List<UserId> memberIds, {ChatName? name}) =>
      _chatRepository.createGroupChat(memberIds, name: name);

  /// Creates a [Chat]-monolog for the authenticated [MyUser].
  Future<void> createMonologChat({ChatName? name}) =>
      _chatRepository.createMonologChat(name: name);

  /// Returns a [Chat] by the provided [id].
  Future<RxChat?> get(ChatId id) => _chatRepository.get(id);

  /// Renames the specified [Chat] by the authority of authenticated [MyUser].
  ///
  /// Removes the [Chat.name] of the [Chat] if the provided [name] is `null`.
  ///
  /// Only [Chat]-groups can be named or renamed.
  Future<void> renameChat(ChatId id, ChatName? name) =>
      _chatRepository.renameChat(id, name);

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
  Future<void> resendChatItem(ChatItem item) =>
      _chatRepository.resendChatItem(item);

  /// Marks the specified [Chat] as hidden for the authenticated [MyUser].
  Future<void> hideChat(ChatId id) {
    final Chat? chat = chats[id]?.chat.value;
    if (chat != null) {
      router.removeWhere((e) => chat.isRoute(e, me));
    }

    return _chatRepository.hideChat(id);
  }

  /// Adds an [User] to a [Chat]-group by the authority of the authenticated
  /// [MyUser].
  Future<void> addChatMember(ChatId chatId, UserId userId) =>
      _chatRepository.addChatMember(chatId, userId);

  /// Removes an [User] from a [Chat]-group by the authority of the
  /// authenticated [MyUser].
  Future<void> removeChatMember(ChatId chatId, UserId userId) async {
    RxChat? chat;

    if (userId == me) {
      chat = chats.remove(chatId);
      if (router.route.startsWith('${Routes.chat}/$chatId')) {
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
  Future<void> readChat(ChatId chatId, ChatItemId untilId) =>
      _chatRepository.readChat(chatId, untilId);

  /// Edits the specified [ChatMessage] posted by the authenticated [MyUser].
  Future<void> editChatMessage(ChatMessage item, ChatMessageText? text) =>
      _chatRepository.editChatMessageText(item, text);

  /// Deletes the specified [ChatItem] posted by the authenticated [MyUser].
  Future<void> deleteChatItem(ChatItem item) async {
    if (item is! ChatMessage && item is! ChatForward) {
      throw UnimplementedError('Deletion of $item is not implemented.');
    }

    Chat? chat = chats[item.chatId]?.chat.value;

    if (item is ChatMessage) {
      if (item.authorId != me) {
        throw const DeleteChatMessageException(
          DeleteChatMessageErrorCode.notAuthor,
        );
      }

      if (me != null && chat?.isRead(item, me!) == true) {
        throw const DeleteChatMessageException(DeleteChatMessageErrorCode.read);
      }

      await _chatRepository.deleteChatMessage(item);
    } else if (item is ChatForward) {
      if (item.authorId != me) {
        throw const DeleteChatForwardException(
          DeleteChatForwardErrorCode.notAuthor,
        );
      }

      if (me != null && chat?.isRead(item, me!) == true) {
        throw const DeleteChatForwardException(DeleteChatForwardErrorCode.read);
      }

      await _chatRepository.deleteChatForward(item);
    }
  }

  /// Hides the specified [ChatItem] for the authenticated [MyUser].
  Future<void> hideChatItem(ChatItem item) async {
    await _chatRepository.hideChatItem(item.chatId, item.id);
  }

  /// Creates a new [Attachment] from the provided [LocalAttachment] linked to
  /// the authenticated [MyUser] for a later use in the [sendChatMessage]
  /// method.
  Future<Attachment> uploadAttachment(LocalAttachment attachment) =>
      _chatRepository.uploadAttachment(attachment);

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the given [Chat]-group (if
  /// any).
  Future<void> createChatDirectLink(ChatId chatId, ChatDirectLinkSlug slug) =>
      _chatRepository.createChatDirectLink(chatId, slug);

  /// Deletes the current [ChatDirectLink] of the given [Chat]-group.
  Future<void> deleteChatDirectLink(ChatId chatId) =>
      _chatRepository.deleteChatDirectLink(chatId);

  /// Notifies [ChatMember]s about the authenticated [MyUser] typing in the
  /// specified [Chat] at the moment.
  Stream<dynamic> keepTyping(ChatId chatId) =>
      _chatRepository.keepTyping(chatId);

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
    void Function(int count, int total)? onSendProgress,
  }) =>
      _chatRepository.updateChatAvatar(
        id,
        file: file,
        onSendProgress: onSendProgress,
      );

  /// Mutes or unmutes the specified [Chat] for the authenticated [MyUser].
  /// Overrides an existing mute even if it's longer.
  Future<void> toggleChatMute(ChatId id, MuteDuration? mute) =>
      _chatRepository.toggleChatMute(id, mute);

  /// Callback, called when a [User] identified by the provided [userId] gets
  /// removed from the specified [Chat].
  ///
  /// If [userId] is [me], then removes the specified [Chat] from the [chats].
  Future<void> _onMemberRemoved(ChatId id, UserId userId) async {
    if (userId == me) {
      if (router.route.startsWith('${Routes.chat}/$id')) {
        router.home();
      }
      await _chatRepository.remove(id);
    }
  }

  /// Marks the specified [Chat] as favorited for the authenticated [MyUser] and
  /// sets its [position] in the favorites list.
  Future<void> favoriteChat(ChatId id, [ChatFavoritePosition? position]) =>
      _chatRepository.favoriteChat(id, position);

  /// Removes the specified [Chat] from the favorites list of the authenticated
  /// [MyUser].
  Future<void> unfavoriteChat(ChatId id) => _chatRepository.unfavoriteChat(id);

  /// Clears an existing [Chat] (hides all its [ChatItem]s) for the
  /// authenticated [MyUser] until the specified [ChatItem] inclusively.
  ///
  /// Clears all [ChatItem]s in the specified [Chat], if [untilId] if not
  /// provided.
  Future<void> clearChat(ChatId id, [ChatItemId? untilId]) =>
      _chatRepository.clearChat(id, untilId);
}

/// Extension adding a route from the [router] comparison with a [Chat].
extension ChatIsRoute on Chat {
  /// Indicates whether the provided [route] represents this [Chat].
  bool isRoute(String route, UserId? me) {
    final UserId? member =
        members.firstWhereOrNull((e) => e.user.id != me)?.user.id;

    final bool byId = route.startsWith('${Routes.chat}/$id');
    final bool byUser = isDialog &&
        member != null &&
        route.startsWith('${Routes.chat}/${ChatId.local(member)}');

    return byId || byUser;
  }
}
