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

import '/api/backend/schema.dart' show ChatCallFinishReason;
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/provider/hive/chat.dart';
import '/provider/hive/chat_item.dart';
import '/store/model/chat.dart';

/// Possible kinds of a [ChatEvent].
enum ChatEventKind {
  avatarDeleted,
  avatarUpdated,
  callDeclined,
  callFinished,
  callMemberJoined,
  callMemberLeft,
  callMoved,
  callStarted,
  cleared,
  delivered,
  directLinkDeleted,
  directLinkUpdated,
  directLinkUsageCountUpdated,
  favorited,
  hidden,
  itemDeleted,
  itemHidden,
  itemPosted,
  itemTextEdited,
  lastItemUpdated,
  muted,
  read,
  redialed,
  renamed,
  totalItemsCountUpdated,
  typingStarted,
  typingStopped,
  unfavorited,
  unmuted,
  unreadItemsCountUpdated,
}

/// Tag representing a [ChatEvents] kind.
enum ChatEventsKind {
  initialized,
  chat,
  event,
}

/// [Chat] event union.
abstract class ChatEvents {
  const ChatEvents();

  /// [ChatEventsKind] of this event.
  ChatEventsKind get kind;
}

/// Indicator notifying about a GraphQL subscription being successfully
/// initialized.
class ChatEventsInitialized extends ChatEvents {
  const ChatEventsInitialized();

  @override
  ChatEventsKind get kind => ChatEventsKind.initialized;
}

/// Initial state of the [Chat].
class ChatEventsChat extends ChatEvents {
  const ChatEventsChat(this.chat);

  /// Initial state itself.
  final HiveChat chat;

  @override
  ChatEventsKind get kind => ChatEventsKind.chat;
}

/// [ChatEventsVersioned] happening in the [Chat].
class ChatEventsEvent extends ChatEvents {
  const ChatEventsEvent(this.event);

  /// [ChatEventsVersioned] itself.
  final ChatEventsVersioned event;

  @override
  ChatEventsKind get kind => ChatEventsKind.event;
}

/// [ChatEvent]s along with the corresponding [ChatVersion].
class ChatEventsVersioned {
  const ChatEventsVersioned(this.events, this.ver);

  /// [ChatEvent]s themselves.
  final List<ChatEvent> events;

  /// Version of the [Chat]'s state updated by these [ChatEvent]s.
  final ChatVersion ver;
}

/// Events happening in a [Chat].
abstract class ChatEvent {
  const ChatEvent(this.chatId);

  /// ID of the [Chat] this [ChatEvent] is related to.
  final ChatId chatId;

  /// Returns [ChatEventKind] of this [ChatEvent].
  ChatEventKind get kind;
}

/// Event of a [ChatCall] being moved from its [Chat]-dialog to a newly created
/// [Chat]-group.
class EventChatCallMoved extends ChatEvent {
  const EventChatCallMoved(
    ChatId chatId,
    this.callId,
    this.call,
    this.newChatId,
    this.newChat,
    this.newCallId,
    this.newCall,
    this.user,
    this.at,
  ) : super(chatId);

  /// ID of the moved [ChatCall] in the [Chat]-dialog.
  final ChatItemId callId;

  /// Moved [ChatCall] in the [Chat]-dialog.
  final ChatCall call;

  /// ID of the newly created [Chat]-group the [ChatCall] was moved to.
  final ChatId newChatId;

  /// Newly created [Chat]-group the [ChatCall] was moved to.
  final Chat newChat;

  /// ID of the moved [ChatCall] in the newly created [Chat]-group.
  final ChatItemId newCallId;

  /// Moved [ChatCall] in the newly created [Chat]-group.
  final ChatCall newCall;

  /// [User] who moved the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [ChatCall] was moved.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callMoved;
}

/// Event of a [Chat] being renamed by some [User].
class EventChatRenamed extends ChatEvent {
  const EventChatRenamed(ChatId chatId, this.chatName, this.byUser, this.at)
      : super(chatId);

  /// New [ChatName].
  final ChatName? chatName;

  /// [User] who renamed the [Chat].
  final User byUser;

  /// [PreciseDateTime] when the [Chat] was renamed.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.renamed;
}

/// Event of a [User] being redialed in a [ChatCall].
class EventChatCallMemberRedialed extends ChatEvent {
  const EventChatCallMemberRedialed(
    ChatId chatId,
    this.at,
    this.callId,
    this.call,
    this.user,
    this.byUser,
  ) : super(chatId);

  /// ID of the [ChatCall] the [User] is redialed in.
  final ChatItemId callId;

  /// [DateTime] when the [ChatMember] was redialed in the [ChatCall].
  final PreciseDateTime at;

  /// [ChatCall] the [User] is redialed in.
  final ChatCall call;

  /// [User] representing the [ChatMember] who was redialed in the [ChatCall].
  final User user;

  /// [User] representing the [ChatMember] who redialed the [User] in the
  /// [ChatCall].
  final User byUser;

  @override
  ChatEventKind get kind => ChatEventKind.redialed;
}

/// Event of a [Chat] being cleared by the authenticated [MyUser].
class EventChatCleared extends ChatEvent {
  const EventChatCleared(ChatId chatId, this.at) : super(chatId);

  /// [PreciseDateTime] when the [Chat] was cleared.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.cleared;
}

/// Event of a [ChatItem] being hidden by the authenticated [MyUser].
class EventChatItemHidden extends ChatEvent {
  const EventChatItemHidden(ChatId chatId, this.itemId) : super(chatId);

  /// ID of the hidden [ChatItem].
  final ChatItemId itemId;

  @override
  ChatEventKind get kind => ChatEventKind.itemHidden;
}

/// Event of a [Chat] being muted by the authenticated [MyUser].
class EventChatMuted extends ChatEvent {
  const EventChatMuted(ChatId chatId, this.duration) : super(chatId);

  /// Duration the [Chat] should be muted until.
  final MuteDuration duration;

  @override
  ChatEventKind get kind => ChatEventKind.muted;
}

/// Event of a [ChatAvatar] being deleted in a [Chat].
class EventChatAvatarDeleted extends ChatEvent {
  const EventChatAvatarDeleted(ChatId chatId, this.byUser, this.at)
      : super(chatId);

  /// [User] who deleted the [ChatAvatar].
  final User byUser;

  /// [PreciseDateTime] when the [ChatAvatar] was deleted.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.avatarDeleted;
}

/// Event of a [ChatMember] started typing in a [Chat].
class EventChatTypingStarted extends ChatEvent {
  const EventChatTypingStarted(ChatId chatId, this.user) : super(chatId);

  /// [User] who started typing.
  final User user;

  @override
  ChatEventKind get kind => ChatEventKind.typingStarted;
}

/// Event of a [Chat] being unmuted by the authenticated [MyUser].
class EventChatUnmuted extends ChatEvent {
  const EventChatUnmuted(ChatId chatId) : super(chatId);

  @override
  ChatEventKind get kind => ChatEventKind.unmuted;
}

/// Event of a [ChatMember] stopped typing in a [Chat].
class EventChatTypingStopped extends ChatEvent {
  const EventChatTypingStopped(ChatId chatId, this.user) : super(chatId);

  /// [User] who stopped typing.
  final User user;

  @override
  ChatEventKind get kind => ChatEventKind.typingStopped;
}

/// Event of a [Chat] being hidden by the authenticated [MyUser].
class EventChatHidden extends ChatEvent {
  const EventChatHidden(ChatId chatId, this.at) : super(chatId);

  /// [PreciseDateTime] when the [Chat] was hidden.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.hidden;
}

/// Event of a [ChatItem] being deleted by some [User].
class EventChatItemDeleted extends ChatEvent {
  const EventChatItemDeleted(ChatId chatId, this.itemId) : super(chatId);

  /// ID of the deleted [ChatItem].
  final ChatItemId itemId;

  @override
  ChatEventKind get kind => ChatEventKind.itemDeleted;
}

/// Event of a [ChatItem]'s text being edited by its author.
class EventChatItemTextEdited extends ChatEvent {
  const EventChatItemTextEdited(ChatId chatId, this.itemId, this.text)
      : super(chatId);

  /// ID of the edited [ChatItem].
  final ChatItemId itemId;

  /// Edited [ChatItem]'s text.
  final ChatMessageText? text;

  @override
  ChatEventKind get kind => ChatEventKind.itemTextEdited;
}

/// Event of a [ChatCall] being started.
class EventChatCallStarted extends ChatEvent {
  const EventChatCallStarted(ChatId chatId, this.call) : super(chatId);

  /// Started [ChatCall].
  final ChatCall call;

  @override
  ChatEventKind get kind => ChatEventKind.callStarted;
}

/// Event of a [Chat] unread items count being updated.
class EventChatUnreadItemsCountUpdated extends ChatEvent {
  const EventChatUnreadItemsCountUpdated(ChatId chatId, this.count)
      : super(chatId);

  /// Updated unread [ChatItem]s count.
  final int count;

  @override
  ChatEventKind get kind => ChatEventKind.unreadItemsCountUpdated;
}

/// Event of a [ChatAvatar] being updated in a [Chat].
class EventChatAvatarUpdated extends ChatEvent {
  const EventChatAvatarUpdated(ChatId chatId, this.avatar, this.byUser, this.at)
      : super(chatId);

  /// Updated [ChatAvatar].
  final ChatAvatar avatar;

  /// [User] who updated the [ChatAvatar].
  final User byUser;

  /// [PreciseDateTime] when the [ChatAvatar] was updated.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.avatarUpdated;
}

/// Event of a [Chat]'s [ChatDirectLink.usageCount] being updated.
class EventChatDirectLinkUsageCountUpdated extends ChatEvent {
  const EventChatDirectLinkUsageCountUpdated(ChatId chatId, this.usageCount)
      : super(chatId);

  /// New [Chat]'s [ChatDirectLink.usageCount].
  final int usageCount;

  @override
  ChatEventKind get kind => ChatEventKind.directLinkUsageCountUpdated;
}

/// Event of a [ChatCall] being finished.
class EventChatCallFinished extends ChatEvent {
  const EventChatCallFinished(ChatId chatId, this.call, this.reason)
      : super(chatId);

  /// Finished [ChatCall].
  final ChatCall call;

  /// Reason of why the [call] was finished.
  final ChatCallFinishReason reason;

  @override
  ChatEventKind get kind => ChatEventKind.callFinished;
}

/// Event of a [User] leaving a [ChatCall].
class EventChatCallMemberLeft extends ChatEvent {
  const EventChatCallMemberLeft(ChatId chatId, this.user, this.at)
      : super(chatId);

  /// User who left the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [User] left the [ChatCall].
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callMemberLeft;
}

/// Event of a [User] joined a [ChatCall].
class EventChatCallMemberJoined extends ChatEvent {
  const EventChatCallMemberJoined(ChatId chatId, this.user, this.at)
      : super(chatId);

  /// [User] who joined the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [User] joined the [ChatCall].
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callMemberJoined;
}

/// Event of a [Chat] last item being updated.
class EventChatLastItemUpdated extends ChatEvent {
  const EventChatLastItemUpdated(ChatId chatId, this.lastItem) : super(chatId);

  /// Updated last [ChatItem].
  final List<HiveChatItem>? lastItem;

  @override
  ChatEventKind get kind => ChatEventKind.lastItemUpdated;
}

/// Event of last [ChatItem]s posted by the authenticated [MyUser] being
/// delivered to other [User]s in a [Chat].
class EventChatDelivered extends ChatEvent {
  const EventChatDelivered(ChatId chatId, this.at) : super(chatId);

  /// [PreciseDateTime] when [ChatItem]s were delivered.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.delivered;
}

/// Event of a [Chat] being read by a [User].
class EventChatRead extends ChatEvent {
  const EventChatRead(ChatId chatId, this.byUser, this.at) : super(chatId);

  /// [User] who read the [Chat].
  final User byUser;

  /// [PreciseDateTime] when the [Chat] was read by the [User].
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.read;
}

/// Event of a [ChatCall] being declined by a [ChatMember].
class EventChatCallDeclined extends ChatEvent {
  const EventChatCallDeclined(
      ChatId chatId, this.callId, this.call, this.user, this.at)
      : super(chatId);

  /// ID of the [ChatCall] being declined.
  final ChatItemId callId;

  /// Declined [ChatCall].
  final ChatCall call;

  /// [User] who declined the [ChatCall].
  final User user;

  /// [PreciseDateTime] when the [ChatCall] was declined.
  final PreciseDateTime at;

  @override
  ChatEventKind get kind => ChatEventKind.callDeclined;
}

/// Event of a new [ChatItem] being posted in a [Chat].
class EventChatItemPosted extends ChatEvent {
  const EventChatItemPosted(ChatId chatId, this.item) : super(chatId);

  /// New [ChatItem].
  final List<HiveChatItem> item;

  @override
  ChatEventKind get kind => ChatEventKind.itemPosted;
}

/// Event of a [Chat] total items count being updated.
class EventChatTotalItemsCountUpdated extends ChatEvent {
  const EventChatTotalItemsCountUpdated(ChatId chatId, this.count)
      : super(chatId);

  /// Updated total [ChatItem]s count.
  final int count;

  @override
  ChatEventKind get kind => ChatEventKind.totalItemsCountUpdated;
}

/// Event of a [Chat]'s [ChatDirectLink] being deleted.
class EventChatDirectLinkDeleted extends ChatEvent {
  const EventChatDirectLinkDeleted(ChatId chatId) : super(chatId);

  @override
  ChatEventKind get kind => ChatEventKind.directLinkDeleted;
}

/// Event of a [Chat]'s [ChatDirectLink] being updated.
class EventChatDirectLinkUpdated extends ChatEvent {
  const EventChatDirectLinkUpdated(ChatId chatId, this.link) : super(chatId);

  /// New [Chat]'s [ChatDirectLink].
  final ChatDirectLink link;

  @override
  ChatEventKind get kind => ChatEventKind.directLinkUpdated;
}

/// Events happening in the the favorite [Chat]s list.
abstract class FavoriteChatsEvent extends ChatEvent {
  const FavoriteChatsEvent(super.chatId, this.at);

  /// [PreciseDateTime] when this [FavoriteChatsEvent] happened.
  final PreciseDateTime at;
}

/// Event of a [Chat] being added to the favorites list of the authenticated
/// [MyUser].
class EventChatFavorited extends FavoriteChatsEvent {
  const EventChatFavorited(super.chatId, super.at, this.position);

  /// Position of the [Chat] in the favorites list.
  final ChatFavoritePosition position;

  @override
  ChatEventKind get kind => ChatEventKind.favorited;
}

/// Event of a [Chat] being removed from the favorites list of the authenticated
/// [MyUser].
class EventChatUnfavorited extends FavoriteChatsEvent {
  const EventChatUnfavorited(super.chatId, super.at);

  @override
  ChatEventKind get kind => ChatEventKind.unfavorited;
}
