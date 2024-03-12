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

import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/chat_message_input.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/repository/user.dart';
import '/util/obs/obs.dart';
import 'paginated.dart';

/// [Chat]s repository interface.
abstract class AbstractChatRepository {
  /// Returns reactive map of [RxChat]s in the current pagination view.
  RxObsMap<ChatId, RxChat> get paginated;

  /// Returns reactive map of all [RxChat]s stored.
  RxObsMap<ChatId, RxChat> get chats;

  /// Returns the initialization [RxStatus] of this repository.
  Rx<RxStatus> get status;

  /// Returns [ChatId] of the [Chat]-monolog of the currently authenticated
  /// [MyUser], if any.
  ChatId get monolog;

  /// Indicates whether the [paginated] have next page.
  RxBool get hasNext;

  /// Indicates whether a next page of the [paginated] is loading.
  RxBool get nextLoading;

  /// Initializes this repository.
  ///
  /// Callback [onMemberRemoved] should be called once an [User] is removed from
  /// a [Chat].
  Future<void> init({
    required Future<void> Function(ChatId, UserId) onMemberRemoved,
  });

  /// Clears the stored [chats].
  Future<void> clear();

  /// Returns an [RxChat] by the provided [id].
  FutureOr<RxChat?> get(ChatId id);

  /// Removes a [Chat] identified by the provided [id] from the [chats].
  Future<void> remove(ChatId id);

  /// Fetches the next [paginated] page.
  Future<void> next();

  /// Renames the specified [Chat] by the authority of authenticated [MyUser].
  ///
  /// Removes the [Chat.name] of the [Chat] if the provided [name] is `null`.
  ///
  /// Only [Chat]-groups can be named or renamed.
  Future<void> renameChat(ChatId id, ChatName? name);

  /// Creates a group [Chat] with the provided members and the authenticated
  /// [MyUser], optionally [name]d.
  Future<RxChat> createGroupChat(List<UserId> memberIds, {ChatName? name});

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
  });

  /// Resends the specified [item].
  Future<void> resendChatItem(ChatItem item);

  /// Adds an [User] to a [Chat]-group by the authority of the authenticated
  /// [MyUser].
  Future<void> addChatMember(ChatId chatId, UserId userId);

  /// Removes an [User] from a [Chat]-group by the authority of the
  /// authenticated [MyUser].
  Future<void> removeChatMember(ChatId chatId, UserId userId);

  /// Marks the specified [Chat] as hidden for the authenticated [MyUser].
  Future<void> hideChat(ChatId id);

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
  /// new [ChatItem]s appeared in the [Chat]'s UI and directly influences the
  /// [Chat.unreadCount] value.
  Future<void> readChat(ChatId chatId, ChatItemId untilId);

  /// Edits the specified [ChatMessage] posted by the authenticated [MyUser].
  Future<void> editChatMessage(
    ChatMessage message, {
    ChatMessageTextInput? text,
    ChatMessageAttachmentsInput? attachments,
    ChatMessageRepliesInput? repliesTo,
  });

  /// Deletes the specified [ChatMessage] posted by the authenticated [MyUser].
  Future<void> deleteChatMessage(ChatMessage message);

  /// Deletes the specified [ChatForward] posted by the authenticated [MyUser].
  Future<void> deleteChatForward(ChatForward forward);

  /// Hides the specified [ChatItem] for the authenticated [MyUser].
  Future<void> hideChatItem(ChatId chatId, ChatItemId id);

  /// Creates a new [Attachment] linked to the authenticated [MyUser] for a
  /// later use in the [sendChatMessage] method.
  Future<Attachment> uploadAttachment(LocalAttachment attachment);

  /// Creates a new [ChatDirectLink] with the specified [ChatDirectLinkSlug] and
  /// deletes the current active [ChatDirectLink] of the given [Chat]-group (if
  /// any).
  Future<void> createChatDirectLink(ChatId chatId, ChatDirectLinkSlug slug);

  /// Deletes the current [ChatDirectLink] of the given [Chat]-group.
  Future<void> deleteChatDirectLink(ChatId chatId);

  /// Notifies [ChatMember]s about the authenticated [MyUser] typing in the
  /// specified [Chat] at the moment.
  Stream<dynamic> keepTyping(ChatId id);

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
  });

  /// Updates the [Chat.avatar] field with the provided image, or resets it to
  /// `null`, by authority of the authenticated [MyUser].
  Future<void> updateChatAvatar(
    ChatId id, {
    NativeFile? file,
    void Function(int count, int total)? onSendProgress,
  });

  /// Mutes or unmutes the specified [Chat] for the authenticated [MyUser].
  /// Overrides an existing mute even if it's longer.
  Future<void> toggleChatMute(ChatId id, MuteDuration? mute);

  /// Marks the specified [Chat] as favorited for the authenticated [MyUser] and
  /// sets its position in the favorites list.
  Future<void> favoriteChat(ChatId id, ChatFavoritePosition? position);

  /// Removes the specified [Chat] from the favorites list of the authenticated
  /// [MyUser].
  Future<void> unfavoriteChat(ChatId id);

  /// Clears an existing [Chat] (hides all its [ChatItem]s) for the
  /// authenticated [MyUser] until the specified [ChatItem] inclusively.
  ///
  /// Clears all [ChatItem]s in the specified [Chat], if [untilId] if not
  /// provided.
  Future<void> clearChat(ChatId id, [ChatItemId? untilId]);
}

/// Unified reactive [Chat] entity with its [ChatItem]s.
abstract class RxChat implements Comparable<RxChat> {
  /// Reactive value of a [Chat] this [RxChat] represents.
  Rx<Chat> get chat;

  /// Returns a [ChatId] of the [chat].
  ChatId get id => chat.value.id;

  // TODO: Use observable variant of [RxSplayTreeMap] here with a pair of
  //       [PreciseDateTime] and [ChatItemId] as a key.
  /// Observable list of [ChatItem]s of the [chat].
  RxObsList<Rx<ChatItem>> get messages;

  /// Status of the [messages] fetching.
  ///
  /// May be:
  /// - `status.isEmpty`, meaning [messages] were not yet initialized.
  /// - `status.isLoading`, meaning [messages] are being loaded from the
  ///   local storage.
  /// - `status.isSuccess`, meaning [messages] were successfully initialized
  ///   with local data and are ready to be used.
  /// - `status.isLoadingMore`, meaning [messages] are being fetched from the
  ///   service.
  Rx<RxStatus> get status;

  /// List of [User]s currently typing in this [chat].
  RxList<User> get typingUsers;

  /// [Paginated] of [User]s being members of this [chat].
  Paginated<UserId, RxChatMember> get members;

  /// Text representing the title of this [chat].
  String get title;

  /// Reactive [Avatar] of this [chat].
  Rx<Avatar?> get avatar;

  /// Returns [MyUser]'s [UserId].
  UserId? get me;

  /// Returns an actual [UserCallCover] of this [RxChat].
  UserCallCover? get callCover;

  /// [ChatMessage] being a draft in this [chat].
  Rx<ChatMessage?> get draft;

  /// Indicates whether the [messages] have next page.
  RxBool get hasNext;

  /// Indicates whether a next page of the [messages] is loading.
  RxBool get nextLoading;

  /// Indicates whether the [messages] have previous page.
  RxBool get hasPrevious;

  /// Indicates whether a previous page of the [messages] is loading.
  RxBool get previousLoading;

  /// [LastChatRead]s of this [chat].
  RxList<LastChatRead> get reads;

  /// Count of [ChatItem]s unread by the authenticated [MyUser] in this
  /// [RxChat].
  RxInt get unreadCount;

  /// Indicates whether this [RxChat] is blocked or not.
  bool get blocked =>
      chat.value.isDialog &&
      members.values
              .firstWhereOrNull((e) => e.user.id != me)
              ?.user
              .user
              .value
              .isBlocked !=
          null;

  /// Returns the first [ChatItem] unread by the currently authenticated
  /// [MyUser] in this [chat].
  Rx<ChatItem>? get firstUnread;

  /// Returns the last [ChatItem] of this [RxChat].
  ChatItem? get lastItem;

  /// Listens to the updates of this [RxChat] while the returned [Stream] is
  /// listened to.
  Stream<void> get updates;

  /// Indicates whether this [chat] has an [OngoingCall] active on this device.
  RxBool get inCall;

  /// Fetches the [Paginated] page around the [item], if specified, or
  /// [messages] around the [firstUnread] otherwise.
  ///
  /// If [reply] or [forward] is provided, then the [item] is considered as a
  /// quote of the specified [reply] of [forward].
  Future<Paginated<ChatItemId, Rx<ChatItem>>?> around({
    ChatItem? item,
    ChatItemId? reply,
    ChatItemId? forward,
  });

  /// Fetches the next [messages] page.
  Future<void> next();

  /// Fetches the previous [messages] page.
  Future<void> previous();

  /// Updates the [Attachment]s of the specified [item] to be up-to-date.
  ///
  /// Intended to be used to update the [StorageFile.relativeRef] links.
  Future<void> updateAttachments(ChatItem item);

  /// Updates the [avatar] of the [chat].
  ///
  /// Intended to be used to update the [StorageFile.relativeRef] links.
  Future<void> updateAvatar();

  /// Removes a [ChatItem] identified by its [id].
  Future<void> remove(ChatItemId itemId);

  /// Updates the [draft] with the provided [text], [attachments] and
  /// [repliesTo].
  ///
  /// Resets it, if the specified fields are empty or `null`.
  void setDraft({
    ChatMessageText? text,
    List<Attachment> attachments = const [],
    List<ChatItem> repliesTo = const [],
  });

  // TODO: Remove when backend supports welcome messages.
  /// Posts a new [ChatMessage] with the provided [text] by the recipient.
  Future<void> addMessage(ChatMessageText text);
}

/// Reactive [ChatMember] entity.
class RxChatMember implements Comparable<RxChatMember> {
  RxChatMember(this.user, this.joinedAt);

  /// [RxUser] itself.
  final RxUser user;

  /// [PreciseDateTime] when the [User] became a [ChatMember].
  final PreciseDateTime joinedAt;

  @override
  int compareTo(RxChatMember other) {
    int result = joinedAt.compareTo(other.joinedAt);

    if (result == 0) {
      result = user.id.compareTo(other.user.id);
    }

    return result;
  }
}
